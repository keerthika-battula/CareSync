import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import caresyncLogoIcon from '../../assets/caresync-logo-icon.png';

export default function ProtectedRoute({ children, requiredRole, requireAdmin = false }) {
  const { isAuthenticated, isLoading, isAdmin, user } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="flex flex-col items-center gap-4 text-center">
          <img
            src={caresyncLogoIcon}
            alt="CareSync Logo"
            className="h-16 w-16 object-contain animate-pulse"
          />
          <div className="flex items-center gap-2">
            <div className="h-4 w-4 animate-spin rounded-full border-2 border-indigo-600 border-t-transparent" />
            <p className="text-sm font-bold text-slate-800">Loading CareSync...</p>
          </div>
          <p className="text-xs text-slate-400 font-medium tracking-wide">Your Care. In Sync. On Time.</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if ((requireAdmin || requiredRole === 'ADMIN') && !isAdmin && user?.role !== 'ADMIN') {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}

export { ProtectedRoute };
