package com.caresync.backend;

import com.caresync.backend.modules.appointment.entity.Appointment;
import com.caresync.backend.modules.appointment.repository.AppointmentRepository;
import com.caresync.backend.modules.appointment.service.AppointmentService;
import com.caresync.backend.modules.auth.entity.User;
import com.caresync.backend.modules.document.entity.HealthcareDocument;
import com.caresync.backend.modules.document.repository.DocumentRepository;
import com.caresync.backend.modules.document.service.DocumentService;
import com.caresync.backend.modules.document.service.MinioService;
import com.caresync.backend.modules.family.entity.FamilyMember;
import com.caresync.backend.modules.family.repository.FamilyMemberRepository;
import com.caresync.backend.modules.history.service.HistoryService;
import com.caresync.backend.modules.reminder.entity.ReminderOccurrence;
import com.caresync.backend.modules.reminder.repository.ReminderOccurrenceRepository;
import com.caresync.backend.modules.statistics.service.StatisticsService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class Phase4IntegrationTest {

    @Mock private AppointmentRepository appointmentRepository;
    @Mock private FamilyMemberRepository familyMemberRepository;
    @Mock private DocumentRepository documentRepository;
    @Mock private MinioService minioService;
    @Mock private ReminderOccurrenceRepository occurrenceRepository;
    @Mock private com.caresync.backend.modules.medicine.repository.MedicineRepository medicineRepository;

    @InjectMocks private AppointmentService appointmentService;
    @InjectMocks private DocumentService documentService;
    @InjectMocks private StatisticsService statisticsService;

    @Test
    void testCreateAppointment_OwnershipCheck() {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(userId);
        FamilyMember member = new FamilyMember(); member.setId(UUID.randomUUID()); member.setUser(user);
        
        Appointment appReq = new Appointment();
        appReq.setDoctorName("Dr. Smith");
        appReq.setAppointmentDate(LocalDate.now().plusDays(1));
        appReq.setAppointmentTime(LocalTime.of(10, 0));

        when(familyMemberRepository.findById(member.getId())).thenReturn(Optional.of(member));
        when(appointmentRepository.save(any())).thenAnswer(i -> i.getArguments()[0]);

        Appointment saved = appointmentService.createAppointment(userId, appReq, member.getId());
        assertEquals("Dr. Smith", saved.getDoctorName());
        assertEquals(member, saved.getFamilyMember());
    }

    @Test
    void testUploadDocument_SecurityAndMinio() throws Exception {
        UUID userId = UUID.randomUUID();
        User user = new User(); user.setId(userId);
        FamilyMember member = new FamilyMember(); member.setId(UUID.randomUUID()); member.setUser(user);

        when(familyMemberRepository.findById(member.getId())).thenReturn(Optional.of(member));
        when(documentRepository.save(any())).thenAnswer(i -> i.getArguments()[0]);

        MockMultipartFile file = new MockMultipartFile("file", "test.pdf", "application/pdf", "dummy content".getBytes());
        
        HealthcareDocument doc = documentService.uploadDocument(userId, member.getId(), "MEDICAL_REPORT", "Title", "Desc", file);
        
        assertEquals("test.pdf", doc.getFileName());
        assertTrue(doc.getFilePath().startsWith(userId.toString()));
        verify(minioService).uploadFile(eq(doc.getFilePath()), any());
    }

    @Test
    void testStatisticsDashboard() {
        UUID userId = UUID.randomUUID();
        when(appointmentRepository.findAllByFamilyMemberUserIdAndAppointmentDateGreaterThanEqualAndStatus(any(), any(), any())).thenReturn(List.of(new Appointment()));
        when(documentRepository.findAllByFamilyMemberUserId(any())).thenReturn(List.of(new HealthcareDocument(), new HealthcareDocument()));

        when(medicineRepository.findAllByFamilyMemberUserIdAndIsActiveTrue(any())).thenReturn(List.of(new com.caresync.backend.modules.medicine.entity.Medicine()));
        Map<String, Object> stats = statisticsService.getDashboardStats(userId);
        assertEquals(1L, stats.get("upcomingAppointments"));
        assertEquals(2L, stats.get("totalDocuments"));
    }
    
    @Test
    void testUnauthorizedDocumentDelete() {
        UUID userId = UUID.randomUUID();
        UUID otherUserId = UUID.randomUUID();
        User otherUser = new User(); otherUser.setId(otherUserId);
        FamilyMember member = new FamilyMember(); member.setUser(otherUser);
        
        HealthcareDocument doc = new HealthcareDocument();
        doc.setId(UUID.randomUUID());
        doc.setFamilyMember(member);
        
        when(documentRepository.findById(doc.getId())).thenReturn(Optional.of(doc));
        
        assertThrows(SecurityException.class, () -> {
            documentService.deleteDocument(userId, doc.getId());
        });
    }
}
