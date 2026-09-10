package com.caresync.backend.modules.user.controller;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminControllerSecurityIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    private User adminUser;
    private User normalUser;
    private String adminToken;
    private String userToken;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();

        adminUser = userRepository.save(User.builder()
                .firstName("System")
                .lastName("Administrator")
                .email("admin@caresync.test")
                .passwordHash(passwordEncoder.encode("AdminPass123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        normalUser = userRepository.save(User.builder()
                .firstName("Regular")
                .lastName("Patient")
                .email("patient@caresync.test")
                .passwordHash(passwordEncoder.encode("PatientPass123!"))
                .role(Role.USER)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        adminToken = jwtService.generateAccessToken(adminUser);
        userToken = jwtService.generateAccessToken(normalUser);
    }

    @Test
    @DisplayName("Unauthenticated request to /api/v1/admin/users returns 401 or 403")
    void testUnauthenticatedAdminAccess_Rejected() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Normal USER accessing /api/v1/admin/users returns 403 Forbidden")
    void testUserAccessToAdminEndpoints_Forbidden() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Normal USER accessing /api/v1/admin/users/{userId} returns 403 Forbidden")
    void testUserAccessToAdminUserDetail_Forbidden() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users/" + normalUser.getId())
                        .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Normal USER calling POST /api/v1/admin/users returns 403 Forbidden")
    void testUserCreatingUserViaAdminApi_Forbidden() throws Exception {
        String body = """
                {
                    "firstName": "Hacked",
                    "lastName": "User",
                    "email": "hacked@caresync.test",
                    "password": "Password123"
                }
                """;

        mockMvc.perform(post("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Normal USER calling PATCH /api/v1/admin/users/{userId}/role returns 403 Forbidden")
    void testUserChangingRole_Forbidden() throws Exception {
        String body = """
                {
                    "role": "ADMIN"
                }
                """;

        mockMvc.perform(patch("/api/v1/admin/users/" + normalUser.getId() + "/role")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Normal USER calling PATCH /api/v1/admin/users/{userId}/status returns 403 Forbidden")
    void testUserChangingStatus_Forbidden() throws Exception {
        String body = """
                {
                    "isActive": false
                }
                """;

        mockMvc.perform(patch("/api/v1/admin/users/" + normalUser.getId() + "/status")
                        .header("Authorization", "Bearer " + userToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("ADMIN accessing /api/v1/admin/users returns 200 OK and paginated users")
    void testAdminAccessToAdminEndpoints_Success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray())
                .andExpect(jsonPath("$.data.content", hasSize(2)))
                .andExpect(jsonPath("$.data.content[*].passwordHash").doesNotExist());
    }

    @Test
    @DisplayName("ADMIN creates user via POST /api/v1/admin/users returns 201 CREATED without passwordHash")
    void testAdminCreateUser_Success() throws Exception {
        String body = """
                {
                    "firstName": "Doctor",
                    "lastName": "Who",
                    "email": "doctor.who@caresync.test",
                    "password": "TardisPassword123!",
                    "role": "USER"
                }
                """;

        mockMvc.perform(post("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.email").value("doctor.who@caresync.test"))
                .andExpect(jsonPath("$.data.role").value("USER"))
                .andExpect(jsonPath("$.data.passwordHash").doesNotExist())
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    @DisplayName("ADMIN cannot demote the only active ADMIN (Last-admin protection returns 400)")
    void testAdminDemoteLastAdmin_FailsWith400() throws Exception {
        String body = """
                {
                    "role": "USER"
                }
                """;

        mockMvc.perform(patch("/api/v1/admin/users/" + adminUser.getId() + "/role")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("Cannot demote the last active administrator")));
    }

    @Test
    @DisplayName("ADMIN cannot deactivate the only active ADMIN (Last-admin protection returns 400)")
    void testAdminDeactivateLastAdmin_FailsWith400() throws Exception {
        String body = """
                {
                    "isActive": false
                }
                """;

        mockMvc.perform(patch("/api/v1/admin/users/" + adminUser.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message", containsString("Cannot deactivate the last active administrator")));
    }

    @Test
    @DisplayName("Public user names endpoint GET /api/v1/users/names requires authentication")
    void testPublicNamesEndpoint_Unauthenticated_Rejected() throws Exception {
        mockMvc.perform(get("/api/v1/users/names"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Public user names endpoint GET /api/v1/users/names returns ONLY display names to normal user")
    void testPublicNamesEndpoint_AuthenticatedUser_ReturnsOnlyNames() throws Exception {
        mockMvc.perform(get("/api/v1/users/names")
                        .header("Authorization", "Bearer " + userToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data", hasSize(2)))
                .andExpect(jsonPath("$.data[0].displayName").exists())
                // Ensure no sensitive or healthcare fields are exposed
                .andExpect(jsonPath("$.data[*].id").doesNotExist())
                .andExpect(jsonPath("$.data[*].email").doesNotExist())
                .andExpect(jsonPath("$.data[*].phoneNumber").doesNotExist())
                .andExpect(jsonPath("$.data[*].role").doesNotExist())
                .andExpect(jsonPath("$.data[*].isActive").doesNotExist())
                .andExpect(jsonPath("$.data[*].passwordHash").doesNotExist())
                .andExpect(jsonPath("$.data[*].medicines").doesNotExist())
                .andExpect(jsonPath("$.data[*].familyMembers").doesNotExist());
    }
}
