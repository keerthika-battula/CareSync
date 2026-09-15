import React, { useState, useEffect } from 'react';
import { Menu, Plus, Pill, Calendar, FileUp, Heart } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { Button } from '../ui/Button';

export function Navbar({ onMenuToggle }) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [currentDate, setCurrentDate] = useState('');

  useEffect(() => {
    const formatNow = () => {
      const options = { weekday: 'long', month: 'short', day: 'numeric', year: 'numeric' };
      setCurrentDate(new Date().toLocaleDateString('en-US', options));
    };
    formatNow();
    const interval = setInterval(formatNow, 60000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="sticky top-0 z-30 flex h-16 w-full items-center justify-between border-b border-slate-100 bg-white/95 px-4 sm:px-8 backdrop-blur-md">
      {/* Left Menu Toggle for Mobile + Date */}
      <div className="flex items-center gap-4">
        <button
          onClick={onMenuToggle}
          className="rounded-xl p-2 text-slate-500 hover:bg-slate-100 hover:text-slate-700 lg:hidden"
        >
          <Menu className="h-5 w-5" />
        </button>

        <div className="hidden sm:block">
          <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
            Today
          </p>
          <p className="text-sm font-bold text-slate-800">{currentDate}</p>
        </div>
      </div>

      {/* Center/Right Quick Actions & User Greeting */}
      <div className="flex items-center gap-2 sm:gap-3">
        <Button
          variant="secondary"
          size="sm"
          onClick={() => navigate('/medicines?action=add')}
          className="hidden md:inline-flex border-indigo-100 text-indigo-600 bg-indigo-50/50 hover:bg-indigo-50"
        >
          <Pill className="h-3.5 w-3.5 text-indigo-600" />
          <span>+ Add Medicine</span>
        </Button>

        <Button
          variant="secondary"
          size="sm"
          onClick={() => navigate('/appointments?action=add')}
          className="hidden lg:inline-flex border-sky-100 text-sky-600 bg-sky-50/50 hover:bg-sky-50"
        >
          <Calendar className="h-3.5 w-3.5 text-sky-600" />
          <span>Schedule Visit</span>
        </Button>

        <Button
          variant="secondary"
          size="sm"
          onClick={() => navigate('/documents?action=upload')}
          className="hidden xl:inline-flex border-emerald-100 text-emerald-600 bg-emerald-50/50 hover:bg-emerald-50"
        >
          <FileUp className="h-3.5 w-3.5 text-emerald-600" />
          <span>Upload Document</span>
        </Button>

        {/* Profile Avatar Quick Button */}
        <div
          onClick={() => navigate('/profile')}
          className="flex items-center gap-2.5 pl-2 cursor-pointer group"
        >
          <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-indigo-600 text-white font-bold text-sm shadow-sm shadow-indigo-200 group-hover:scale-105 transition-transform">
            {user?.firstName ? user.firstName[0].toUpperCase() : 'U'}
          </div>
          <div className="hidden sm:block text-left">
            <p className="text-xs font-bold text-slate-800 leading-tight group-hover:text-indigo-600 transition-colors">
              {user?.firstName} {user?.lastName}
            </p>
            <p className="text-[10px] font-semibold text-slate-400 capitalize">
              {user?.role?.toLowerCase() || 'Member'}
            </p>
          </div>
        </div>
      </div>
    </header>
  );
}
