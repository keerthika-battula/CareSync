import React, { useState } from 'react';
import { 
  User, Mail, Shield, Lock, KeyRound, CheckCircle2, 
  AlertCircle, LogOut, HeartPulse, Eye, EyeOff 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Badge } from '@/components/ui/Badge';
import { useAuth } from '@/context/AuthContext';
import { useToast } from '@/context/ToastContext';
import { authApi } from '@/services/api';

export default function ProfilePage() {
  const { user, logout } = useAuth();
  const { addToast } = useToast();

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
        <CardHeader>
          <CardTitle>Personal Information</CardTitle>
          <CardDescription>Your registered identity and account details on CareSync</CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-2xl bg-teal-600 text-white flex items-center justify-center font-bold text-2xl shadow-sm">
              {user?.fullName?.charAt(0) || user?.email?.charAt(0) || 'U'}
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-900">{user?.fullName || 'CareSync User'}</h2>
              <p className="text-sm text-slate-500">{user?.email}</p>
              <div className="flex items-center gap-2 mt-2">
                <Badge variant={user?.role === 'ADMIN' ? 'warning' : 'default'}>
                  {user?.role === 'ADMIN' ? 'System Administrator' : 'Patient / Caregiver'}
                </Badge>
                <Badge variant="success">Account Active</Badge>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-slate-100 text-sm">
            <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-200">
              <span className="text-xs text-slate-500 block mb-1">Full Name</span>
              <span className="font-semibold text-slate-900">{user?.fullName || 'Not provided'}</span>
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
