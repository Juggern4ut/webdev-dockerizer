FROM node:24

# Create app directory
WORKDIR /app

# Copy package files and install dependencies
COPY app/package*.json ./

RUN npm cache clean --force && \
    npm install --prefer-offline --no-audit


# Copy rest of the app
COPY app .

# Führe nuxt prepare aus
RUN npm run postinstall

# Expose Nuxt port
EXPOSE 3000

# Setze die Umgebungsvariablen
ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

# Start Nuxt in development mode
CMD ["npm", "run", "dev"]