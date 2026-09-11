## Initial Setup

0. (Optional) Delete the folder `./git` aswell as the file `.gitignore`

1. Place the entire directory in a location of your choice, for example: `/home/username`.
2. Create a file .env in the same directory and set MYSQL_ROOT_PASSWORD aswell as MYSQL_PASSWORD to whatever values you want to use.
2. Execute the command `docker network create backend` to create a local Docker network.
3. Navigate to the `web` folder and run `docker compose up -d`. This will create and start the following containers: - Reverse Proxy - Database - phpMyAdmin
4. Update your `hosts` file with an entry to access phpMyAdmin. For example: `127.0.0.1 pma.local` - To verify everything is working correctly, visit [http://pma.local](http://pma.local) in your browser.

- Use the username and password defined in `./docker-compose.yml`.

## Setting Up a New Project

1. Clone the project codebase into the `./projects/` directory.
2. If the cloned codebase already contains a `docker-compose.yml` file, skip to the next step in your setup process.
3. If not, create a `docker-compose.yml` file in the root of the codebase.
4. Use one of the following templates depending on your project type. Replace `[projectname]` with your desired project name.

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

### Nuxt Project Template

```yaml
services:
  [projectname]:
    build:
      context: .
      dockerfile: ../../dockerfiles/node-nuxt.Dockerfile
    container_name: [projectname]
    networks:
      - backend
    volumes:
      - ./app:/app
    environment:
      - HOST=0.0.0.0
    expose:
      - "3000"
      - "24678"

networks:
  backend:
    external: true
```

5. In the folder `./nginx/conf.d` create a new file called `[projectname].conf`. Replace `[projectname]` with your desired project name.
6. When not using SSL, paste the content of the file `./templates/conf.d/default.conf` into the newly created conf file. 
7. When using SSL use the file `./templates/conf.d/ssl.conf` instead.
    1. If using SSL also execute the command `mkcert [project-url]` in the folder `./nginx/ssl_cert`

8. In the codebase, execute the command `docker compose -p "[projectname]" up -d`. (The Parameter -p [projectname] can be omitted but helps organize the containers in Docker Desktop)
9. In your hosts file create a new entry pointing towards your new project url `127.0.0.1 [project-url]`
9. Either restart the nginx or within the container execute the command `nginx -s reload`

You should now be able to visit your project under `http(s)://[project-url]`
