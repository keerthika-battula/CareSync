# =============================================
# CareSync Backend Dockerfile
# Multi-stage build: Builder + Runtime
# =============================================

# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN apk add --no-cache maven
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -S caresync && adduser -S caresync -G caresync

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

RUN chown caresync:caresync app.jar

USER caresync

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
