package com.caresync.backend.modules.user.service;

import com.caresync.backend.common.exception.BadRequestException;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@ActiveProfiles("test")
class LastAdminConcurrencyIntegrationTest {

    @Autowired
    private AdminUserService adminUserService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User admin1;
    private User admin2;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();

        admin1 = userRepository.save(User.builder()
                .firstName("Admin")
                .lastName("One")
                .email("admin1@caresync.test")
                .passwordHash(passwordEncoder.encode("Secret123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());

        admin2 = userRepository.save(User.builder()
                .firstName("Admin")
                .lastName("Two")
                .email("admin2@caresync.test")
                .passwordHash(passwordEncoder.encode("Secret123!"))
                .role(Role.ADMIN)
                .isActive(true)
                .isEmailVerified(true)
                .build());
    }

    @Test
    @DisplayName("Concurrent demotion: two simultaneous requests cannot both demote and leave 0 active admins")
    void testConcurrentDemotion_LeavesAtLeastOneAdmin() throws Exception {
        int threadCount = 2;
        ExecutorService executorService = Executors.newFixedThreadPool(threadCount);
        CountDownLatch readyLatch = new CountDownLatch(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger rejectedCount = new AtomicInteger(0);
        List<Future<?>> futures = new ArrayList<>();

        futures.add(executorService.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                adminUserService.updateUserRole(admin1.getId(), Role.USER);
                successCount.incrementAndGet();
            } catch (BadRequestException e) {
                rejectedCount.incrementAndGet();
            } catch (Exception e) {
                // Unexpected exception
            }
        }));

        futures.add(executorService.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                adminUserService.updateUserRole(admin2.getId(), Role.USER);
                successCount.incrementAndGet();
            } catch (BadRequestException e) {
                rejectedCount.incrementAndGet();
            } catch (Exception e) {
                // Unexpected exception
            }
        }));

        readyLatch.await(5, TimeUnit.SECONDS);
        startLatch.countDown(); // Release both threads at the exact same instant

        for (Future<?> f : futures) {
            f.get(10, TimeUnit.SECONDS);
        }
        executorService.shutdown();

        // Exactly one demotion must succeed, and one must be rejected by the last-admin check
        assertEquals(1, successCount.get(), "Exactly one concurrent demotion request must succeed");
        assertEquals(1, rejectedCount.get(), "The concurrent conflicting request must be rejected as last active admin");

        // The database must still contain exactly one active administrator
        long remainingActiveAdmins = userRepository.countByRoleAndIsActiveTrue(Role.ADMIN);
        assertEquals(1, remainingActiveAdmins, "Database must strictly retain at least 1 active administrator");
    }

    @Test
    @DisplayName("Concurrent deactivation: two simultaneous requests cannot both deactivate and leave 0 active admins")
    void testConcurrentDeactivation_LeavesAtLeastOneAdmin() throws Exception {
        int threadCount = 2;
        ExecutorService executorService = Executors.newFixedThreadPool(threadCount);
        CountDownLatch readyLatch = new CountDownLatch(threadCount);
        CountDownLatch startLatch = new CountDownLatch(1);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger rejectedCount = new AtomicInteger(0);
        List<Future<?>> futures = new ArrayList<>();

        futures.add(executorService.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                adminUserService.updateUserStatus(admin1.getId(), false);
                successCount.incrementAndGet();
            } catch (BadRequestException e) {
                rejectedCount.incrementAndGet();
            } catch (Exception e) {
                // Unexpected exception
            }
        }));

        futures.add(executorService.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                adminUserService.updateUserStatus(admin2.getId(), false);
                successCount.incrementAndGet();
            } catch (BadRequestException e) {
                rejectedCount.incrementAndGet();
            } catch (Exception e) {
                // Unexpected exception
            }
        }));

        readyLatch.await(5, TimeUnit.SECONDS);
        startLatch.countDown(); // Fire simultaneous requests

        for (Future<?> f : futures) {
            f.get(10, TimeUnit.SECONDS);
        }
        executorService.shutdown();

        // Exactly one deactivation must succeed, and one must be rejected
        assertEquals(1, successCount.get(), "Exactly one concurrent deactivation request must succeed");
        assertEquals(1, rejectedCount.get(), "The concurrent conflicting deactivation must be rejected");

        // The database must still contain exactly one active administrator
        long remainingActiveAdmins = userRepository.countByRoleAndIsActiveTrue(Role.ADMIN);
        assertEquals(1, remainingActiveAdmins, "Database must strictly retain at least 1 active administrator");
    }
}
