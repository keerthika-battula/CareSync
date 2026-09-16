import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Lock, Mail, User, ArrowRight, AlertCircle, Shield, Sparkles } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import { Button } from '../components/ui/Button';
import { Input } from '../components/ui/Input';
import { Card } from '../components/ui/Card';
import { Select } from '../components/ui/Select';

export default function RegisterPage() {
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: '',
    confirmPassword: '',
    role: 'USER',
  });
  const [isLoading, setIsLoading] = useState(false);
  const [statusNote, setStatusNote] = useState('');
  const [error, setError] = useState('');

  const { register } = useAuth();
  const { showToast } = useToast();
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData((prev) => ({ ...prev, [e.target.name]: e.target.value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setStatusNote('');

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    if (formData.password.length < 6) {
      setError('Password must be at least 6 characters long');
      return;
    }

    setIsLoading(true);

    const timer = setTimeout(() => {
      setStatusNote('Creating your account on CareSync servers... (Free-tier instances may take a few seconds on initial wake-up)');
    }, 2500);

    try {
      await register({
        firstName: formData.firstName.trim(),
        lastName: formData.lastName.trim(),
        email: formData.email.trim(),
        password: formData.password,
        role: formData.role,
      });
      clearTimeout(timer);
      showToast('Account created successfully! Welcome to CareSync.', 'success');
      navigate('/dashboard', { replace: true });
    } catch (err) {
      clearTimeout(timer);
      const msg = err.message || 'Failed to create account. Please try again.';
      setError(msg);
      showToast(msg, 'error');
    } finally {
      clearTimeout(timer);
      setIsLoading(false);
      setStatusNote('');
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
            Create Your Account
          </h2>
          <p className="text-sm text-slate-500">
            Join CareSync to manage your personal & family health
          </p>
        </div>

        <Card className="p-8 shadow-xl shadow-slate-100 border-slate-200/80">
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="flex items-start gap-2.5 p-3.5 rounded-xl bg-rose-50 border border-rose-100 text-rose-700 text-xs font-medium">
                <AlertCircle className="h-4 w-4 flex-shrink-0 text-rose-500 mt-0.5" />
                <span>{error}</span>
              </div>
            )}

            <div className="grid grid-cols-2 gap-3">
              <Input
                label="First Name"
                name="firstName"
                placeholder="Jane"
                icon={User}
                value={formData.firstName}
                onChange={handleChange}
                required
              />
              <Input
                label="Last Name"
                name="lastName"
                placeholder="Doe"
                value={formData.lastName}
                onChange={handleChange}
                required
              />
            </div>

            <Input
              label="Email Address"
              type="email"
              name="email"
              placeholder="jane.doe@example.com"
              icon={Mail}
              value={formData.email}
              onChange={handleChange}
              required
            />

            <Input
              label="Password"
              type="password"
              name="password"
              placeholder="Min 6 characters"
              icon={Lock}
              value={formData.password}
              onChange={handleChange}
              required
            />

            <Input
              label="Confirm Password"
              type="password"
              name="confirmPassword"
              placeholder="Confirm password"
              icon={Lock}
              value={formData.confirmPassword}
              onChange={handleChange}
              required
            />

            <Select
              label="Account Role"
              name="role"
              value={formData.role}
              onChange={handleChange}
              options={[
                { value: 'USER', label: 'Patient / Caregiver (Standard)' },
                { value: 'ADMIN', label: 'Healthcare Administrator' },
              ]}
            />

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
              Create Free Account
              <ArrowRight className="h-4 w-4 ml-1" />
            </Button>
          </form>
        </Card>

        <p className="text-center text-xs text-slate-500">
          Already have an account?{' '}
          <Link to="/login" className="font-bold text-indigo-600 hover:text-indigo-700 underline">
            Sign In
          </Link>
        </p>
      </div>
    </div>
  );
}
