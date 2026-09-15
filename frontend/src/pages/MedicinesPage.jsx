import React, { useState, useEffect } from 'react';
import { 
  Pill, Plus, Search, Filter, AlertTriangle, Clock, Calendar, 
  Trash2, Edit, CheckCircle2, User, ChevronDown, RefreshCw, X 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/context/ToastContext';
import { medicinesApi, familyApi } from '@/services/api';

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
  const [medicines, setMedicines] = useState([]);
  const [familyMembers, setFamilyMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMember, setFilterMember] = useState('ALL');
  const [filterStock, setFilterStock] = useState('ALL');

  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [selectedMedicine, setSelectedMedicine] = useState(null);
  const [medicineToDelete, setMedicineToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Form states
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
      const [medRes, famRes] = await Promise.all([
        medicinesApi.getAll().catch(() => ({ data: [] })),
        familyApi.getAll().catch(() => ({ data: [] })),
      ]);

      const medList = Array.isArray(medRes) ? medRes : (medRes.data || []);
      const famList = Array.isArray(famRes) ? famRes : (famRes.data || []);
      setMedicines(medList);
      setFamilyMembers(famList);
    } catch (err) {
      addToast(err.message || 'Failed to load medicines', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

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

  // Filtering
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
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Medicine Management</h1>
          <p className="text-sm text-slate-500 mt-1">
            Track your medications, schedule dose timings, and manage refill alerts
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

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="relative">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <Input
                placeholder="Search medicines..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>

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
            <div className="w-12 h-12 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center mx-auto">
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
            {!(searchQuery || filterMember !== 'ALL' || filterStock !== 'ALL') && (
              <Button onClick={openAddModal}>
                <Plus className="w-4 h-4 mr-2" />
                Add Medicine
              </Button>
            )}
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
                      <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
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

                  {/* Badges / Details */}
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
                        <div className="flex flex-wrap gap-1">
                          {scheduleTimes.map((t, idx) => (
                            <span key={idx} className="bg-white border border-slate-200 px-1.5 py-0.5 rounded font-mono text-[11px] text-slate-700">
                              {t}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Stock Remaining:</span>
                      <span className={`font-semibold ${isLowStock ? 'text-amber-600' : 'text-slate-800'}`}>
                        {med.currentQuantity != null ? `${med.currentQuantity} units` : 'Not tracked'}
                      </span>
                    </div>
                    {memberName && (
                      <div className="flex items-center justify-between">
                        <span className="text-slate-500">Family Member:</span>
                        <span className="font-medium text-teal-700 bg-teal-50 px-2 py-0.5 rounded">
                          {memberName}
                        </span>
                      </div>
                    )}
                  </div>

                  {med.notes && (
                    <p className="text-xs text-slate-500 line-clamp-2 italic">
                      "{med.notes}"
                    </p>
                  )}
                </CardContent>

                {/* Card Actions */}
                <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-end gap-2">
                  <Button variant="outline" size="sm" onClick={() => openEditModal(med)}>
                    <Edit className="w-3.5 h-3.5 mr-1" />
                    Edit
                  </Button>
                  <Button variant="ghost" size="sm" className="text-rose-600 hover:text-rose-700 hover:bg-rose-50" onClick={() => confirmDelete(med)}>
                    <Trash2 className="w-3.5 h-3.5" />
                  </Button>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* Add / Edit Medicine Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => !submitting && setIsModalOpen(false)}
        title={selectedMedicine ? 'Edit Medicine' : 'Add New Medicine'}
        description="Fill in prescription dosage, schedule timing, and stock tracking parameters."
        maxWidth="max-w-2xl"
      >
        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Main Info */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Input
              label="Medicine Name *"
              placeholder="e.g., Metformin, Lisinopril"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              required
            />
            <Input
              label="Dosage / Strength"
              placeholder="e.g., 500mg, 10ml, 1 tablet"
              value={formData.dosage}
              onChange={(e) => setFormData({ ...formData, dosage: e.target.value })}
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="Frequency"
              value={formData.frequency}
              onChange={(e) => handleFrequencyChange(e.target.value)}
              options={FREQUENCY_OPTIONS.map(f => ({ value: f.value, label: f.label }))}
            />

            <Select
              label="Assign to Family Member"
              value={formData.familyMemberId}
              onChange={(e) => setFormData({ ...formData, familyMemberId: e.target.value })}
              options={[
                { value: '', label: 'For Myself (Primary User)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
          </div>

          {/* Schedule Times */}
          {formData.frequency !== 'AS_NEEDED' && (
            <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 space-y-3">
              <div className="flex items-center justify-between">
                <label className="text-xs font-semibold text-slate-800 flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-teal-600" />
                  Reminder Schedule Times (24h format)
                </label>
                <Button type="button" variant="outline" size="sm" onClick={handleAddTime} className="h-7 text-xs">
                  <Plus className="w-3 h-3 mr-1" />
                  Add Time
                </Button>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
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

              {/* Weekly Days Selector */}
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
                            selected ? 'bg-teal-600 text-white' : 'bg-white border border-slate-200 text-slate-700 hover:bg-slate-100'
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

          {/* Stock Tracking */}
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

          {/* Dates */}
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
            placeholder="e.g., Take after food with a full glass of water"
            value={formData.notes}
            onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
          />

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" loading={submitting}>
              {selectedMedicine ? 'Save Changes' : 'Add Medicine'}
            </Button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
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
