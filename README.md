# webdev-dockerizer

A local development setup for running multiple web projects side by side behind a shared Docker reverse proxy, with a shared MySQL database and phpMyAdmin instance.

## Repository structure

```
.
├── docker-compose.yml       # Reverse proxy (nginx), MySQL, phpMyAdmin
├── example.env              # Template for .env (DB credentials)
├── php-custom.ini           # PHP overrides mounted into the phpMyAdmin container
├── dockerfiles/
│   ├── php-apache.Dockerfile        # PHP 8.2 + Apache
│   ├── php-apache-8.4.Dockerfile    # PHP 8.4 + Apache
│   └── node-nuxt.Dockerfile         # Node 24, runs `npm run dev` for Nuxt
├── nginx/
│   ├── conf.d/               # One vhost file per host (mysql.conf, pma.conf, ...)
│   └── ssl_cert/              # SSL certs (e.g. generated with mkcert), mounted read-only
└── projects/                 # Project codebases are cloned/checked out here (gitignored)
```

All shared containers (reverse proxy, database, phpMyAdmin) and every project's own containers are attached to a single external Docker network called `backend`, which is how nginx can proxy to any of them by container name.

## Initial Setup

1. Place the entire directory in a location of your choice, for example: `/home/username/webdev-dockerizer`.
2. Copy `example.env` to `.env` and fill in `MYSQL_ROOT_PASSWORD`, `MYSQL_USER` and `MYSQL_PASSWORD`.
3. Execute `docker network create backend` to create the shared Docker network.
4. From the repository root, run `docker compose up -d`. This creates and starts:
   - `nginx_proxy` — the reverse proxy (ports 80/443)
   - `mysql_db` — the shared MySQL database (also exposed on host port 3306)
   - `phpmyadmin` — phpMyAdmin, configured for large file imports/exports
5. Add an entry to your `hosts` file to reach phpMyAdmin, e.g. `127.0.0.1 pma.local`.
   Visit [http://pma.local](http://pma.local) (or `https://pma.local` — a cert for `pma.local` is already included under `nginx/ssl_cert`) to verify everything is working.
6. Log into phpMyAdmin with the `MYSQL_USER` / `MYSQL_PASSWORD` (or `root` / `MYSQL_ROOT_PASSWORD`) you set in `.env`.

Any external DB client can also connect directly to `127.0.0.1:3306` using the same credentials.

## Setting Up a New Project

1. Clone the project codebase into `./projects/[projectname]`.
2. If the codebase already has a `docker-compose.yml`, skip to step 4.
3. Otherwise, create a `docker-compose.yml` in the root of the codebase using one of the templates below. Replace `[projectname]` with your desired project name.

### PHP Project Template

```yaml
services:
  [projectname]:
    build:
      context: .
      dockerfile: ../../dockerfiles/php-apache.Dockerfile
    container_name: [projectname]
    networks:
      - backend
    volumes:
      - ./:/var/www/html

networks:
  backend:
    external: true
```

Use `dockerfiles/php-apache-8.4.Dockerfile` instead if the project needs PHP 8.4.

### PHP + Nuxt Project Template

```yaml
name: [projectname]

services:
  [projectname]-php:
    build:
      context: .
      dockerfile: ../../dockerfiles/php-apache.Dockerfile
    container_name: [projectname]-php
    networks:
      - backend
    volumes:
      - ./:/var/www/html

  [projectname]-nuxt:
    build:
      context: ./templates/nuxt
      dockerfile: ../../../../dockerfiles/node-nuxt.Dockerfile
    container_name: [projectname]-nuxt
    networks:
      - backend
    volumes:
      - ./templates/nuxt:/app
    environment:
      - HOST=0.0.0.0
    expose:
      - "3000"
      - "24678"

networks:
  backend:
    external: true
```

`./templates/nuxt` is a folder inside the _project's own codebase_ holding the Nuxt frontend source — create it there, it is not part of this repository.

4. In `./nginx/conf.d`, create a new file called `[projectname].conf` pointing at your project's container(s) and port(s). Pick the snippet matching your project template below and replace `[projectname]`/`[project-url]` with your values.

   If you want SSL, generate the certificate first by running `mkcert [project-url]` inside `./nginx/ssl_cert`, then add a `listen 443 ssl;` server block as shown.

#### PHP-only vhost

```nginx
server {
    listen 80;
    server_name [project-url];

    location / {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]:80;
        proxy_pass $upstream;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        client_max_body_size 0;
    }
}
```

To add SSL to the above, add a second server block:

```nginx
server {
    listen 443 ssl;
    server_name [project-url];

    ssl_certificate /etc/nginx/ssl/[project-url].pem;
    ssl_certificate_key /etc/nginx/ssl/[project-url]-key.pem;

    location / {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]:80;
        proxy_pass $upstream;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        client_max_body_size 0;
    }
}
```

#### PHP + Nuxt vhost

Routes `cp`/`api`/`assets` paths to the PHP container and everything else (including Nuxt's `_nuxt`/`__nuxt` build assets, and websocket upgrades for HMR) to the Nuxt dev server. Adjust the regex in the first `location` block to match whichever paths your PHP backend actually serves.

```nginx
server {
    listen 80;
    server_name [project-url];
    client_max_body_size 0;

    location ~ ^/(cp|api|assets) {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]-php:80;
        proxy_pass $upstream;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location ~ ^/(|_nuxt|__nuxt|\.nuxt) {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]-nuxt:3000;
        proxy_pass $upstream;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name [project-url];

    ssl_certificate /etc/nginx/ssl/[project-url].pem;
    ssl_certificate_key /etc/nginx/ssl/[project-url]-key.pem;

    location ~ ^/(cp|api|assets) {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]-php:80;
        proxy_pass $upstream;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location ~ ^/(|_nuxt|__nuxt|\.nuxt) {
        resolver 127.0.0.11 valid=10s;
        set $upstream http://[projectname]-nuxt:3000;
        proxy_pass $upstream;

        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

5. In the project's codebase, run `docker compose up -d`.
6. Add an entry to your `hosts` file: `127.0.0.1 [project-url]`.
7. Reload nginx so it picks up the new vhost: `docker exec nginx_proxy nginx -s reload` (or restart the `nginx_proxy` container).

You should now be able to visit your project at `http(s)://[project-url]`.
