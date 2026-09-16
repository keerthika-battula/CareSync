import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Pill,
  Clock,
  Calendar,
  AlertTriangle,
  Plus,
  CheckCircle2,
  XCircle,
  Clock3,
  FileText,
  Users,
  ArrowRight,
  ShieldCheck,
  ChevronRight,
  RefreshCw
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import { statsApi, remindersApi, medicinesApi, appointmentsApi } from '../services/api';
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';

export default function DashboardPage() {
  const { user } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();

  const [stats, setStats] = useState({
    activePrescriptions: 0,
    todayDoses: 0,
    upcomingAppointments: 0,
    refillAlerts: 0,
  });
  const [todayDoses, setTodayDoses] = useState([]);
  const [medicines, setMedicines] = useState([]);
  const [appointments, setAppointments] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Snooze Modal state
  const [snoozeModalOpen, setSnoozeModalOpen] = useState(false);
  const [selectedDoseId, setSelectedDoseId] = useState(null);
  const [snoozeMinutes, setSnoozeMinutes] = useState(15);
  const [isActionLoading, setIsActionLoading] = useState(false);

  const fetchDashboardData = async () => {
    setIsLoading(true);
    try {
      const [statsRes, dosesRes, medsRes, apptsRes] = await Promise.allSettled([
        statsApi.getDashboardStats(),
        remindersApi.getToday(),
        medicinesApi.getAll(),
        appointmentsApi.getAll(),
      ]);

      if (statsRes.status === 'fulfilled' && statsRes.value?.data) {
        setStats(statsRes.value.data);
      }
      if (dosesRes.status === 'fulfilled' && Array.isArray(dosesRes.value?.data)) {
        setTodayDoses(dosesRes.value.data);
      }
      if (medsRes.status === 'fulfilled' && Array.isArray(medsRes.value?.data)) {
        setMedicines(medsRes.value.data);
      }
      if (apptsRes.status === 'fulfilled' && Array.isArray(apptsRes.value?.data)) {
        setAppointments(apptsRes.value.data);
      }
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const handleMarkTaken = async (id) => {
    try {
      await remindersApi.markTaken(id);
      showToast('Medication marked as Taken', 'success');
      fetchDashboardData();
    } catch (err) {
      showToast(err.message || 'Failed to update dose status', 'error');
    }
  };

  const handleMarkSkipped = async (id) => {
    try {
      await remindersApi.markSkipped(id);
      showToast('Medication marked as Skipped', 'info');
      fetchDashboardData();
    } catch (err) {
      showToast(err.message || 'Failed to update dose status', 'error');
    }
  };

  const handleOpenSnooze = (id) => {
    setSelectedDoseId(id);
    setSnoozeMinutes(15);
    setSnoozeModalOpen(true);
  };

  const handleConfirmSnooze = async () => {
    if (!selectedDoseId) return;
    setIsActionLoading(true);
    try {
      await remindersApi.snooze(selectedDoseId, snoozeMinutes);
      showToast(`Reminder snoozed for ${snoozeMinutes} minutes`, 'info');
      setSnoozeModalOpen(false);
      fetchDashboardData();
    } catch (err) {
      showToast(err.message || 'Failed to snooze reminder', 'error');
    } finally {
      setIsActionLoading(false);
    }
  };

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  };

  const lowStockMedicines = medicines.filter(
    (m) => m.currentQuantity != null && m.refillThreshold != null && m.currentQuantity <= m.refillThreshold
  );

  return (
    <div className="space-y-8">
      {/* Hero Welcome Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-r from-indigo-600 via-indigo-700 to-blue-600 p-6 sm:p-8 text-white shadow-xl shadow-indigo-100">
        <div className="relative z-10 max-w-2xl space-y-2">
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
            {getGreeting()}, {user?.firstName || 'Valued Member'}!
          </h1>
          <p className="text-sm text-indigo-100 leading-relaxed">
            Your daily medication schedule, clinical appointments, and family care records are synchronized and up to date.
          </p>
        </div>
      </div>

      {/* Metric Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-6">
        <Card className="p-5 flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-indigo-50 text-indigo-600">
            <Pill className="h-6 w-6" />
          </div>
          <div>
            <p className="text-2xl font-black text-slate-900">{stats.activePrescriptions || medicines.length || 0}</p>
            <p className="text-xs font-semibold text-slate-500">Active Medicines</p>
          </div>
        </Card>

        <Card className="p-5 flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-600">
            <Clock className="h-6 w-6" />
          </div>
          <div>
            <p className="text-2xl font-black text-slate-900">{stats.todayDoses || todayDoses.length || 0}</p>
            <p className="text-xs font-semibold text-slate-500">Today's Doses</p>
          </div>
        </Card>

        <Card className="p-5 flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-sky-50 text-sky-600">
            <Calendar className="h-6 w-6" />
          </div>
          <div>
            <p className="text-2xl font-black text-slate-900">{stats.upcomingAppointments || appointments.length || 0}</p>
            <p className="text-xs font-semibold text-slate-500">Upcoming Visits</p>
          </div>
        </Card>

        <Card className="p-5 flex items-center gap-4">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-50 text-amber-600">
            <AlertTriangle className="h-6 w-6" />
          </div>
          <div>
            <p className="text-2xl font-black text-slate-900">{stats.refillAlerts || lowStockMedicines.length || 0}</p>
            <p className="text-xs font-semibold text-slate-500">Refill Alerts</p>
          </div>
        </Card>
      </div>

      {/* Quick Actions Grid */}
      <div className="space-y-3">
        <h3 className="text-sm font-bold uppercase tracking-wider text-slate-400">
          Quick Actions
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
          <button
            onClick={() => navigate('/medicines?action=add')}
            className="flex items-center gap-3 rounded-2xl border border-indigo-100 bg-indigo-50/40 p-4 text-left hover:bg-indigo-50 transition-colors group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-sm shadow-indigo-100 group-hover:scale-105 transition-transform">
              <Plus className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">Add Medicine</p>
              <p className="text-xs text-slate-500">New prescription</p>
            </div>
          </button>

          <button
            onClick={() => navigate('/appointments?action=add')}
            className="flex items-center gap-3 rounded-2xl border border-sky-100 bg-sky-50/40 p-4 text-left hover:bg-sky-50 transition-colors group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-sky-600 text-white shadow-sm shadow-sky-100 group-hover:scale-105 transition-transform">
              <Calendar className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">Schedule Visit</p>
              <p className="text-xs text-slate-500">Doctor appointment</p>
            </div>
          </button>

          <button
            onClick={() => navigate('/documents?action=upload')}
            className="flex items-center gap-3 rounded-2xl border border-emerald-100 bg-emerald-50/40 p-4 text-left hover:bg-emerald-50 transition-colors group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-600 text-white shadow-sm shadow-emerald-100 group-hover:scale-105 transition-transform">
              <FileText className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">Upload Record</p>
              <p className="text-xs text-slate-500">Reports & bills</p>
            </div>
          </button>

          <button
            onClick={() => navigate('/family?action=add')}
            className="flex items-center gap-3 rounded-2xl border border-purple-100 bg-purple-50/40 p-4 text-left hover:bg-purple-50 transition-colors group"
          >
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-600 text-white shadow-sm shadow-purple-100 group-hover:scale-105 transition-transform">
              <Users className="h-5 w-5" />
            </div>
            <div>
              <p className="text-sm font-bold text-slate-900">Add Family</p>
              <p className="text-xs text-slate-500">Care circle member</p>
            </div>
          </button>
        </div>
      </div>

      {/* Main Content Grid: Today's Doses & Sidebar Insights */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Left 2 Cols: Today's Medications */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-slate-900">Today's Medication Schedule</h3>
              <p className="text-xs text-slate-500">Log your doses and stay on track with adherence</p>
            </div>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => navigate('/medicines?tab=schedule')}
              className="text-indigo-600 hover:text-indigo-700"
            >
              View Full Schedule
              <ArrowRight className="h-3.5 w-3.5 ml-1" />
            </Button>
          </div>

          {isLoading ? (
            <div className="rounded-2xl border border-slate-100 bg-white p-12 text-center">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-indigo-600 border-t-transparent mx-auto mb-3" />
              <p className="text-sm text-slate-500">Loading today's doses...</p>
            </div>
          ) : todayDoses.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-slate-200 bg-white p-10 text-center space-y-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-indigo-50 text-indigo-600 mx-auto">
                <CheckCircle2 className="h-6 w-6" />
              </div>
              <h4 className="text-base font-bold text-slate-800">All Caught Up!</h4>
              <p className="text-xs text-slate-500 max-w-sm mx-auto">
                No scheduled doses pending for today. You can add new prescriptions to generate automatic reminders.
              </p>
              <Button
                variant="primary"
                size="sm"
                onClick={() => navigate('/medicines?action=add')}
              >
                <Plus className="h-4 w-4 mr-1" />
                Add New Medicine
              </Button>
            </div>
          ) : (
            <div className="space-y-3">
              {todayDoses.map((dose) => {
                const isTaken = dose.status === 'TAKEN';
                const isSkipped = dose.status === 'SKIPPED';
                const isSnoozed = dose.status === 'SNOOZED';

                return (
                  <Card key={dose.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="flex items-start gap-4">
                      <div className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-indigo-600 font-bold">
                        <Pill className="h-5 w-5" />
                      </div>
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <h4 className="text-base font-bold text-slate-900">{dose.medicineName}</h4>
                          {isTaken && <Badge variant="success">TAKEN</Badge>}
                          {isSkipped && <Badge variant="danger">SKIPPED</Badge>}
                          {isSnoozed && <Badge variant="warning">SNOOZED</Badge>}
                          {!isTaken && !isSkipped && !isSnoozed && (
                            <Badge variant="primary">SCHEDULED</Badge>
                          )}
                        </div>
                        <div className="flex items-center gap-3 text-xs text-slate-500">
                          <span className="font-semibold text-slate-700">{dose.dosage || '1 dose'}</span>
                          <span>•</span>
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {dose.scheduledTime || 'Scheduled'}
                          </span>
                          {dose.familyMemberName && (
                            <>
                              <span>•</span>
                              <span className="text-indigo-600 font-medium">For: {dose.familyMemberName}</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>

                    {!isTaken && !isSkipped && (
                      <div className="flex items-center gap-2 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100">
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => handleMarkTaken(dose.id)}
                          className="flex-1 sm:flex-none"
                        >
                          <CheckCircle2 className="h-3.5 w-3.5 mr-1" />
                          Taken
                        </Button>
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleMarkSkipped(dose.id)}
                          className="flex-1 sm:flex-none"
                        >
                          <XCircle className="h-3.5 w-3.5 mr-1 text-slate-400" />
                          Skip
                        </Button>
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleOpenSnooze(dose.id)}
                          className="flex-1 sm:flex-none text-amber-600"
                        >
                          <Clock3 className="h-3.5 w-3.5 mr-1" />
                          Snooze
                        </Button>
                      </div>
                    )}
                  </Card>
                );
              })}
            </div>
          )}
        </div>

        {/* Right 1 Col: Refill Alerts & Upcoming Visits */}
        <div className="space-y-6">
          {/* Refill Alerts */}
          <Card className="p-5 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-amber-500" />
                <h4 className="text-sm font-bold text-slate-900">Refill & Stock Alerts</h4>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => navigate('/medicines')}
                className="text-xs text-indigo-600 p-0 h-auto hover:bg-transparent"
              >
                Manage
              </Button>
            </div>

            {lowStockMedicines.length === 0 ? (
              <p className="text-xs text-slate-500 text-center py-3">
                ✓ All medication inventory levels are healthy.
              </p>
            ) : (
              <div className="space-y-2.5">
                {lowStockMedicines.slice(0, 3).map((med) => (
                  <div key={med.id} className="flex items-center justify-between p-3 rounded-xl bg-amber-50/60 border border-amber-100">
                    <div>
                      <p className="text-xs font-bold text-slate-900">{med.name}</p>
                      <p className="text-[11px] text-amber-700 font-semibold">
                        Remaining: {med.currentQuantity} / Threshold: {med.refillThreshold}
                      </p>
                    </div>
                    <Button
                      variant="warning"
                      size="sm"
                      onClick={() => navigate('/medicines')}
                      className="text-xs py-1 px-2.5"
                    >
                      Refill
                    </Button>
                  </div>
                ))}
              </div>
            )}
          </Card>

          {/* Upcoming Consultations */}
          <Card className="p-5 space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <Calendar className="h-4 w-4 text-sky-600" />
                <h4 className="text-sm font-bold text-slate-900">Upcoming Visits</h4>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => navigate('/appointments')}
                className="text-xs text-sky-600 p-0 h-auto hover:bg-transparent"
              >
                View All
              </Button>
            </div>

            {appointments.length === 0 ? (
              <p className="text-xs text-slate-500 text-center py-3">
                No appointments scheduled.
              </p>
            ) : (
              <div className="space-y-2.5">
                {appointments.slice(0, 3).map((apt) => (
                  <div key={apt.id} className="p-3 rounded-xl bg-slate-50 border border-slate-100 space-y-1">
                    <p className="text-xs font-bold text-slate-900">{apt.title}</p>
                    <p className="text-[11px] text-slate-500">{apt.doctorName} • {apt.location || 'Clinic'}</p>
                    <p className="text-[11px] font-semibold text-sky-600">{apt.appointmentTime}</p>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      </div>

      {/* Snooze Modal */}
      <Modal
        isOpen={snoozeModalOpen}
        onClose={() => setSnoozeModalOpen(false)}
        title="Snooze Medication Reminder"
        description="Choose how long to delay this dose notification"
      >
        <div className="space-y-4 pt-2">
          <div className="grid grid-cols-3 gap-3">
            {[15, 30, 60].map((mins) => (
              <button
                key={mins}
                type="button"
                onClick={() => setSnoozeMinutes(mins)}
                className={`py-3 px-4 rounded-xl border text-center font-bold text-sm transition-all ${
                  snoozeMinutes === mins
                    ? 'border-indigo-600 bg-indigo-50 text-indigo-700 shadow-sm'
                    : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'
                }`}
              >
                {mins} Mins
              </button>
            ))}
          </div>

          <div className="flex justify-end gap-2 pt-4 border-t border-slate-100">
            <Button
              variant="secondary"
              onClick={() => setSnoozeModalOpen(false)}
            >
              Cancel
            </Button>
            <Button
              variant="primary"
              isLoading={isActionLoading}
              onClick={handleConfirmSnooze}
            >
              Confirm Snooze
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
