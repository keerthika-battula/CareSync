import React from 'react';
import { usePWAInstall } from '../../context/PWAInstallContext';
import { Share, PlusSquare, X, Download, Smartphone, Info } from 'lucide-react';
import { Button } from '../ui/Button';
import caresyncLogoIcon from '../../assets/caresync-logo-icon.png';

export function PWAInstallModal() {
  const {
    showIOSModal,
    setShowIOSModal,
    showFallbackModal,
    setShowFallbackModal,
  } = usePWAInstall();

  if (!showIOSModal && !showFallbackModal) return null;

  const handleClose = () => {
    setShowIOSModal(false);
    setShowFallbackModal(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fadeIn">
      <div className="relative w-full max-w-md p-6 bg-white rounded-2xl shadow-2xl border border-slate-100 overflow-hidden">
        {/* Close Button */}
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 p-1.5 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
          aria-label="Close dialog"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Content Header */}
        <div className="flex items-center gap-3.5 mb-5">
          <img
            src={caresyncLogoIcon}
            alt="CareSync"
            className="w-11 h-11 object-contain flex-shrink-0"
          />
          <div>
            <h3 className="text-lg font-bold text-slate-900 leading-tight">
              Install CareSync App
            </h3>
            <p className="text-xs text-slate-500 font-medium">
              Healthcare & Medication Tracking
            </p>
          </div>
        </div>

        {/* iOS Specific Instructions */}
        {showIOSModal && (
          <div className="space-y-4">
            <p className="text-sm text-slate-600 leading-relaxed">
              Install CareSync on your iPhone or iPad for quick one-tap access, offline medication schedules, and a full-screen experience:
            </p>

            <div className="space-y-3 p-4 bg-slate-50 rounded-xl border border-slate-200/70 text-xs text-slate-700">
              <div className="flex items-start gap-3">
                <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-indigo-100 text-indigo-600 font-bold">
                  1
                </div>
                <div className="flex-1 pt-0.5">
                  Tap the <span className="font-semibold text-slate-900 inline-flex items-center gap-1 mx-1 px-1.5 py-0.5 rounded bg-slate-200/80"><Share className="w-3.5 h-3.5 inline text-indigo-600" /> Share</span> button in Safari's bottom toolbar.
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-indigo-100 text-indigo-600 font-bold">
                  2
                </div>
                <div className="flex-1 pt-0.5">
                  Scroll down and select <span className="font-semibold text-slate-900 inline-flex items-center gap-1 mx-1 px-1.5 py-0.5 rounded bg-slate-200/80"><PlusSquare className="w-3.5 h-3.5 inline text-indigo-600" /> Add to Home Screen</span>.
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md bg-indigo-100 text-indigo-600 font-bold">
                  3
                </div>
                <div className="flex-1 pt-0.5">
                  Tap <span className="font-bold text-indigo-600">Add</span> in the top right corner to complete.
                </div>
              </div>
            </div>

            <Button
              variant="primary"
              size="md"
              className="w-full font-bold shadow-md shadow-indigo-100"
              onClick={handleClose}
            >
              Got It
            </Button>
          </div>
        )}

        {/* Fallback Browser Instructions */}
        {showFallbackModal && (
          <div className="space-y-4">
            <div className="flex items-start gap-3 p-4 bg-indigo-50/70 rounded-xl border border-indigo-100 text-indigo-900 text-xs leading-relaxed">
              <Info className="w-5 h-5 flex-shrink-0 text-indigo-600 mt-0.5" />
              <div>
                <p className="font-bold mb-1">Direct Installation</p>
                <p className="text-slate-600">
                  Install is not directly triggered in this browser. You can use your browser's menu (<span className="font-bold">⋮</span> or <span className="font-bold">⋯</span>) to select <span className="font-semibold text-slate-900">"Install CareSync"</span> or <span className="font-semibold text-slate-900">"Add to Home screen"</span>.
                </p>
              </div>
            </div>

            <Button
              variant="primary"
              size="md"
              className="w-full font-bold shadow-md shadow-indigo-100"
              onClick={handleClose}
            >
              Understood
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
