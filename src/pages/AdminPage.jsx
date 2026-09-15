import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, Users, UserPlus, Search, CheckCircle2, XCircle, 
  Eye, EyeOff, Lock, RefreshCw, Pill, Calendar, FileText, UserCheck, UserX, 
  Download, ChevronLeft, ChevronRight, Shield, Trash2, AlertCircle, UserRoundX 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { adminApi } from '@/services/api';

export default function AdminPage() {
  const { user: currentAuthUser } = useAuth();
  const { addToast } = useToast();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');

  // Create User Modal
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [showAdminCreatePassword, setShowAdminCreatePassword] = useState(false);
  const [createForm, setCreateForm] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    role: 'USER',
  });
  const [submitting, setSubmitting] = useState(false);

  // Delete User Confirmation Modal
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [userToDelete, setUserToDelete] = useState(null);
  const [isDeleting, setIsDeleting] = useState(false);

  // Healthcare Overview Modal
  const [isOverviewModalOpen, setIsOverviewModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [userOverview, setUserOverview] = useState(null);
  const [overviewLoading, setOverviewLoading] = useState(false);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getUsers(page, 20);
      const data = res?.data || res;
      if (Array.isArray(data)) {
        setUsers(data);
        setTotalPages(1);
      } else if (data?.content) {
        setUsers(data.content);
        setTotalPages(data.totalPages || 1);
      } else {
        setUsers([]);
      }
    } catch (err) {
      addToast(err.message || 'Failed to load user directory', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [page]);

  const handleCreateUser = async (e) => {
    e.preventDefault();
    const firstName = createForm.firstName.trim();
    const lastName = createForm.lastName.trim();
    const email = createForm.email.trim();
    const password = createForm.password;

    if (!firstName || !lastName || !email || !password) {
      addToast('First name, last name, email, and password are required', 'warning');
      return;
    }

    if (password.length < 6) {
      addToast('Password must be at least 6 characters', 'warning');
      return;
    }

    try {
      setSubmitting(true);
      await adminApi.createUser({
        firstName,
        lastName,
        email,
        password,
        role: createForm.role,
      });
      addToast(`User ${email} created successfully`, 'success');
      setIsCreateModalOpen(false);
      setCreateForm({ firstName: '', lastName: '', email: '', password: '', role: 'USER' });
      setShowAdminCreatePassword(false);
      fetchUsers();
    } catch (err) {
      addToast(err.message || 'Failed to create user', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRoleToggle = async (user) => {
    const newRole = user.role === 'ADMIN' ? 'USER' : 'ADMIN';
    try {
      await adminApi.updateRole(user.id, newRole);
      addToast(`Updated ${user.email} role to ${newRole}`, 'success');
      fetchUsers();
    } catch (err) {
      addToast(err.message || 'Failed to update user role', 'error');
    }
  };

  const handleStatusToggle = async (user) => {
    const newStatus = !user.isActive;
    try {
      await adminApi.updateStatus(user.id, newStatus);
      addToast(`Account ${user.email} marked as ${newStatus ? 'Active' : 'Deactivated'}`, 'info');
      fetchUsers();
    } catch (err) {
      addToast(err.message || 'Failed to update account status', 'error');
    }
  };

  const handleDeleteUser = async () => {
    if (!userToDelete) return;
    try {
      setIsDeleting(true);
      await adminApi.deleteUser(userToDelete.id);
      addToast('User account removed successfully.', 'success');
      setIsDeleteModalOpen(false);
      setUserToDelete(null);
      if (users.length === 1 && page > 0) {
        setPage((p) => p - 1);
      } else {
        fetchUsers();
      }
    } catch (err) {
      addToast(err.message || 'Failed to remove user account', 'error');
    } finally {
      setIsDeleting(false);
    }
  };

  const openUserOverview = async (user) => {
    setSelectedUser(user);
    setIsOverviewModalOpen(true);
    setOverviewLoading(true);
    try {
      const res = await adminApi.getUserHealthcareOverview(user.id);
      setUserOverview(res?.data || res || {});
    } catch (err) {
      addToast(err.message || 'Failed to load healthcare records', 'error');
    } finally {
      setOverviewLoading(false);
    }
  };

  const handleDownloadDoc = async (docId, fileName) => {
    if (!selectedUser) return;
    try {
      const blob = await adminApi.downloadUserDocument(selectedUser.id, docId);
      const blobUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = blobUrl;
      link.download = fileName || 'document.pdf';
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(blobUrl);
    } catch (err) {
      addToast(err.message || 'Failed to download document', 'error');
    }
  };

  const filteredUsers = users.filter(u => {
    const q = searchQuery.toLowerCase();
    return (
      u.email?.toLowerCase().includes(q) ||
      u.fullName?.toLowerCase().includes(q) ||
      u.role?.toLowerCase().includes(q)
    );
  });

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Shield className="w-6 h-6 text-teal-600" />
            <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Admin User Control Center</h1>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Manage user accounts, RBAC permissions, and review cross-account healthcare records
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchUsers} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button size="sm" onClick={() => setIsCreateModalOpen(true)}>
            <UserPlus className="w-4 h-4 mr-2" />
            Create User
          </Button>
        </div>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Total Registered Users</p>
              <h3 className="text-2xl font-bold text-slate-900 mt-1">{users.length}</h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
          </div>
        </Card>

        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Administrators</p>
              <h3 className="text-2xl font-bold text-amber-600 mt-1">
                {users.filter(u => u.role === 'ADMIN').length}
              </h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <ShieldAlert className="w-5 h-5" />
            </div>
          </div>
        </Card>

        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Patients / Caregivers</p>
              <h3 className="text-2xl font-bold text-teal-700 mt-1">
                {users.filter(u => u.role === 'USER').length}
              </h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <UserCheck className="w-5 h-5" />
            </div>
          </div>
        </Card>
      </div>

      {/* Search Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="relative">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
            <Input
              placeholder="Search users by name, email, or role..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9"
            />
          </div>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-600 uppercase tracking-wider">
              <tr>
                <th className="px-6 py-3.5">User Identity</th>
                <th className="px-6 py-3.5">Role</th>
                <th className="px-6 py-3.5">Account Status</th>
                <th className="px-6 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-slate-400">
                    <div className="inline-flex items-center gap-2">
                      <RefreshCw className="w-4 h-4 animate-spin text-teal-600" />
                      Loading user accounts...
                    </div>
                  </td>
                </tr>
              ) : filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan="4" className="px-6 py-12 text-center text-slate-500">
                    No users found matching your search.
                  </td>
                </tr>
              ) : (
                filteredUsers.map(u => (
                  <tr key={u.id} className="hover:bg-slate-50/75 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-teal-50 text-teal-700 flex items-center justify-center font-bold text-sm">
                          {u.fullName?.charAt(0) || u.email?.charAt(0) || 'U'}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-900">{u.fullName || 'Unnamed User'}</div>
                          <div className="text-xs text-slate-500">{u.email}</div>
                        </div>
                      </div>
                    </td>

                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleRoleToggle(u)}
                        title="Click to toggle role"
                        className="group flex items-center gap-1.5 cursor-pointer"
                      >
                        <Badge variant={u.role === 'ADMIN' ? 'warning' : 'default'}>
                          {u.role}
                        </Badge>
                        <span className="text-[10px] text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity">
                          (Switch)
                        </span>
                      </button>
                    </td>

                    <td className="px-6 py-4">
                      <button
                        onClick={() => handleStatusToggle(u)}
                        title="Click to toggle active status"
                        className="group flex items-center gap-1.5 cursor-pointer"
                      >
                        <Badge variant={u.isActive !== false ? 'success' : 'danger'}>
                          {u.isActive !== false ? 'Active' : 'Deactivated'}
                        </Badge>
                        <span className="text-[10px] text-slate-400 opacity-0 group-hover:opacity-100 transition-opacity">
                          (Toggle)
                        </span>
                      </button>
                    </td>

                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openUserOverview(u)}
                          className="text-xs"
                          title="View healthcare records overview"
                        >
                          <Eye className="w-3.5 h-3.5 mr-1" />
                          Healthcare Records
                        </Button>

                        {currentAuthUser?.id !== u.id && currentAuthUser?.email !== u.email && (
                          <Button
                            variant="danger"
                            size="sm"
                            onClick={() => {
                              setUserToDelete(u);
                              setIsDeleteModalOpen(true);
                            }}
                            className="text-xs bg-rose-50 text-rose-700 hover:bg-rose-100 hover:text-rose-800 border border-rose-200"
                            title="Remove user"
                            aria-label={`Remove user ${u.fullName || u.email}`}
                          >
                            <Trash2 className="w-3.5 h-3.5 mr-1 text-rose-600" />
                            Remove User
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination if multiple pages */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>Page {page + 1} of {totalPages}</span>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={page === 0}
                onClick={() => setPage(p => Math.max(0, p - 1))}
              >
                <ChevronLeft className="w-4 h-4" />
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={page >= totalPages - 1}
                onClick={() => setPage(p => p + 1)}
              >
                <ChevronRight className="w-4 h-4" />
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* Create User Modal */}
      <Modal
        isOpen={isCreateModalOpen}
        onClose={() => !submitting && setIsCreateModalOpen(false)}
        title="Create New User Account"
        description="Provision a patient or admin account directly with specified role credentials."
        maxWidth="max-w-md"
      >
        <form onSubmit={handleCreateUser} className="space-y-4">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <Input
              label="First Name *"
              placeholder="e.g., Robert"
              value={createForm.firstName}
              onChange={(e) => setCreateForm({ ...createForm, firstName: e.target.value })}
              required
            />
            <Input
              label="Last Name *"
              placeholder="e.g., Vance"
              value={createForm.lastName}
              onChange={(e) => setCreateForm({ ...createForm, lastName: e.target.value })}
              required
            />
          </div>

          <Input
            label="Email Address *"
            type="email"
            placeholder="robert@example.com"
            value={createForm.email}
            onChange={(e) => setCreateForm({ ...createForm, email: e.target.value })}
            required
          />

          <Input
            label="Initial Password *"
            type={showAdminCreatePassword ? 'text' : 'password'}
            placeholder="Minimum 6 characters"
            icon={Lock}
            value={createForm.password}
            onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
            required
            rightElement={
              <button
                type="button"
                onClick={() => setShowAdminCreatePassword((prev) => !prev)}
                aria-label={showAdminCreatePassword ? 'Hide password' : 'Show password'}
                className="text-slate-400 hover:text-slate-600 focus:outline-none focus:text-indigo-600 transition-colors p-1 rounded-lg"
              >
                {showAdminCreatePassword ? (
                  <EyeOff className="h-4 w-4" />
                ) : (
                  <Eye className="h-4 w-4" />
                )}
              </button>
            }
          />

          <Select
            label="Assigned System Role *"
            value={createForm.role}
            onChange={(e) => setCreateForm({ ...createForm, role: e.target.value })}
            options={[
              { value: 'USER', label: 'Patient / Caregiver (USER)' },
              { value: 'ADMIN', label: 'System Administrator (ADMIN)' },
            ]}
          />

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={() => setIsCreateModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" loading={submitting}>
              Create Account
            </Button>
          </div>
        </form>
      </Modal>

      {/* User Healthcare Overview Modal */}
      <Modal
        isOpen={isOverviewModalOpen}
        onClose={() => setIsOverviewModalOpen(false)}
        title={`Healthcare Records: ${selectedUser?.fullName || selectedUser?.email || ''}`}
        description={`Account email: ${selectedUser?.email} • Role: ${selectedUser?.role}`}
        maxWidth="max-w-3xl"
      >
        {overviewLoading ? (
          <div className="py-12 text-center text-slate-400">
            <RefreshCw className="w-6 h-6 animate-spin mx-auto text-teal-600 mb-2" />
            <p className="text-xs">Fetching user healthcare data...</p>
          </div>
        ) : (
          <div className="space-y-6 max-h-[70vh] overflow-y-auto pr-1">
            {/* Medicines List */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Pill className="w-4 h-4 text-teal-600" />
                Active Medicines ({userOverview?.medicines?.length || 0})
              </h4>
              {userOverview?.medicines && userOverview.medicines.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {userOverview.medicines.map((m, idx) => (
                    <div key={idx} className="p-2.5 rounded-lg border border-slate-200 bg-slate-50 text-xs">
                      <div className="font-semibold text-slate-900">{m.name}</div>
                      <div className="text-slate-500">{m.dosage || 'No dosage specified'} • {m.frequency || 'Once Daily'}</div>
                      <div className="text-[11px] text-teal-700 mt-1">Stock: {m.currentQuantity ?? 'N/A'} units</div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">No medicines recorded for this user.</p>
              )}
            </div>

            {/* Appointments List */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Calendar className="w-4 h-4 text-teal-600" />
                Scheduled Visits ({userOverview?.appointments?.length || 0})
              </h4>
              {userOverview?.appointments && userOverview.appointments.length > 0 ? (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {userOverview.appointments.map((a, idx) => (
                    <div key={idx} className="p-2.5 rounded-lg border border-slate-200 bg-slate-50 text-xs">
                      <div className="font-semibold text-slate-900">{a.doctorName}</div>
                      <div className="text-slate-500">{a.hospitalClinic || 'Clinic'} • {a.appointmentDate} at {a.appointmentTime}</div>
                      {a.purpose && <div className="text-[11px] text-slate-600 mt-0.5">{a.purpose}</div>}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">No appointments recorded for this user.</p>
              )}
            </div>

            {/* Documents List */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <FileText className="w-4 h-4 text-teal-600" />
                Medical Documents ({userOverview?.documents?.length || 0})
              </h4>
              {userOverview?.documents && userOverview.documents.length > 0 ? (
                <div className="space-y-2">
                  {userOverview.documents.map((d, idx) => (
                    <div key={idx} className="p-2.5 rounded-lg border border-slate-200 bg-slate-50 text-xs flex items-center justify-between">
                      <div>
                        <div className="font-semibold text-slate-900">{d.title || d.fileName}</div>
                        <div className="text-slate-500">{d.documentType} • {d.fileName}</div>
                      </div>
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs"
                        onClick={() => handleDownloadDoc(d.id, d.fileName)}
                      >
                        <Download className="w-3 h-3 mr-1" />
                        Download
                      </Button>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">No documents uploaded for this user.</p>
              )}
            </div>

            {/* Family Members */}
            <div className="space-y-2">
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
                <Users className="w-4 h-4 text-teal-600" />
                Care Circle Members ({userOverview?.familyMembers?.length || 0})
              </h4>
              {userOverview?.familyMembers && userOverview.familyMembers.length > 0 ? (
                <div className="flex flex-wrap gap-2">
                  {userOverview.familyMembers.map((f, idx) => (
                    <span key={idx} className="px-2.5 py-1 rounded-md bg-purple-50 text-purple-700 text-xs font-medium border border-purple-200">
                      {f.name} ({f.relationship})
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400 italic">No family members registered.</p>
              )}
            </div>
          </div>
        )}

        <div className="flex justify-end pt-4 border-t border-slate-100">
          <Button variant="outline" onClick={() => setIsOverviewModalOpen(false)}>
            Close Overview
          </Button>
        </div>
      </Modal>

      {/* Delete User Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => !isDeleting && setIsDeleteModalOpen(false)}
        title="Remove User Account?"
        description="Please confirm user account removal"
        maxWidth="max-w-md"
      >
        <div className="space-y-4">
          <div className="p-3.5 bg-rose-50 border border-rose-100 rounded-xl text-rose-800 text-sm flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-rose-600 shrink-0 mt-0.5" />
            <div className="text-xs text-rose-900 leading-relaxed font-medium">
              Are you sure you want to remove this user? This action cannot be undone.
            </div>
          </div>

          <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 space-y-2 text-xs">
            <div className="flex justify-between">
              <span className="text-slate-500 font-medium">Full Name:</span>
              <span className="font-semibold text-slate-900">{userToDelete?.fullName || 'Not provided'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-500 font-medium">Email Address:</span>
              <span className="font-semibold text-slate-900">{userToDelete?.email}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-slate-500 font-medium">Current Role:</span>
              <Badge variant={userToDelete?.role === 'ADMIN' ? 'warning' : 'default'}>
                {userToDelete?.role}
              </Badge>
            </div>
          </div>

          <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
            <Button
              type="button"
              variant="outline"
              onClick={() => setIsDeleteModalOpen(false)}
              disabled={isDeleting}
            >
              Cancel
            </Button>
            <Button
              type="button"
              variant="danger"
              loading={isDeleting}
              onClick={handleDeleteUser}
              className="bg-rose-600 hover:bg-rose-700 text-white"
            >
              <Trash2 className="w-4 h-4 mr-1.5" />
              {isDeleting ? 'Deleting...' : 'Confirm Delete'}
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
