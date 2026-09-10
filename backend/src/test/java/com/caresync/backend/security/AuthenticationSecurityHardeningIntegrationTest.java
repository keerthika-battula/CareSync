package com.caresync.backend.security;

import com.caresync.backend.modules.auth.dto.LoginRequest;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.user.service.AdminUserService;
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

import java.util.Date;
import java.util.HashMap;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthenticationSecurityHardeningIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private AdminUserService adminUserService;

    private User activeUser;
    private User activeAdmin;
    private User disabledUser;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();

        activeUser = userRepository.save(User.builder()
                .firstName("Active")
                .lastName("User")
                .email("active.user@caresync.test")
                .passwordHash(passwordEncoder.encode("UserPassword123!"))
                .role(Role.USER)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        activeAdmin = userRepository.save(User.builder()
                .firstName("Active")
                .lastName("Admin")
                .email("active.admin@caresync.test")
                .passwordHash(passwordEncoder.encode("AdminPassword123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        disabledUser = userRepository.save(User.builder()
                .firstName("Disabled")
                .lastName("User")
                .email("disabled.user@caresync.test")
                .passwordHash(passwordEncoder.encode("DisabledPass123!"))
                .role(Role.USER)
                .isActive(false)
                .isEmailVerified(true)
                .build());
    }

    @Test
    @DisplayName("Active USER can authenticate via /api/auth/login and receives valid token and user profile")
    void testActiveUserLogin_Success() throws Exception {
        String loginJson = """
                {
                    "email": "active.user@caresync.test",
                    "password": "UserPassword123!"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").isString())
                .andExpect(jsonPath("$.data.user.email").value("active.user@caresync.test"));
    }

    @Test
    @DisplayName("Active ADMIN can authenticate via /api/auth/login")
    void testActiveAdminLogin_Success() throws Exception {
        String loginJson = """
                {
                    "email": "active.admin@caresync.test",
                    "password": "AdminPassword123!"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").isString());
    }

    @Test
    @DisplayName("Disabled user cannot authenticate via /api/auth/login")
    void testDisabledUserLogin_Rejected() throws Exception {
        String loginJson = """
                {
                    "email": "disabled.user@caresync.test",
                    "password": "DisabledPass123!"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginJson))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Disabled user with pre-existing JWT is rejected on protected APIs")
    void testDisabledUserToken_RejectedOnProtectedApis() throws Exception {
        // Generate a token while temporarily enabled
        String token = jwtService.generateAccessToken(disabledUser);

        mockMvc.perform(get("/api/v1/users/names")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Invalid / malformed JWT is rejected with 401 Unauthorized")
    void testMalformedJwt_Rejected() throws Exception {
        mockMvc.perform(get("/api/v1/users/names")
                        .header("Authorization", "Bearer this.is.a.completely.invalid.jwt.token"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Expired JWT is rejected with 401 Unauthorized")
    void testExpiredJwt_Rejected() throws Exception {
        // Generate token expired 1 hour ago
        String expiredToken = io.jsonwebtoken.Jwts.builder()
                .subject(activeUser.getEmail())
                .issuedAt(new Date(System.currentTimeMillis() - 7200000))
                .expiration(new Date(System.currentTimeMillis() - 3600000))
                .signWith(io.jsonwebtoken.security.Keys.hmacShaKeyFor(
                        io.jsonwebtoken.io.Decoders.BASE64.decode("dGVzdC1zZWNyZXQta2V5LWZvci11bml0LXRlc3RpbmctY2FyZXN5bmM=")))
                .compact();

        mockMvc.perform(get("/api/v1/users/names")
                        .header("Authorization", "Bearer " + expiredToken))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Demoted ADMIN loses ADMIN privileges immediately on next request with existing JWT")
    void testDemotedAdminLosesPrivilegesImmediately() throws Exception {
        // Add a second admin so demotion is allowed
        User secondAdmin = userRepository.save(User.builder()
                .firstName("Second")
                .lastName("Admin")
                .email("second.admin@caresync.test")
                .passwordHash(passwordEncoder.encode("SecondAdmin123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        // Issue token to activeAdmin while role = ADMIN
        String adminToken = jwtService.generateAccessToken(activeAdmin);

        // Verify token works on admin endpoint
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());

        // Demote activeAdmin to USER
        adminUserService.updateUserRole(activeAdmin.getId(), Role.USER);

        // Next request with the SAME old JWT must immediately receive 403 Forbidden!
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Deactivated ADMIN loses all access immediately on next request with existing JWT")
    void testDeactivatedAdminLosesAccessImmediately() throws Exception {
        // Add a second admin so deactivation is allowed
        User secondAdmin = userRepository.save(User.builder()
                .firstName("Second")
                .lastName("Admin")
                .email("second.admin2@caresync.test")
                .passwordHash(passwordEncoder.encode("SecondAdmin123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        String adminToken = jwtService.generateAccessToken(activeAdmin);

        // Deactivate activeAdmin
        adminUserService.updateUserStatus(activeAdmin.getId(), false);

        // Next request with the SAME token is treated as unauthenticated because isEnabled() is false
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Mass assignment prevention: Normal registration payload with injected role/isActive is ignored")
    void testRegistrationMassAssignment_Ignored() throws Exception {
        String body = """
                {
                    "firstName": "Attacker",
                    "lastName": "User",
                    "email": "attacker@caresync.test",
                    "password": "Password123!",
                    "role": "ADMIN",
                    "isActive": false,
                    "passwordHash": "$2a$fakeHash"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated());

        User registered = userRepository.findByEmail("attacker@caresync.test").orElseThrow();
        // Role MUST be USER, not ADMIN
        assertEquals(Role.USER, registered.getRole());
        // isActive must be true
        assertTrue(registered.isActive());
        // Password hash must be bcrypt of Password123!, not $2a$fakeHash
        assertTrue(passwordEncoder.matches("Password123!", registered.getPasswordHash()));
    }

    @Test
    @DisplayName("User can register with unique username and login using username (case-insensitive)")
    void testRegisterAndLoginWithUsername_Success() throws Exception {
        String regBody = """
                {
                    "firstName": "John",
                    "lastName": "Doe",
                    "email": "johndoe@caresync.test",
                    "username": "john_doe99",
                    "password": "Password123!"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.user.username").value("john_doe99"));

        // Login with uppercase/mixed-case username
        String loginBody = """
                {
                    "email": "JOHN_DOE99",
                    "password": "Password123!"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").isString())
                .andExpect(jsonPath("$.data.user.username").value("john_doe99"));
    }

    @Test
    @DisplayName("Registration with duplicate email returns HTTP 409 Conflict")
    void testRegisterDuplicateEmail_Returns409() throws Exception {
        String regBody = """
                {
                    "firstName": "Duplicate",
                    "lastName": "User",
                    "email": "active.user@caresync.test",
                    "password": "Password123!"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Email is already registered"));
    }

    @Test
    @DisplayName("Registration with duplicate username returns HTTP 409 Conflict")
    void testRegisterDuplicateUsername_Returns409() throws Exception {
        // Register first user with username "test_user_unique"
        String regBody1 = """
                {
                    "firstName": "User1",
                    "lastName": "Test",
                    "email": "user1@caresync.test",
                    "username": "test_user_unique",
                    "password": "Password123!"
                }
                """;
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody1))
                .andExpect(status().isCreated());

        // Attempt second registration with same username (different case)
        String regBody2 = """
                {
                    "firstName": "User2",
                    "lastName": "Test",
                    "email": "user2@caresync.test",
                    "username": "TEST_USER_UNIQUE",
                    "password": "Password123!"
                }
                """;
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(regBody2))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Username is already taken"));
    }

    @Test
    @DisplayName("Invalid login returns security-safe generic error message")
    void testInvalidLogin_ReturnsSecuritySafeMessage() throws Exception {
        String invalidPass = """
                {
                    "email": "active.user@caresync.test",
                    "password": "WrongPassword!"
                }
                """;

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(invalidPass))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email/username or password."));
    }

    @Test
    @DisplayName("Designated production admin emails automatically receive Role.ADMIN upon registration")
    void testDesignatedAdminRegistration_ReceivesAdminRole() throws Exception {
        String adminRegBody = """
                {
                    "firstName": "Keerthika",
                    "lastName": "Battula",
                    "email": "battula.keerthika0@gmail.com",
                    "password": "SecurePassword123!"
                }
                """;

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(adminRegBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.user.role").value("ADMIN"));

        User created = userRepository.findByEmail("battula.keerthika0@gmail.com").orElseThrow();
        assertEquals(Role.ADMIN, created.getRole());
    }
}
