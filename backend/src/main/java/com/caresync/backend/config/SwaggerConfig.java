package com.caresync.backend.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "CareSync API",
                version = "1.0",
                description = "CareSync — Smart Medicine & Healthcare Reminder Platform API. " +
                              "Your Care. In Sync. On Time.",
                contact = @Contact(name = "CareSync Team")
        ),
        servers = {
                @Server(url = "/", description = "Default Server")
        }
)
@SecurityScheme(
        name = "bearerAuth",
        description = "JWT Authentication. Provide the token as: Bearer <token>",
        scheme = "bearer",
        type = SecuritySchemeType.HTTP,
        bearerFormat = "JWT",
        in = SecuritySchemeIn.HEADER
)
public class SwaggerConfig {
    // Configuration via annotations above
}
