package com.caresync.backend.modules.user.service;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.user.dto.PublicUserNameResponse;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicUserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private PublicUserService publicUserService;

    @Test
    @DisplayName("Public user names endpoint returns ONLY display names of active users")
    void testGetPublicUserNames_ReturnsOnlyNames() {
        User user1 = User.builder()
                .firstName("Alice")
                .lastName("Smith")
                .email("alice@secret.com")
                .phoneNumber("+123456789")
                .role(Role.ADMIN)
                .isActive(true)
                .build();
        user1.setId(UUID.randomUUID());

        User user2 = User.builder()
                .firstName("Bob")
                .lastName("Jones")
                .email("bob@secret.com")
                .phoneNumber("+987654321")
                .role(Role.USER)
                .isActive(true)
                .build();
        user2.setId(UUID.randomUUID());

        when(userRepository.findAllByIsActiveTrue()).thenReturn(List.of(user1, user2));

        List<PublicUserNameResponse> names = publicUserService.getPublicUserNames();

        assertNotNull(names);
        assertEquals(2, names.size());
        assertEquals("Alice Smith", names.get(0).getDisplayName());
        assertEquals("Bob Jones", names.get(1).getDisplayName());

        // Verify that PublicUserNameResponse class itself contains only the displayName field
        assertEquals(1, PublicUserNameResponse.class.getDeclaredFields().length);
        assertEquals("displayName", PublicUserNameResponse.class.getDeclaredFields()[0].getName());
    }
}
