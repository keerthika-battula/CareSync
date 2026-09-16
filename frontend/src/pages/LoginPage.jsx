import React, { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { Lock, Mail, ArrowRight, AlertCircle, Sparkles, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Card } from '../components/ui/Card';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [statusNote, setStatusNote] = useState('');
  const [error, setError] = useState('');

  const { login } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();
  const location = useLocation();

  const from = location.state?.from?.pathname || '/dashboard';

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setStatusNote('');

    if (!email.trim() || !password) {
      setError('Please enter both your email address and password');
      return;
    }

    setIsLoading(true);

    // If backend takes more than 2.5s (e.g. Render cold start), display friendly note
    const timer = setTimeout(() => {
      setStatusNote('Connecting to secure CareSync servers... (Free-tier instances may take a few seconds on initial wake-up)');
    }, 2500);

    try {
      await login(email.trim(), password, remember);
      clearTimeout(timer);
      showToast('Welcome back to CareSync!', 'success');
      navigate(from, { replace: true });
    } catch (err) {
      clearTimeout(timer);
      const msg = err.message || 'Invalid email/username or password.';
      setError(msg);
    } finally {
      clearTimeout(timer);
      setIsLoading(false);
      setStatusNote('');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 px-4 py-12">
      <div className="max-w-md w-full space-y-6">
        {/* Brand Header */}
        <div className="text-center space-y-3">
          <Link to="/" className="inline-block group transition-transform hover:scale-105">
            <img
              src="/caresync-logo-full-transparent.png"
              alt="CareSync — Your Care. In Sync. On Time."
              className="h-28 w-auto mx-auto object-contain drop-shadow-sm"
            />
          </Link>
          <h2 className="text-2xl font-extrabold text-slate-900 tracking-tight">
            Sign In to Your Account
          </h2>
          <p className="text-sm text-slate-500">
            Sign in to manage medications, visits, and family health records
          </p>
        </div>

        {/* Login Card */}
        <Card className="p-8 shadow-xl shadow-slate-100 border-slate-200/80">
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
              autoFocus
              autoComplete="email"
            />

            <div className="space-y-1">
              <Input
                label="Password"
                type={showPassword ? 'text' : 'password'}
                name="password"
                autoComplete="current-password"
                placeholder="••••••••"
                icon={Lock}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                rightElement={
                  <button
                    type="button"
                    onClick={() => setShowPassword((prev) => !prev)}
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    className="text-slate-400 hover:text-slate-600 focus:outline-none focus:text-indigo-600 transition-colors p-1 rounded-lg"
                  >
                    {showPassword ? (
                      <EyeOff className="h-4 w-4" />
                    ) : (
                      <Eye className="h-4 w-4" />
                    )}
                  </button>
                }
              />
              <div className="flex justify-end pt-1">
                <Link
                  to="/forgot-password"
                  className="text-xs font-semibold text-indigo-600 hover:text-indigo-700 transition-colors"
                >
                  Forgot password?
                </Link>
              </div>
            </div>

            <div className="flex items-center gap-2 pt-1">
              <input
                id="remember-me"
                type="checkbox"
                checked={remember}
                onChange={(e) => setRemember(e.target.checked)}
                className="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
              />
              <label htmlFor="remember-me" className="text-xs font-medium text-slate-600 select-none">
                Remember this device
              </label>
            </div>

            {statusNote && (
              <div className="flex items-center gap-2 p-3 rounded-xl bg-indigo-50 border border-indigo-100 text-indigo-700 text-xs animate-pulse">
                <Sparkles className="h-4 w-4 flex-shrink-0 text-indigo-500" />
                <span>{statusNote}</span>
              </div>
            )}

            <Button
              type="submit"
              size="lg"
              isLoading={isLoading}
              className="w-full mt-2 font-bold"
            >
              Sign In to CareSync
              <ArrowRight className="h-4 w-4 ml-1" />
            </Button>
          </form>
        </Card>

        {/* Register Link */}
        <p className="text-center text-xs text-slate-500">
          Don't have an account?{' '}
          <Link to="/register" className="font-bold text-indigo-600 hover:text-indigo-700 underline">
            Create an account
          </Link>
        </p>
      </div>
    </div>
  );
}
