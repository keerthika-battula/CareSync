import React from 'react';
import { Link } from 'react-router-dom';
import {
  Heart,
  Pill,
  Calendar,
  Users,
  FileText,
  ShieldCheck,
  Clock,
  ArrowRight,
  CheckCircle2,
  Lock,
  Activity,
  Zap,
  ChevronRight
} from 'lucide-react';
import { Button } from '../components/ui/Button';

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 selection:bg-indigo-500 selection:text-white">
      {/* Top Navigation */}
      <header className="sticky top-0 z-40 w-full border-b border-slate-100 bg-white/80 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link to="/" className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-100">
              <Heart className="h-5 w-5 fill-white" />
            </div>
            <div>
              <span className="text-lg font-extrabold tracking-tight text-slate-900">Care<span className="text-indigo-600">Sync</span></span>
              <p className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Healthcare Platform</p>
            </div>
          </Link>

          <div className="flex items-center gap-3">
            <Link to="/login">
              <Button variant="ghost" size="sm">
                Sign In
              </Button>
            </Link>
            <Link to="/register">
              <Button variant="primary" size="sm">
                Get Started
                <ArrowRight className="h-4 w-4 ml-1" />
              </Button>
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-12 pb-20 lg:pt-20 lg:pb-32">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto space-y-6">
            <div className="inline-flex items-center gap-2 rounded-full border border-indigo-200 bg-indigo-50/80 px-3.5 py-1 text-xs font-semibold text-indigo-700">
              <ShieldCheck className="h-3.5 w-3.5" />
              <span>Secure Web-Based Healthcare Management</span>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 leading-[1.15]">
              Your Medication, Care Circle & Health Records. <br className="hidden sm:inline" />
              <span className="bg-gradient-to-r from-indigo-600 via-indigo-700 to-blue-600 bg-clip-text text-transparent">
                All In Sync. On Time.
              </span>
            </h1>

            <p className="text-lg text-slate-600 leading-relaxed">
              CareSync is a secure, cloud-enabled web platform designed to streamline prescription management, daily dose adherence, doctor appointments, and family healthcare tracking from any modern browser.
            </p>

            <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-4">
              <Link to="/register" className="w-full sm:w-auto">
                <Button size="lg" className="w-full sm:w-auto text-base">
                  Start Managing Health Free
                  <ArrowRight className="h-4 w-4 ml-1.5" />
                </Button>
              </Link>
              <Link to="/login" className="w-full sm:w-auto">
                <Button variant="secondary" size="lg" className="w-full sm:w-auto text-base">
                  Sign In to Your Account
                </Button>
              </Link>
            </div>

            <div className="pt-8 flex items-center justify-center gap-8 text-xs font-semibold text-slate-500">
              <div className="flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                <span>100% Web-Based</span>
              </div>
              <div className="flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                <span>Enterprise Spring Boot Backend</span>
              </div>
              <div className="flex items-center gap-1.5">
                <CheckCircle2 className="h-4 w-4 text-emerald-500" />
                <span>Role-Based Access Control</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Feature Grid */}
      <section className="bg-white py-20 border-y border-slate-100">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16 space-y-3">
            <h2 className="text-xs font-bold uppercase tracking-widest text-indigo-600">
              Complete Healthcare Suite
            </h2>
            <h3 className="text-3xl font-extrabold text-slate-900 tracking-tight">
              Everything You Need to Manage Daily Care
            </h3>
            <p className="text-slate-600 text-sm">
              Integrated modules built on top of robust REST APIs ensuring seamless clinical data management.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Feature 1 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-100 group-hover:scale-105 transition-transform mb-5">
                <Pill className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Smart Prescription Tracking</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Log active medications, custom dosages, multi-time schedules, and track inventory with automatic low-stock alerts.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-600 text-white shadow-md shadow-emerald-100 group-hover:scale-105 transition-transform mb-5">
                <Clock className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Daily Dose Logging & Actions</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Mark doses as Taken, Skipped, or Snoozed in real time. Maintain a complete adherence timeline with accurate audit timestamps.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-sky-600 text-white shadow-md shadow-sky-100 group-hover:scale-105 transition-transform mb-5">
                <Calendar className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Doctor Visits & Appointments</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Schedule clinical consultations, lab tests, and follow-ups. Keep location and doctor notes organized for the entire care circle.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-purple-600 text-white shadow-md shadow-purple-100 group-hover:scale-105 transition-transform mb-5">
                <Users className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Care Circle & Family Profiles</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Manage dependents, children, and elderly parents under a unified profile with customized relationships, blood groups, and notes.
              </p>
            </div>

            {/* Feature 5 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-600 text-white shadow-md shadow-teal-100 group-hover:scale-105 transition-transform mb-5">
                <FileText className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Secure Health Records</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Upload prescriptions, lab reports, discharge summaries, and medical invoices. Direct streaming downloads with S3/MinIO backend.
              </p>
            </div>

            {/* Feature 6 */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-7 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group">
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-amber-600 text-white shadow-md shadow-amber-100 group-hover:scale-105 transition-transform mb-5">
                <Lock className="h-6 w-6" />
              </div>
              <h4 className="text-lg font-bold text-slate-900 mb-2">Enterprise Security & RBAC</h4>
              <p className="text-sm text-slate-600 leading-relaxed">
                Stateless JWT authentication with BCrypt hashing, strict tenant data isolation, and comprehensive Admin oversight controls.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Footer */}
      <footer className="bg-slate-900 text-white py-14">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 border-b border-slate-800 pb-8">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-600 text-white">
                <Heart className="h-5 w-5 fill-white" />
              </div>
              <div>
                <span className="text-lg font-extrabold text-white">CareSync</span>
                <p className="text-xs text-slate-400">Web Healthcare Platform</p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              <Link to="/login" className="text-sm text-slate-300 hover:text-white transition-colors">
                Sign In
              </Link>
              <Link to="/register" className="text-sm text-indigo-400 hover:text-indigo-300 font-semibold transition-colors">
                Create Account
              </Link>
            </div>
          </div>

          <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
            <p>© 2026 CareSync Healthcare Platform. All rights reserved.</p>
            <p>Built with React.js, Tailwind CSS, and Spring Boot.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
