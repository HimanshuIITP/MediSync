import { useEffect, useMemo, useRef, useState } from 'react';
import { HeartPulse, Bell, Settings, LogOut, LayoutDashboard, Calendar, Users, FileText, Activity, MessageSquare, Plus, Search } from 'lucide-react';
import { Link, useLocation, useNavigate } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface PatientAppointmentSnapshot {
  id: string;
  doctorEmail: string;
  status: string;
  date: string;
  time: string;
  scheduledBy?: string;
}

interface NotificationItem {
  id: string;
  appointmentId: string;
  message: string;
  createdAt: string;
  read: boolean;
  route?: string;
}

function getSnapshotStorageKey(email: string) {
  return `medisync_appointments_snapshot_${email}`;
}

function getNotificationStorageKey(email: string) {
  return `medisync_notifications_${email}`;
}

function safeParseArray<T>(value: string | null): T[] {
  if (!value) {
    return [];
  }
  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed as T[] : [];
  } catch {
    return [];
  }
}

function formatDoctorName(email: string) {
  const base = (email || 'Doctor').split('@')[0] || 'Doctor';
  return `Dr. ${base}`;
}

function isStatusChangeNotification(status: string) {
  const normalized = (status || '').toLowerCase();
  return ['accepted', 'confirmed', 'approved', 'declined', 'rejected', 'rescheduled'].includes(normalized);
}

function getStatusLabel(status: string) {
  const normalized = (status || '').toLowerCase();
  if (['accepted', 'confirmed', 'approved'].includes(normalized)) {
    return 'accepted';
  }
  if (['declined', 'rejected'].includes(normalized)) {
    return 'declined';
  }
  if (normalized === 'rescheduled') {
    return 'rescheduled';
  }
  return normalized || 'updated';
}

interface DashboardLayoutProps {
  children: React.ReactNode;
  role: 'patient' | 'doctor' | 'department';
}

export default function DashboardLayout({ children, role }: DashboardLayoutProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const [searchQuery, setSearchQuery] = useState('');
  const storedName = localStorage.getItem('medisync_name');
  const storedEmail = localStorage.getItem('medisync_email');
  const patientEmail = storedEmail ?? '';
  const profileName = storedName || storedEmail || (role === 'patient' ? 'Patient' : role === 'doctor' ? 'Doctor' : 'Department');
  const settingsPath = role === 'patient' ? '/patient-dashboard/settings' : role === 'doctor' ? '/doctor-dashboard/settings' : '/department-dashboard/settings';
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [isBellOpen, setIsBellOpen] = useState(false);
  const [floatingNotification, setFloatingNotification] = useState<NotificationItem | null>(null);
  const toastTimeoutRef = useRef<number | null>(null);

  useEffect(() => {
    if (role !== 'patient' || !patientEmail) {
      setNotifications([]);
      return;
    }

    setNotifications(safeParseArray<NotificationItem>(localStorage.getItem(getNotificationStorageKey(patientEmail))));
  }, [role, patientEmail]);

  useEffect(() => {
    if (role !== 'patient' || !patientEmail) {
      return;
    }

    const notificationStorageKey = getNotificationStorageKey(patientEmail);
    localStorage.setItem(notificationStorageKey, JSON.stringify(notifications));
  }, [notifications, role, patientEmail]);

  useEffect(() => {
    if (role !== 'patient' || !patientEmail) {
      return;
    }

    const snapshotStorageKey = getSnapshotStorageKey(patientEmail);

    const pollAppointments = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/patient/appointments/${patientEmail}`);
        if (!response.ok) {
          return;
        }

        const result = await response.json() as { appointments?: Array<{ _id: string; doctor_email: string; status: string; date: string; time: string; scheduled_by?: string }> };
        const currentAppointments = (result.appointments ?? []).map((appointment) => ({
          id: appointment._id,
          doctorEmail: appointment.doctor_email,
          status: appointment.status,
          date: appointment.date,
          time: appointment.time,
          scheduledBy: appointment.scheduled_by,
        })) as PatientAppointmentSnapshot[];

        const previousSnapshots = safeParseArray<PatientAppointmentSnapshot>(localStorage.getItem(snapshotStorageKey));
        const previousById = new Map(previousSnapshots.map((item) => [item.id, item]));
        const generated: NotificationItem[] = [];

        currentAppointments.forEach((item) => {
          const previous = previousById.get(item.id);
          const statusChanged = Boolean(previous) && previous.status !== item.status;
          const scheduleChanged = Boolean(previous) && (previous.date !== item.date || previous.time !== item.time);
          const normalizedStatus = (item.status || '').toLowerCase();

          if (statusChanged && isStatusChangeNotification(item.status)) {
            generated.push({
              id: `${item.id}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              appointmentId: item.id,
              message: `${formatDoctorName(item.doctorEmail)} has ${getStatusLabel(item.status)} your request.`,
              createdAt: new Date().toISOString(),
              read: false,
              route: '/patient-dashboard/appointments',
            });
            return;
          }

          if (!previous && previousSnapshots.length > 0 && item.scheduledBy === 'doctor' && ['accepted', 'confirmed', 'approved'].includes(normalizedStatus)) {
            generated.push({
              id: `${item.id}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              appointmentId: item.id,
              message: `${formatDoctorName(item.doctorEmail)} scheduled your next appointment for ${item.date} ${item.time}.`,
              createdAt: new Date().toISOString(),
              read: false,
              route: '/patient-dashboard/appointments',
            });
            return;
          }

          if (!statusChanged && scheduleChanged && ['accepted', 'confirmed', 'approved', 'rescheduled'].includes(normalizedStatus)) {
            generated.push({
              id: `${item.id}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              appointmentId: item.id,
              message: `${formatDoctorName(item.doctorEmail)} has rescheduled your appointment to ${item.date} ${item.time}.`,
              createdAt: new Date().toISOString(),
              read: false,
              route: '/patient-dashboard/appointments',
            });
          }
        });

        if (generated.length > 0) {
          setNotifications((previous) => [...generated, ...previous].slice(0, 50));
          setFloatingNotification(generated[0]);
          if (toastTimeoutRef.current) {
            window.clearTimeout(toastTimeoutRef.current);
          }
          toastTimeoutRef.current = window.setTimeout(() => setFloatingNotification(null), 10000);
        }

        localStorage.setItem(snapshotStorageKey, JSON.stringify(currentAppointments));
      } catch {
        // Ignore transient network errors; next poll will recover.
      }
    };

    pollAppointments();
    const intervalId = window.setInterval(pollAppointments, 5000);

    return () => {
      window.clearInterval(intervalId);
      if (toastTimeoutRef.current) {
        window.clearTimeout(toastTimeoutRef.current);
      }
    };
  }, [role, patientEmail]);

  const unreadCount = useMemo(() => notifications.filter((item) => !item.read).length, [notifications]);

  const toggleBell = () => {
    setIsBellOpen((previous) => {
      const next = !previous;
      if (next) {
        setNotifications((items) => items.map((item) => ({ ...item, read: true })));
      }
      return next;
    });
  };

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    setSearchQuery(params.get('q') ?? '');
  }, [location.search]);

  const handleGlobalSearch = (event: React.FormEvent) => {
    event.preventDefault();
    const query = searchQuery.trim();
    if (!query) {
      navigate(location.pathname);
      return;
    }

    const normalized = query.toLowerCase();
    if (role === 'patient') {
      if (normalized.includes('record') || normalized.includes('report') || normalized.includes('scan')) {
        navigate(`/patient-dashboard/records?q=${encodeURIComponent(query)}`);
        return;
      }
      if (normalized.includes('appoint') || normalized.includes('book') || normalized.includes('schedule')) {
        navigate(`/patient-dashboard/appointments?q=${encodeURIComponent(query)}`);
        return;
      }
      if (normalized.includes('doctor') || normalized.includes('special') || normalized.includes('cardio') || normalized.includes('neuro')) {
        navigate(`/patient-dashboard/doctors?q=${encodeURIComponent(query)}`);
        return;
      }
      if (normalized.includes('message') || normalized.includes('chat')) {
        navigate(`/patient-dashboard/messages?q=${encodeURIComponent(query)}`);
        return;
      }
      navigate(`/patient-dashboard/doctors?q=${encodeURIComponent(query)}`);
      return;
    }

    navigate(`${location.pathname}?q=${encodeURIComponent(query)}`);
  };

  const getNavItems = () => {
    switch (role) {
      case 'patient':
        return [
          { name: 'Dashboard', icon: LayoutDashboard, path: '/patient-dashboard' },
          { name: 'Appointments', icon: Calendar, path: '/patient-dashboard/appointments' },
          { name: 'My Doctors', icon: Users, path: '/patient-dashboard/doctors' },
          { name: 'Medical Records', icon: FileText, path: '/patient-dashboard/records' },
          { name: 'AI Consult', icon: Activity, path: '/patient-dashboard/ai-consult' },
          { name: 'Messages', icon: MessageSquare, path: '/patient-dashboard/messages' },
        ];
      case 'doctor':
        return [
          { name: 'Dashboard', icon: LayoutDashboard, path: '/doctor-dashboard' },
          { name: 'My Patients', icon: Users, path: '/doctor-dashboard/patients' },
          { name: 'Schedule', icon: Calendar, path: '/doctor-dashboard/schedule' },
          { name: 'Pre-consults', icon: FileText, path: '/doctor-dashboard/pre-consults' },
          { name: 'Messages', icon: MessageSquare, path: '/doctor-dashboard/messages' },
        ];
      case 'department':
        return [
          { name: 'Dashboard', icon: LayoutDashboard, path: '/department-dashboard' },
          { name: 'Upload Reports', icon: Plus, path: '/department-dashboard/upload-reports' },
          { name: 'Patient Directory', icon: Users, path: '/department-dashboard/patient-directory' },
          { name: 'Archives', icon: FileText, path: '/department-dashboard/archives' },
        ];
    }
  };

  const navItems = getNavItems();

  return (
    <div className="min-h-screen bg-slate-100 flex font-sans">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-slate-200 flex flex-col fixed h-full z-10 hidden md:flex shadow-sm">
        <div className="h-20 flex items-center px-6 border-b border-slate-100">
          <Link to="/" className="flex items-center space-x-2 text-indigo-600 font-bold text-xl">
            <HeartPulse size={28} />
            <span>MediSync</span>
          </Link>
        </div>

        <div className="flex-1 py-6 px-4 space-y-2 overflow-y-auto">
          {navItems.map((item, index) => {
            const isActive = location.pathname === item.path;
            const Icon = item.icon;
            return (
              <Link 
                key={index}
                to={item.path} 
                className={`flex items-center space-x-3 px-4 py-3 rounded-xl transition-all ${
                  isActive 
                    ? 'bg-indigo-50 text-indigo-700 font-semibold border-l-4 border-indigo-600' 
                    : 'text-slate-500 hover:bg-slate-50 hover:text-slate-900'
                }`}
              >
                <Icon size={20} className={isActive ? 'text-indigo-600' : 'text-slate-400'} />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </div>

        <div className="p-4 border-t border-slate-100 space-y-2">
          <button
            onClick={() => navigate(settingsPath)}
            className="flex items-center space-x-3 px-4 py-3 rounded-xl text-slate-500 hover:bg-slate-50 hover:text-slate-900 w-full transition"
          >
            <Settings size={20} className="text-slate-400" />
            <span>Settings</span>
          </button>
          <button 
            onClick={() => {
              localStorage.removeItem('medisync_token');
              localStorage.removeItem('medisync_email');
              localStorage.removeItem('medisync_name');
              localStorage.removeItem('medisync_role');
              navigate('/role', { replace: true });
            }}
            className="flex items-center space-x-3 px-4 py-3 rounded-xl text-rose-500 hover:bg-rose-50 w-full transition"
          >
            <LogOut size={20} className="text-rose-400" />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 md:ml-64 flex flex-col min-h-screen bg-[#f8fafc]">
        {/* Top Navbar */}
        <header className="h-20 bg-white border-b border-slate-200 flex items-center justify-between px-8 sticky top-0 z-10 shadow-sm">
          <div className="flex-1 flex items-center">
             <form className="relative w-full max-w-md hidden md:block" onSubmit={handleGlobalSearch}>
               <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
               <input
                 type="text"
                 value={searchQuery}
                 onChange={(event) => setSearchQuery(event.target.value)}
                 placeholder="Search doctors, patients, or records..."
                 className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
               />
             </form>
             {/* Mobile logo */}
             <div className="md:hidden flex items-center space-x-2 text-indigo-600 font-bold text-xl">
               <HeartPulse size={24} />
               <span>MediSync</span>
             </div>
          </div>

          <div className="flex items-center space-x-6">
            <button
              onClick={toggleBell}
              className="relative p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-full transition"
            >
              <Bell size={22} />
              {unreadCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 min-w-[18px] h-[18px] px-1 bg-rose-500 text-white text-[10px] font-bold rounded-full border-2 border-white flex items-center justify-center">
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </button>
            {isBellOpen && (
              <div className="absolute top-16 right-24 w-96 max-h-[420px] overflow-y-auto bg-white border border-slate-200 rounded-2xl shadow-xl p-3 z-20">
                <div className="flex items-center justify-between px-2 py-1">
                  <h3 className="text-sm font-bold text-slate-900">Notifications</h3>
                  <button
                    onClick={() => setNotifications([])}
                    className="text-xs text-slate-500 hover:text-slate-700"
                  >
                    Clear all
                  </button>
                </div>
                {notifications.length === 0 ? (
                  <p className="text-sm text-slate-500 px-2 py-4">No notifications yet.</p>
                ) : (
                  <div className="space-y-2 mt-1">
                    {notifications.map((item) => (
                      <button
                        key={item.id}
                        onClick={() => {
                          if (item.route) {
                            navigate(item.route);
                          }
                          setIsBellOpen(false);
                        }}
                        className="w-full text-left px-3 py-2.5 rounded-xl border border-slate-100 bg-slate-50 hover:bg-indigo-50 transition"
                      >
                        <p className="text-sm text-slate-800">{item.message}</p>
                        <p className="text-[11px] text-slate-400 mt-1">{new Date(item.createdAt).toLocaleString()}</p>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
            <div className="flex items-center space-x-3 border-l border-slate-200 pl-6">
              <div className="text-right hidden sm:block">
                <p className="text-sm font-bold text-slate-900 leading-tight">
                  {profileName}
                </p>
                <p className="text-xs text-slate-500 capitalize">{role}</p>
              </div>
              <img 
                src={role === 'doctor' ? "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=150&q=80" : "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80"} 
                alt="Profile" 
                className="w-10 h-10 rounded-full object-cover border-2 border-indigo-100 shadow-sm"
              />
            </div>
          </div>
        </header>

        {/* Page Content */}
        <div className="flex-1 p-8 overflow-y-auto">
          {children}
        </div>
      </main>

      {floatingNotification && (
        <button
          onClick={() => {
            if (floatingNotification.route) {
              navigate(floatingNotification.route);
            }
            setFloatingNotification(null);
          }}
          className="fixed bottom-6 right-6 max-w-sm bg-slate-900 text-white rounded-xl px-4 py-3 shadow-2xl z-30 text-left"
        >
          <p className="text-sm font-semibold">Appointment Update</p>
          <p className="text-sm text-slate-200 mt-1">{floatingNotification.message}</p>
        </button>
      )}
    </div>
  );
}
