package com.caresync.backend.modules.auth.dto;

import lombok.Builder;
import lombok.Data;
import java.util.UUID;

@Data
@Builder
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private UserDto user;

    @Data
    @Builder
    public static class UserDto {
        private UUID id;
        private String email;
        private String firstName;
        private String lastName;
    }
}
