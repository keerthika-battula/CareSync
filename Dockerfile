# ==============================================================================
# CareSync Frontend - React.js + Tailwind CSS + Vite Production Dockerfile
# Root repository context Dockerfile for Render Web Service
# ==============================================================================

# Stage 1: Build React SPA
FROM node:20-alpine AS builder

WORKDIR /app

# Accept optional build arguments for environment variables
ARG VITE_API_BASE_URL
ARG VITE_API_URL

ENV VITE_API_BASE_URL=${VITE_API_BASE_URL:-https://caresync-4dfr.onrender.com}
ENV VITE_API_URL=${VITE_API_URL:-https://caresync-4dfr.onrender.com}

# Install dependencies from frontend directory
COPY frontend/package*.json ./
RUN npm ci

# Copy frontend source code and build production distribution
COPY frontend/ ./
RUN npm run build

# Stage 2: Production Nginx Runtime
FROM nginx:alpine AS runtime

# Copy compiled React output to Nginx web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy Nginx template configuration and entrypoint script
COPY frontend/nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY frontend/docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

# Expose Render default port (10000) and standard HTTP (80)
EXPOSE 10000 80

ENTRYPOINT ["/docker-entrypoint.sh"]
