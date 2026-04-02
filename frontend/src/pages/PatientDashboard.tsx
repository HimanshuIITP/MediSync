import { useEffect, useMemo, useState } from 'react';
import DashboardLayout from '../components/DashboardLayout';
import { Calendar, Stethoscope, Activity, FileText, Pill, Clock, AlertCircle, ChevronRight, Download } from 'lucide-react';
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

interface PatientReport {
  _id: string;
  patient_email: string;
  file_url: string;
  file_name: string;
  type: string;
}

interface PreconsultReport {
  _id: string;
  patient_email: string;
  doctor_email: string;
  appointment_id: string;
  summary: string;
  status: string;
}

interface MedicationItem {
  id: string;
  name: string;
  dose: string;
  timing: string;
  status: string;
  doctor: {
    name: string;
    email: string;
    specialization: string;
  };
  appointment: {
    id: string;
    date: string;
    time: string;
    reason: string;
    status: string;
  };
  report_id: string;
}

const ACCEPTED_STATUSES = new Set(['accepted', 'confirmed', 'approved']);

function isAcceptedAppointment(status: string) {
  return ACCEPTED_STATUSES.has((status || '').toLowerCase());
}

function toAppointmentTimestamp(date: string, time: string) {
  const parsed = new Date(`${date}T${time || '00:00'}`);
  return Number.isNaN(parsed.getTime()) ? 0 : parsed.getTime();
}

function formatAppointmentDate(value: string) {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return value;
  }
  return parsed.toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' });
}

function formatAppointmentTime(value: string) {
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

export default function PatientDashboard() {
  const navigate = useNavigate();
  const patientEmail = localStorage.getItem('medisync_email') ?? '';
  const displayName = localStorage.getItem('medisync_name') || patientEmail.split('@')[0] || 'Patient';
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [reports, setReports] = useState<PatientReport[]>([]);
  const [preconsultReports, setPreconsultReports] = useState<PreconsultReport[]>([]);
  const [medications, setMedications] = useState<MedicationItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');

  const previousVisits = useMemo(
    () => appointments.filter((appointment) => appointment.status !== 'pending').slice(0, 3),
    [appointments],
  );

  const upcomingAppointments = useMemo(() => {
    const now = Date.now();
    return appointments
      .filter((appointment) => isAcceptedAppointment(appointment.status))
      .filter((appointment) => toAppointmentTimestamp(appointment.date, appointment.time) >= now)
      .sort((left, right) => toAppointmentTimestamp(left.date, left.time) - toAppointmentTimestamp(right.date, right.time))
      .slice(0, 5);
  }, [appointments]);

  const pendingPreconsultAppointment = useMemo(() => {
    const reportKeys = new Set(preconsultReports.map((report) => `${report.appointment_id}:${report.doctor_email}`));
    return upcomingAppointments.find((appointment) => !reportKeys.has(`${appointment._id}:${appointment.doctor_email}`)) ?? null;
  }, [preconsultReports, upcomingAppointments]);

  const preconsultStatusByAppointment = useMemo(() => {
    const reportKeys = new Set(preconsultReports.map((report) => `${report.appointment_id}:${report.doctor_email}`));
    return new Map(
      upcomingAppointments.map((appointment) => {
        const key = `${appointment._id}:${appointment.doctor_email}`;
        return [appointment._id, reportKeys.has(key) ? 'Done' : 'Not done'] as const;
      }),
    );
  }, [preconsultReports, upcomingAppointments]);

  useEffect(() => {
    if (!patientEmail) {
      setErrorMessage('Please login again to load your dashboard data.');
      setIsLoading(false);
      return;
    }

    const loadDashboardData = async () => {
      try {
        const [appointmentsResponse, reportsResponse, preconsultsResponse, medicationsResponse] = await Promise.all([
          fetch(`${API_BASE_URL}/patient/appointments/${patientEmail}`),
          fetch(`${API_BASE_URL}/patient/reports/${patientEmail}`),
          fetch(`${API_BASE_URL}/patient/preconsults/${patientEmail}`),
          fetch(`${API_BASE_URL}/patient/medications/${patientEmail}`),
        ]);

        if (!appointmentsResponse.ok || !reportsResponse.ok || !medicationsResponse.ok) {
          throw new Error('Unable to fetch dashboard data from backend.');
        }

        const appointmentsResult = (await appointmentsResponse.json()) as { appointments?: Appointment[] };
        const reportsResult = (await reportsResponse.json()) as { reports?: PatientReport[] };
        const preconsultsResult = (await preconsultsResponse.json()) as { preconsults?: PreconsultReport[] };
        const medicationsResult = (await medicationsResponse.json()) as { medications?: MedicationItem[] };

        setAppointments(appointmentsResult.appointments ?? []);
        setReports(reportsResult.reports ?? []);
        setPreconsultReports(preconsultsResult.preconsults ?? []);
        setMedications(medicationsResult.medications ?? []);
        setErrorMessage('');
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unable to load patient data';
        setErrorMessage(message);
      } finally {
        setIsLoading(false);
      }
    };

    loadDashboardData();
    const intervalId = window.setInterval(loadDashboardData, 15000);
    return () => window.clearInterval(intervalId);
  }, [patientEmail]);

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6">
        <div className="flex justify-between items-end">
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Good Morning, {displayName}!</h1>
            <p className="text-slate-500 mt-1">Here is your health overview for today.</p>
          </div>
          <button
            onClick={() => navigate('/patient-dashboard/appointments')}
            className="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-xl font-medium shadow-sm shadow-indigo-200 transition flex items-center space-x-2"
          >
            <Calendar size={18} />
            <span>Book Appointment</span>
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-gradient-to-r from-indigo-500 to-purple-600 rounded-3xl p-8 text-white relative overflow-hidden shadow-lg shadow-indigo-200/50">
              <div className="relative z-10 flex justify-between items-center">
                <div className="max-w-md">
                  <span className="bg-white/20 px-3 py-1 rounded-full text-xs font-semibold backdrop-blur-sm tracking-wide uppercase">New Feature</span>
                  <h2 className="text-2xl font-bold mt-4 mb-2">AI Pre-Consultation</h2>
                  <p className="text-indigo-100 text-sm mb-6 leading-relaxed">
                    Save time during your next visit. Tell our AI about your symptoms to generate a pre-consultation report for your doctor.
                  </p>
                  <button
                    onClick={() => navigate('/patient-dashboard/appointments')}
                    className="bg-white text-indigo-600 px-6 py-3 rounded-full font-bold shadow-sm hover:shadow-md transition flex items-center space-x-2 text-sm"
                  >
                    <Activity size={18} />
                    <span>Let&apos;s Book an Appointment</span>
                  </button>
                </div>
                <div className="hidden md:block">
                  <div className="w-32 h-32 bg-white/10 rounded-full flex items-center justify-center backdrop-blur-md border border-white/20">
                    <Activity size={64} className="text-white" />
                  </div>
                </div>
              </div>
              <div className="absolute -top-24 -right-24 w-64 h-64 bg-white/10 rounded-full blur-3xl"></div>
              <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-black/10 rounded-full blur-3xl"></div>
            </div>

            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-slate-900">Upcoming Appointments</h3>
                <button className="text-sm text-indigo-600 font-semibold hover:underline">View All</button>
              </div>

              {pendingPreconsultAppointment && (
                <button
                  onClick={() => navigate(`/patient-dashboard/ai-consult?appointment_id=${encodeURIComponent(pendingPreconsultAppointment._id)}&doctor_email=${encodeURIComponent(pendingPreconsultAppointment.doctor_email)}`)}
                  className="w-full mb-4 text-left rounded-2xl border border-indigo-200 bg-indigo-50/80 p-4 hover:bg-indigo-100 transition"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-wide text-indigo-600">Pre-consult Ready</p>
                      <h4 className="font-bold text-slate-900 mt-1">Take pre consultation with Dr. {pendingPreconsultAppointment.doctor_email.split('@')[0]}</h4>
                      <p className="text-sm text-slate-600 mt-1">{pendingPreconsultAppointment.reason}</p>
                    </div>
                    <div className="text-right text-sm text-indigo-700 font-semibold">
                      Open AI Consult
                    </div>
                  </div>
                </button>
              )}

              <div className="space-y-4">
                {upcomingAppointments.map((item) => (
                  <div key={item._id} className="flex items-center justify-between p-4 rounded-2xl border border-slate-100 hover:border-indigo-100 hover:bg-indigo-50/50 transition">
                    <div className="flex items-center space-x-4">
                      <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-xl flex items-center justify-center">
                        <Stethoscope size={24} />
                      </div>
                      <div>
                        <h4 className="font-bold text-slate-900">Dr. {item.doctor_email.split('@')[0]}</h4>
                        <p className="text-sm text-slate-500">{item.reason}</p>
                        <p className={`text-xs mt-1 font-semibold ${preconsultStatusByAppointment.get(item._id) === 'Done' ? 'text-emerald-600' : 'text-amber-600'}`}>
                          Pre-consult: {preconsultStatusByAppointment.get(item._id) ?? 'Not done'}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="flex items-center space-x-1 text-slate-700 font-medium">
                        <Calendar size={14} className="text-slate-400" />
                        <span>{formatAppointmentDate(item.date)}</span>
                      </div>
                      <div className="flex items-center justify-end space-x-1 text-sm text-slate-500 mt-1">
                        <Clock size={14} />
                        <span>{formatAppointmentTime(item.time)}</span>
                      </div>
                    </div>
                  </div>
                ))}
                {!isLoading && upcomingAppointments.length === 0 && (
                  <p className="text-sm text-slate-500">No accepted upcoming appointments yet.</p>
                )}
              </div>
            </div>

            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-bold text-slate-900">Medical Reports & Scans</h3>
                <span className="text-xs font-semibold bg-emerald-100 text-emerald-700 px-2.5 py-1 rounded-md">Uploaded Reports</span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {reports.slice(0, 4).map((report) => (
                  <a
                    key={report._id}
                    href={report.file_url}
                    target="_blank"
                    rel="noreferrer"
                    className="border border-slate-100 rounded-2xl p-4 flex items-start space-x-4 hover:shadow-md transition cursor-pointer"
                  >
                    <div className="bg-sky-100 p-3 rounded-xl text-sky-600">
                      <FileText size={24} />
                    </div>
                    <div className="flex-1">
                      <h4 className="font-bold text-slate-900 text-sm">{report.file_name}</h4>
                      <p className="text-xs text-slate-500 mt-1">{report.type}</p>
                      <div className="flex items-center space-x-2 mt-3 text-sky-600 text-xs font-semibold">
                        <Download size={14} />
                        <span>Open Report</span>
                      </div>
                    </div>
                  </a>
                ))}
                {!isLoading && reports.length === 0 && (
                  <p className="text-sm text-slate-500">No reports uploaded for this patient yet.</p>
                )}
              </div>
            </div>
          </div>

          <div className="space-y-6">
            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center">
                <Pill className="mr-2 text-indigo-500" size={20} />
                Current Medications
              </h3>

              <div className="space-y-4">
                {medications.length === 0 ? (
                  <p className="text-sm text-slate-500">No medication guidance found yet. It will appear after a doctor completes a pre-consult report or adds a prescription.</p>
                ) : medications.map((medication) => (
                  <div key={medication.id} className="bg-slate-50 rounded-2xl p-4 border border-slate-100 space-y-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <h4 className="font-bold text-slate-900">{medication.name}</h4>
                        <p className="text-xs text-slate-500 mt-1">{medication.dose}</p>
                      </div>
                      <span className={`text-xs font-bold px-2 py-1 rounded-lg ${medication.status === 'active' ? 'bg-emerald-100 text-emerald-700' : medication.status === 'completed' ? 'bg-sky-100 text-sky-700' : medication.status === 'changed' ? 'bg-amber-100 text-amber-700' : 'bg-rose-100 text-rose-700'}`}>
                        {medication.status}
                      </span>
                    </div>
                    <div className="text-xs text-slate-600 space-y-1">
                      <p className="flex items-start gap-2"><AlertCircle size={14} className="mt-0.5 text-amber-500" /> <span>{medication.timing}</span></p>
                      <p>Doctor: {medication.doctor.name} ({medication.doctor.specialization})</p>
                      <p>Visit: {medication.appointment.date} at {medication.appointment.time}</p>
                    </div>
                    <button
                      onClick={() => navigate(`/patient-dashboard/ai-consult?appointment_id=${encodeURIComponent(medication.appointment.id)}&doctor_email=${encodeURIComponent(medication.doctor.email)}`)}
                      className="inline-flex items-center gap-2 text-sm font-semibold text-indigo-600 hover:text-indigo-700"
                    >
                      View prescription <ChevronRight size={16} />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
              <h3 className="text-lg font-bold text-slate-900 mb-4 flex items-center">
                <Clock className="mr-2 text-indigo-500" size={20} />
                Previous Visits
              </h3>

              <div className="relative pl-4 border-l-2 border-indigo-100 space-y-6 pb-4">
                {previousVisits.map((appointment) => (
                  <div key={appointment._id} className="relative">
                    <div className="absolute -left-[21px] top-1 w-3 h-3 bg-white border-2 border-indigo-500 rounded-full"></div>
                    <h4 className="font-bold text-slate-900 text-sm">{appointment.reason || 'Visit'}</h4>
                    <p className="text-xs text-slate-500 mt-1 mb-2">Dr. {appointment.doctor_email.split('@')[0]} • {formatAppointmentDate(appointment.date)}</p>
                    <button className="text-xs text-indigo-600 font-semibold flex items-center hover:underline">
                      View summary <ChevronRight size={14} />
                    </button>
                  </div>
                ))}
                {!isLoading && previousVisits.length === 0 && (
                  <p className="text-xs text-slate-500">Previous visits will appear here when completed appointments are available.</p>
                )}
              </div>
            </div>

            {errorMessage && (
              <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">
                {errorMessage}
              </div>
            )}

            {isLoading && (
              <div className="bg-indigo-50 border border-indigo-100 rounded-2xl p-4 text-sm text-indigo-700">
                Syncing dashboard with backend...
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
