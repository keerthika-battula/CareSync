import React, { useState, useEffect } from 'react';
import { 
  User, Mail, Shield, Lock, KeyRound, CheckCircle2, 
  AlertCircle, LogOut, HeartPulse, Eye, EyeOff, Pencil, X
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { authApi } from '@/services/api';

export default function ProfilePage() {
  const { user, logout, updateUser } = useAuth();
  const { addToast } = useToast();

  // Personal Details Edit State
  const [isEditingProfile, setIsEditingProfile] = useState(false);
  const [profileForm, setProfileForm] = useState({
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
  });
  const [submittingProfile, setSubmittingProfile] = useState(false);

  useEffect(() => {
    if (user) {
      setProfileForm({
        firstName: user.firstName || (user.fullName ? user.fullName.split(' ')[0] : ''),
        lastName: user.lastName || (user.fullName ? user.fullName.split(' ').slice(1).join(' ') : ''),
      });
    }
  }, [user]);

  const handleProfileSubmit = async (e) => {
    e.preventDefault();
    const firstName = profileForm.firstName.trim();
    const lastName = profileForm.lastName.trim();

    if (!firstName) {
      addToast('First name is required', 'warning');
      return;
    }
    if (!lastName) {
      addToast('Last name is required', 'warning');
      return;
    }

    try {
      setSubmittingProfile(true);
      const res = await authApi.updateProfile({ firstName, lastName });
      const updatedData = res?.data || res;
      updateUser(updatedData || { firstName, lastName });
      addToast('Personal details updated successfully!', 'success');
      setIsEditingProfile(false);
    } catch (err) {
      addToast(err.message || 'Failed to update personal details', 'error');
    } finally {
      setSubmittingProfile(false);
    }
  };

  const [passwordForm, setPasswordForm] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [submittingPassword, setSubmittingPassword] = useState(false);

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    if (!passwordForm.currentPassword) {
      addToast('Please enter your current password', 'warning');
      return;
    }
    if (passwordForm.newPassword !== passwordForm.confirmPassword) {
      addToast('New password and confirm password do not match', 'error');
      return;
    }
    if (passwordForm.newPassword.length < 6) {
      addToast('Password must be at least 6 characters', 'error');
      return;
    }

    try {
      setSubmittingPassword(true);
      await authApi.changePassword({
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword,
        confirmPassword: passwordForm.confirmPassword,
      });
      addToast('Password updated successfully! Please use your new password next time you sign in.', 'success');
      setPasswordForm({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (err) {
      addToast(err.message || 'Failed to update password', 'error');
    } finally {
      setSubmittingPassword(false);
    }
  };

  return (
    <div className="max-w-4xl space-y-6">
      {/* Top Header */}
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Account & Profile</h1>
        <p className="text-sm text-slate-500 mt-1">
          Manage your personal information, role permissions, and security settings
        </p>
      </div>

      {/* Profile Overview Card */}
      <Card>
        <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pb-4">
          <div>
            <CardTitle>Personal Information</CardTitle>
            <CardDescription>Your registered identity and account details on CareSync</CardDescription>
          </div>
          {!isEditingProfile && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setProfileForm({
                  firstName: user?.firstName || (user?.fullName ? user.fullName.split(' ')[0] : ''),
                  lastName: user?.lastName || (user?.fullName ? user.fullName.split(' ').slice(1).join(' ') : ''),
                });
                setIsEditingProfile(true);
              }}
              className="border-slate-200 hover:bg-slate-50 text-slate-700 font-medium"
            >
              <Pencil className="w-3.5 h-3.5 mr-1.5 text-teal-600" />
              Edit Personal Details
            </Button>
          )}
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-teal-600 text-white flex items-center justify-center font-bold text-2xl shadow-sm">
              {user?.fullName?.charAt(0) || user?.firstName?.charAt(0) || user?.email?.charAt(0) || 'U'}
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-900">
                {user?.fullName || [user?.firstName, user?.lastName].filter(Boolean).join(' ') || 'CareSync User'}
              </h2>
              <p className="text-sm text-slate-500">{user?.email}</p>
              <div className="flex items-center gap-2 mt-2">
                <Badge variant={user?.role === 'ADMIN' ? 'warning' : 'default'}>
                  {user?.role === 'ADMIN' ? 'System Administrator' : 'Patient / Caregiver'}
                </Badge>
                <Badge variant="success">Account Active</Badge>
              </div>
            </div>
          </div>

          {isEditingProfile ? (
            <form onSubmit={handleProfileSubmit} className="space-y-4 pt-4 border-t border-slate-100">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Input
                  label="First Name *"
                  type="text"
                  placeholder="e.g. Jane"
                  value={profileForm.firstName}
                  onChange={(e) => setProfileForm({ ...profileForm, firstName: e.target.value })}
                  required
                />
                <Input
                  label="Last Name *"
                  type="text"
                  placeholder="e.g. Doe"
                  value={profileForm.lastName}
                  onChange={(e) => setProfileForm({ ...profileForm, lastName: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-600 uppercase tracking-wider mb-1.5">
                  Email Address
                </label>
                <input
                  type="email"
                  value={user?.email || ''}
                  disabled
                  className="w-full px-3.5 py-2.5 bg-slate-100 border border-slate-200 rounded-lg text-sm text-slate-500 cursor-not-allowed font-medium"
                />
                <p className="text-xs text-slate-400 mt-1">Email address is permanently tied to your account login and cannot be modified.</p>
              </div>

              <div className="flex items-center gap-3 pt-2">
                <Button type="submit" loading={submittingProfile}>
                  <CheckCircle2 className="w-4 h-4 mr-1.5" />
                  Save Changes
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  disabled={submittingProfile}
                  onClick={() => setIsEditingProfile(false)}
                >
                  <X className="w-4 h-4 mr-1.5" />
                  Cancel
                </Button>
              </div>
            </form>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-slate-100 text-sm">
              <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block mb-1">Full Name</span>
                <span className="font-semibold text-slate-900">
                  {user?.fullName || [user?.firstName, user?.lastName].filter(Boolean).join(' ') || 'Not provided'}
                </span>
              </div>

              <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block mb-1">Email Address</span>
                <span className="font-semibold text-slate-900">{user?.email}</span>
              </div>

              <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block mb-1">Access Role</span>
                <span className="font-semibold text-slate-900">{user?.role || 'USER'}</span>
              </div>

              <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-200">
                <span className="text-xs text-slate-500 block mb-1">Account ID</span>
                <span className="font-mono text-xs text-slate-700">{user?.id || 'Active Session'}</span>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Security & Password Card */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-2">
            <Shield className="w-5 h-5 text-teal-600" />
            <CardTitle>Security & Password</CardTitle>
          </div>
          <CardDescription>Update your login credentials and enhance your account protection</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handlePasswordChange} className="space-y-4 max-w-md">
            <Input
              label="Current Password"
              type={showCurrentPassword ? 'text' : 'password'}
              placeholder="••••••••"
              icon={Lock}
              value={passwordForm.currentPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, currentPassword: e.target.value })}
              required
              rightElement={
                <button
                  type="button"
                  onClick={() => setShowCurrentPassword((prev) => !prev)}
                  aria-label={showCurrentPassword ? 'Hide current password' : 'Show current password'}
                  className="text-slate-400 hover:text-slate-600 focus:outline-none focus:text-indigo-600 transition-colors p-1 rounded-lg"
                >
                  {showCurrentPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              }
            />

            <Input
              label="New Password"
              type={showNewPassword ? 'text' : 'password'}
              placeholder="At least 6 characters"
              icon={Lock}
              value={passwordForm.newPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, newPassword: e.target.value })}
              required
              rightElement={
                <button
                  type="button"
                  onClick={() => setShowNewPassword((prev) => !prev)}
                  aria-label={showNewPassword ? 'Hide new password' : 'Show new password'}
                  className="text-slate-400 hover:text-slate-600 focus:outline-none focus:text-indigo-600 transition-colors p-1 rounded-lg"
                >
                  {showNewPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              }
            />

            <Input
              label="Confirm New Password"
              type={showConfirmPassword ? 'text' : 'password'}
              placeholder="Repeat new password"
              icon={Lock}
              value={passwordForm.confirmPassword}
              onChange={(e) => setPasswordForm({ ...passwordForm, confirmPassword: e.target.value })}
              required
              rightElement={
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword((prev) => !prev)}
                  aria-label={showConfirmPassword ? 'Hide confirm password' : 'Show confirm password'}
                  className="text-slate-400 hover:text-slate-600 focus:outline-none focus:text-indigo-600 transition-colors p-1 rounded-lg"
                >
                  {showConfirmPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              }
            />

            <div className="pt-2">
              <Button type="submit" loading={submittingPassword}>
                <KeyRound className="w-4 h-4 mr-2" />
                Update Password
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      {/* Danger Zone / Logout */}
      <Card className="border-rose-200">
        <CardHeader>
          <CardTitle className="text-rose-600">Session Management</CardTitle>
          <CardDescription>Sign out of your active browser session</CardDescription>
        </CardHeader>
        <CardContent className="flex items-center justify-between">
          <p className="text-xs text-slate-500">
            Sign out to terminate your current JWT authentication token on this device.
          </p>
          <Button variant="danger" size="sm" onClick={logout}>
            <LogOut className="w-4 h-4 mr-1.5" />
            Sign Out
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}
