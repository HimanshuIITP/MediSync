import { useEffect, useMemo, useState } from 'react';
import { Stethoscope, Mail, CalendarDays, FileText, ClipboardList } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface DoctorProfile {
  id: string;
  name: string;
  email: string;
  specialization: string;
}

interface Appointment {
  id: string;
  date: string;
  time: string;
  status: string;
  reason: string;
  doctor_notes?: string | null;
  prescription?: string | null;
  follow_up?: string | null;
}

interface DoctorSummary {
  doctor: DoctorProfile;
  previous_appointment: Appointment | null;
  next_appointment: Appointment | null;
  latest_doctor_notes: string | null;
  latest_prescription: string | null;
  appointments: Appointment[];
}

function formatDateTime(date: string, time: string) {
  const parsed = new Date(`${date}T${time || '00:00'}`);
  if (Number.isNaN(parsed.getTime())) {
    return `${date} ${time}`.trim();
  }
  return parsed.toLocaleString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  });
}

function sortAppointmentsDescending(appointments: Appointment[]) {
  return [...appointments].sort((left, right) => {
    const leftDate = new Date(`${left.date}T${left.time || '00:00'}`).getTime();
    const rightDate = new Date(`${right.date}T${right.time || '00:00'}`).getTime();
    return rightDate - leftDate;
  });
}

export default function PatientDoctors() {
  const location = useLocation();
  const patientEmail = localStorage.getItem('medisync_email') ?? '';
  const [doctorSummaries, setDoctorSummaries] = useState<DoctorSummary[]>([]);
  const [selectedDoctorEmail, setSelectedDoctorEmail] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');

  useEffect(() => {
    const loadData = async () => {
      if (!patientEmail) {
        setErrorMessage('Please login as patient first.');
        setIsLoading(false);
        return;
      }

      try {
        const response = await fetch(`${API_BASE_URL}/patient/doctors/${patientEmail}`);

        if (!response.ok) {
          throw new Error('Failed to fetch doctor summaries.');
        }

        const result = (await response.json()) as { doctors?: DoctorSummary[] };
        const summaries = result.doctors ?? [];
        setDoctorSummaries(summaries);

        if (summaries.length > 0) {
          setSelectedDoctorEmail(summaries[0].doctor.email);
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unable to load doctors';
        setErrorMessage(message);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [patientEmail]);

  const selectedDoctor = useMemo(
    () => doctorSummaries.find((summary) => summary.doctor.email === selectedDoctorEmail) ?? null,
    [doctorSummaries, selectedDoctorEmail],
  );

  const filteredDoctorSummaries = useMemo(() => {
    const query = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
    if (!query) {
      return doctorSummaries;
    }

    return doctorSummaries.filter((summary) => {
      const doctor = summary.doctor;
      return [
        doctor.name,
        doctor.email,
        doctor.specialization,
        summary.latest_doctor_notes ?? '',
        summary.latest_prescription ?? '',
      ].some((value) => value.toLowerCase().includes(query));
    });
  }, [doctorSummaries, location.search]);

  const getDoctorDisplayName = (doctor: DoctorProfile) => {
    const emailValue = String(doctor.email ?? '').trim();
    return String(doctor.name ?? '').trim() || (emailValue.includes('@') ? emailValue.split('@')[0] : emailValue) || 'Unknown doctor';
  };

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">My Doctors</h1>
          <p className="text-slate-500 mt-1">Doctors you have appointment history with are shown here.</p>
        </div>

        {errorMessage && (
          <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">{errorMessage}</div>
        )}

        {isLoading ? (
          <div className="bg-white border border-slate-100 rounded-2xl p-6 text-slate-600">Loading doctors...</div>
        ) : filteredDoctorSummaries.length === 0 ? (
          <div className="bg-white border border-slate-100 rounded-2xl p-6 text-slate-600">
            No doctors matched your search or appointment history.
          </div>
        ) : (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
              {filteredDoctorSummaries.map((summary) => {
                const doctor = summary.doctor;
                const isSelected = selectedDoctorEmail === doctor.email;
                return (
                  <button
                    key={doctor.id}
                    type="button"
                    onClick={() => setSelectedDoctorEmail(doctor.email)}
                    className={`text-left bg-white border rounded-2xl p-5 shadow-sm transition ${
                      isSelected ? 'border-indigo-300 ring-2 ring-indigo-100' : 'border-slate-100 hover:border-indigo-200'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-11 h-11 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center">
                        <Stethoscope size={20} />
                      </div>
                      <div>
                        <h3 className="font-bold text-slate-900">Dr. {getDoctorDisplayName(doctor)}</h3>
                        <p className="text-sm text-slate-600">{doctor.specialization}</p>
                      </div>
                    </div>

                    <div className="mt-4 space-y-2 text-sm text-slate-600">
                      <p className="flex items-center gap-2"><Mail size={14} /> {doctor.email}</p>
                      <p className="flex items-center gap-2">
                        <CalendarDays size={14} />
                        Next: {summary.next_appointment ? formatDateTime(summary.next_appointment.date, summary.next_appointment.time) : 'None'}
                      </p>
                      <p className="flex items-center gap-2">
                        <CalendarDays size={14} />
                        Previous: {summary.previous_appointment ? formatDateTime(summary.previous_appointment.date, summary.previous_appointment.time) : 'None'}
                      </p>
                    </div>
                  </button>
                );
              })}
            </div>

            {selectedDoctor && (
              <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-sm space-y-5">
                <div>
                  <h2 className="text-xl font-bold text-slate-900">Dr. {selectedDoctor.doctor.name} - Clinical Summary</h2>
                  <p className="text-slate-500 text-sm mt-1">Notes, prescription and appointment timeline from your history.</p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="border border-slate-100 rounded-xl p-4 bg-slate-50">
                    <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">Latest Doctor Notes</p>
                    <p className="text-slate-800 text-sm">{selectedDoctor.latest_doctor_notes ?? 'No notes added by doctor yet.'}</p>
                  </div>
                  <div className="border border-slate-100 rounded-xl p-4 bg-slate-50">
                    <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">Latest Prescription</p>
                    <p className="text-slate-800 text-sm">{selectedDoctor.latest_prescription ?? 'No prescription uploaded yet.'}</p>
                  </div>
                </div>

                <div>
                  <h3 className="font-semibold text-slate-900 mb-3 inline-flex items-center gap-2"><ClipboardList size={16} /> Appointment Timeline</h3>
                  <div className="space-y-3">
                    {sortAppointmentsDescending(selectedDoctor.appointments).map((appointment) => (
                      <div key={appointment.id} className="border border-slate-100 rounded-xl p-4">
                        <div className="flex items-center justify-between gap-3">
                          <p className="font-semibold text-slate-900">{formatDateTime(appointment.date, appointment.time)}</p>
                          <span className="text-xs px-2.5 py-1 rounded-lg bg-indigo-50 text-indigo-700 font-semibold">{appointment.status || 'scheduled'}</span>
                        </div>
                        <p className="text-sm text-slate-600 mt-1">Reason: {appointment.reason || 'Not specified'}</p>
                        {appointment.doctor_notes && (
                          <p className="text-sm text-slate-700 mt-2 inline-flex items-start gap-2"><FileText size={14} className="mt-0.5" /> {appointment.doctor_notes}</p>
                        )}
                        {appointment.prescription && (
                          <p className="text-sm text-slate-700 mt-1"><span className="font-semibold">Prescription:</span> {appointment.prescription}</p>
                        )}
                        {appointment.follow_up && (
                          <p className="text-sm text-slate-700 mt-1"><span className="font-semibold">Follow-up:</span> {appointment.follow_up}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
