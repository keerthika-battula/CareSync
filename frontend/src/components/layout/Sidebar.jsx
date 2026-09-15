import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Pill,
  Clock,
  Calendar,
  Users,
  FileText,
  ShieldAlert,
  User,
  LogOut,
  X,
  Heart
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { Badge } from '../ui/Badge';
import { cn } from '../../utils/cn';

export function Sidebar({ isOpen, onClose }) {
  const { user, isAdmin, logout } = useAuth();
  const navigate = useNavigate();

  const navItems = [
    { name: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
    { name: 'Medicines', path: '/medicines', icon: Pill },
    { name: 'Doses & Reminders', path: '/reminders', icon: Clock },
    { name: 'Visits & Appointments', path: '/appointments', icon: Calendar },
    { name: 'Care Circle / Family', path: '/family', icon: Users },
    { name: 'Health Documents', path: '/documents', icon: FileText },
  ];

  if (isAdmin) {
    navItems.push({ name: 'Admin Panel', path: '/admin', icon: ShieldAlert, badge: 'ADMIN' });
  }

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-900/50 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-72 flex-col bg-white border-r border-slate-100 transition-transform duration-300 ease-in-out lg:static lg:translate-x-0",
          isOpen ? "translate-x-0" : "-translate-x-full"
        )}
      >
        {/* Brand Header */}
        <div className="flex h-16 items-center justify-between px-6 border-b border-slate-100">
          <div className="flex items-center gap-3 cursor-pointer" onClick={() => navigate('/dashboard')}>
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-600 text-white shadow-md shadow-indigo-100">
              <Heart className="h-5 w-5 fill-white" />
            </div>
            <div>
              <span className="text-lg font-extrabold tracking-tight text-slate-900">Care<span className="text-indigo-600">Sync</span></span>
              <p className="text-[10px] uppercase font-bold tracking-wider text-slate-400">Healthcare Platform</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-100 lg:hidden"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation Links */}
        <div className="flex-1 overflow-y-auto px-4 py-6 space-y-1.5">
          <p className="px-3 text-xs font-bold uppercase tracking-wider text-slate-400 mb-2">
            Main Navigation
          </p>
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                onClick={() => onClose && onClose()}
                className={({ isActive }) =>
                  cn(
                    "flex items-center justify-between gap-3 px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all duration-150",
                    isActive
                      ? "bg-indigo-50 text-indigo-700 shadow-sm shadow-indigo-50"
                      : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                  )
                }
              >
                {({ isActive }) => (
                  <>
                    <div className="flex items-center gap-3">
                      <Icon className={cn("h-4 w-4", isActive ? "text-indigo-600" : "text-slate-400")} />
                      <span>{item.name}</span>
                    </div>
                    {item.badge && (
                      <Badge variant="purple" className="text-[10px] px-1.5 py-0">
                        {item.badge}
                      </Badge>
                    )}
                  </>
                )}
              </NavLink>
            );
          })}
        </div>

        {/* User Card & Logout Footer */}
        <div className="border-t border-slate-100 p-4">
          <div className="flex items-center justify-between gap-3 rounded-xl bg-slate-50 p-3 mb-2">
            <div className="flex items-center gap-3 overflow-hidden">
              <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-indigo-100 text-indigo-700 font-bold text-sm">
                {user?.firstName ? user.firstName[0].toUpperCase() : 'U'}
              </div>
              <div className="truncate">
                <p className="text-xs font-bold text-slate-900 truncate">
                  {user?.firstName} {user?.lastName}
                </p>
                <p className="text-[11px] text-slate-500 truncate">{user?.email}</p>
              </div>
            </div>
            {isAdmin && (
              <Badge variant="purple" className="text-[10px] px-1.5">
                Admin
              </Badge>
            )}
          </div>

          <div className="grid grid-cols-2 gap-2">
            <NavLink
              to="/profile"
              onClick={() => onClose && onClose()}
              className="flex items-center justify-center gap-1.5 rounded-xl border border-slate-200 bg-white py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
            >
              <User className="h-3.5 w-3.5" />
              <span>Profile</span>
            </NavLink>
            <button
              onClick={logout}
              className="flex items-center justify-center gap-1.5 rounded-xl border border-rose-100 bg-rose-50/50 py-2 text-xs font-semibold text-rose-600 hover:bg-rose-50 transition-colors"
            >
              <LogOut className="h-3.5 w-3.5" />
              <span>Sign Out</span>
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
