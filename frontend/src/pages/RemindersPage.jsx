import React, { useState, useEffect } from 'react';
import { 
  Clock, CheckCircle2, XCircle, AlertCircle, RefreshCw, 
  Calendar, Pill, ChevronRight, Check, X, Bell, User 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/context/ToastContext';
import { remindersApi } from '@/services/api';
import { Link } from 'react-router-dom';

export default function RemindersPage() {
  const { addToast } = useToast();
  const [reminders, setReminders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('ALL'); // ALL, PENDING, TAKEN, SKIPPED

  // Snooze modal
  const [snoozeModalOpen, setSnoozeModalOpen] = useState(false);
  const [selectedReminder, setSelectedReminder] = useState(null);
  const [snoozeMinutes, setSnoozeMinutes] = useState(15);
  const [actionLoading, setActionLoading] = useState(null);

  const fetchReminders = async () => {
    try {
      setLoading(true);
      const res = await remindersApi.getToday();
      const list = Array.isArray(res) ? res : (res.data || []);
      setReminders(list);
    } catch (err) {
      addToast(err.message || 'Failed to load today’s schedule', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReminders();
  }, []);

  const handleMarkTaken = async (id) => {
    try {
      setActionLoading(id);
      await remindersApi.markTaken(id);
      addToast('Dose recorded as taken!', 'success');
      fetchReminders();
    } catch (err) {
      addToast(err.message || 'Failed to record dose', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  const handleMarkSkipped = async (id) => {
    try {
      setActionLoading(id);
      await remindersApi.markSkipped(id);
      addToast('Dose marked as skipped', 'info');
      fetchReminders();
    } catch (err) {
      addToast(err.message || 'Failed to skip dose', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  const openSnooze = (rem) => {
    setSelectedReminder(rem);
    setSnoozeMinutes(15);
    setSnoozeModalOpen(true);
  };

  const handleSnooze = async () => {
    if (!selectedReminder) return;
    try {
      setActionLoading(selectedReminder.id);
      await remindersApi.snooze(selectedReminder.id, snoozeMinutes);
      addToast(`Snoozed dose for ${snoozeMinutes} minutes`, 'info');
      setSnoozeModalOpen(false);
      fetchReminders();
    } catch (err) {
      addToast(err.message || 'Failed to snooze reminder', 'error');
    } finally {
      setActionLoading(null);
    }
  };

  // Metrics
  const totalCount = reminders.length;
  const takenCount = reminders.filter(r => r.status === 'TAKEN').length;
  const pendingCount = reminders.filter(r => r.status === 'PENDING' || r.status === 'SNOOZED').length;
  const skippedCount = reminders.filter(r => r.status === 'SKIPPED').length;
  const adherenceRate = totalCount > 0 ? Math.round((takenCount / totalCount) * 100) : 100;

  // Filtered List
  const filteredReminders = reminders.filter(rem => {
    if (activeTab === 'PENDING') return rem.status === 'PENDING' || rem.status === 'SNOOZED';
    if (activeTab === 'TAKEN') return rem.status === 'TAKEN';
    if (activeTab === 'SKIPPED') return rem.status === 'SKIPPED';
    return true;
  });

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Daily Dose Schedule</h1>
          <p className="text-sm text-slate-500 mt-1">
            Track, confirm, and manage your scheduled medication intake for today
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchReminders} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Link to="/medicines">
            <Button size="sm">
              <Pill className="w-4 h-4 mr-2" />
              Manage Medicines
            </Button>
          </Link>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Today's Doses</p>
              <h3 className="text-2xl font-bold text-slate-900 mt-1">{totalCount}</h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <Clock className="w-5 h-5" />
            </div>
          </div>
        </Card>

        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Taken</p>
              <h3 className="text-2xl font-bold text-emerald-600 mt-1">{takenCount}</h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <CheckCircle2 className="w-5 h-5" />
            </div>
          </div>
        </Card>

        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Pending</p>
              <h3 className="text-2xl font-bold text-amber-600 mt-1">{pendingCount}</h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <AlertCircle className="w-5 h-5" />
            </div>
          </div>
        </Card>

        <Card className="p-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500">Adherence Rate</p>
              <h3 className="text-2xl font-bold text-teal-700 mt-1">{adherenceRate}%</h3>
            </div>
            <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <Check className="w-5 h-5" />
            </div>
          </div>
        </Card>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
        {[
          { id: 'ALL', label: `All Doses (${totalCount})` },
          { id: 'PENDING', label: `Pending (${pendingCount})` },
          { id: 'TAKEN', label: `Taken (${takenCount})` },
          { id: 'SKIPPED', label: `Skipped (${skippedCount})` },
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
              activeTab === tab.id
                ? 'bg-teal-50 text-teal-700 font-semibold'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Doses List */}
      {loading ? (
        <Card className="p-6 space-y-4">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-16 bg-slate-100 rounded-lg animate-pulse"></div>
          ))}
        </Card>
      ) : filteredReminders.length === 0 ? (
        <Card className="text-center py-12">
          <CardContent className="space-y-3">
            <div className="w-12 h-12 rounded-full bg-slate-100 text-slate-500 flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-6 h-6 text-teal-600" />
            </div>
            <h3 className="text-base font-semibold text-slate-900">
              {activeTab === 'ALL' ? 'No doses scheduled for today' : `No ${activeTab.toLowerCase()} doses`}
            </h3>
            <p className="text-sm text-slate-500 max-w-sm mx-auto">
              {activeTab === 'ALL' 
                ? 'All your scheduled medications for today will appear here once configured.'
                : `There are currently no doses matching the ${activeTab.toLowerCase()} filter.`}
            </p>
            {activeTab === 'ALL' && (
              <Link to="/medicines">
                <Button className="mt-2">
                  <Pill className="w-4 h-4 mr-2" />
                  Add Medicine
                </Button>
              </Link>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {filteredReminders.map(rem => {
            const isTaken = rem.status === 'TAKEN';
            const isSkipped = rem.status === 'SKIPPED';
            const isSnoozed = rem.status === 'SNOOZED';
            const isPending = rem.status === 'PENDING' || isSnoozed;

            const timeDisplay = rem.scheduledTime ? rem.scheduledTime.substring(0, 5) : '--:--';

            return (
              <Card
                key={rem.id}
                className={`transition-all duration-200 border ${
                  isTaken
                    ? 'border-emerald-200 bg-emerald-50/20'
                    : isSkipped
                      ? 'border-slate-200 bg-slate-50/50 opacity-70'
                      : 'border-slate-200 hover:border-slate-300'
                }`}
              >
                <CardContent className="p-4 sm:p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  {/* Left: Time & Medicine Info */}
                  <div className="flex items-start gap-4">
                    <div className={`p-2.5 rounded-xl text-center shrink-0 min-w-[64px] ${
                      isTaken 
                        ? 'bg-emerald-100 text-emerald-800' 
                        : isSkipped 
                          ? 'bg-slate-200 text-slate-600' 
                          : 'bg-teal-50 text-teal-800 border border-teal-200'
                    }`}>
                      <div className="text-xs font-mono font-bold">{timeDisplay}</div>
                      <div className="text-[10px] uppercase font-medium mt-0.5">
                        {isTaken ? 'Taken' : isSkipped ? 'Skipped' : 'Scheduled'}
                      </div>
                    </div>

                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <h3 className="font-semibold text-slate-900 text-base">{rem.medicineName}</h3>
                        {rem.dosage && (
                          <span className="text-xs bg-slate-100 text-slate-700 font-medium px-2 py-0.5 rounded">
                            {rem.dosage}
                          </span>
                        )}
                        {rem.familyMemberName && (
                          <span className="text-xs bg-purple-50 text-purple-700 font-medium px-2 py-0.5 rounded flex items-center gap-1">
                            <User className="w-3 h-3" />
                            {rem.familyMemberName}
                          </span>
                        )}
                        {isSnoozed && (
                          <Badge variant="warning">Snoozed</Badge>
                        )}
                      </div>

                      {rem.instructions && (
                        <p className="text-xs text-slate-500 mt-1 italic">
                          "{rem.instructions}"
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Right: Actions */}
                  <div className="flex items-center gap-2 sm:self-center shrink-0">
                    {isPending ? (
                      <>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => openSnooze(rem)}
                          disabled={actionLoading === rem.id}
                          className="text-xs text-slate-600"
                        >
                          <Bell className="w-3.5 h-3.5 mr-1" />
                          Snooze
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleMarkSkipped(rem.id)}
                          disabled={actionLoading === rem.id}
                          className="text-xs text-slate-500 hover:text-rose-600 hover:bg-rose-50 hover:border-rose-200"
                        >
                          <X className="w-3.5 h-3.5 mr-1" />
                          Skip
                        </Button>
                        <Button
                          size="sm"
                          onClick={() => handleMarkTaken(rem.id)}
                          loading={actionLoading === rem.id}
                          className="text-xs bg-emerald-600 hover:bg-emerald-700 text-white"
                        >
                          <Check className="w-3.5 h-3.5 mr-1" />
                          Take Dose
                        </Button>
                      </>
                    ) : isTaken ? (
                      <div className="flex items-center text-emerald-600 font-medium text-xs bg-emerald-50 px-3 py-1.5 rounded-lg border border-emerald-200">
                        <CheckCircle2 className="w-4 h-4 mr-1.5" />
                        Completed
                      </div>
                    ) : (
                      <div className="flex items-center text-slate-500 font-medium text-xs bg-slate-100 px-3 py-1.5 rounded-lg">
                        <XCircle className="w-4 h-4 mr-1.5" />
                        Skipped
                      </div>
                    )}
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Snooze Modal */}
      <Modal
        isOpen={snoozeModalOpen}
        onClose={() => setSnoozeModalOpen(false)}
        title="Snooze Reminder"
        description="Select how long you would like to postpone this dose notification."
        maxWidth="max-w-md"
      >
        <div className="space-y-4">
          <div className="grid grid-cols-3 gap-2">
            {[15, 30, 60].map(mins => (
              <button
                key={mins}
                type="button"
                onClick={() => setSnoozeMinutes(mins)}
                className={`py-2 px-3 text-xs font-semibold rounded-lg border transition-all ${
                  snoozeMinutes === mins
                    ? 'border-teal-600 bg-teal-50 text-teal-700'
                    : 'border-slate-200 bg-white text-slate-700 hover:bg-slate-50'
                }`}
              >
                {mins} Minutes
              </button>
            ))}
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button variant="outline" onClick={() => setSnoozeModalOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSnooze} loading={actionLoading === selectedReminder?.id}>
              Confirm Snooze
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
