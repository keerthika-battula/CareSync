import React from 'react';
import { Link } from 'react-router-dom';
import {
  Pill,
  Calendar,
  Users,
  FileText,
  ShieldCheck,
  Clock,
  ArrowRight,
  Lock,
  Activity,
  AlertTriangle,
  Sparkles,
  Check,
  Bell,
  ChevronRight,
  TrendingUp,
  Shield
} from 'lucide-react';
import { Button } from '../components/ui/Button';

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 selection:bg-indigo-500 selection:text-white">
      {/* Top Navigation */}
      <header className="sticky top-0 z-40 w-full border-b border-slate-100 bg-white/90 backdrop-blur-md">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8">
          <Link to="/" className="flex items-center gap-3 group">
            <img
              src="/caresync-logo-icon.png"
              alt="CareSync Logo"
              className="h-10 w-auto object-contain flex-shrink-0 group-hover:scale-105 transition-transform"
            />
            <div>
              <span className="text-lg font-extrabold tracking-tight text-slate-900 leading-tight block">
                Care<span className="text-indigo-600">Sync</span>
              </span>
              <p className="text-[10px] uppercase font-bold tracking-wider text-slate-400">
                Healthcare Platform
              </p>
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

      {/* Hero Section - 2 Column Grid */}
      <section className="relative overflow-hidden pt-8 pb-16 lg:pt-14 lg:pb-24">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 lg:gap-12 items-center">
            {/* Left Hero Column */}
            <div className="lg:col-span-7 space-y-6 text-left">
              <div className="inline-flex items-center gap-2 rounded-full border border-indigo-200 bg-indigo-50/90 px-3.5 py-1 text-xs font-semibold text-indigo-700">
                <ShieldCheck className="h-3.5 w-3.5" />
                <span>Clinical-Grade Web Healthcare Platform</span>
              </div>

              <h1 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold tracking-tight text-slate-900 leading-[1.18]">
                Your Medication, Care Circle & Health Records.{' '}
                <span className="block mt-1 bg-gradient-to-r from-indigo-600 via-indigo-700 to-teal-600 bg-clip-text text-transparent">
                  All In Sync. On Time.
                </span>
              </h1>

              <p className="text-base sm:text-lg text-slate-600 leading-relaxed max-w-2xl">
                CareSync is a secure, cloud-enabled web platform designed to streamline prescription management, daily dose adherence, doctor appointments, and family healthcare tracking from any modern browser.
              </p>

              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                <Link to="/register" className="w-full sm:w-auto">
                  <Button size="lg" className="w-full sm:w-auto text-base font-bold shadow-lg shadow-indigo-100">
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
            </div>

            {/* Right Hero Column: Interactive Patient Hub Live Preview */}
            <div className="lg:col-span-5">
              <div className="relative rounded-2xl border border-slate-200/90 bg-white p-5 sm:p-6 shadow-2xl shadow-slate-200/80">
                {/* Visual Header */}
                <div className="flex items-center justify-between border-b border-slate-100 pb-4 mb-4">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-full bg-indigo-100 border border-indigo-200 flex items-center justify-center text-indigo-700 font-bold text-sm">
                      EV
                    </div>
                    <div>
                      <h3 className="text-sm font-bold text-slate-900 leading-tight">Eleanor Vance</h3>
                      <p className="text-[11px] text-slate-400 font-medium">CareSync Patient • ID #CS-8921</p>
                    </div>
                  </div>
                  <div className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 border border-emerald-200 px-2.5 py-0.5 text-[11px] font-bold text-emerald-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-ping" />
                    <span>Active Schedule</span>
                  </div>
                </div>

                {/* Dashboard Items */}
                <div className="space-y-3">
                  {/* Card 1: Next Dose */}
                  <div className="rounded-xl border border-indigo-100 bg-indigo-50/40 p-3.5 transition-all">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-lg bg-indigo-600 text-white flex items-center justify-center shadow-sm">
                          <Pill className="h-4 w-4" />
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="text-xs font-bold text-slate-900">Atorvastatin 20mg</h4>
                            <span className="rounded bg-indigo-100 px-1.5 py-0.5 text-[10px] font-semibold text-indigo-700">
                              Due 8:00 PM
                            </span>
                          </div>
                          <p className="text-[11px] text-slate-500">Daily with dinner • 1 tablet</p>
                        </div>
                      </div>
                      <span className="inline-flex items-center gap-1 rounded-md bg-indigo-600 px-2.5 py-1 text-[11px] font-bold text-white shadow-sm">
                        <Check className="h-3 w-3" />
                        Take
                      </span>
                    </div>
                  </div>

                  {/* Card 2: Refill Alert */}
                  <div className="rounded-xl border border-amber-200/80 bg-amber-50/50 p-3.5">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div className="flex items-center gap-2">
                        <AlertTriangle className="h-4 w-4 text-amber-600 flex-shrink-0" />
                        <span className="text-xs font-bold text-amber-900">Metformin 500mg</span>
                      </div>
                      <span className="text-[10px] font-bold uppercase tracking-wider text-amber-700 bg-amber-100 px-1.5 py-0.5 rounded">
                        5 Doses Left
                      </span>
                    </div>
                    <div className="w-full bg-amber-100/80 rounded-full h-1.5 mb-1.5 overflow-hidden">
                      <div className="bg-amber-500 h-1.5 rounded-full w-[18%]" />
                    </div>
                    <p className="text-[11px] text-amber-800">
                      Low stock threshold reached. Refill suggested before Friday.
                    </p>
                  </div>

                  {/* Card 3: Upcoming Doctor Appointment */}
                  <div className="rounded-xl border border-sky-100 bg-sky-50/40 p-3.5">
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-lg bg-sky-600 text-white flex items-center justify-center shadow-sm">
                          <Calendar className="h-4 w-4" />
                        </div>
                        <div>
                          <h4 className="text-xs font-bold text-slate-900">Dr. Sarah Jenkins</h4>
                          <p className="text-[11px] text-slate-500">Cardiology Consultation • Tomorrow, 10:30 AM</p>
                        </div>
                      </div>
                      <span className="text-[10px] font-bold text-sky-700 bg-sky-100 px-2 py-0.5 rounded-full">
                        Confirmed
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 4-Module Healthcare Feature Grid */}
      <section className="bg-white py-16 lg:py-20 border-y border-slate-100">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-14 space-y-3">
            <h2 className="text-xs font-bold uppercase tracking-widest text-indigo-600">
              Core Platform Capabilities
            </h2>
            <h3 className="text-3xl font-extrabold text-slate-900 tracking-tight">
              Everything You Need to Manage Daily Healthcare
            </h3>
            <p className="text-slate-600 text-sm sm:text-base">
              Unified healthcare tools providing seamless clinical precision, patient compliance, and family health management.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Feature 1: Medication Tracking */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-6 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group flex flex-col justify-between">
              <div>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-100 group-hover:scale-105 transition-transform mb-5">
                  <Pill className="h-6 w-6" />
                </div>
                <h4 className="text-base font-bold text-slate-900 mb-2">Medication Tracking</h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Log active prescriptions, multi-time schedules (Daily, Twice Daily, Weekly), dosage instructions, and real-time adherence logging.
                </p>
              </div>
              <div className="pt-4 mt-4 border-t border-slate-100/80 flex items-center text-xs font-semibold text-indigo-600">
                <span>Dose logging & refill alerts</span>
              </div>
            </div>

            {/* Feature 2: Doctor Appointments */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-6 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group flex flex-col justify-between">
              <div>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-sky-600 text-white shadow-md shadow-sky-100 group-hover:scale-105 transition-transform mb-5">
                  <Calendar className="h-6 w-6" />
                </div>
                <h4 className="text-base font-bold text-slate-900 mb-2">Doctor Appointments</h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Schedule clinical consultations, lab tests, and hospital visits. Keep clinic locations, time slots, and doctor notes organized.
                </p>
              </div>
              <div className="pt-4 mt-4 border-t border-slate-100/80 flex items-center text-xs font-semibold text-sky-600">
                <span>Visit timelines & status</span>
              </div>
            </div>

            {/* Feature 3: Family Care Circle */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-6 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group flex flex-col justify-between">
              <div>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-purple-600 text-white shadow-md shadow-purple-100 group-hover:scale-105 transition-transform mb-5">
                  <Users className="h-6 w-6" />
                </div>
                <h4 className="text-base font-bold text-slate-900 mb-2">Family Care Circle</h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Manage dependents, children, and elderly parents under a unified profile with customizable relationships, blood groups, and emergency notes.
                </p>
              </div>
              <div className="pt-4 mt-4 border-t border-slate-100/80 flex items-center text-xs font-semibold text-purple-600">
                <span>Multi-profile support</span>
              </div>
            </div>

            {/* Feature 4: Health Records Vault */}
            <div className="rounded-2xl border border-slate-100 bg-slate-50/50 p-6 hover:bg-slate-50 hover:shadow-lg transition-all duration-200 group flex flex-col justify-between">
              <div>
                <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-teal-600 text-white shadow-md shadow-teal-100 group-hover:scale-105 transition-transform mb-5">
                  <FileText className="h-6 w-6" />
                </div>
                <h4 className="text-base font-bold text-slate-900 mb-2">Health Records Vault</h4>
                <p className="text-xs text-slate-600 leading-relaxed">
                  Securely store prescriptions, lab reports, discharge summaries, and medical bills with encrypted storage and direct browser downloads.
                </p>
              </div>
              <div className="pt-4 mt-4 border-t border-slate-100/80 flex items-center text-xs font-semibold text-teal-600">
                <span>Encrypted medical storage</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Security & Infrastructure Highlights */}
      <section className="bg-slate-50 py-16">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="rounded-3xl border border-slate-200/80 bg-gradient-to-br from-white via-indigo-50/30 to-slate-50 p-8 lg:p-12 shadow-sm">
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-center">
              <div className="lg:col-span-2 space-y-4">
                <div className="inline-flex items-center gap-2 rounded-lg bg-indigo-100 px-3 py-1 text-xs font-bold text-indigo-800">
                  <Shield className="h-3.5 w-3.5" />
                  Enterprise Data Architecture
                </div>
                <h3 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                  Engineered with High-Security Healthcare Standards
                </h3>
                <p className="text-sm text-slate-600 leading-relaxed">
                  CareSync separates user roles with granular RBAC permissions. All clinical records, dosages, and patient details are protected through BCrypt password hashing, stateless JWT session tokens, and strict tenant-level database isolation.
                </p>
              </div>
              <div className="flex flex-col sm:flex-row lg:flex-col gap-3">
                <Link to="/register" className="w-full">
                  <Button size="lg" className="w-full font-bold">
                    Create Free Account
                    <ArrowRight className="h-4 w-4 ml-1.5" />
                  </Button>
                </Link>
                <Link to="/login" className="w-full">
                  <Button variant="secondary" size="lg" className="w-full">
                    Sign In to Your Account
                  </Button>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Footer */}
      <footer className="bg-slate-900 text-white py-12">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 border-b border-slate-800 pb-8">
            <div className="flex items-center gap-3">
              <img
                src="/caresync-logo-icon.png"
                alt="CareSync Logo"
                className="h-10 w-10 object-contain"
              />
              <div>
                <span className="text-lg font-extrabold text-white">CareSync</span>
                <p className="text-xs text-slate-400">Your Care. In Sync. On Time.</p>
              </div>
            </div>

            <div className="flex items-center gap-6">
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
            <div className="flex items-center gap-3 text-xs text-slate-400">
              <span className="hover:text-slate-300 transition-colors cursor-pointer">Privacy Policy</span>
              <span className="text-slate-700">|</span>
              <span className="hover:text-slate-300 transition-colors cursor-pointer">Terms of Service</span>
              <span className="text-slate-700">|</span>
              <span className="hover:text-slate-300 transition-colors cursor-pointer">Contact</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

