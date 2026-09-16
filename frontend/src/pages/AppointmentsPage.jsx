import React, { useState, useEffect } from 'react';
import { 
  Calendar, Clock, MapPin, User, Plus, Search, Filter, 
  Trash2, RefreshCw, AlertCircle, Stethoscope, ChevronRight 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/context/ToastContext';
import { appointmentsApi, familyApi } from '@/services/api';

export default function AppointmentsPage() {
  const { addToast } = useToast();
  const [appointments, setAppointments] = useState([]);
  const [familyMembers, setFamilyMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMember, setFilterMember] = useState('ALL');
  const [filterPeriod, setFilterPeriod] = useState('ALL'); // ALL, UPCOMING, PAST

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [appointmentToDelete, setAppointmentToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Form
  const [formData, setFormData] = useState({
    doctorName: '',
    hospitalClinic: '',
    appointmentDate: new Date().toISOString().split('T')[0],
    appointmentTime: '10:00',
    purpose: '',
    notes: '',
    familyMemberId: '',
    reminderMinutesBefore: '60',
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const [appRes, famRes] = await Promise.all([
        appointmentsApi.getAll().catch(() => ({ data: [] })),
        familyApi.getAll().catch(() => ({ data: [] })),
      ]);

      const appList = Array.isArray(appRes) ? appRes : (appRes.data || []);
      const famList = Array.isArray(famRes) ? famRes : (famRes.data || []);
      setAppointments(appList);
      setFamilyMembers(famList);
    } catch (err) {
      addToast(err.message || 'Failed to load visits', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const openAddModal = () => {
    setFormData({
      doctorName: '',
      hospitalClinic: '',
      appointmentDate: new Date().toISOString().split('T')[0],
      appointmentTime: '10:00',
      purpose: '',
      notes: '',
      familyMemberId: '',
      reminderMinutesBefore: '60',
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.doctorName.trim() || !formData.appointmentDate || !formData.appointmentTime) {
      addToast('Please fill in doctor name, date, and time', 'warning');
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        doctorName: formData.doctorName.trim(),
        hospitalClinic: formData.hospitalClinic.trim() || null,
        appointmentDate: formData.appointmentDate,
        appointmentTime: formData.appointmentTime.length === 5 ? `${formData.appointmentTime}:00` : formData.appointmentTime,
        purpose: formData.purpose.trim() || null,
        notes: formData.notes.trim() || null,
        familyMemberId: formData.familyMemberId || null,
        reminderMinutesBefore: formData.reminderMinutesBefore ? parseInt(formData.reminderMinutesBefore, 10) : 60,
      };

      await appointmentsApi.create(payload);
      addToast('Appointment scheduled successfully', 'success');
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to schedule appointment', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = (app) => {
    setAppointmentToDelete(app);
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!appointmentToDelete) return;
    try {
      setSubmitting(true);
      await appointmentsApi.delete(appointmentToDelete.id);
      addToast('Appointment deleted', 'success');
      setIsDeleteModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to delete appointment', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const todayStr = new Date().toISOString().split('T')[0];

  const filteredAppointments = appointments.filter(app => {
    const matchesSearch = app.doctorName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      app.hospitalClinic?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      app.purpose?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesMember = filterMember === 'ALL'
      ? true
      : filterMember === 'SELF'
        ? !app.familyMemberId
        : app.familyMemberId === filterMember;

    const isUpcoming = app.appointmentDate >= todayStr;
    const matchesPeriod = filterPeriod === 'ALL'
      ? true
      : filterPeriod === 'UPCOMING'
        ? isUpcoming
        : !isUpcoming;

    return matchesSearch && matchesMember && matchesPeriod;
  });

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Doctor Visits & Appointments</h1>
          <p className="text-sm text-slate-500 mt-1">
            Keep track of medical checkups, clinic visits, and physician consultations
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button size="sm" onClick={openAddModal}>
            <Plus className="w-4 h-4 mr-2" />
            Schedule Visit
          </Button>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input
              placeholder="Search by doctor or clinic..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              icon={Search}
            />

            <Select
              value={filterPeriod}
              onChange={(e) => setFilterPeriod(e.target.value)}
              options={[
                { value: 'ALL', label: 'All Visits' },
                { value: 'UPCOMING', label: 'Upcoming Visits' },
                { value: 'PAST', label: 'Past Visits' },
              ]}
            />

            <Select
              value={filterMember}
              onChange={(e) => setFilterMember(e.target.value)}
              options={[
                { value: 'ALL', label: 'All Family Members' },
                { value: 'SELF', label: 'Myself (Primary)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
          </div>
        </CardContent>
      </Card>

      {/* Appointments List */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[1, 2, 3, 4].map(i => (
            <Card key={i} className="animate-pulse p-6 space-y-3">
              <div className="h-6 bg-slate-200 rounded w-1/3"></div>
              <div className="h-4 bg-slate-100 rounded w-1/2"></div>
              <div className="h-4 bg-slate-100 rounded w-2/3"></div>
            </Card>
          ))}
        </div>
      ) : filteredAppointments.length === 0 ? (
        <Card className="text-center py-12">
          <CardContent className="space-y-4">
            <div className="w-12 h-12 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center mx-auto">
              <Stethoscope className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base font-semibold text-slate-900">No appointments found</h3>
              <p className="text-sm text-slate-500 max-w-sm mx-auto mt-1">
                {searchQuery || filterMember !== 'ALL' || filterPeriod !== 'ALL'
                  ? 'No appointments match your active filter criteria.'
                  : 'Schedule your next doctor appointment or consultation.'}
              </p>
            </div>
            {!(searchQuery || filterMember !== 'ALL' || filterPeriod !== 'ALL') && (
              <Button onClick={openAddModal}>
                <Plus className="w-4 h-4 mr-2" />
                Schedule First Visit
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filteredAppointments.map(app => {
            const isUpcoming = app.appointmentDate >= todayStr;
            const memberName = familyMembers.find(f => f.id === app.familyMemberId)?.name;
            const timeDisplay = app.appointmentTime ? app.appointmentTime.substring(0, 5) : '';

            return (
              <Card key={app.id} className="flex flex-col justify-between hover:border-slate-300 transition-all">
                <CardContent className="p-5 space-y-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-start gap-3">
                      <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
                        <Stethoscope className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">{app.doctorName}</h3>
                        {app.hospitalClinic && (
                          <div className="flex items-center text-xs text-slate-500 mt-0.5">
                            <MapPin className="w-3.5 h-3.5 mr-1 text-slate-400" />
                            {app.hospitalClinic}
                          </div>
                        )}
                      </div>
                    </div>

                    <Badge variant={isUpcoming ? 'default' : 'secondary'}>
                      {isUpcoming ? 'Upcoming' : 'Past'}
                    </Badge>
                  </div>

                  <div className="space-y-2 text-xs bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <div className="flex items-center justify-between text-slate-700">
                      <span className="flex items-center text-slate-500">
                        <Calendar className="w-3.5 h-3.5 mr-1 text-slate-400" />
                        Date & Time:
                      </span>
                      <span className="font-semibold text-slate-900">
                        {app.appointmentDate} at {timeDisplay}
                      </span>
                    </div>

                    {app.purpose && (
                      <div className="flex items-center justify-between text-slate-700">
                        <span className="text-slate-500">Purpose:</span>
                        <span className="font-medium text-teal-800 bg-teal-50 px-2 py-0.5 rounded">
                          {app.purpose}
                        </span>
                      </div>
                    )}

                    {memberName && (
                      <div className="flex items-center justify-between text-slate-700">
                        <span className="text-slate-500">Patient:</span>
                        <span className="font-medium text-purple-700 bg-purple-50 px-2 py-0.5 rounded flex items-center gap-1">
                          <User className="w-3 h-3" />
                          {memberName}
                        </span>
                      </div>
                    )}
                  </div>

                  {app.notes && (
                    <p className="text-xs text-slate-500 italic">
                      "{app.notes}"
                    </p>
                  )}
                </CardContent>

                <div className="p-3 border-t border-slate-100 bg-slate-50/50 flex items-center justify-end">
                  <Button variant="ghost" size="sm" className="text-rose-600 hover:text-rose-700 hover:bg-rose-50" onClick={() => confirmDelete(app)}>
                    <Trash2 className="w-3.5 h-3.5 mr-1" />
                    Cancel Visit
                  </Button>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* Add Appointment Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => !submitting && setIsModalOpen(false)}
        title="Schedule Doctor Visit"
        description="Add details for an upcoming medical appointment or consultation."
        maxWidth="max-w-lg"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Doctor / Physician Name *"
            placeholder="e.g., Dr. Sarah Jenkins, MD"
            value={formData.doctorName}
            onChange={(e) => setFormData({ ...formData, doctorName: e.target.value })}
            required
          />

          <Input
            label="Hospital / Clinic / Department"
            placeholder="e.g., City Medical Center, Suite 402"
            value={formData.hospitalClinic}
            onChange={(e) => setFormData({ ...formData, hospitalClinic: e.target.value })}
          />

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Appointment Date *"
              type="date"
              value={formData.appointmentDate}
              onChange={(e) => setFormData({ ...formData, appointmentDate: e.target.value })}
              required
            />
            <Input
              label="Time *"
              type="time"
              value={formData.appointmentTime}
              onChange={(e) => setFormData({ ...formData, appointmentTime: e.target.value })}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <Input
              label="Purpose / Specialization"
              placeholder="e.g., Annual Checkup, Dental"
              value={formData.purpose}
              onChange={(e) => setFormData({ ...formData, purpose: e.target.value })}
            />

            <Select
              label="For Patient"
              value={formData.familyMemberId}
              onChange={(e) => setFormData({ ...formData, familyMemberId: e.target.value })}
              options={[
                { value: '', label: 'Myself (Primary User)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
          </div>

          <Input
            label="Notes / Special Instructions"
            placeholder="e.g., Fasting 8 hours before blood test"
            value={formData.notes}
            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          />

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" loading={submitting}>
              Schedule Appointment
            </Button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => !submitting && setIsDeleteModalOpen(false)}
        title="Cancel Appointment"
        description="Are you sure you want to cancel and remove this scheduled appointment record?"
        maxWidth="max-w-md"
      >
        <div className="flex items-center justify-end gap-3 pt-4">
          <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)} disabled={submitting}>
            Keep Appointment
          </Button>
          <Button variant="danger" onClick={handleDelete} loading={submitting}>
            Confirm Cancellation
          </Button>
        </div>
      </Modal>
    </div>
  );
}
