package com.caresync.backend.modules.user.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.common.exception.ConflictException;
import com.caresync.backend.common.exception.ResourceNotFoundException;
import com.caresync.backend.common.response.PageResponse;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.user.dto.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AdminUserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private FamilyMemberRepository familyMemberRepository;

    @Mock
    private MedicineRepository medicineRepository;

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private DocumentRepository documentRepository;

    @InjectMocks
    private AdminUserService adminUserService;

    private User sampleUser;
    private User sampleAdmin;
    private UUID userId;
    private UUID adminId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        adminId = UUID.randomUUID();

        sampleUser = User.builder()
                .firstName("John")
                .lastName("Doe")
                .email("john.doe@example.com")
                .passwordHash("encoded_pwd")
                .phoneNumber("+1234567890")
                .role(Role.USER)
                .isActive(true)
                .isEmailVerified(true)
                .build();
        sampleUser.setId(userId);
        sampleUser.setCreatedAt(LocalDateTime.now());
        sampleUser.setUpdatedAt(LocalDateTime.now());

        sampleAdmin = User.builder()
                .firstName("Admin")
                .lastName("User")
                .email("admin@caresync.com")
                .passwordHash("admin_hash")
                .phoneNumber("+1987654321")
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build();
        sampleAdmin.setId(adminId);
        sampleAdmin.setCreatedAt(LocalDateTime.now());
        sampleAdmin.setUpdatedAt(LocalDateTime.now());
    }

    @Test
    @DisplayName("Admin can list paginated users without returning passwordHash")
    void testGetAllUsers_Paginated() {
        Pageable pageable = PageRequest.of(0, 10);
        Page<User> userPage = new PageImpl<>(List.of(sampleUser, sampleAdmin), pageable, 2);
        when(userRepository.findAll(pageable)).thenReturn(userPage);

        PageResponse<AdminUserResponse> result = adminUserService.getAllUsers(pageable);

        assertNotNull(result);
        assertEquals(2, result.getContent().size());
        assertEquals("john.doe@example.com", result.getContent().get(0).getEmail());
        assertEquals(Role.USER, result.getContent().get(0).getRole());
        assertEquals(Role.ADMIN, result.getContent().get(1).getRole());
    }

    @Test
    @DisplayName("Admin can view specific user details")
    void testGetUserById_Success() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));

        AdminUserResponse response = adminUserService.getUserById(userId);

        assertNotNull(response);
        assertEquals(userId, response.getId());
        assertEquals("John", response.getFirstName());
        assertEquals("Doe", response.getLastName());
        assertEquals(Role.USER, response.getRole());
        assertTrue(response.isActive());
    }

    @Test
    @DisplayName("Admin viewing non-existent user throws ResourceNotFoundException")
    void testGetUserById_NotFound() {
        UUID randomId = UUID.randomUUID();
        when(userRepository.findById(randomId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> adminUserService.getUserById(randomId));
    }

    @Test
    @DisplayName("Admin creates user with BCrypt encoded password and default USER role")
    void testCreateUser_Success() {
        AdminCreateUserRequest req = AdminCreateUserRequest.builder()
                .firstName("New")
                .lastName("Person")
                .email("new.person@example.com")
                .password("plainText123")
                .phoneNumber("+1122334455")
                .build();

        when(userRepository.existsByEmail("new.person@example.com")).thenReturn(false);
        when(passwordEncoder.encode("plainText123")).thenReturn("$2a$10$encodedString");
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User u = invocation.getArgument(0);
            u.setId(UUID.randomUUID());
            u.setCreatedAt(LocalDateTime.now());
            u.setUpdatedAt(LocalDateTime.now());
            return u;
        });

        AdminUserResponse created = adminUserService.createUser(req);

        assertNotNull(created);
        assertEquals("new.person@example.com", created.getEmail());
        assertEquals(Role.USER, created.getRole());
        assertTrue(created.isActive());
        verify(passwordEncoder).encode("plainText123");
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("Admin creating user with duplicate email throws ConflictException")
    void testCreateUser_DuplicateEmail() {
        AdminCreateUserRequest req = AdminCreateUserRequest.builder()
                .firstName("New")
                .lastName("Person")
                .email("existing@example.com")
                .password("secret123")
                .build();

        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThrows(ConflictException.class, () -> adminUserService.createUser(req));
        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Admin promotes USER to ADMIN")
    void testUpdateUserRole_PromoteUserToAdmin() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminUserResponse updated = adminUserService.updateUserRole(userId, Role.ADMIN);

        assertNotNull(updated);
        assertEquals(Role.ADMIN, updated.getRole());
        assertEquals(Role.ADMIN, sampleUser.getRole());
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("Admin demotes ADMIN to USER when another active ADMIN remains")
    void testUpdateUserRole_DemoteAdmin_MultipleAdmins() {
        User secondAdmin = User.builder()
                .firstName("Second")
                .lastName("Admin")
                .email("second@admin.com")
                .role(Role.ADMIN)
                .isActive(true)
                .build();
        secondAdmin.setId(UUID.randomUUID());

        when(userRepository.findById(adminId)).thenReturn(Optional.of(sampleAdmin));
        when(userRepository.findAllActiveAdminsForUpdate(Role.ADMIN)).thenReturn(List.of(sampleAdmin, secondAdmin));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminUserResponse updated = adminUserService.updateUserRole(adminId, Role.USER);

        assertNotNull(updated);
        assertEquals(Role.USER, updated.getRole());
        assertEquals(Role.USER, sampleAdmin.getRole());
    }

    @Test
    @DisplayName("Cannot demote the ONLY active ADMIN (Last-admin protection)")
    void testUpdateUserRole_CannotDemoteLastActiveAdmin() {
        when(userRepository.findById(adminId)).thenReturn(Optional.of(sampleAdmin));
        when(userRepository.findAllActiveAdminsForUpdate(Role.ADMIN)).thenReturn(List.of(sampleAdmin));

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                adminUserService.updateUserRole(adminId, Role.USER));

        assertTrue(ex.getMessage().contains("Cannot demote the last active administrator"));
        assertEquals(Role.ADMIN, sampleAdmin.getRole());
        verify(userRepository, never()).save(sampleAdmin);
    }

    @Test
    @DisplayName("Cannot deactivate the ONLY active ADMIN (Last-admin protection)")
    void testUpdateUserStatus_CannotDeactivateLastActiveAdmin() {
        when(userRepository.findById(adminId)).thenReturn(Optional.of(sampleAdmin));
        when(userRepository.findAllActiveAdminsForUpdate(Role.ADMIN)).thenReturn(List.of(sampleAdmin));

        BadRequestException ex = assertThrows(BadRequestException.class, () ->
                adminUserService.updateUserStatus(adminId, false));

        assertTrue(ex.getMessage().contains("Cannot deactivate the last active administrator"));
        assertTrue(sampleAdmin.isActive());
        verify(userRepository, never()).save(sampleAdmin);
    }

    @Test
    @DisplayName("Admin deactivates user (Soft Delete) successfully")
    void testUpdateUserStatus_DeactivateNormalUser() {
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminUserResponse result = adminUserService.updateUserStatus(userId, false);

        assertNotNull(result);
        assertFalse(result.isActive());
        assertFalse(sampleUser.isActive());
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("Admin reactivates a deactivated user")
    void testUpdateUserStatus_ReactivateUser() {
        sampleUser.setActive(false);
        when(userRepository.findById(userId)).thenReturn(Optional.of(sampleUser));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminUserResponse result = adminUserService.updateUserStatus(userId, true);

        assertNotNull(result);
        assertTrue(result.isActive());
        assertTrue(sampleUser.isActive());
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("Admin loads user healthcare overview on-demand (lazy-loaded)")
    void testGetUserHealthcareOverview() {
        when(userRepository.existsById(userId)).thenReturn(true);
        when(familyMemberRepository.findAllByUserId(userId)).thenReturn(Collections.emptyList());
        when(medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(userId)).thenReturn(Collections.emptyList());
        when(appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(any(), any(), any()))
                .thenReturn(Collections.emptyList());
        when(documentRepository.findAllByFamilyMemberUserId(userId)).thenReturn(Collections.emptyList());

        AdminUserHealthcareOverviewResponse overview = adminUserService.getUserHealthcareOverview(userId);

        assertNotNull(overview);
        assertEquals(userId, overview.getUserId());
        assertEquals(0, overview.getFamilyMembersCount());
        assertEquals(0, overview.getActiveMedicinesCount());
        assertEquals(0, overview.getUpcomingAppointmentsCount());
        assertEquals(0, overview.getTotalDocumentsCount());
    }
}
