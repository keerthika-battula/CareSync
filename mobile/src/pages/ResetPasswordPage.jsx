import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Lock, Key, Mail, ArrowRight, ArrowLeft, CheckCircle2, AlertCircle } from 'lucide-react';
import { authApi } from '../services/api';
import { useToast } from '../context/ToastContext';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Card } from '../components/ui/Card';

export default function ResetPasswordPage() {
  const [searchParams] = useSearchParams();
  const [email, setEmail] = useState('');
  const [token, setToken] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [error, setError] = useState('');

  const { showToast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    const qEmail = searchParams.get('email');
    const qToken = searchParams.get('token');
    if (qEmail) setEmail(qEmail);
    if (qToken) setToken(qToken);
  }, [searchParams]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!email.trim() || !token.trim() || !newPassword) {
      setError('Please fill in all fields');
      return;
    }

    if (newPassword !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    if (newPassword.length < 8) {
      setError('New password must be at least 8 characters long');
      return;
    }

    setIsLoading(true);
    try {
      await authApi.resetPassword({
        email: email.trim(),
        token: token.trim(),
        newPassword,
      });
      setIsSuccess(true);
      showToast('Password reset successfully! You can now log in.', 'success');
    } catch (err) {
      setError(err.message || 'Failed to reset password. Please verify the code.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 px-4 py-12">
      <div className="max-w-md w-full space-y-6">
        <div className="text-center space-y-3">
          <Link to="/" className="inline-block group transition-transform hover:scale-105">
            <img
              src="/caresync-logo-full-transparent.png"
              alt="CareSync — Your Care. In Sync. On Time."
              className="h-28 w-auto mx-auto object-contain drop-shadow-sm"
            />
          </Link>
          <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Create New Password
          </h2>
          <p className="text-sm text-slate-500">
            Enter your reset code and set a new secure password
          </p>
        </div>

        <Card className="p-8 shadow-xl shadow-slate-100 border-slate-200/80">
          {isSuccess ? (
            <div className="text-center space-y-4 py-2">
              <div className="flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100 text-emerald-600 mx-auto">
                <CheckCircle2 className="h-6 w-6" />
              </div>
              <h3 className="text-base font-bold text-slate-900">Password Changed</h3>
              <p className="text-xs text-slate-600 leading-relaxed">
                Your password has been successfully updated. Please sign in with your new credentials.
              </p>
              <div className="pt-2">
                <Link to="/login">
                  <Button size="md" className="w-full font-semibold">
                    Sign In Now
                    <ArrowRight className="h-4 w-4 ml-1" />
                  </Button>
                </Link>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              {error && (
                <div className="flex items-start gap-2.5 p-3.5 rounded-xl bg-rose-50 border border-rose-100 text-rose-700 text-xs font-medium">
                  <AlertCircle className="h-4 w-4 flex-shrink-0 text-rose-500 mt-0.5" />
                  <span>{error}</span>
                </div>
              )}

              <Input
                label="Email Address"
                type="email"
                placeholder="name@example.com"
                icon={Mail}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />

              <Input
                label="Reset Code / Token"
                placeholder="Enter reset code"
                icon={Key}
                value={token}
                onChange={(e) => setToken(e.target.value)}
                required
              />

              <Input
                label="New Password"
                type="password"
                placeholder="Min 8 characters"
                icon={Lock}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                required
              />

              <Input
                label="Confirm New Password"
                type="password"
                placeholder="Confirm new password"
                icon={Lock}
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                required
              />

              <Button
                type="submit"
                size="lg"
                isLoading={isLoading}
                className="w-full mt-2 font-bold"
              >
                Reset Password
                <ArrowRight className="h-4 w-4 ml-1" />
              </Button>
            </form>
          )}

          <div className="mt-6 pt-6 border-t border-slate-100 text-center">
            <Link
              to="/login"
              className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-600 hover:text-slate-900 transition-colors"
            >
              <ArrowLeft className="h-3.5 w-3.5" />
              <span>Back to Sign In</span>
            </Link>
          </div>
        </Card>
      </div>
    </div>
  );
}
