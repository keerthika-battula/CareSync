import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { 
  Pill, Plus, Search, Filter, AlertTriangle, Clock, Calendar, 
  Trash2, Edit, CheckCircle2, XCircle, AlertCircle, User, 
  RefreshCw, X, Check, Bell, Layers 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/context/ToastContext';
import { medicinesApi, familyApi, remindersApi } from '@/services/api';

const FREQUENCY_OPTIONS = [
  { value: 'ONCE_DAILY', label: 'Once Daily (1x/day)', defaultTimes: ['08:00'] },
  { value: 'TWICE_DAILY', label: 'Twice Daily (2x/day)', defaultTimes: ['08:00', '20:00'] },
  { value: 'THREE_TIMES_DAILY', label: 'Three Times Daily (3x/day)', defaultTimes: ['08:00', '14:00', '20:00'] },
  { value: 'FOUR_TIMES_DAILY', label: 'Four Times Daily (4x/day)', defaultTimes: ['08:00', '12:00', '16:00', '20:00'] },
  { value: 'WEEKLY', label: 'Weekly', defaultTimes: ['08:00'] },
  { value: 'AS_NEEDED', label: 'As Needed (PRN)', defaultTimes: [] },
  { value: 'CUSTOM', label: 'Custom Schedule', defaultTimes: ['09:00'] },
];

const DAYS_OF_WEEK = [
  { id: 1, label: 'Mon' },
  { id: 2, label: 'Tue' },
  { id: 3, label: 'Wed' },
  { id: 4, label: 'Thu' },
  { id: 5, label: 'Fri' },
  { id: 6, label: 'Sat' },
  { id: 7, label: 'Sun' },
];

export default function MedicinesPage() {
  const { addToast } = useToast();
  const [searchParams, setSearchParams] = useSearchParams();

  // Active sub-tab: 'schedule' (Daily Doses) or 'inventory' (All Medicines)
  const initialTab = searchParams.get('tab') === 'inventory' ? 'inventory' : 'schedule';
  const [activeViewTab, setActiveViewTab] = useState(initialTab);

  // Data states
  const [medicines, setMedicines] = useState([]);
  const [familyMembers, setFamilyMembers] = useState([]);
  const [reminders, setReminders] = useState([]);
  const [loading, setLoading] = useState(true);

  // Inventory Filters
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMember, setFilterMember] = useState('ALL');
  const [filterStock, setFilterStock] = useState('ALL');

  // Dose Schedule Filters & Actions
  const [doseTab, setDoseTab] = useState('ALL'); // ALL, PENDING, TAKEN, SKIPPED
  const [actionLoading, setActionLoading] = useState(null);
  const [snoozeModalOpen, setSnoozeModalOpen] = useState(false);
  const [selectedReminder, setSelectedReminder] = useState(null);
  const [snoozeMinutes, setSnoozeMinutes] = useState(15);

  // Medicine Form Modal
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedMedicine, setSelectedMedicine] = useState(null);
  const [medicineToDelete, setMedicineToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    dosage: '',
    frequency: 'ONCE_DAILY',
    scheduledTimes: ['08:00'],
    daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
    currentQuantity: '',
    refillThreshold: '',
    startDate: new Date().toISOString().split('T')[0],
    endDate: '',
    notes: '',
    familyMemberId: '',
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const [medRes, famRes, remRes] = await Promise.all([
        medicinesApi.getAll().catch(() => ({ data: [] })),
        familyApi.getAll().catch(() => ({ data: [] })),
        remindersApi.getToday().catch(() => ({ data: [] })),
      ]);

      const medList = Array.isArray(medRes) ? medRes : (medRes.data || []);
      const famList = Array.isArray(famRes) ? famRes : (famRes.data || []);
      const remList = Array.isArray(remRes) ? remRes : (remRes.data || []);

      setMedicines(medList);
      setFamilyMembers(famList);
      setReminders(remList);
    } catch (err) {
      addToast(err.message || 'Failed to load medication details', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // Handle URL query parameters
  useEffect(() => {
    const tabParam = searchParams.get('tab');
    if (tabParam === 'inventory' || tabParam === 'schedule') {
      setActiveViewTab(tabParam);
    }
    if (searchParams.get('action') === 'add') {
      openAddModal();
      setSearchParams(prev => {
        const next = new URLSearchParams(prev);
        next.delete('action');
        return next;
      }, { replace: true });
    }
  }, [searchParams]);

  const handleTabChange = (tab) => {
    setActiveViewTab(tab);
    setSearchParams(prev => {
      const next = new URLSearchParams(prev);
      next.set('tab', tab);
      return next;
    }, { replace: true });
  };

  // --- Dose Actions ---
  const handleMarkTaken = async (id) => {
    try {
      setActionLoading(id);
      await remindersApi.markTaken(id);
      addToast('Dose recorded as taken!', 'success');
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to record dose', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  const handleMarkSkipped = async (id) => {
    try {
      setActionLoading(id);
      await remindersApi.markSkipped(id);
      addToast('Dose marked as skipped', 'info');
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to skip dose', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  const openSnooze = (rem) => {
    setSelectedReminder(rem);
    setSnoozeMinutes(15);
    setSnoozeModalOpen(true);
  };

  const handleSnooze = async () => {
    if (!selectedReminder) return;
    try {
      setActionLoading(selectedReminder.id);
      await remindersApi.snooze(selectedReminder.id, snoozeMinutes);
      addToast(`Snoozed dose for ${snoozeMinutes} minutes`, 'info');
      setSnoozeModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to snooze reminder', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  // Dose Metrics
  const totalDoses = reminders.length;
  const takenCount = reminders.filter(r => r.status === 'TAKEN').length;
  const pendingCount = reminders.filter(r => r.status === 'PENDING' || r.status === 'SNOOZED').length;
  const skippedCount = reminders.filter(r => r.status === 'SKIPPED').length;
  const adherenceRate = totalDoses > 0 ? Math.round((takenCount / totalDoses) * 100) : 100;

  const filteredReminders = reminders.filter(rem => {
    if (doseTab === 'PENDING') return rem.status === 'PENDING' || rem.status === 'SNOOZED';
    if (doseTab === 'TAKEN') return rem.status === 'TAKEN';
    if (doseTab === 'SKIPPED') return rem.status === 'SKIPPED';
    return true;
  });

  // --- Medicine Inventory Form Actions ---
  const openAddModal = () => {
    setSelectedMedicine(null);
    setFormData({
      name: '',
      dosage: '',
      frequency: 'ONCE_DAILY',
      scheduledTimes: ['08:00'],
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      currentQuantity: '30',
      refillThreshold: '5',
      startDate: new Date().toISOString().split('T')[0],
      endDate: '',
      notes: '',
      familyMemberId: '',
    });
    setIsModalOpen(true);
  };

  const openEditModal = (med) => {
    setSelectedMedicine(med);
    const times = med.schedules && med.schedules.length > 0
      ? (med.schedules[0].scheduledTimes || [med.schedules[0].scheduledTime || '08:00'])
      : ['08:00'];

    setFormData({
      name: med.name || '',
      dosage: med.dosage || '',
      frequency: med.frequency || 'ONCE_DAILY',
      scheduledTimes: times,
      daysOfWeek: med.schedules?.[0]?.daysOfWeek || [1, 2, 3, 4, 5, 6, 7],
      currentQuantity: med.currentQuantity != null ? String(med.currentQuantity) : '',
      refillThreshold: med.refillThreshold != null ? String(med.refillThreshold) : '',
      startDate: med.startDate ? med.startDate.split('T')[0] : '',
      endDate: med.endDate ? med.endDate.split('T')[0] : '',
      notes: med.notes || '',
      familyMemberId: med.familyMemberId || '',
    });
    setIsModalOpen(true);
  };

  const handleFrequencyChange = (freq) => {
    const matched = FREQUENCY_OPTIONS.find(o => o.value === freq);
    setFormData(prev => ({
      ...prev,
      frequency: freq,
      scheduledTimes: matched ? [...matched.defaultTimes] : ['08:00'],
    }));
  };

  const handleAddTime = () => {
    setFormData(prev => ({
      ...prev,
      scheduledTimes: [...prev.scheduledTimes, '12:00'],
    }));
  };

  const handleRemoveTime = (index) => {
    setFormData(prev => ({
      ...prev,
      scheduledTimes: prev.scheduledTimes.filter((_, i) => i !== index),
    }));
  };

  const handleTimeChange = (index, val) => {
    setFormData(prev => {
      const updated = [...prev.scheduledTimes];
      updated[index] = val;
      return { ...prev, scheduledTimes: updated };
    });
  };

  const toggleDayOfWeek = (dayId) => {
    setFormData(prev => {
      const days = prev.daysOfWeek.includes(dayId)
        ? prev.daysOfWeek.filter(d => d !== dayId)
        : [...prev.daysOfWeek, dayId].sort();
      return { ...prev, daysOfWeek: days };
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim()) {
      addToast('Medicine name is required', 'warning');
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        name: formData.name.trim(),
        dosage: formData.dosage.trim() || null,
        frequency: formData.frequency,
        currentQuantity: formData.currentQuantity !== '' ? parseInt(formData.currentQuantity, 10) : null,
        refillThreshold: formData.refillThreshold !== '' ? parseInt(formData.refillThreshold, 10) : null,
        startDate: formData.startDate || null,
        endDate: formData.endDate || null,
        notes: formData.notes.trim() || null,
        familyMemberId: formData.familyMemberId || null,
        schedules: [
          {
            scheduledTime: formData.scheduledTimes[0] || '08:00',
            scheduledTimes: formData.scheduledTimes,
            frequency: formData.frequency,
            daysOfWeek: formData.daysOfWeek,
          }
        ]
      };

      if (selectedMedicine) {
        await medicinesApi.update(selectedMedicine.id, payload);
        addToast(`Updated ${payload.name} successfully`, 'success');
      } else {
        await medicinesApi.create(payload);
        addToast(`Added ${payload.name} successfully`, 'success');
      }

      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to save medicine', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = (med) => {
    setMedicineToDelete(med);
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!medicineToDelete) return;
    try {
      setSubmitting(true);
      await medicinesApi.delete(medicineToDelete.id);
      addToast(`Deleted ${medicineToDelete.name}`, 'success');
      setIsDeleteModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to delete medicine', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  // Filtered Medicines
  const filteredMedicines = medicines.filter(med => {
    const matchesSearch = med.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      med.dosage?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      med.notes?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesMember = filterMember === 'ALL' 
      ? true 
      : filterMember === 'SELF' 
        ? !med.familyMemberId 
        : med.familyMemberId === filterMember;

    const isLow = med.currentQuantity != null && med.refillThreshold != null && med.currentQuantity <= med.refillThreshold;
    const isOutOfStock = med.currentQuantity === 0;

    const matchesStock = filterStock === 'ALL'
      ? true
      : filterStock === 'LOW'
        ? isLow
        : filterStock === 'OUT'
          ? isOutOfStock
          : true;

    return matchesSearch && matchesMember && matchesStock;
  });

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Medicines & Doses</h1>
          <p className="text-sm text-slate-500 mt-1">
            Track scheduled dose timings, confirm intake, and manage medication inventory
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button size="sm" onClick={openAddModal}>
            <Plus className="w-4 h-4 mr-2" />
            Add New Medicine
          </Button>
        </div>
      </div>

      {/* Sub-Tabs: Dose Schedule vs Medication Inventory */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-1">
        <button
          onClick={() => handleTabChange('schedule')}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-xl transition-all ${
            activeViewTab === 'schedule'
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-200'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Clock className="w-4 h-4" />
          <span>Daily Dose Schedule</span>
          {totalDoses > 0 && (
            <span className={`text-xs px-2 py-0.5 rounded-full font-bold ${
              activeViewTab === 'schedule' ? 'bg-indigo-500 text-white' : 'bg-slate-200 text-slate-700'
            }`}>
              {totalDoses}
            </span>
          )}
        </button>

        <button
          onClick={() => handleTabChange('inventory')}
          className={`flex items-center gap-2 px-4 py-2 text-sm font-semibold rounded-xl transition-all ${
            activeViewTab === 'inventory'
              ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-200'
              : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
          }`}
        >
          <Pill className="w-4 h-4" />
          <span>Medication Inventory</span>
          {medicines.length > 0 && (
            <span className={`text-xs px-2 py-0.5 rounded-full font-bold ${
              activeViewTab === 'inventory' ? 'bg-indigo-500 text-white' : 'bg-slate-200 text-slate-700'
            }`}>
              {medicines.length}
            </span>
          )}
        </button>
      </div>

      {/* VIEW TAB 1: DAILY DOSE SCHEDULE */}
      {activeViewTab === 'schedule' && (
        <div className="space-y-6">
          {/* Stats Cards */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <Card className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium text-slate-500">Today's Doses</p>
                  <h3 className="text-2xl font-bold text-slate-900 mt-1">{totalDoses}</h3>
                </div>
                <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                  <Clock className="w-5 h-5" />
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium text-slate-500">Taken</p>
                  <h3 className="text-2xl font-bold text-emerald-600 mt-1">{takenCount}</h3>
                </div>
                <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <CheckCircle2 className="w-5 h-5" />
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium text-slate-500">Pending</p>
                  <h3 className="text-2xl font-bold text-amber-600 mt-1">{pendingCount}</h3>
                </div>
                <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
                  <AlertCircle className="w-5 h-5" />
                </div>
              </div>
            </Card>

            <Card className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-medium text-slate-500">Adherence Rate</p>
                  <h3 className="text-2xl font-bold text-indigo-700 mt-1">{adherenceRate}%</h3>
                </div>
                <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
                  <Check className="w-5 h-5" />
                </div>
              </div>
            </Card>
          </div>

          {/* Dose Status Filter Tabs */}
          <div className="flex items-center gap-2 border-b border-slate-100 pb-2">
            {[
              { id: 'ALL', label: `All Doses (${totalDoses})` },
              { id: 'PENDING', label: `Pending (${pendingCount})` },
              { id: 'TAKEN', label: `Taken (${takenCount})` },
              { id: 'SKIPPED', label: `Skipped (${skippedCount})` },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setDoseTab(tab.id)}
                className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
                  doseTab === tab.id
                    ? 'bg-indigo-50 text-indigo-700 font-semibold'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Doses List */}
          {loading ? (
            <Card className="p-6 space-y-4">
              {[1, 2, 3].map(i => (
                <div key={i} className="h-16 bg-slate-100 rounded-lg animate-pulse"></div>
              ))}
            </Card>
          ) : filteredReminders.length === 0 ? (
            <Card className="text-center py-12">
              <CardContent className="space-y-3">
                <div className="w-12 h-12 rounded-full bg-slate-100 text-slate-500 flex items-center justify-center mx-auto">
                  <CheckCircle2 className="w-6 h-6 text-indigo-600" />
                </div>
                <h3 className="text-base font-semibold text-slate-900">
                  {doseTab === 'ALL' ? 'No doses scheduled for today' : `No ${doseTab.toLowerCase()} doses`}
                </h3>
                <p className="text-sm text-slate-500 max-w-sm mx-auto">
                  {doseTab === 'ALL' 
                    ? 'All your scheduled medications for today will appear here once configured in the inventory.'
                    : `There are currently no doses matching the ${doseTab.toLowerCase()} filter.`}
                </p>
                {doseTab === 'ALL' && (
                  <Button onClick={openAddModal} className="mt-2">
                    <Plus className="w-4 h-4 mr-2" />
                    Add First Medicine
                  </Button>
                )}
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {filteredReminders.map(rem => {
                const isTaken = rem.status === 'TAKEN';
                const isSkipped = rem.status === 'SKIPPED';
                const isSnoozed = rem.status === 'SNOOZED';
                const isPending = rem.status === 'PENDING' || isSnoozed;

                const timeDisplay = rem.scheduledTime ? rem.scheduledTime.substring(0, 5) : '--:--';

                return (
                  <Card
                    key={rem.id}
                    className={`transition-all duration-200 border ${
                      isTaken
                        ? 'border-emerald-200 bg-emerald-50/20'
                        : isSkipped
                          ? 'border-slate-200 bg-slate-50/50 opacity-70'
                          : 'border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <CardContent className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                      {/* Left: Time & Medicine Info */}
                      <div className="flex items-start gap-4">
                        <div className={`p-2.5 rounded-xl text-center shrink-0 min-w-[64px] ${
                          isTaken 
                            ? 'bg-emerald-100 text-emerald-800' 
                            : isSkipped 
                              ? 'bg-slate-200 text-slate-600' 
                              : 'bg-indigo-50 text-indigo-800 border border-indigo-200'
                        }`}>
                          <div className="text-xs font-mono font-bold">{timeDisplay}</div>
                          <div className="text-[10px] uppercase font-medium mt-0.5">
                            {isTaken ? 'Taken' : isSkipped ? 'Skipped' : 'Scheduled'}
                          </div>
                        </div>

                        <div>
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="font-semibold text-slate-900 text-base">{rem.medicineName}</h3>
                            {rem.dosage && (
                              <span className="text-xs bg-slate-100 text-slate-700 font-medium px-2 py-0.5 rounded">
                                {rem.dosage}
                              </span>
                            )}
                            {rem.familyMemberName && (
                              <span className="text-xs bg-purple-50 text-purple-700 font-medium px-2 py-0.5 rounded flex items-center gap-1">
                                <User className="w-3 h-3" />
                                {rem.familyMemberName}
                              </span>
                            )}
                            {isSnoozed && (
                              <Badge variant="warning">Snoozed</Badge>
                            )}
                          </div>

                          {rem.instructions && (
                            <p className="text-xs text-slate-500 mt-1 italic">
                              "{rem.instructions}"
                            </p>
                          )}
                        </div>
                      </div>

                      {/* Right: Actions */}
                      <div className="flex items-center gap-2 sm:self-center shrink-0">
                        {isPending ? (
                          <>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => openSnooze(rem)}
                              disabled={actionLoading === rem.id}
                              className="text-xs text-slate-600"
                            >
                              <Bell className="w-3.5 h-3.5 mr-1" />
                              Snooze
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleMarkSkipped(rem.id)}
                              disabled={actionLoading === rem.id}
                              className="text-xs text-slate-500 hover:text-rose-600 hover:bg-rose-50 hover:border-rose-200"
                            >
                              <X className="w-3.5 h-3.5 mr-1" />
                              Skip
                            </Button>
                            <Button
                              size="sm"
                              onClick={() => handleMarkTaken(rem.id)}
                              loading={actionLoading === rem.id}
                              className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white"
                            >
                              <Check className="w-3.5 h-3.5 mr-1" />
                              Take Dose
                            </Button>
                          </>
                        ) : isTaken ? (
                          <div className="flex items-center text-emerald-600 font-medium text-xs bg-emerald-50 px-3 py-1.5 rounded-lg border border-emerald-200">
                            <CheckCircle2 className="w-4 h-4 mr-1.5" />
                            Completed
                          </div>
                        ) : (
                          <div className="flex items-center text-slate-500 font-medium text-xs bg-slate-100 px-3 py-1.5 rounded-lg">
                            <XCircle className="w-4 h-4 mr-1.5" />
                            Skipped
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* VIEW TAB 2: MEDICATION INVENTORY */}
      {activeViewTab === 'inventory' && (
        <div className="space-y-6">
          {/* Filters Bar */}
          <Card>
            <CardContent className="p-4">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <Input
                  placeholder="Search medicines..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  icon={Search}
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

                <Select
                  value={filterStock}
                  onChange={(e) => setFilterStock(e.target.value)}
                  options={[
                    { value: 'ALL', label: 'All Stock Levels' },
                    { value: 'LOW', label: 'Low Stock Alert' },
                    { value: 'OUT', label: 'Out of Stock' },
                  ]}
                />
              </div>
            </CardContent>
          </Card>

          {/* Medicine Grid */}
          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {[1, 2, 3, 4, 5, 6].map(i => (
                <Card key={i} className="animate-pulse">
                  <CardContent className="p-6 space-y-4">
                    <div className="h-6 bg-slate-200 rounded w-1/2"></div>
                    <div className="h-4 bg-slate-100 rounded w-3/4"></div>
                    <div className="h-8 bg-slate-100 rounded"></div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : filteredMedicines.length === 0 ? (
            <Card className="text-center py-12">
              <CardContent className="space-y-4">
                <div className="w-12 h-12 rounded-full bg-indigo-50 text-indigo-600 flex items-center justify-center mx-auto">
                  <Pill className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="text-base font-semibold text-slate-900">No medicines found</h3>
                  <p className="text-sm text-slate-500 max-w-sm mx-auto mt-1">
                    {searchQuery || filterMember !== 'ALL' || filterStock !== 'ALL'
                      ? 'No medicines match your active search filters.'
                      : 'Get started by adding your first prescription or over-the-counter medicine.'}
                  </p>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {filteredMedicines.map(med => {
                const isLowStock = med.currentQuantity != null && med.refillThreshold != null && med.currentQuantity <= med.refillThreshold;
                const isOutOfStock = med.currentQuantity === 0;
                const memberName = familyMembers.find(f => f.id === med.familyMemberId)?.name;

                const scheduleTimes = med.schedules?.[0]?.scheduledTimes || 
                  (med.schedules?.[0]?.scheduledTime ? [med.schedules[0].scheduledTime] : []);

                return (
                  <Card key={med.id} className="flex flex-col justify-between hover:border-slate-300 transition-shadow hover:shadow-sm">
                    <CardContent className="p-5 space-y-4">
                      {/* Header info */}
                      <div className="flex items-start justify-between gap-2">
                        <div className="flex items-start gap-3">
                          <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0">
                            <Pill className="w-5 h-5" />
                          </div>
                          <div>
                            <h3 className="font-semibold text-slate-900 leading-snug">{med.name}</h3>
                            {med.dosage && (
                              <span className="text-xs font-medium text-slate-500 block">{med.dosage}</span>
                            )}
                          </div>
                        </div>
                        {isOutOfStock ? (
                          <Badge variant="danger" className="shrink-0">Out of Stock</Badge>
                        ) : isLowStock ? (
                          <Badge variant="warning" className="shrink-0">Low Stock</Badge>
                        ) : (
                          <Badge variant="secondary" className="shrink-0">Active</Badge>
                        )}
                      </div>

                      {/* Details Card */}
                      <div className="space-y-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-lg border border-slate-100">
                        <div className="flex items-center justify-between">
                          <span className="text-slate-500">Frequency:</span>
                          <span className="font-medium text-slate-800">
                            {med.frequency ? med.frequency.replace(/_/g, ' ') : 'Once Daily'}
                          </span>
                        </div>
                        {scheduleTimes.length > 0 && (
                          <div className="flex items-center justify-between">
                            <span className="text-slate-500">Scheduled:</span>
                            <span className="font-mono font-medium text-indigo-600 bg-indigo-50 px-1.5 py-0.5 rounded">
                              {scheduleTimes.join(', ')}
                            </span>
                          </div>
                        )}
                        {memberName && (
                          <div className="flex items-center justify-between">
                            <span className="text-slate-500">Assigned To:</span>
                            <span className="font-medium text-purple-700 bg-purple-50 px-1.5 py-0.5 rounded flex items-center gap-1">
                              <User className="w-3 h-3" />
                              {memberName}
                            </span>
                          </div>
                        )}
                        {med.currentQuantity != null && (
                          <div className="flex items-center justify-between pt-1 border-t border-slate-200">
                            <span className="text-slate-500">Stock Remaining:</span>
                            <span className={`font-semibold ${isOutOfStock ? 'text-rose-600' : isLowStock ? 'text-amber-600' : 'text-slate-800'}`}>
                              {med.currentQuantity} units {med.refillThreshold ? `(Refill at ${med.refillThreshold})` : ''}
                            </span>
                          </div>
                        )}
                      </div>

                      {med.notes && (
                        <p className="text-xs text-slate-500 italic bg-white p-2 rounded border border-slate-100">
                          "{med.notes}"
                        </p>
                      )}

                      {/* Card Actions */}
                      <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => openEditModal(med)}
                          className="text-xs h-8 text-slate-600 hover:text-indigo-600"
                        >
                          <Edit className="w-3.5 h-3.5 mr-1" />
                          Edit
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => confirmDelete(med)}
                          className="text-xs h-8 text-rose-500 hover:text-rose-600 hover:bg-rose-50"
                        >
                          <Trash2 className="w-3.5 h-3.5 mr-1" />
                          Delete
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </div>
      )}

      {/* SNOOZE MODAL */}
      <Modal
        isOpen={snoozeModalOpen}
        onClose={() => setSnoozeModalOpen(false)}
        title="Snooze Dose Reminder"
        description="Select how long you would like to postpone this dose notification."
        maxWidth="max-w-md"
      >
        <div className="space-y-4">
          <div className="grid grid-cols-3 gap-2">
            {[15, 30, 60].map(mins => (
              <button
                key={mins}
                type="button"
                onClick={() => setSnoozeMinutes(mins)}
                className={`py-2.5 px-3 text-xs font-semibold rounded-xl border transition-all ${
                  snoozeMinutes === mins
                    ? 'border-indigo-600 bg-indigo-50 text-indigo-700'
                    : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'
                }`}
              >
                {mins} Minutes
              </button>
            ))}
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button variant="outline" onClick={() => setSnoozeModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSnooze} loading={actionLoading === selectedReminder?.id}>
              Confirm Snooze
            </Button>
          </div>
        </div>
      </Modal>

      {/* ADD / EDIT MEDICINE MODAL */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => !submitting && setIsModalOpen(false)}
        title={selectedMedicine ? "Edit Medication" : "Add New Medication"}
        description="Enter prescription details, dose schedule timings, and stock alerts."
        maxWidth="max-w-xl"
        footer={
          <>
            <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" form="medicine-form" loading={submitting}>
              {selectedMedicine ? 'Save Changes' : 'Add Medication'}
            </Button>
          </>
        }
      >
        <form id="medicine-form" onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Medicine Name *"
              placeholder="e.g., Atorvastatin, Metformin"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
            <Input
              label="Dosage / Strength"
              placeholder="e.g., 20mg, 500mg, 1 tablet"
              value={formData.dosage}
              onChange={(e) => setFormData({ ...formData, dosage: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="Assigned Family Member"
              value={formData.familyMemberId}
              onChange={(e) => setFormData({ ...formData, familyMemberId: e.target.value })}
              options={[
                { value: '', label: 'Myself (Primary User)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
            <Select
              label="Dosage Frequency"
              value={formData.frequency}
              onChange={(e) => handleFrequencyChange(e.target.value)}
              options={FREQUENCY_OPTIONS}
            />
          </div>

          {/* Schedule Timings */}
          {formData.frequency !== 'AS_NEEDED' && (
            <div className="space-y-3 bg-slate-50 p-3.5 rounded-xl border border-slate-100">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-slate-700">
                  Reminder Schedule Times (24h format)
                </label>
                <Button type="button" variant="outline" size="sm" onClick={handleAddTime} className="h-7 text-xs">
                  <Plus className="w-3 h-3 mr-1" />
                  Add Time
                </Button>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                {formData.scheduledTimes.map((time, idx) => (
                  <div key={idx} className="flex items-center gap-1 bg-white p-1 rounded-lg border border-slate-200 shadow-sm">
                    <input
                      type="time"
                      value={time}
                      onChange={(e) => handleTimeChange(idx, e.target.value)}
                      className="w-full text-xs font-mono px-2 py-1 bg-transparent focus:outline-none text-slate-800"
                    />
                    {formData.scheduledTimes.length > 1 && (
                      <button
                        type="button"
                        onClick={() => handleRemoveTime(idx)}
                        className="p-1 text-slate-400 hover:text-rose-500 rounded"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                ))}
              </div>

              {formData.frequency === 'WEEKLY' && (
                <div className="pt-2">
                  <label className="text-xs font-medium text-slate-600 block mb-1.5">Select Days of Week</label>
                  <div className="flex flex-wrap gap-1.5">
                    {DAYS_OF_WEEK.map(d => {
                      const selected = formData.daysOfWeek.includes(d.id);
                      return (
                        <button
                          key={d.id}
                          type="button"
                          onClick={() => toggleDayOfWeek(d.id)}
                          className={`px-2.5 py-1 text-xs rounded-md font-medium transition-colors ${
                            selected ? 'bg-indigo-600 text-white' : 'bg-white border border-slate-200 text-slate-700 hover:bg-slate-100'
                          }`}
                        >
                          {d.label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Current Quantity (Stock)"
              type="number"
              min="0"
              placeholder="e.g., 30"
              value={formData.currentQuantity}
              onChange={(e) => setFormData({ ...formData, currentQuantity: e.target.value })}
            />
            <Input
              label="Refill Alert Level (Threshold)"
              type="number"
              min="0"
              placeholder="e.g., 5"
              value={formData.refillThreshold}
              onChange={(e) => setFormData({ ...formData, refillThreshold: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Start Date"
              type="date"
              value={formData.startDate}
              onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
            />
            <Input
              label="End Date (Optional)"
              type="date"
              value={formData.endDate}
              onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
            />
          </div>

          <Input
            label="Instructions / Notes"
            placeholder="e.g., Take after food with water"
            value={formData.notes}
            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          />
        </form>
      </Modal>

      {/* DELETE CONFIRMATION MODAL */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => !submitting && setIsDeleteModalOpen(false)}
        title="Delete Medicine"
        description="Are you sure you want to delete this medicine? All scheduled reminders and logs for this medicine will be permanently removed."
        maxWidth="max-w-md"
      >
        <div className="flex items-center justify-end gap-3 pt-4">
          <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button variant="danger" onClick={handleDelete} loading={submitting}>
            Delete Medicine
          </Button>
        </div>
      </Modal>
    </div>
  );
}
