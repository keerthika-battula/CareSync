import React, { useState } from 'react';
import { Modal } from '../ui/Modal';
import { Button } from '../ui/Button';
import { 
  ShieldCheck, FileText, Mail, Phone, MapPin, 
  Check, Copy, ExternalLink, AlertCircle, HeartPulse, Clock, Sparkles
} from 'lucide-react';

export function FooterModal({ type, isOpen, onClose }) {
  const [copiedEmail, setCopiedEmail] = useState(false);

  const handleCopyEmail = async (email) => {
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(email);
      } else {
        const ta = document.createElement('textarea');
        ta.value = email;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.focus();
        ta.select();
        document.execCommand('copy');
        document.body.removeChild(ta);
      }
      setCopiedEmail(true);
      setTimeout(() => setCopiedEmail(false), 2000);
    } catch (err) {
      console.error('Failed to copy email:', err);
    }
  };

  if (!isOpen || !type) return null;

  if (type === 'privacy') {
    return (
      <Modal
        isOpen={isOpen}
        onClose={onClose}
        maxWidth="max-w-2xl"
        title={
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-indigo-50 text-indigo-600">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <span className="text-lg font-bold text-slate-900">Privacy Policy</span>
              <p className="text-xs text-slate-500 font-normal">Last updated: September 2026</p>
            </div>
          </div>
        }
        footer={
          <Button variant="primary" size="sm" onClick={onClose} className="px-5">
            Understood & Close
          </Button>
        }
      >
        <div className="space-y-4 text-slate-700 text-sm leading-relaxed">
          <div className="p-3.5 rounded-xl bg-indigo-50/70 border border-indigo-100 text-xs text-indigo-900 flex items-start gap-2.5">
            <HeartPulse className="w-4 h-4 text-indigo-600 flex-shrink-0 mt-0.5" />
            <span>
              <strong>Your health privacy is our highest priority.</strong> CareSync is built with strict privacy-by-design principles to ensure your medical logs and records remain confidential and secure.
            </span>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">1. Information We Collect</h4>
            <p className="text-xs text-slate-600">
              We collect information you provide directly to provide healthcare management services, including:
            </p>
            <ul className="list-disc pl-5 mt-1.5 space-y-1 text-xs text-slate-600">
              <li><strong>Account Information:</strong> Name, email address, password hash (encrypted with BCrypt).</li>
              <li><strong>Medication & Health Data:</strong> Medicine names, dosages, schedules, intake logs, prescriptions, and health notes.</li>
              <li><strong>Caregiver & Family Contacts:</strong> Details of linked dependents or family members you choose to manage.</li>
              <li><strong>Uploaded Medical Documents:</strong> Lab reports, doctor summaries, and PDF/image records uploaded to your vault.</li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">2. How We Protect & Use Your Data</h4>
            <ul className="list-disc pl-5 space-y-1 text-xs text-slate-600">
              <li>Your data is used solely to provide medication reminders, dose tracking, and health organization.</li>
              <li><strong>Zero Advertising / Telemetry:</strong> We never sell, rent, monetize, or share your personal or health data with third-party advertisers or data brokers.</li>
              <li>Access is strictly restricted to your authenticated user account via secure JSON Web Tokens (JWT).</li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">3. Data Security & Storage</h4>
            <p className="text-xs text-slate-600">
              We employ enterprise-grade security controls including TLS 1.3 encryption in transit, isolated relational databases with transactional integrity, and service worker policies that strictly prevent unauthorized caching of sensitive medical endpoints.
            </p>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">4. Your Data Rights & Deletion</h4>
            <p className="text-xs text-slate-600">
              You maintain 100% ownership of your health records. You may review, edit, export, or permanently delete your medication logs, uploaded documents, or complete account at any time directly through your profile settings or by contacting our team.
            </p>
          </div>
        </div>
      </Modal>
    );
  }

  if (type === 'terms') {
    return (
      <Modal
        isOpen={isOpen}
        onClose={onClose}
        maxWidth="max-w-2xl"
        title={
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-indigo-50 text-indigo-600">
              <FileText className="w-5 h-5" />
            </div>
            <div>
              <span className="text-lg font-bold text-slate-900">Terms of Service</span>
              <p className="text-xs text-slate-500 font-normal">Last updated: September 2026</p>
            </div>
          </div>
        }
        footer={
          <Button variant="primary" size="sm" onClick={onClose} className="px-5">
            Accept & Close
          </Button>
        }
      >
        <div className="space-y-4 text-slate-700 text-sm leading-relaxed">
          <div className="p-3.5 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-900 flex items-start gap-2.5">
            <AlertCircle className="w-4 h-4 text-amber-600 flex-shrink-0 mt-0.5" />
            <span>
              <strong>Medical Disclaimer:</strong> CareSync is a self-care medication tracking and organizational platform. It does not provide medical diagnosis, prescription advice, or emergency treatment.
            </span>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">1. Acceptance of Terms</h4>
            <p className="text-xs text-slate-600">
              By accessing or using CareSync ("the Platform"), you agree to be bound by these Terms of Service. If you disagree with any portion of these terms, please do not use the application.
            </p>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">2. Healthcare Organization & Not Clinical Advice</h4>
            <p className="text-xs text-slate-600">
              CareSync is designed to assist you in organizing schedules, logging doses, and storing health documents. It is not a substitute for professional clinical judgment, physician consultations, or pharmaceutical verification. In any acute medical emergency, contact your local emergency response (911/112) immediately.
            </p>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">3. User Responsibilities & Account Security</h4>
            <ul className="list-disc pl-5 space-y-1 text-xs text-slate-600">
              <li>You are responsible for keeping your login credentials confidential and secure.</li>
              <li>You agree to provide accurate medication names, dosage quantities, and times to ensure reminder notifications are reliable.</li>
              <li>You agree not to use the platform for any unlawful, disruptive, or unauthorized automated activities.</li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold text-slate-900 text-sm mb-1">4. Availability, Updates & Service Level</h4>
            <p className="text-xs text-slate-600">
              We continually enhance and update CareSync. While we strive for 99.9% uptime and reliable cloud synchronization, the service is provided on an "as is" and "as available" basis.
            </p>
          </div>
        </div>
      </Modal>
    );
  }

  if (type === 'contact') {
    const supportEmail = 'battula.keerthika0@gmail.com';

    return (
      <Modal
        isOpen={isOpen}
        onClose={onClose}
        maxWidth="max-w-xl"
        title={
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-indigo-50 text-indigo-600">
              <Mail className="w-5 h-5" />
            </div>
            <div>
              <span className="text-lg font-bold text-slate-900">Contact & Support</span>
              <p className="text-xs text-slate-500 font-normal">We're here to assist you with CareSync</p>
            </div>
          </div>
        }
        footer={
          <Button variant="outline" size="sm" onClick={onClose} className="px-5">
            Close
          </Button>
        }
      >
        <div className="space-y-4">
          <p className="text-xs text-slate-600 leading-relaxed">
            Have questions, feedback, or need technical assistance with your CareSync account? Reach out to our dedicated healthcare support team.
          </p>

          {/* Primary Email Card */}
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-indigo-100 text-indigo-600 flex items-center justify-center flex-shrink-0">
                <Mail className="w-4 h-4" />
              </div>
              <div className="min-w-0">
                <span className="text-xs text-slate-500 block font-medium">Primary Support Email</span>
                <span className="text-sm font-semibold text-slate-900 font-mono break-all">{supportEmail}</span>
              </div>
            </div>
            <div className="flex items-center gap-2 sm:self-center">
              <button
                type="button"
                onClick={() => handleCopyEmail(supportEmail)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                  copiedEmail
                    ? 'bg-emerald-100 text-emerald-700'
                    : 'bg-white border border-slate-200 text-slate-700 hover:bg-slate-100'
                }`}
                title="Copy Email to Clipboard"
              >
                {copiedEmail ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5 text-slate-500" />}
                <span>{copiedEmail ? 'Copied' : 'Copy'}</span>
              </button>
              <a
                href={`mailto:${supportEmail}?subject=CareSync%20Support%20Request`}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 text-white hover:bg-indigo-700 flex items-center gap-1.5 shadow-sm transition-colors"
              >
                <span>Write</span>
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>

          {/* Service Details Card */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1 text-xs">
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/80">
              <div className="flex items-center gap-2 text-indigo-600 font-semibold mb-1">
                <Clock className="w-4 h-4" />
                <span>Response Time</span>
              </div>
              <p className="text-slate-600">Typically within 24 hours on business days</p>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200/80">
              <div className="flex items-center gap-2 text-indigo-600 font-semibold mb-1">
                <Sparkles className="w-4 h-4" />
                <span>Platform Lead</span>
              </div>
              <p className="text-slate-600">Keerthika Battula & Engineering Team</p>
            </div>
          </div>

          {/* Emergency Notice */}
          <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-100 text-xs text-rose-900 flex items-start gap-2.5">
            <AlertCircle className="w-4 h-4 text-rose-600 flex-shrink-0 mt-0.5" />
            <span>
              <strong>Emergency Notice:</strong> This contact channel is for platform support only. If you are experiencing a medical emergency, please call your local emergency hotline (911 / 112) or go to the nearest emergency room.
            </span>
          </div>
        </div>
      </Modal>
    );
  }

  return null;
}
