package com.caresync.backend.security;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;

import java.util.Collection;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class RoleAndAuthenticationTest {

    @Test
    @DisplayName("Role enum values map correctly to Spring Security GrantedAuthority")
    void testRoleAuthoritiesMapping() {
        User normalUser = User.builder()
                .email("user@caresync.test")
                .role(Role.USER)
                .build();

        Collection<? extends GrantedAuthority> userAuthorities = normalUser.getAuthorities();
        assertTrue(userAuthorities.contains(new SimpleGrantedAuthority("ROLE_USER")));
        assertFalse(userAuthorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")));

        User adminUser = User.builder()
                .email("admin@caresync.test")
                .role(Role.ADMIN)
                .build();

        Collection<? extends GrantedAuthority> adminAuthorities = adminUser.getAuthorities();
        assertTrue(adminAuthorities.contains(new SimpleGrantedAuthority("ROLE_ADMIN")));
        assertFalse(adminAuthorities.contains(new SimpleGrantedAuthority("ROLE_USER")));
    }

    @Test
    @DisplayName("Default User entity role is USER")
    void testDefaultRoleIsUser() {
        User defaultUser = new User();
        assertEquals(Role.USER, defaultUser.getRole());
        assertTrue(defaultUser.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_USER")));
    }

    @Test
    @DisplayName("Disabled user has isEnabled() = false")
    void testDisabledUserIsNotEnabled() {
        User activeUser = User.builder()
                .email("active@caresync.test")
                .isActive(true)
                .build();
        assertTrue(activeUser.isEnabled());
        assertTrue(activeUser.isAccountNonLocked());

        User disabledUser = User.builder()
                .email("disabled@caresync.test")
                .isActive(false)
                .build();
        assertFalse(disabledUser.isEnabled());
        assertFalse(disabledUser.isAccountNonLocked());
    }

    @Test
    @DisplayName("Role demotion takes effect immediately on authorities")
    void testRoleDemotionImmediateEffect() {
        User user = User.builder()
                .email("dynamic@caresync.test")
                .role(Role.ADMIN)
                .isActive(true)
                .build();

        // Initially has ROLE_ADMIN
        assertTrue(user.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN")));

        // Demote to USER
        user.setRole(Role.USER);

        // Next authority check immediately reflects ROLE_USER, eliminating stale ADMIN access
        assertTrue(user.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_USER")));
        assertFalse(user.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_ADMIN")));
    }
}
