# ==============================================================================
# CareSync Frontend - React.js + Tailwind CSS + Vite Production Dockerfile
# Self-contained multi-stage build: Node.js 20 Builder + Nginx Alpine Runtime
# ==============================================================================

# Stage 1: Build React SPA
FROM node:20-alpine AS builder

WORKDIR /app

# Accept optional build arguments for environment variables
ARG VITE_API_BASE_URL
ARG VITE_API_URL

ENV VITE_API_BASE_URL=${VITE_API_BASE_URL:-https://caresync-4dfr.onrender.com}
ENV VITE_API_URL=${VITE_API_URL:-https://caresync-4dfr.onrender.com}

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code and build production distribution
COPY . .
RUN npm run build

# Stage 2: Production Nginx Runtime
FROM nginx:alpine AS runtime

# Copy compiled React output to Nginx web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Self-contained Nginx configuration (Listens on port 10000 for Render and port 80)
RUN printf 'server {\n\
    listen 10000 default_server;\n\
    listen 80;\n\
    server_name _;\n\
\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
\n\
    gzip on;\n\
    gzip_vary on;\n\
    gzip_min_length 256;\n\
    gzip_comp_level 6;\n\
    gzip_proxied any;\n\
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;\n\
\n\
    location ~* (index\\.html|manifest\\.json|version\\.json)$ {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;\n\
        add_header Pragma "no-cache" always;\n\
        add_header Expires "0" always;\n\
        try_files $uri =404;\n\
    }\n\
\n\
    location /assets/ {\n\
        add_header Cache-Control "public, max-age=31536000, immutable" always;\n\
        try_files $uri =404;\n\
    }\n\
\n\
    location ~* \\.(?:ico|png|jpg|jpeg|svg|webp|woff|woff2|ttf|eot|wasm)$ {\n\
        add_header Cache-Control "public, max-age=2592000, immutable" always;\n\
        try_files $uri =404;\n\
    }\n\
\n\
    location = /healthz {\n\
        access_log off;\n\
        return 200 "OK";\n\
        add_header Content-Type text/plain;\n\
    }\n\
\n\
    location / {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate, max-age=0" always;\n\
        add_header Pragma "no-cache" always;\n\
        add_header Expires "0" always;\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 10000 80

CMD ["nginx", "-g", "daemon off;"]
