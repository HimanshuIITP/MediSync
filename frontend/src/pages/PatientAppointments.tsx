import { FormEvent, useEffect, useState } from 'react';
import { Calendar, Clock, Stethoscope } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface Doctor {
  id: string;
  name: string;
  email: string;
  specialization: string;
}

interface PatientAppointment {
  _id: string;
  doctor_email: string;
  date: string;
  time: string;
  reason: string;
  status: string;
}

function formatAppointmentStatus(status: string) {
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

export default function PatientAppointments() {
  const location = useLocation();
  const patientEmail = localStorage.getItem('medisync_email') ?? '';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [doctors, setDoctors] = useState<Doctor[]>([]);
  const [myAppointments, setMyAppointments] = useState<PatientAppointment[]>([]);
  const [selectedDoctorEmail, setSelectedDoctorEmail] = useState('');
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [reason, setReason] = useState('');
  const [isLoadingDoctors, setIsLoadingDoctors] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isMutating, setIsMutating] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  const searchQuery = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
  const filteredDoctors = doctors.filter((doctor) => {
    if (!searchQuery) {
      return true;
    }
    return [doctor.name, doctor.email, doctor.specialization].some((value) => value.toLowerCase().includes(searchQuery));
  });

  const filteredAppointments = myAppointments.filter((appointment) => {
    if (!searchQuery) {
      return true;
    }
    return [appointment.doctor_email, appointment.reason, appointment.status, appointment.date, appointment.time]
      .some((value) => value.toLowerCase().includes(searchQuery));
  });

  const loadMyAppointments = async () => {
    if (!patientEmail) {
      setMyAppointments([]);
      return;
    }
    const response = await fetch(`${API_BASE_URL}/patient/appointments/${patientEmail}`);
    if (!response.ok) {
      throw new Error('Unable to load your appointments.');
    }
    const result = (await response.json()) as { appointments?: PatientAppointment[] };
    setMyAppointments(result.appointments ?? []);
  };

  useEffect(() => {
    const loadInitialData = async () => {
      try {
        const [doctorResponse] = await Promise.all([
          fetch(`${API_BASE_URL}/doctors`),
          loadMyAppointments(),
        ]);

        if (!doctorResponse.ok) {
          throw new Error('Unable to load doctors from backend.');
        }

        const result = (await doctorResponse.json()) as { doctors?: Doctor[] };
        const doctorList = result.doctors ?? [];
        setDoctors(doctorList);
        if (doctorList.length > 0) {
          setSelectedDoctorEmail(doctorList[0].email);
        }
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Unable to fetch doctors';
        setErrorMessage(message);
      } finally {
        setIsLoadingDoctors(false);
      }
    };

    loadInitialData();
  }, []);

  const handleBookAppointment = async (event: FormEvent) => {
    event.preventDefault();
    setErrorMessage('');
    setSuccessMessage('');

    if (!patientEmail) {
      setErrorMessage('Please login as a patient first.');
      return;
    }

    if (!selectedDoctorEmail || !date || !time || !reason.trim()) {
      setErrorMessage('Please fill all booking fields.');
      return;
    }

    setIsSubmitting(true);
    try {
      const response = await fetch(`${API_BASE_URL}/appointments/book`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patient_email: patientEmail,
          doctor_email: selectedDoctorEmail,
          date,
          time,
          reason,
        }),
      });

      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error ?? result.message ?? 'Booking failed');
      }

      setSuccessMessage('Appointment booked successfully.');
      setReason('');
      setDate('');
      setTime('');
      await loadMyAppointments();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Booking failed';
      setErrorMessage(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handlePatientAction = async (appointment: PatientAppointment, action: 'cancel' | 'reschedule') => {
    if (!token) {
      setErrorMessage('Please login again as patient.');
      return;
    }

    let newDate = '';
    let newTime = '';
    if (action === 'reschedule') {
      newDate = window.prompt('Enter new date (YYYY-MM-DD):', appointment.date) ?? '';
      newTime = window.prompt('Enter new time (HH:MM):', appointment.time) ?? '';
      if (!newDate || !newTime) {
        return;
      }
    }

    setIsMutating(true);
    setErrorMessage('');
    setSuccessMessage('');

    try {
      const response = await fetch(`${API_BASE_URL}/appointments/${appointment._id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
        body: JSON.stringify({ action, date: newDate, time: newTime }),
      });

      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Failed to update appointment');
      }

      setSuccessMessage(action === 'cancel' ? 'Appointment cancelled.' : 'Reschedule request sent. Await doctor confirmation.');
      await loadMyAppointments();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to update appointment';
      setErrorMessage(message);
    } finally {
      setIsMutating(false);
    }
  };

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Book Appointment</h1>
          <p className="text-slate-500 mt-1">Choose a signed-up doctor and submit your slot request.</p>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="xl:col-span-2 bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Available Doctors</h2>

            {isLoadingDoctors && <p className="text-sm text-slate-500">Loading doctors...</p>}

            {!isLoadingDoctors && filteredDoctors.length === 0 && (
              <p className="text-sm text-slate-500">No doctors are registered yet.</p>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredDoctors.map((doctor) => {
                const isSelected = selectedDoctorEmail === doctor.email;
                return (
                  <button
                    key={doctor.id}
                    onClick={() => setSelectedDoctorEmail(doctor.email)}
                    className={`text-left p-4 rounded-2xl border transition ${
                      isSelected
                        ? 'border-indigo-300 bg-indigo-50'
                        : 'border-slate-100 hover:border-indigo-200 hover:bg-slate-50'
                    }`}
                    type="button"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-11 h-11 rounded-xl bg-indigo-100 text-indigo-600 flex items-center justify-center">
                        <Stethoscope size={20} />
                      </div>
                      <div>
                        <h3 className="font-bold text-slate-900">Dr. {doctor.name}</h3>
                        <p className="text-sm text-slate-600">{doctor.specialization}</p>
                        <p className="text-xs text-slate-400 mt-1">{doctor.email}</p>
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          </div>

          <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
            <h2 className="text-lg font-bold text-slate-900 mb-4">Appointment Details</h2>

            <form onSubmit={handleBookAppointment} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Selected Doctor</label>
                <select
                  value={selectedDoctorEmail}
                  onChange={(event) => setSelectedDoctorEmail(event.target.value)}
                  className="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  required
                >
                  {filteredDoctors.map((doctor) => (
                    <option key={doctor.id} value={doctor.email}>
                      Dr. {doctor.name} - {doctor.specialization}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Date</label>
                <div className="relative">
                  <Calendar size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    type="date"
                    value={date}
                    onChange={(event) => setDate(event.target.value)}
                    className="w-full pl-10 pr-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Time</label>
                <div className="relative">
                  <Clock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                  <input
                    type="time"
                    value={time}
                    onChange={(event) => setTime(event.target.value)}
                    className="w-full pl-10 pr-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Reason for visit</label>
                <textarea
                  value={reason}
                  onChange={(event) => setReason(event.target.value)}
                  rows={4}
                  className="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  placeholder="Describe your symptoms or concern"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={isSubmitting || filteredDoctors.length === 0}
                className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 disabled:cursor-not-allowed text-white py-2.5 rounded-xl font-semibold"
              >
                {isSubmitting ? 'Booking...' : 'Confirm Booking'}
              </button>
            </form>

            {errorMessage && <p className="mt-4 text-sm text-rose-600">{errorMessage}</p>}
            {successMessage && <p className="mt-4 text-sm text-emerald-600">{successMessage}</p>}
          </div>
        </div>

        <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
          <h2 className="text-lg font-bold text-slate-900 mb-4">My Appointment Requests</h2>
          {filteredAppointments.length === 0 ? (
            <p className="text-sm text-slate-500">No appointments yet.</p>
          ) : (
            <div className="space-y-3">
              {filteredAppointments.map((appointment) => {
                const normalizedStatus = (appointment.status || '').toLowerCase();
                const canEdit = !['declined', 'rejected', 'cancelled_by_patient', 'cancelled_by_doctor'].includes(normalizedStatus);
                return (
                  <div key={appointment._id} className="p-4 border border-slate-100 rounded-2xl">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                      <div>
                        <p className="font-semibold text-slate-900">Dr. {appointment.doctor_email.split('@')[0]}</p>
                        <p className="text-sm text-slate-600">{appointment.date} at {appointment.time} • {appointment.reason}</p>
                        <p className="text-xs text-slate-500 mt-1">Status: {formatAppointmentStatus(appointment.status)}</p>
                      </div>
                      {canEdit && (
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => handlePatientAction(appointment, 'reschedule')}
                            disabled={isMutating}
                            className="px-3 py-1.5 rounded-lg bg-amber-50 text-amber-700 text-xs font-bold hover:bg-amber-100 disabled:opacity-60"
                          >
                            Reschedule
                          </button>
                          <button
                            onClick={() => handlePatientAction(appointment, 'cancel')}
                            disabled={isMutating}
                            className="px-3 py-1.5 rounded-lg bg-rose-50 text-rose-700 text-xs font-bold hover:bg-rose-100 disabled:opacity-60"
                          >
                            Cancel
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
