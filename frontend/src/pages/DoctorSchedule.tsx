import { useEffect, useMemo, useState } from 'react';
import { Calendar, Clock, User, ChevronLeft, ChevronRight } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface Appointment {
  _id: string;
  patient_email: string;
  date: string;
  time: string;
  reason: string;
  status: string;
}

type CalendarView = 'month' | 'week' | 'day';

interface AppointmentWithDate extends Appointment {
  parsedDate: Date;
}

const HOURS = Array.from({ length: 13 }, (_, index) => index + 8);

function parseAppointment(date: string, time: string) {
  const parsed = new Date(`${date}T${time || '00:00'}`);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function startOfDay(date: Date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function addDays(date: Date, amount: number) {
  const next = new Date(date);
  next.setDate(next.getDate() + amount);
  return next;
}

function sameDay(left: Date, right: Date) {
  return left.getFullYear() === right.getFullYear() && left.getMonth() === right.getMonth() && left.getDate() === right.getDate();
}

function statusColor(status: string) {
  const normalized = (status || '').toLowerCase();
  if (['accepted', 'confirmed', 'approved'].includes(normalized)) {
    return 'bg-emerald-100 text-emerald-700';
  }
  if (['pending'].includes(normalized)) {
    return 'bg-amber-100 text-amber-700';
  }
  if (['declined', 'cancelled_by_patient', 'cancelled_by_doctor'].includes(normalized)) {
    return 'bg-rose-100 text-rose-700';
  }
  if (['rescheduled'].includes(normalized)) {
    return 'bg-sky-100 text-sky-700';
  }
  return 'bg-slate-100 text-slate-700';
}

function formatDateTime(date: string, time: string) {
  const parsed = new Date(`${date}T${time || '00:00'}`);
  if (Number.isNaN(parsed.getTime())) {
    return `${date} ${time}`;
  }
  return parsed.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

export default function DoctorSchedule() {
  const location = useLocation();
  const doctorEmail = localStorage.getItem('medisync_email') ?? '';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [errorMessage, setErrorMessage] = useState('');
  const [view, setView] = useState<CalendarView>('week');
  const [focusDate, setFocusDate] = useState<Date>(new Date());

  useEffect(() => {
    const load = async () => {
      if (!doctorEmail || !token) {
        setErrorMessage('Please login as doctor first.');
        return;
      }

      try {
        const response = await fetch(`${API_BASE_URL}/appointments/${doctorEmail}`, { headers: { Authorization: token } });
        const result = await response.json() as { appointments?: Appointment[]; error?: string };
        if (!response.ok || result.error) {
          throw new Error(result.error ?? 'Failed to load schedule');
        }
        setAppointments(result.appointments ?? []);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Failed to load schedule';
        setErrorMessage(message);
      }
    };

    load();
  }, [doctorEmail, token]);

  const filtered = useMemo(() => {
    const query = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
    if (!query) {
      return appointments;
    }
    return appointments.filter((appointment) =>
      [appointment.patient_email, appointment.reason, appointment.status, appointment.date, appointment.time]
        .some((value) => value.toLowerCase().includes(query)),
    );
  }, [appointments, location.search]);

  const events = useMemo(() => {
    return filtered
      .map((appointment) => {
        const parsedDate = parseAppointment(appointment.date, appointment.time);
        if (!parsedDate) {
          return null;
        }
        return { ...appointment, parsedDate } as AppointmentWithDate;
      })
      .filter((item): item is AppointmentWithDate => item !== null)
      .sort((left, right) => left.parsedDate.getTime() - right.parsedDate.getTime());
  }, [filtered]);

  const monthCells = useMemo(() => {
    const monthStart = new Date(focusDate.getFullYear(), focusDate.getMonth(), 1);
    const monthStartWeekday = monthStart.getDay();
    const gridStart = addDays(monthStart, -monthStartWeekday);
    return Array.from({ length: 42 }, (_, index) => addDays(gridStart, index));
  }, [focusDate]);

  const weekDays = useMemo(() => {
    const current = startOfDay(focusDate);
    const weekStart = addDays(current, -current.getDay());
    return Array.from({ length: 7 }, (_, index) => addDays(weekStart, index));
  }, [focusDate]);

  const dayEvents = useMemo(
    () => events.filter((eventItem) => sameDay(eventItem.parsedDate, focusDate)),
    [events, focusDate],
  );

  const moveCalendar = (direction: -1 | 1) => {
    if (view === 'month') {
      setFocusDate((previous) => new Date(previous.getFullYear(), previous.getMonth() + direction, 1));
      return;
    }
    if (view === 'week') {
      setFocusDate((previous) => addDays(previous, direction * 7));
      return;
    }
    setFocusDate((previous) => addDays(previous, direction));
  };

  return (
    <DashboardLayout role="doctor">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Schedule</h1>
          <p className="text-slate-500 mt-1">Live appointment schedule from backend.</p>
        </div>

        {errorMessage && <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">{errorMessage}</div>}

        <div className="bg-white border border-slate-100 rounded-2xl p-4 md:p-6 shadow-sm space-y-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <div className="flex items-center gap-2">
              <button onClick={() => moveCalendar(-1)} className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50">
                <ChevronLeft size={18} />
              </button>
              <button onClick={() => moveCalendar(1)} className="p-2 rounded-lg border border-slate-200 hover:bg-slate-50">
                <ChevronRight size={18} />
              </button>
              <button onClick={() => setFocusDate(new Date())} className="px-3 py-2 rounded-lg border border-slate-200 text-sm font-semibold hover:bg-slate-50">
                Today
              </button>
              <p className="text-sm md:text-base font-semibold text-slate-900 ml-1">
                {view === 'month'
                  ? focusDate.toLocaleDateString(undefined, { month: 'long', year: 'numeric' })
                  : focusDate.toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric', year: 'numeric' })}
              </p>
            </div>

            <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl w-fit">
              {(['month', 'week', 'day'] as CalendarView[]).map((mode) => (
                <button
                  key={mode}
                  onClick={() => setView(mode)}
                  className={`px-3 py-1.5 rounded-lg text-sm font-semibold capitalize transition ${
                    view === mode ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  {mode}
                </button>
              ))}
            </div>
          </div>

          {events.length === 0 ? (
            <p className="text-sm text-slate-500">No appointments found.</p>
          ) : view === 'month' ? (
            <div className="grid grid-cols-7 gap-2">
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((day) => (
                <div key={day} className="text-xs font-semibold text-slate-500 px-2 py-1">{day}</div>
              ))}
              {monthCells.map((cellDate) => {
                const isCurrentMonth = cellDate.getMonth() === focusDate.getMonth();
                const isToday = sameDay(cellDate, new Date());
                const dayEventsInCell = events.filter((eventItem) => sameDay(eventItem.parsedDate, cellDate));
                return (
                  <button
                    key={cellDate.toISOString()}
                    onClick={() => {
                      setFocusDate(cellDate);
                      setView('day');
                    }}
                    className={`min-h-[120px] rounded-xl border p-2 text-left transition ${
                      isCurrentMonth ? 'border-slate-100 bg-white' : 'border-slate-100 bg-slate-50'
                    } ${isToday ? 'ring-2 ring-indigo-200' : ''}`}
                  >
                    <p className={`text-xs font-semibold ${isCurrentMonth ? 'text-slate-700' : 'text-slate-400'}`}>
                      {cellDate.getDate()}
                    </p>
                    <div className="mt-2 space-y-1">
                      {dayEventsInCell.slice(0, 3).map((eventItem) => (
                        <div key={eventItem._id} className={`px-2 py-1 rounded text-[11px] ${statusColor(eventItem.status)}`}>
                          {eventItem.time} • {eventItem.patient_email.split('@')[0]}
                        </div>
                      ))}
                      {dayEventsInCell.length > 3 && (
                        <p className="text-[11px] text-slate-500">+{dayEventsInCell.length - 3} more</p>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          ) : view === 'week' ? (
            <div className="overflow-x-auto">
              <div className="min-w-[900px]">
                <div className="grid grid-cols-8 gap-2 text-xs font-semibold text-slate-500 mb-2">
                  <div className="px-2 py-1">Time</div>
                  {weekDays.map((day) => (
                    <div key={day.toISOString()} className="px-2 py-1 text-center">
                      {day.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' })}
                    </div>
                  ))}
                </div>
                <div className="space-y-2">
                  {HOURS.map((hour) => (
                    <div key={hour} className="grid grid-cols-8 gap-2">
                      <div className="text-xs text-slate-500 px-2 py-3">{hour}:00</div>
                      {weekDays.map((day) => {
                        const cellEvents = events.filter((eventItem) => sameDay(eventItem.parsedDate, day) && eventItem.parsedDate.getHours() === hour);
                        return (
                          <div key={`${day.toISOString()}-${hour}`} className="min-h-[72px] border border-slate-100 rounded-lg p-1.5 bg-slate-50/50">
                            {cellEvents.map((eventItem) => (
                              <div key={eventItem._id} className={`px-2 py-1 rounded text-[11px] mb-1 ${statusColor(eventItem.status)}`}>
                                <p className="font-semibold">{eventItem.time}</p>
                                <p>{eventItem.patient_email.split('@')[0]}</p>
                              </div>
                            ))}
                          </div>
                        );
                      })}
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <div className="space-y-3">
              {dayEvents.length === 0 ? (
                <p className="text-sm text-slate-500">No appointments on this day.</p>
              ) : (
                dayEvents.map((eventItem) => (
                  <div key={eventItem._id} className="p-4 rounded-xl border border-slate-100">
                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <p className="font-semibold text-slate-900 flex items-center gap-2"><User size={14} /> {eventItem.patient_email.split('@')[0]}</p>
                        <p className="text-sm text-slate-600 mt-1">{eventItem.reason}</p>
                      </div>
                      <span className={`text-xs px-2.5 py-1 rounded-lg capitalize ${statusColor(eventItem.status)}`}>{eventItem.status}</span>
                    </div>
                    <p className="text-sm text-slate-600 mt-2 inline-flex items-center gap-2"><Calendar size={14} /> {formatDateTime(eventItem.date, eventItem.time)}</p>
                    <p className="text-sm text-slate-600 mt-1 inline-flex items-center gap-2"><Clock size={14} /> {eventItem.time}</p>
                  </div>
                ))
              )}
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
