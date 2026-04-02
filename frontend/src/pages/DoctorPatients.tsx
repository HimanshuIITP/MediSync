import { useCallback, useEffect, useMemo, useState } from 'react';
import { Mail, CalendarDays, UserRound, FileText, Download } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface PatientVisit {
  id: string;
  date: string;
  time: string;
  status: string;
  reason: string;
}

interface DoctorPatientSummary {
  patient: {
    name: string;
    email: string;
    age: number | null;
    gender: string | null;
  };
  appointment_count: number;
  latest_status: string | null;
  last_visit: PatientVisit | null;
  next_visit: PatientVisit | null;
}

interface DoctorPatientFile {
  _id: string;
  file_name: string;
  file_url: string;
  report_type: string;
  uploaded_at: string;
  status: string;
}

interface DoctorPatientFilesGroup {
  patient_name: string;
  patient_email: string;
  files: DoctorPatientFile[];
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

function getPatientStatusLabel(status: string | null) {
  const normalized = (status || '').toLowerCase();
  if (normalized === 'declined' || normalized === 'rejected') {
    return 'Rejected';
  }
  if (normalized === 'accepted' || normalized === 'approved' || normalized === 'confirmed') {
    return 'Accepted';
  }
  if (!normalized) {
    return 'n/a';
  }
  return `${normalized.charAt(0).toUpperCase()}${normalized.slice(1)}`;
}

function canScheduleFollowUp(latestStatus: string | null) {
  const normalized = (latestStatus || '').toLowerCase();
  if (!normalized) {
    return false;
  }
  return ['accepted', 'confirmed', 'approved', 'completed'].includes(normalized);
}

export default function DoctorPatients() {
  const location = useLocation();
  const doctorEmail = localStorage.getItem('medisync_email') ?? '';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [patients, setPatients] = useState<DoctorPatientSummary[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState('');
  const [actionMessage, setActionMessage] = useState('');
  const [patientFiles, setPatientFiles] = useState<DoctorPatientFilesGroup[]>([]);
  const [isScheduleModalOpen, setIsScheduleModalOpen] = useState(false);
  const [selectedPatientEmail, setSelectedPatientEmail] = useState('');
  const [scheduleDate, setScheduleDate] = useState('');
  const [scheduleTime, setScheduleTime] = useState('10:00');
  const [scheduleReason, setScheduleReason] = useState('Follow-up consultation');

  const loadPatients = useCallback(async () => {
    if (!doctorEmail || !token) {
      setErrorMessage('Please login as doctor first.');
      setIsLoading(false);
      return;
    }

    try {
      const [response, filesResponse] = await Promise.all([
        fetch(`${API_BASE_URL}/doctor/patients/${doctorEmail}`, {
          headers: { Authorization: token },
        }),
        fetch(`${API_BASE_URL}/doctor/patient-files/${doctorEmail}`),
      ]);

      if (!response.ok) {
        throw new Error('Unable to load patients from backend.');
      }

      const result = await response.json() as { patients?: DoctorPatientSummary[]; error?: string };
      const filesResult = filesResponse.ok
        ? await filesResponse.json() as { patient_files?: DoctorPatientFilesGroup[] }
        : { patient_files: [] as DoctorPatientFilesGroup[] };
      if (result.error) {
        throw new Error(result.error);
      }

      setPatients(result.patients ?? []);
      setPatientFiles(filesResult.patient_files ?? []);
      setErrorMessage('');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to load patients';
      setErrorMessage(message);
    } finally {
      setIsLoading(false);
    }
  }, [doctorEmail, token]);

  useEffect(() => {
    loadPatients();
  }, [loadPatients]);

  const openScheduleModal = (patientEmail: string, suggestedReason: string) => {
    setSelectedPatientEmail(patientEmail);
    setScheduleReason(suggestedReason || 'Follow-up consultation');
    setScheduleDate(new Date().toISOString().slice(0, 10));
    setScheduleTime('10:00');
    setIsScheduleModalOpen(true);
  };

  const scheduleNextAppointment = async () => {
    if (!selectedPatientEmail || !scheduleDate || !scheduleTime || !scheduleReason.trim()) {
      setErrorMessage('Please fill date, time, and reason.');
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/doctor/appointments/schedule`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
        body: JSON.stringify({
          patient_email: selectedPatientEmail,
          date: scheduleDate,
          time: scheduleTime,
          reason: scheduleReason.trim(),
        }),
      });

      const result = await response.json() as { message?: string; error?: string };
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Unable to schedule follow-up');
      }

      setActionMessage(result.message ?? 'Follow-up appointment scheduled.');
      setErrorMessage('');
      setIsScheduleModalOpen(false);
      await loadPatients();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to schedule follow-up';
      setErrorMessage(message);
    }
  };

  const filtered = useMemo(() => {
    const query = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
    if (!query) {
      return patients;
    }
    return patients.filter((summary) => {
      const patient = summary.patient;
      const values = [
        patient.name,
        patient.email,
        patient.gender ?? '',
        summary.latest_status ?? '',
      ];
      return values.some((value) => value.toLowerCase().includes(query));
    });
  }, [patients, location.search]);

  const filesByPatient = useMemo(() => {
    const map = new Map<string, DoctorPatientFilesGroup>();
    patientFiles.forEach((group) => {
      map.set(group.patient_email, group);
    });
    return map;
  }, [patientFiles]);

  return (
    <DashboardLayout role="doctor">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">My Patients</h1>
          <p className="text-slate-500 mt-1">Patients with real appointment history from backend.</p>
        </div>

        {errorMessage && <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">{errorMessage}</div>}
        {actionMessage && <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-4 text-sm text-emerald-700">{actionMessage}</div>}

        {isLoading ? (
          <div className="bg-white rounded-2xl border border-slate-100 p-6 text-slate-600">Loading patients...</div>
        ) : filtered.length === 0 ? (
          <div className="bg-white rounded-2xl border border-slate-100 p-6 text-slate-600">No patients found.</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {filtered.map((summary) => (
              <div key={summary.patient.email} className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center">
                    <UserRound size={20} />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900">{summary.patient.name}</h3>
                    <p className="text-sm text-slate-600 capitalize">{summary.patient.gender ?? 'Unknown'} {summary.patient.age ? `• ${summary.patient.age} yrs` : ''}</p>
                  </div>
                </div>

                <div className="mt-4 space-y-2 text-sm text-slate-600">
                  <p className="flex items-center gap-2"><Mail size={14} /> {summary.patient.email}</p>
                  <p>Appointments: <span className="font-semibold text-slate-900">{summary.appointment_count}</span></p>
                  <p>Status: <span className="font-semibold text-slate-900">{getPatientStatusLabel(summary.latest_status)}</span></p>
                  <p className="flex items-center gap-2"><CalendarDays size={14} /> Next: {summary.next_visit ? formatDateTime(summary.next_visit.date, summary.next_visit.time) : 'None'}</p>
                  <p className="flex items-center gap-2"><CalendarDays size={14} /> Last: {summary.last_visit ? formatDateTime(summary.last_visit.date, summary.last_visit.time) : 'None'}</p>
                </div>

                {filesByPatient.get(summary.patient.email)?.files?.length ? (
                  <div className="mt-4 rounded-2xl border border-slate-100 bg-slate-50 p-4">
                    <div className="flex items-center justify-between gap-3 mb-3">
                      <h4 className="font-semibold text-slate-900 text-sm flex items-center gap-2">
                        <FileText size={14} /> Uploaded Files
                      </h4>
                      <span className="text-xs font-semibold text-emerald-700 bg-emerald-50 px-2 py-1 rounded-full">
                        {filesByPatient.get(summary.patient.email)?.files.length} files
                      </span>
                    </div>
                    <div className="space-y-2 max-h-56 overflow-auto pr-1">
                      {filesByPatient.get(summary.patient.email)?.files.map((file) => (
                        <a
                          key={file._id}
                          href={file.file_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-start justify-between gap-3 rounded-xl border border-slate-200 bg-white p-3 hover:border-emerald-200 hover:bg-emerald-50 transition"
                        >
                          <div className="min-w-0">
                            <p className="font-semibold text-slate-900 text-sm truncate">{file.file_name}</p>
                            <p className="text-xs text-slate-500 mt-0.5">{file.report_type}</p>
                            <p className="text-xs text-slate-400 mt-0.5">{file.uploaded_at}</p>
                          </div>
                          <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-700 whitespace-nowrap mt-0.5">
                            Open <Download size={12} />
                          </span>
                        </a>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className="mt-4 text-xs text-slate-500 bg-slate-50 border border-slate-100 rounded-xl p-2.5">
                    No uploaded files for this patient yet.
                  </p>
                )}

                {canScheduleFollowUp(summary.latest_status) ? (
                  <button
                    onClick={() => openScheduleModal(summary.patient.email, summary.last_visit?.reason ?? 'Follow-up consultation')}
                    className="mt-4 w-full rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold py-2"
                  >
                    Schedule Next Appointment
                  </button>
                ) : (
                  <p className="mt-4 text-xs text-amber-700 bg-amber-50 border border-amber-100 rounded-xl p-2.5">
                    Follow-up scheduling is available after you approve the current request.
                  </p>
                )}
              </div>
            ))}
          </div>
        )}

        {isScheduleModalOpen && (
          <div className="fixed inset-0 z-40 bg-slate-900/45 backdrop-blur-[1px] flex items-center justify-center px-4">
            <div className="w-full max-w-md bg-white rounded-2xl border border-slate-200 shadow-xl p-5 space-y-4">
              <div>
                <h2 className="text-lg font-bold text-slate-900">Schedule Next Appointment</h2>
                <p className="text-sm text-slate-500 mt-1">Patient: {selectedPatientEmail}</p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <label className="block">
                  <span className="text-xs font-semibold text-slate-600">Date</span>
                  <input
                    type="date"
                    value={scheduleDate}
                    onChange={(event) => setScheduleDate(event.target.value)}
                    className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                  />
                </label>
                <label className="block">
                  <span className="text-xs font-semibold text-slate-600">Time</span>
                  <input
                    type="time"
                    value={scheduleTime}
                    onChange={(event) => setScheduleTime(event.target.value)}
                    className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                  />
                </label>
              </div>

              <label className="block">
                <span className="text-xs font-semibold text-slate-600">Reason</span>
                <input
                  value={scheduleReason}
                  onChange={(event) => setScheduleReason(event.target.value)}
                  placeholder="Follow-up consultation"
                  className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                />
              </label>

              <div className="flex justify-end gap-2 pt-1">
                <button
                  onClick={() => setIsScheduleModalOpen(false)}
                  className="px-4 py-2 rounded-xl border border-slate-200 text-slate-700 text-sm font-semibold"
                >
                  Cancel
                </button>
                <button
                  onClick={scheduleNextAppointment}
                  className="px-4 py-2 rounded-xl bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700"
                >
                  Schedule
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
