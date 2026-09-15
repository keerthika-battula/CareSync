import React, { useState, useEffect } from 'react';
import { 
  Users, UserPlus, Heart, User, Trash2, Plus, 
  RefreshCw, Calendar, ShieldCheck, Pill, ArrowRight 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { familyApi } from '@/services/api';
import { Link } from 'react-router-dom';

const RELATIONSHIPS = [
  { value: 'Spouse', label: 'Spouse / Partner' },
  { value: 'Child', label: 'Child / Dependent' },
  { value: 'Parent', label: 'Parent / Elder' },
  { value: 'Sibling', label: 'Sibling' },
  { value: 'Grandparent', label: 'Grandparent' },
  { value: 'Other', label: 'Other Relative / Friend' },
];

export default function FamilyPage() {
  const { user } = useAuth();
  const { addToast } = useToast();
  const [familyMembers, setFamilyMembers] = useState([]);
  const [loading, setLoading] = useState(true);

  // Modals
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [memberToDelete, setMemberToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  // Form
  const [formData, setFormData] = useState({
    name: '',
    relationship: 'Spouse',
    dateOfBirth: '',
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const res = await familyApi.getAll();
      const list = Array.isArray(res) ? res : (res.data || []);
      setFamilyMembers(list);
    } catch (err) {
      addToast(err.message || 'Failed to load family members', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const openAddModal = () => {
    setFormData({
      name: '',
      relationship: 'Spouse',
      dateOfBirth: '',
    });
    setIsModalOpen(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name.trim() || !formData.relationship) {
      addToast('Name and relationship are required', 'warning');
      return;
    }

    try {
      setSubmitting(true);
      const payload = {
        name: formData.name.trim(),
        relationship: formData.relationship,
        dateOfBirth: formData.dateOfBirth || null,
      };

      await familyApi.create(payload);
      addToast(`Added ${payload.name} to your care circle`, 'success');
      setIsModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to add family member', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const confirmDelete = (member) => {
    setMemberToDelete(member);
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!memberToDelete) return;
    try {
      setSubmitting(true);
      await familyApi.delete(memberToDelete.id);
      addToast(`Removed ${memberToDelete.name}`, 'success');
      setIsDeleteModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to remove family member', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const calculateAge = (dobString) => {
    if (!dobString) return null;
    try {
      const dob = new Date(dobString);
      const diffMs = Date.now() - dob.getTime();
      const ageDate = new Date(diffMs);
      return Math.abs(ageDate.getUTCFullYear() - 1970);
    } catch {
      return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Family Care Circle</h1>
          <p className="text-sm text-slate-500 mt-1">
            Manage dependent health profiles, prescriptions, and shared appointments
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button size="sm" onClick={openAddModal}>
            <UserPlus className="w-4 h-4 mr-2" />
            Add Family Member
          </Button>
        </div>
      </div>

      {/* Grid of Profiles */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {/* Primary Account Holder Card */}
        <Card className="border-teal-200 bg-gradient-to-br from-teal-50/40 via-white to-white flex flex-col justify-between">
          <CardContent className="p-5 space-y-4">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-xl bg-teal-600 text-white flex items-center justify-center font-bold text-lg shadow-sm">
                  {user?.fullName?.charAt(0) || 'U'}
                </div>
                <div>
                  <h3 className="font-bold text-slate-900">{user?.fullName || 'Primary User'}</h3>
                  <p className="text-xs text-slate-500">{user?.email}</p>
                </div>
              </div>
              <Badge variant="default">Account Owner</Badge>
            </div>

            <div className="space-y-2 text-xs text-slate-600 bg-white/80 p-3 rounded-lg border border-teal-100">
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Role:</span>
                <span className="font-semibold text-teal-800">{user?.role || 'USER'}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-500">Status:</span>
                <span className="font-semibold text-emerald-600">Active Caregiver</span>
              </div>
            </div>
          </CardContent>

          <div className="p-4 border-t border-teal-100 bg-white/60 flex items-center justify-between">
            <span className="text-xs text-slate-500">Primary Profile</span>
            <Link to="/profile" className="text-xs font-semibold text-teal-600 hover:text-teal-700 flex items-center">
              View Profile <ArrowRight className="w-3.5 h-3.5 ml-1" />
            </Link>
          </div>
        </Card>

        {/* Family Member Cards */}
        {loading ? (
          [1, 2].map(i => (
            <Card key={i} className="animate-pulse p-6 space-y-3">
              <div className="h-10 bg-slate-200 rounded-full w-10"></div>
              <div className="h-4 bg-slate-100 rounded w-1/2"></div>
              <div className="h-4 bg-slate-100 rounded w-3/4"></div>
            </Card>
          ))
        ) : familyMembers.map(member => {
          const age = calculateAge(member.dateOfBirth);

          return (
            <Card key={member.id} className="flex flex-col justify-between hover:border-slate-300 transition-all">
              <CardContent className="p-5 space-y-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center font-bold text-lg">
                      {member.name.charAt(0)}
                    </div>
                    <div>
                      <h3 className="font-semibold text-slate-900">{member.name}</h3>
                      <span className="text-xs text-purple-700 font-medium bg-purple-50 px-2 py-0.5 rounded inline-block mt-0.5">
                        {member.relationship}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2 text-xs text-slate-600 bg-slate-50 p-3 rounded-lg border border-slate-100">
                  {member.dateOfBirth ? (
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500 flex items-center">
                        <Calendar className="w-3.5 h-3.5 mr-1 text-slate-400" />
                        Birth Date:
                      </span>
                      <span className="font-medium text-slate-800">
                        {member.dateOfBirth} {age !== null && `(${age} yrs)`}
                      </span>
                    </div>
                  ) : (
                    <div className="text-slate-400 italic">No birth date provided</div>
                  )}
                </div>
              </CardContent>

              <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between">
                <Link to="/medicines" className="text-xs font-semibold text-teal-600 hover:text-teal-700 flex items-center">
                  <Pill className="w-3.5 h-3.5 mr-1" />
                  Prescriptions
                </Link>
                <Button variant="ghost" size="sm" className="text-rose-600 hover:text-rose-700 hover:bg-rose-50" onClick={() => confirmDelete(member)}>
                  <Trash2 className="w-3.5 h-3.5 mr-1" />
                  Remove
                </Button>
              </div>
            </Card>
          );
        })}
      </div>

      {!loading && familyMembers.length === 0 && (
        <Card className="text-center py-8 bg-slate-50 border-dashed">
          <CardContent className="space-y-3">
            <Heart className="w-8 h-8 text-rose-400 mx-auto" />
            <h3 className="text-sm font-semibold text-slate-900">Add your family members</h3>
            <p className="text-xs text-slate-500 max-w-sm mx-auto">
              Add your children, parents, or partner to manage their medicine dosages, refill alerts, and doctor appointments in one place.
            </p>
            <Button size="sm" onClick={openAddModal}>
              <UserPlus className="w-4 h-4 mr-2" />
              Add First Family Member
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Add Member Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => !submitting && setIsModalOpen(false)}
        title="Add Family Member"
        description="Create a dependent or relative profile in your CareSync care circle."
        maxWidth="max-w-md"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            label="Full Name *"
            placeholder="e.g., Emily Davis"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            required
          />

          <Select
            label="Relationship *"
            value={formData.relationship}
            onChange={(e) => setFormData({ ...formData, relationship: e.target.value })}
            options={RELATIONSHIPS}
          />

          <Input
            label="Date of Birth"
            type="date"
            value={formData.dateOfBirth}
            onChange={(e) => setFormData({ ...formData, dateOfBirth: e.target.value })}
          />

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={() => setIsModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" loading={submitting}>
              Add to Circle
            </Button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => !submitting && setIsDeleteModalOpen(false)}
        title="Remove Family Member"
        description="Are you sure you want to remove this family member? Their associated prescriptions and appointments will need reassignment."
        maxWidth="max-w-md"
      >
        <div className="flex items-center justify-end gap-3 pt-4">
          <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button variant="danger" onClick={handleDelete} loading={submitting}>
            Confirm Removal
          </Button>
        </div>
      </Modal>
    </div>
  );
}
