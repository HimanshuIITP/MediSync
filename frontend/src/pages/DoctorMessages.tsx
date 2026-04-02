import { useEffect, useMemo, useState } from 'react';
import { MessageSquare } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface ThreadItem {
  patient: {
    name: string;
    email: string;
  };
  latest_status: string | null;
  next_visit: { date: string; time: string } | null;
}

export default function DoctorMessages() {
  const location = useLocation();
  const doctorEmail = localStorage.getItem('medisync_email') ?? '';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [threads, setThreads] = useState<ThreadItem[]>([]);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    const load = async () => {
      if (!doctorEmail || !token) {
        setErrorMessage('Please login as doctor first.');
        return;
      }

      try {
        const response = await fetch(`${API_BASE_URL}/doctor/patients/${doctorEmail}`, { headers: { Authorization: token } });
        const result = await response.json() as { patients?: ThreadItem[]; error?: string };
        if (!response.ok || result.error) {
          throw new Error(result.error ?? 'Failed to load message threads');
        }
        setThreads(result.patients ?? []);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Failed to load message threads';
        setErrorMessage(message);
      }
    };

    load();
  }, [doctorEmail, token]);

  const filtered = useMemo(() => {
    const query = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
    if (!query) {
      return threads;
    }
    return threads.filter((thread) =>
      [thread.patient.name, thread.patient.email, thread.latest_status ?? ''].some((value) => value.toLowerCase().includes(query)),
    );
  }, [threads, location.search]);

  return (
    <DashboardLayout role="doctor">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Messages</h1>
          <p className="text-slate-500 mt-1">Patient communication threads sourced from backend patient relationships.</p>
        </div>

        {errorMessage && <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">{errorMessage}</div>}

        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-sm space-y-3">
          {filtered.length === 0 ? (
            <p className="text-sm text-slate-500">No patient threads available yet.</p>
          ) : (
            filtered.map((thread) => (
              <div key={thread.patient.email} className="p-4 rounded-xl border border-slate-100">
                <p className="font-semibold text-slate-900 inline-flex items-center gap-2"><MessageSquare size={14} /> {thread.patient.name}</p>
                <p className="text-sm text-slate-600 mt-1">{thread.patient.email}</p>
                <p className="text-xs text-slate-500 mt-2">Latest status: <span className="capitalize">{thread.latest_status ?? 'n/a'}</span></p>
                <p className="text-xs text-slate-500 mt-1">Next visit: {thread.next_visit ? `${thread.next_visit.date} ${thread.next_visit.time}` : 'Not scheduled'}</p>
              </div>
            ))
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
