import React, { createContext, useContext, useState, useEffect } from 'react';
import { useToast } from './ToastContext';

const PWAInstallContext = createContext(null);

export function PWAInstallProvider({ children }) {
  const [deferredPrompt, setDeferredPrompt] = useState(null);
  const [isInstalled, setIsInstalled] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [showIOSModal, setShowIOSModal] = useState(false);
  const [showFallbackModal, setShowFallbackModal] = useState(false);
  const { showToast } = useToast() || { showToast: () => {} };

  useEffect(() => {
    // 1. Check if already installed / running in standalone mode
    const isStandalone = 
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true ||
      document.referrer.includes('android-app://');
    
    if (isStandalone) {
      setIsInstalled(true);
    }

    // 2. Detect iOS Safari
    const ua = window.navigator.userAgent.toLowerCase();
    const isIosDevice = /iphone|ipad|ipod/.test(ua) && !window.MSStream;
    const isSafari = /safari/.test(ua) && !/chrome|crios|fxios|edg/.test(ua);
    setIsIOS(isIosDevice && isSafari && !isStandalone);

    // 3. Listen for Chrome / Android / Edge native PWA install prompt
    const handleBeforeInstallPrompt = (e) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    // 4. Listen for appinstalled event
    const handleAppInstalled = () => {
      setIsInstalled(true);
      setDeferredPrompt(null);
      setShowIOSModal(false);
      setShowFallbackModal(false);
      try {
        showToast('CareSync installed successfully!', 'success');
      } catch (err) {
        // toast fallback
      }
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    window.addEventListener('appinstalled', handleAppInstalled);

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
      window.removeEventListener('appinstalled', handleAppInstalled);
    };
  }, []);

  const promptInstall = async () => {
    if (isInstalled) {
      showToast('CareSync is already installed on this device.', 'info');
      return;
    }

    // Native browser prompt supported
    if (deferredPrompt) {
      try {
        deferredPrompt.prompt();
        const choiceResult = await deferredPrompt.userChoice;
        if (choiceResult.outcome === 'accepted') {
          setIsInstalled(true);
          setDeferredPrompt(null);
        }
      } catch (err) {
        console.error('Error invoking PWA install prompt:', err);
      }
      return;
    }

    // iOS Safari instructions
    if (isIOS) {
      setShowIOSModal(true);
      return;
    }

    // Fallback message for unsupported browsers / desktop Safari / Firefox
    setShowFallbackModal(true);
  };

  const isInstallable = !isInstalled && (!!deferredPrompt || isIOS);

  return (
    <PWAInstallContext.Provider
      value={{
        isInstallable,
        isInstalled,
        isIOS,
        promptInstall,
        showIOSModal,
        setShowIOSModal,
        showFallbackModal,
        setShowFallbackModal,
      }}
    >
      {children}
    </PWAInstallContext.Provider>
  );
}

export function usePWAInstall() {
  const context = useContext(PWAInstallContext);
  if (!context) {
    return {
      isInstallable: false,
      isInstalled: false,
      isIOS: false,
      promptInstall: () => {},
      showIOSModal: false,
      setShowIOSModal: () => {},
      showFallbackModal: false,
      setShowFallbackModal: () => {},
    };
  }
  return context;
}
