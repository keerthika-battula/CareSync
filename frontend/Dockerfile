# ==============================================================================
# CareSync Frontend - React.js + Tailwind CSS + Vite Production Dockerfile
# Multi-stage build: Node.js 20 Builder + Lightweight Nginx Alpine Runtime
# ==============================================================================

# Stage 1: Build React SPA
FROM node:20-alpine AS builder

WORKDIR /app

# Accept optional build arguments for environment variables
ARG VITE_API_BASE_URL
ARG VITE_API_URL

ENV VITE_API_BASE_URL=${VITE_API_BASE_URL:-https://caresync-4dfr.onrender.com}
ENV VITE_API_URL=${VITE_API_URL:-https://caresync-4dfr.onrender.com}

# Install dependencies with clean cache
COPY package*.json ./
RUN npm ci

# Copy source code and build production distribution
COPY . .
RUN npm run build

# Stage 2: Production Nginx Runtime
FROM nginx:alpine AS runtime

# Copy compiled React output to Nginx web root
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy Nginx template configuration and entrypoint script
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

# Expose Render default port (10000) and standard HTTP (80)
EXPOSE 10000 80

ENTRYPOINT ["/docker-entrypoint.sh"]
