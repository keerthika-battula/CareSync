package com.caresync.backend.security;

import com.caresync.backend.common.exception.ForbiddenException;
import com.caresync.backend.modules.appointment.entity.Appointment;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.appointment.service.AppointmentService;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.auth.model.Role;
import com.caresync.backend.modules.auth.repository.UserRepository;
import com.caresync.backend.modules.document.entity.HealthcareDocument;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.document.service.DocumentService;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.medicine.dto.MedicineRequest;
import com.caresync.backend.modules.medicine.repository.MedicineRepository;
import com.caresync.backend.modules.medicine.service.MedicineService;
import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import com.caresync.backend.modules.reminder.service.ReminderActionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class IdorAuthorizationSecurityTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private FamilyMemberRepository familyMemberRepository;

    @Mock
    private MedicineRepository medicineRepository;

    @Mock
    private DocumentRepository documentRepository;

    @Mock
    private AppointmentRepository appointmentRepository;

    @Mock
    private ReminderOccurrenceRepository occurrenceRepository;

    @InjectMocks
    private MedicineService medicineService;

    @InjectMocks
    private DocumentService documentService;

    @InjectMocks
    private AppointmentService appointmentService;

    @InjectMocks
    private ReminderActionService reminderActionService;

    private User userA;
    private User userB;
    private FamilyMember familyMemberB;

    @BeforeEach
    void setUp() {
        userA = User.builder()
                .firstName("User")
                .lastName("A")
                .email("userA@caresync.test")
                .role(Role.USER)
                .isActive(true)
                .build();
        userA.setId(UUID.randomUUID());

        userB = User.builder()
                .firstName("User")
                .lastName("B")
                .email("userB@caresync.test")
                .role(Role.USER)
                .isActive(true)
                .build();
        userB.setId(UUID.randomUUID());

        familyMemberB = FamilyMember.builder()
                .name("Child of B")
                .relationship("Child")
                .user(userB)
                .build();
        familyMemberB.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("IDOR: User A cannot add medicine to User B's family member")
    void testUserACannotAddMedicineToUserBFamilyMember() {
        MedicineRequest req = new MedicineRequest();
        req.setFamilyMemberId(familyMemberB.getId());
        req.setName("Antibiotics");
        req.setStartDate(LocalDate.now());

        when(userRepository.findByEmail("userA@caresync.test")).thenReturn(Optional.of(userA));
        when(familyMemberRepository.findById(familyMemberB.getId())).thenReturn(Optional.of(familyMemberB));

        assertThrows(ForbiddenException.class, () ->
                medicineService.addMedicine("userA@caresync.test", req));
    }

    @Test
    @DisplayName("IDOR: User A cannot access or delete User B's document")
    void testUserACannotDeleteUserBDocument() {
        HealthcareDocument doc = HealthcareDocument.builder()
                .familyMember(familyMemberB)
                .fileName("secret_scan.pdf")
                .filePath("path/to/scan.pdf")
                .build();
        doc.setId(UUID.randomUUID());

        when(documentRepository.findById(doc.getId())).thenReturn(Optional.of(doc));

        assertThrows(SecurityException.class, () ->
                documentService.deleteDocument(userA.getId(), doc.getId()));
    }

    @Test
    @DisplayName("IDOR: User A cannot create appointment for User B's family member")
    void testUserACannotCreateAppointmentForUserBFamilyMember() {
        Appointment app = Appointment.builder()
                .doctorName("Dr. Smith")
                .appointmentDate(LocalDate.now().plusDays(3))
                .build();

        when(familyMemberRepository.findById(familyMemberB.getId())).thenReturn(Optional.of(familyMemberB));

        assertThrows(SecurityException.class, () ->
                appointmentService.createAppointment(userA.getId(), app, familyMemberB.getId()));
    }

    @Test
    @DisplayName("IDOR: User A cannot delete User B's appointment")
    void testUserACannotDeleteUserBAppointment() {
        Appointment app = Appointment.builder()
                .familyMember(familyMemberB)
                .doctorName("Dr. Jones")
                .build();
        app.setId(UUID.randomUUID());

        when(appointmentRepository.findById(app.getId())).thenReturn(Optional.of(app));

        assertThrows(SecurityException.class, () ->
                appointmentService.deleteAppointment(userA.getId(), app.getId()));
    }

    @Test
    @DisplayName("IDOR: User A cannot mark taken User B's reminder occurrence")
    void testUserACannotMarkTakenUserBReminderOccurrence() {
        ReminderOccurrence occurrence = new ReminderOccurrence();
        occurrence.setId(UUID.randomUUID());
        occurrence.setUser(userB);

        when(occurrenceRepository.findById(occurrence.getId())).thenReturn(Optional.of(occurrence));

        assertThrows(SecurityException.class, () ->
                reminderActionService.markTaken(occurrence.getId(), userA.getId()));
    }
}
