package com.caresync.backend.modules.medicine;

import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.medicine.dto.MedicineRequest;
import com.caresync.backend.modules.medicine.dto.MedicineResponse;
import com.caresync.backend.modules.medicine.service.MedicineService;
import com.caresync.backend.modules.reminder.dto.ReminderOccurrenceResponse;
import com.caresync.backend.modules.reminder.service.ReminderActionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
public class MedicineScheduleTimeIntegrationTest {

    @Autowired
    private MedicineService medicineService;

    @Autowired
    private ReminderActionService reminderActionService;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    private User testUser;
    private final String userEmail = "schedule.test@caresync.com";

    @BeforeEach
    void setUp() {
        testUser = userRepository.findByEmail(userEmail).orElseGet(() -> {
            User user = User.builder()
                    .email(userEmail)
                    .username("scheduletest")
                    .passwordHash(passwordEncoder.encode("Password123!"))
                    .firstName("Schedule")
                    .lastName("Tester")
                    .role(Role.USER)
                    .isActive(true)
                    .build();
            return userRepository.save(user);
        });
    }

    @Test
    @DisplayName("Test 1: Create Vitamin B12 with Once Daily at 08:00")
    void testCreateMedicineOnceDailyMorning() {
        MedicineRequest req = new MedicineRequest();
        req.setName("Vitamin B12");
        req.setDosage("1 tablet");
        req.setFrequency("ONCE_DAILY");
        req.setCurrentQuantity(30);
        req.setRefillThreshold(7);

        MedicineRequest.ScheduleRequest sched = new MedicineRequest.ScheduleRequest();
        sched.setScheduledTime("08:00");
        req.setSchedules(List.of(sched));

        MedicineResponse response = medicineService.addMedicine(userEmail, req);

        assertThat(response).isNotNull();
        assertThat(response.getName()).isEqualTo("Vitamin B12");
        assertThat(response.getFrequency()).isEqualTo("ONCE_DAILY");
        assertThat(response.getSchedules()).hasSize(1);
        assertThat(response.getSchedules().get(0).getScheduledTime()).isEqualTo(LocalTime.of(8, 0));

        // Check occurrences generated for today
        List<ReminderOccurrenceResponse> doses = reminderActionService.getTodayDoses(testUser.getId());
        assertThat(doses.stream().anyMatch(d -> d.getMedicineName().equals("Vitamin B12")
                && d.getScheduledTime().toLocalTime().equals(LocalTime.of(8, 0)))).isTrue();
    }

    @Test
    @DisplayName("Test 2: Create Magnesium with Once Daily at 20:00 (proves not hardcoded to 08:00)")
    void testCreateMedicineOnceDailyEvening() {
        MedicineRequest req = new MedicineRequest();
        req.setName("Magnesium");
        req.setDosage("1 tablet");
        req.setFrequency("ONCE_DAILY");
        req.setCurrentQuantity(60);
        req.setRefillThreshold(10);

        MedicineRequest.ScheduleRequest sched = new MedicineRequest.ScheduleRequest();
        sched.setScheduledTime("20:00");
        req.setSchedules(List.of(sched));

        MedicineResponse response = medicineService.addMedicine(userEmail, req);

        assertThat(response).isNotNull();
        assertThat(response.getName()).isEqualTo("Magnesium");
        assertThat(response.getFrequency()).isEqualTo("ONCE_DAILY");
        assertThat(response.getSchedules()).hasSize(1);
        assertThat(response.getSchedules().get(0).getScheduledTime()).isEqualTo(LocalTime.of(20, 0));

        // Check occurrences generated for today
        List<ReminderOccurrenceResponse> doses = reminderActionService.getTodayDoses(testUser.getId());
        assertThat(doses.stream().anyMatch(d -> d.getMedicineName().equals("Magnesium")
                && d.getScheduledTime().toLocalTime().equals(LocalTime.of(20, 0)))).isTrue();
    }

    @Test
    @DisplayName("Test 3: Create Magnesium with Twice Daily at 08:00 and 20:00")
    void testCreateMedicineTwiceDaily() {
        MedicineRequest req = new MedicineRequest();
        req.setName("Magnesium");
        req.setDosage("2 tablets");
        req.setFrequency("TWICE_DAILY");
        req.setCurrentQuantity(60);

        MedicineRequest.ScheduleRequest sched1 = new MedicineRequest.ScheduleRequest();
        sched1.setScheduledTime("08:00");

        MedicineRequest.ScheduleRequest sched2 = new MedicineRequest.ScheduleRequest();
        sched2.setScheduledTime("20:00");

        req.setSchedules(List.of(sched1, sched2));

        MedicineResponse response = medicineService.addMedicine(userEmail, req);

        assertThat(response).isNotNull();
        assertThat(response.getFrequency()).isEqualTo("TWICE_DAILY");
        assertThat(response.getSchedules()).hasSize(2);
        assertThat(response.getSchedules().get(0).getScheduledTime()).isEqualTo(LocalTime.of(8, 0));
        assertThat(response.getSchedules().get(1).getScheduledTime()).isEqualTo(LocalTime.of(20, 0));

        // Check occurrences generated for today
        List<ReminderOccurrenceResponse> doses = reminderActionService.getTodayDoses(testUser.getId());
        List<ReminderOccurrenceResponse> magDoses = doses.stream()
                .filter(d -> d.getMedicineName().equals("Magnesium"))
                .toList();
        assertThat(magDoses).hasSize(2);
    }

    @Test
    @DisplayName("Test 4: Edit existing medicine from 20:00 to 21:00 and verify persistence")
    void testEditMedicineScheduleTime() {
        MedicineRequest req = new MedicineRequest();
        req.setName("Magnesium");
        req.setDosage("1 tablet");
        req.setFrequency("ONCE_DAILY");
        req.setCurrentQuantity(60);

        MedicineRequest.ScheduleRequest sched = new MedicineRequest.ScheduleRequest();
        sched.setScheduledTime("20:00");
        req.setSchedules(List.of(sched));

        MedicineResponse created = medicineService.addMedicine(userEmail, req);
        UUID medicineId = created.getId();

        // Update schedule to 21:00 (9:00 PM)
        MedicineRequest updateReq = new MedicineRequest();
        updateReq.setName("Magnesium");
        updateReq.setDosage("1 tablet");
        updateReq.setFrequency("ONCE_DAILY");
        updateReq.setCurrentQuantity(60);

        MedicineRequest.ScheduleRequest updatedSched = new MedicineRequest.ScheduleRequest();
        updatedSched.setScheduledTime("21:00");
        updateReq.setSchedules(List.of(updatedSched));

        MedicineResponse updated = medicineService.updateMedicine(userEmail, medicineId, updateReq);

        assertThat(updated.getSchedules()).hasSize(1);
        assertThat(updated.getSchedules().get(0).getScheduledTime()).isEqualTo(LocalTime.of(21, 0));

        // Retrieve again by ID and verify persistence
        MedicineResponse fetched = medicineService.getMedicineById(userEmail, medicineId);
        assertThat(fetched.getSchedules().get(0).getScheduledTime()).isEqualTo(LocalTime.of(21, 0));

        // Verify today's occurrence is updated to 21:00
        List<ReminderOccurrenceResponse> doses = reminderActionService.getTodayDoses(testUser.getId());
        assertThat(doses.stream().anyMatch(d -> d.getMedicineName().equals("Magnesium")
                && d.getScheduledTime().toLocalTime().equals(LocalTime.of(21, 0)))).isTrue();
    }
}
