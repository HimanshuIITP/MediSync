import { useCallback, useEffect, useMemo, useState } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import { Calendar, User, Activity, FileText, Clock, FileWarning, Eye, Search, Filter } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface Appointment {
  _id: string;
  patient_email: string;
  doctor_email: string;
  date: string;
  time: string;
  reason: string;
  status: string;
}

interface DoctorPreConsult {
  id: string;
  status: string;
  date: string;
  appointment_id?: string;
  appointment?: {
    id?: string;
    date?: string;
    time?: string;
    reason?: string;
    status?: string;
  };
  doctor?: {
    specialization?: string;
  };
  patient: {
    name: string;
    email: string;
  };
}

function formatTime(value: string) {
  const match = value.match(/^(\d{1,2}):(\d{2})$/);
  if (!match) {
    return value;
  }
  const hours = Number(match[1]);
  const minutes = match[2];
  const suffix = hours >= 12 ? 'PM' : 'AM';
  const normalized = hours % 12 === 0 ? 12 : hours % 12;
  return `${normalized}:${minutes} ${suffix}`;
}

function toTimestamp(date: string, time: string) {
  const parsed = new Date(`${date}T${time || '00:00'}`);
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime();
}

function formatDate(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString(undefined, { year: 'numeric', month: '2-digit', day: '2-digit' });
}

function isScheduledStatus(status: string) {
  const normalized = (status || '').toLowerCase();
  return !['declined', 'cancelled_by_doctor', 'cancelled_by_patient', 'rejected'].includes(normalized);
}

function isConfirmedScheduleStatus(status: string) {
  const normalized = (status || '').toLowerCase();
  return ['accepted', 'confirmed', 'approved', 'completed', 'rescheduled'].includes(normalized);
}

export default function DoctorDashboard() {
  const navigate = useNavigate();
  const doctorEmail = localStorage.getItem('medisync_email') ?? '';
  const doctorName = localStorage.getItem('medisync_name') ?? doctorEmail.split('@')[0] ?? 'Doctor';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [preconsults, setPreconsults] = useState<DoctorPreConsult[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [actionMessage, setActionMessage] = useState('');
  const [popupPendingRequest, setPopupPendingRequest] = useState<Appointment | null>(null);
  const [dismissedPendingIds, setDismissedPendingIds] = useState<string[]>([]);

  const todayDate = new Date().toISOString().slice(0, 10);
  const todayLabel = new Date().toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });

  const todaysAppointments = useMemo(
    () => appointments
      .filter((appointment) => appointment.date === todayDate)
      .filter((appointment) => isScheduledStatus(appointment.status))
      .filter((appointment) => isConfirmedScheduleStatus(appointment.status))
      .sort((left, right) => toTimestamp(left.date, left.time) - toTimestamp(right.date, right.time)),
    [appointments, todayDate],
  );

  const pendingAppointments = useMemo(
    () => appointments
      .filter((appointment) => (appointment.status || '').toLowerCase() === 'pending')
      .sort((left, right) => toTimestamp(left.date, left.time) - toTimestamp(right.date, right.time)),
    [appointments],
  );

  const filteredTodaysAppointments = useMemo(() => {
    const query = searchTerm.trim().toLowerCase();
    if (!query) {
      return todaysAppointments;
    }
    return todaysAppointments.filter((appointment) => {
      const patientName = appointment.patient_email.split('@')[0];
      return [patientName, appointment.patient_email, appointment.reason]
        .some((value) => value.toLowerCase().includes(query));
    });
  }, [searchTerm, todaysAppointments]);

  const todayCount = useMemo(
    () => todaysAppointments.length,
    [todaysAppointments],
  );

  const readyPreconsults = useMemo(
    () => preconsults.filter((item) => (item.status || '').toLowerCase() === 'ready'),
    [preconsults],
  );

  const recentReports = useMemo(() => {
    const source = readyPreconsults.length > 0 ? readyPreconsults : preconsults;
    return source.slice(0, 3).map((report, index) => ({
      id: report.id,
      appointmentId: report.appointment_id || report.appointment?.id || '',
      patient: report.patient?.name || report.patient?.email?.split('@')[0] || 'Patient',
      patientEmail: report.patient?.email || '',
      type: report.appointment?.reason || 'Pre-consult report',
      dept: report.doctor?.specialization || 'General',
      date: formatDate(report.appointment?.date || report.date),
      urgent: (report.status || '').toLowerCase() === 'ready' && index === 0,
    }));
  }, [preconsults, readyPreconsults]);

  const weeklyStats = useMemo(() => {
    const now = new Date();
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(now.getDate() - 7);

    const weeklyAppointments = appointments.filter((appointment) => {
      const timestamp = toTimestamp(appointment.date, appointment.time);
      return timestamp >= sevenDaysAgo.getTime() && timestamp <= now.getTime();
    });

    const seenPatients = new Set(
      weeklyAppointments
        .filter((appointment) => ['accepted', 'confirmed', 'approved', 'completed'].includes((appointment.status || '').toLowerCase()))
        .map((appointment) => appointment.patient_email),
    ).size;

    const pendingRequests = weeklyAppointments.filter(
      (appointment) => (appointment.status || '').toLowerCase() === 'pending',
    ).length;

    const acceptedAppointments = weeklyAppointments.filter(
      (appointment) => ['accepted', 'confirmed', 'approved', 'completed'].includes((appointment.status || '').toLowerCase()),
    ).length;

    const totalWeeklyAppointments = weeklyAppointments.length;
    const acceptedRatio = totalWeeklyAppointments > 0 ? Math.round((acceptedAppointments / totalWeeklyAppointments) * 100) : 0;
    const pendingRatio = totalWeeklyAppointments > 0 ? Math.round((pendingRequests / totalWeeklyAppointments) * 100) : 0;

    return {
      seenPatients,
      pendingRequests,
      acceptedRatio,
      pendingRatio,
    };
  }, [appointments]);

  useEffect(() => {
    const activePopupIsStillPending = popupPendingRequest
      ? pendingAppointments.some((item) => item._id === popupPendingRequest._id)
      : false;

    if (activePopupIsStillPending) {
      return;
    }

    const nextPending = pendingAppointments.find((item) => !dismissedPendingIds.includes(item._id));
    setPopupPendingRequest(nextPending ?? null);
  }, [pendingAppointments, popupPendingRequest, dismissedPendingIds]);

  const loadDashboardData = useCallback(async () => {
    try {
      const [appointmentsResponse, preconsultsResponse] = await Promise.all([
        fetch(`${API_BASE_URL}/appointments/${doctorEmail}`, {
          headers: { Authorization: token },
        }),
        fetch(`${API_BASE_URL}/doctor/preconsults/${doctorEmail}`, {
          headers: { Authorization: token },
        }),
      ]);

      if (!appointmentsResponse.ok || !preconsultsResponse.ok) {
        throw new Error('Failed to load doctor dashboard data.');
      }

      const appointmentsResult = (await appointmentsResponse.json()) as { appointments?: Appointment[]; error?: string };
      const preconsultsResult = (await preconsultsResponse.json()) as { preconsults?: DoctorPreConsult[]; error?: string };
      if (appointmentsResult.error || preconsultsResult.error) {
        throw new Error(appointmentsResult.error ?? preconsultsResult.error ?? 'Unable to load dashboard data');
      }

      setAppointments(appointmentsResult.appointments ?? []);
      setPreconsults(preconsultsResult.preconsults ?? []);
      setErrorMessage('');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to fetch dashboard data';
      setErrorMessage(message);
    }
  }, [doctorEmail, token]);

  useEffect(() => {
    if (!doctorEmail || !token) {
      setErrorMessage('Please login as doctor to load schedule from backend.');
      return;
    }

    loadDashboardData();
    const intervalId = window.setInterval(loadDashboardData, 15000);
    return () => window.clearInterval(intervalId);
  }, [doctorEmail, token, loadDashboardData]);

  const handleAppointmentAction = async (appointment: Appointment, action: 'accept' | 'decline' | 'cancel' | 'reschedule') => {
    if (!token) {
      setErrorMessage('Please login again as doctor.');
      return;
    }

    let date = '';
    let time = '';
    if (action === 'reschedule') {
      date = window.prompt('Enter new date (YYYY-MM-DD):', appointment.date) ?? '';
      time = window.prompt('Enter new time (HH:MM):', appointment.time) ?? '';
      if (!date || !time) {
        return;
      }
    }

    try {
      const response = await fetch(`${API_BASE_URL}/appointments/${appointment._id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
        body: JSON.stringify({ action, date, time }),
      });

      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Appointment update failed');
      }

      setActionMessage(`Appointment ${action}ed successfully.`);
      setDismissedPendingIds((current) => current.filter((id) => id !== appointment._id));
      if (popupPendingRequest?._id === appointment._id) {
        setPopupPendingRequest(null);
      }
      await loadDashboardData();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Appointment update failed';
      setErrorMessage(message);
    }
  };

  return (
    <DashboardLayout role="doctor">
      <div className="space-y-6">
        
        {/* Header section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Welcome, Dr. {doctorName}!</h1>
            <p className="text-slate-500 mt-1">You have {todayCount} appointments scheduled for today.</p>
          </div>
          <div className="flex items-center space-x-3 bg-white p-2 rounded-xl shadow-sm border border-slate-100">
             <div className="flex items-center px-4 py-2 bg-indigo-50 text-indigo-700 rounded-lg font-medium text-sm">
               <Calendar size={16} className="mr-2" />
               Today: {todayLabel}
             </div>
             <button className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-50 rounded-lg transition">
               <Filter size={18} />
             </button>
          </div>
        </div>

        {/* Dashboard Grid */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          
          {/* Main Content - Schedule */}
          <div className="xl:col-span-2 space-y-6">
            
            {/* AI Banner */}
            <div className="bg-indigo-600 rounded-3xl p-6 text-white flex items-center justify-between shadow-lg shadow-indigo-200">
               <div className="flex items-center space-x-4">
                 <div className="p-3 bg-white/20 rounded-xl backdrop-blur-sm">
                   <Activity size={28} className="text-white" />
                 </div>
                 <div>
                   <h3 className="font-bold text-lg">AI Pre-Consultations are ready</h3>
                   <p className="text-indigo-100 text-sm mt-1">{readyPreconsults.length} patient{readyPreconsults.length === 1 ? '' : 's'} completed symptom checks. Review to save time.</p>
                 </div>
               </div>
               <button
                onClick={() => navigate('/doctor-dashboard/pre-consults')}
                className="hidden md:block px-5 py-2.5 bg-white text-indigo-600 rounded-full font-bold text-sm hover:shadow-md transition"
              >
                 Review All
               </button>
            </div>

            {/* Today's Appointments */}
            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-slate-900">Pending Booking Requests</h3>
                <span className="text-xs font-semibold bg-amber-100 text-amber-700 px-2 py-1 rounded-md">{pendingAppointments.length} Pending</span>
              </div>

              <div className="space-y-4 mb-8">
                {pendingAppointments.slice(0, 5).map((apt) => (
                  <div key={`pending-${apt._id}`} className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 rounded-2xl border border-amber-100 bg-amber-50/50 gap-4">
                    <div>
                      <h4 className="font-bold text-slate-900">{apt.patient_email.split('@')[0]}</h4>
                      <p className="text-xs text-slate-600 mt-1">{apt.reason}</p>
                      <p className="text-xs text-slate-500 mt-1">{apt.date} at {formatTime(apt.time)}</p>
                    </div>
                    <div className="flex items-center gap-2">
                      <button
                        onClick={() => handleAppointmentAction(apt, 'accept')}
                        className="px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-bold hover:bg-emerald-100 transition"
                      >
                        Approve
                      </button>
                      <button
                        onClick={() => handleAppointmentAction(apt, 'decline')}
                        className="px-3 py-1.5 bg-rose-50 text-rose-700 rounded-lg text-xs font-bold hover:bg-rose-100 transition"
                      >
                        Reject
                      </button>
                    </div>
                  </div>
                ))}
                {pendingAppointments.length === 0 && (
                  <p className="text-sm text-slate-500">No pending booking requests.</p>
                )}
              </div>

              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-slate-900">Today's Schedule</h3>
                <div className="relative">
                  <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    value={searchTerm}
                    onChange={(event) => setSearchTerm(event.target.value)}
                    placeholder="Search patient..."
                    className="pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              <div className="space-y-4">
                {filteredTodaysAppointments.map((apt) => (
                  <div key={apt._id} className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 rounded-2xl border border-slate-100 hover:border-indigo-100 hover:bg-slate-50 transition gap-4">
                    <div className="flex items-center space-x-4 w-full sm:w-auto">
                      <div className="w-12 h-12 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center font-bold text-lg border border-indigo-100">
                        {apt.patient_email.charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <h4 className="font-bold text-slate-900">{apt.patient_email.split('@')[0]}</h4>
                        <div className="flex items-center text-xs text-slate-500 mt-1 space-x-3">
                           <span className="flex items-center"><Clock size={12} className="mr-1" /> {formatTime(apt.time)}</span>
                           <span className="flex items-center"><User size={12} className="mr-1" /> {apt.reason}</span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-3 w-full sm:w-auto justify-end">
                      <span className="text-xs text-slate-600 px-3 py-1.5 border border-slate-200 rounded-lg bg-slate-50 capitalize">
                        {apt.status}
                      </span>
                      {apt.status === 'pending' && (
                        <>
                          <button
                            onClick={() => handleAppointmentAction(apt, 'accept')}
                            className="px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-bold hover:bg-emerald-100 transition"
                          >
                            Accept
                          </button>
                          <button
                            onClick={() => handleAppointmentAction(apt, 'decline')}
                            className="px-3 py-1.5 bg-rose-50 text-rose-700 rounded-lg text-xs font-bold hover:bg-rose-100 transition"
                          >
                            Decline
                          </button>
                        </>
                      )}
                      {(apt.status === 'accepted' || apt.status === 'confirmed' || apt.status === 'approved') && (
                        <>
                          <button
                            onClick={() => handleAppointmentAction(apt, 'reschedule')}
                            className="px-3 py-1.5 bg-amber-50 text-amber-700 rounded-lg text-xs font-bold hover:bg-amber-100 transition"
                          >
                            Reschedule
                          </button>
                          <button
                            onClick={() => handleAppointmentAction(apt, 'cancel')}
                            className="px-3 py-1.5 bg-rose-50 text-rose-700 rounded-lg text-xs font-bold hover:bg-rose-100 transition"
                          >
                            Cancel
                          </button>
                        </>
                      )}
                    </div>
                  </div>
                ))}
                {filteredTodaysAppointments.length === 0 && (
                  <p className="text-sm text-slate-500">No scheduled appointments found for today.</p>
                )}
              </div>
            </div>
          </div>

          {/* Right Column - Reports & Analytics */}
          <div className="space-y-6">
            
            {/* Newly Uploaded Reports */}
            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-slate-900 flex items-center">
                  <FileText className="mr-2 text-indigo-500" size={20} />
                  New Reports
                </h3>
                <span className="bg-rose-100 text-rose-600 text-xs font-bold px-2 py-0.5 rounded-full">{recentReports.length} New</span>
              </div>
              
              <div className="space-y-4">
                {recentReports.map((report) => (
                  <div key={report.id} className="p-4 rounded-2xl border border-slate-100 bg-slate-50 hover:bg-white transition relative overflow-hidden group">
                    {report.urgent && (
                       <div className="absolute top-0 right-0 w-2 h-full bg-rose-500"></div>
                    )}
                    <div className="flex justify-between items-start mb-2">
                      <div>
                        <h4 className="font-bold text-slate-900 text-sm flex items-center">
                          {report.patient}
                          {report.urgent && <FileWarning size={14} className="ml-2 text-rose-500" />}
                        </h4>
                        <p className="text-xs text-slate-500 mt-0.5">{report.type}</p>
                      </div>
                      <span className="text-[10px] text-slate-400 font-medium">{report.date}</span>
                    </div>
                    
                    <div className="flex items-center justify-between mt-4">
                      <span className="text-xs bg-slate-200 text-slate-600 px-2 py-1 rounded-md font-medium">
                        {report.dept} Dept
                      </span>
                      <button
                        onClick={() => navigate(`/doctor-dashboard/pre-consults?q=${encodeURIComponent(report.appointmentId || report.id || report.patientEmail)}`)}
                        className="text-indigo-600 text-xs font-bold flex items-center opacity-0 group-hover:opacity-100 transition"
                      >
                        <Eye size={14} className="mr-1" /> View
                      </button>
                    </div>
                  </div>
                ))}
                {recentReports.length === 0 && (
                  <p className="text-sm text-slate-500">No pre-consult reports available yet.</p>
                )}
              </div>
              <button
                onClick={() => navigate('/doctor-dashboard/pre-consults')}
                className="w-full mt-4 py-2 border border-slate-200 rounded-xl text-sm font-bold text-slate-600 hover:bg-slate-50 transition"
              >
                View All Records
              </button>
              {errorMessage && (
                <p className="mt-3 text-xs text-rose-600">{errorMessage}</p>
              )}
              {actionMessage && (
                <p className="mt-1 text-xs text-emerald-600">{actionMessage}</p>
              )}
            </div>

            <div className="bg-slate-900 rounded-3xl p-6 shadow-sm text-white">
               <h3 className="text-lg font-bold mb-4">Weekly Overview</h3>
               <div className="space-y-4">
                 <div className="flex justify-between items-center">
                   <span className="text-slate-400 text-sm">Total Patients Seen</span>
                   <span className="font-bold text-lg">{weeklyStats.seenPatients}</span>
                 </div>
                 <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                   <div className="bg-indigo-500 h-full" style={{ width: `${weeklyStats.acceptedRatio}%` }}></div>
                 </div>
                 
                 <div className="flex justify-between items-center mt-2">
                   <span className="text-slate-400 text-sm">Pending Requests</span>
                   <span className="font-bold text-lg">{weeklyStats.pendingRequests}</span>
                 </div>
                 <div className="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                   <div className="bg-emerald-500 h-full" style={{ width: `${weeklyStats.pendingRatio}%` }}></div>
                 </div>
               </div>
            </div>

          </div>
        </div>
      </div>

      {popupPendingRequest && (
        <div className="fixed right-6 bottom-6 z-30 w-full max-w-sm bg-white border border-slate-200 rounded-2xl shadow-xl p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-amber-600">New Booking Request</p>
          <h4 className="font-bold text-slate-900 mt-1">{popupPendingRequest.patient_email.split('@')[0]}</h4>
          <p className="text-sm text-slate-600 mt-1">{popupPendingRequest.reason}</p>
          <p className="text-xs text-slate-500 mt-1">{popupPendingRequest.date} at {formatTime(popupPendingRequest.time)}</p>
          <div className="flex items-center gap-2 mt-3">
            <button
              onClick={() => handleAppointmentAction(popupPendingRequest, 'accept')}
              className="px-3 py-1.5 bg-emerald-50 text-emerald-700 rounded-lg text-xs font-bold hover:bg-emerald-100 transition"
            >
              Approve
            </button>
            <button
              onClick={() => handleAppointmentAction(popupPendingRequest, 'decline')}
              className="px-3 py-1.5 bg-rose-50 text-rose-700 rounded-lg text-xs font-bold hover:bg-rose-100 transition"
            >
              Reject
            </button>
            <button
              onClick={() => {
                setDismissedPendingIds((current) => [...current, popupPendingRequest._id]);
                setPopupPendingRequest(null);
              }}
              className="ml-auto text-xs font-semibold text-slate-500 hover:text-slate-700"
            >
              Dismiss
            </button>
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}
