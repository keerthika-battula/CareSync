# ==============================================================================
# CareSync Frontend - Flutter Web / PWA Dockerfile
# Multi-stage build: Flutter Builder + Lightweight Nginx Runtime
# ==============================================================================

# Stage 1: Build Flutter Web Release
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Pre-cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and build for web in release mode
COPY . .
RUN flutter build web --release

# Stage 2: Production Nginx Runtime
FROM nginx:alpine AS runtime

# Copy compiled web output
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy Nginx template configuration and entrypoint script
COPY nginx.conf /etc/nginx/conf.d/default.conf.template
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

# Default port documentation (overridden dynamically at runtime by $PORT)
EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
