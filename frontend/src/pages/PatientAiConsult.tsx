/// <reference types="vite/client" />

import { FormEvent, useEffect, useMemo, useState } from 'react';
import { ClipboardList, Send, Sparkles } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface Appointment {
  _id: string;
  doctor_email: string;
  date: string;
  time: string;
  reason: string;
  status: string;
}

interface DoctorInfo {
  name: string;
  email: string;
  specialization: string;
}

interface PreconsultReport {
  id: string;
  doctor_email: string;
  appointment_id: string;
  summary: string;
  ai_response: string;
  conversation: string[];
  status: string;
  doctor?: DoctorInfo;
  appointment?: {
    id: string;
    date: string;
    time: string;
    reason: string;
    status: string;
  };
}

const ACCEPTED_STATUSES = new Set(['accepted', 'confirmed', 'approved']);

function formatDoctorLabel(email: string) {
  const base = email.split('@')[0] || 'doctor';
  return `Dr. ${base}`;
}

export default function PatientAiConsult() {
  const location = useLocation();
  const patientEmail = localStorage.getItem('medisync_email') ?? '';
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [selectedAppointmentId, setSelectedAppointmentId] = useState('');
  const [conversationsByAppointment, setConversationsByAppointment] = useState<Record<string, string[]>>({});
  const [reportsByAppointment, setReportsByAppointment] = useState<Record<string, PreconsultReport>>({});
  const [message, setMessage] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');

  const selectedAppointment = useMemo(
    () => appointments.find((appointment) => appointment._id === selectedAppointmentId) ?? null,
    [appointments, selectedAppointmentId],
  );

  const activeConversation = selectedAppointmentId ? (conversationsByAppointment[selectedAppointmentId] ?? reportsByAppointment[selectedAppointmentId]?.conversation ?? []) : [];
  const activeReport = selectedAppointmentId ? reportsByAppointment[selectedAppointmentId] ?? null : null;

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const appointmentId = params.get('appointment_id') ?? '';
    if (appointmentId && appointments.some((appointment) => appointment._id === appointmentId)) {
      setSelectedAppointmentId(appointmentId);
    }
  }, [location.search, appointments]);

  useEffect(() => {
    const loadAppointments = async () => {
      if (!patientEmail) {
        return;
      }

      try {
        const response = await fetch(`${API_BASE_URL}/patient/appointments/${patientEmail}`);
        if (!response.ok) {
          return;
        }

        const result = await response.json() as { appointments?: Appointment[] };
        const accepted = (result.appointments ?? [])
          .filter((appointment) => ACCEPTED_STATUSES.has((appointment.status || '').toLowerCase()))
          .sort((left, right) => `${left.date} ${left.time}`.localeCompare(`${right.date} ${right.time}`));

        setAppointments(accepted);
        const params = new URLSearchParams(location.search);
        const appointmentId = params.get('appointment_id') ?? '';
        const matchedAppointment = accepted.find((appointment) => appointment._id === appointmentId);
        if (matchedAppointment) {
          setSelectedAppointmentId(matchedAppointment._id);
        } else if (accepted.length > 0 && !selectedAppointmentId) {
          setSelectedAppointmentId(accepted[0]._id);
        }
      } catch {
        // ignore transient loading issues
      }
    };

    loadAppointments();
  }, [patientEmail, selectedAppointmentId, location.search]);

  useEffect(() => {
    const loadReport = async () => {
      if (!patientEmail || !selectedAppointment) {
        return;
      }

      try {
        const response = await fetch(
          `${API_BASE_URL}/patient/preconsults/${patientEmail}?doctor_email=${encodeURIComponent(selectedAppointment.doctor_email)}&appointment_id=${encodeURIComponent(selectedAppointment._id)}`,
        );

        if (!response.ok) {
          return;
        }

        const result = await response.json() as { preconsults?: PreconsultReport[] };
        const existing = result.preconsults?.[0];
        if (existing) {
          setReportsByAppointment((current) => ({
            ...current,
            [selectedAppointment._id]: existing,
          }));
          setConversationsByAppointment((current) => ({
            ...current,
            [selectedAppointment._id]: existing.conversation ?? [],
          }));
        }
      } catch {
        // ignore transient loading issues
      }
    };

    loadReport();
  }, [patientEmail, selectedAppointment]);

  const sendMessage = async (event: FormEvent) => {
    event.preventDefault();
    setErrorMessage('');

    if (!patientEmail) {
      setErrorMessage('Please login as patient first.');
      return;
    }
    if (!selectedAppointment) {
      setErrorMessage('Select an accepted appointment first.');
      return;
    }
    if (!message.trim()) {
      return;
    }

    setIsSending(true);
    try {
      const response = await fetch(`${API_BASE_URL}/ai-chat`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patient_email: patientEmail,
          doctor_email: selectedAppointment.doctor_email,
          appointment_id: selectedAppointment._id,
          message,
          conversation: activeConversation,
        }),
      });

      const result = await response.json();
      if (!response.ok || !result.response) {
        throw new Error(result.error ?? 'AI response failed');
      }

      const updatedConversation = result.conversation ?? [];
      const nextReport: PreconsultReport = {
        id: result.appointment_id ?? selectedAppointment._id,
        doctor_email: result.doctor_email ?? selectedAppointment.doctor_email,
        appointment_id: result.appointment_id ?? selectedAppointment._id,
        summary: result.summary ?? '',
        ai_response: result.response,
        conversation: updatedConversation,
        status: 'ready',
        doctor: result.doctor,
        appointment: result.appointment,
      };

      setConversationsByAppointment((current) => ({
        ...current,
        [selectedAppointment._id]: updatedConversation,
      }));
      setReportsByAppointment((current) => ({
        ...current,
        [selectedAppointment._id]: nextReport,
      }));
      setMessage('');
    } catch (error) {
      const messageText = error instanceof Error ? error.message : 'Failed to contact AI service';
      setErrorMessage(messageText);
    } finally {
      setIsSending(false);
    }
  };

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6 max-w-7xl">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">AI Pre-Consult</h1>
          <p className="text-slate-500 mt-1">Select an accepted appointment, chat with the assistant, and generate a doctor-specific pre-consult report.</p>
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4">
            <div className="flex items-center gap-2 text-slate-700 font-semibold">
              <ClipboardList size={18} className="text-indigo-500" />
              Accepted Appointments
            </div>
            {appointments.length === 0 ? (
              <p className="text-sm text-slate-500">No accepted appointment yet. The pre-consult report appears after the doctor accepts a booking.</p>
            ) : (
              <div className="space-y-3 max-h-[560px] overflow-y-auto pr-1">
                {appointments.map((appointment) => {
                  const isActive = appointment._id === selectedAppointmentId;
                  return (
                    <button
                      key={appointment._id}
                      onClick={() => setSelectedAppointmentId(appointment._id)}
                      className={`w-full text-left p-4 rounded-xl border transition ${isActive ? 'border-indigo-300 bg-indigo-50' : 'border-slate-100 hover:bg-slate-50'}`}
                    >
                      <p className="font-semibold text-slate-900">{formatDoctorLabel(appointment.doctor_email)}</p>
                      <p className="text-xs text-slate-500 mt-1">{appointment.doctor_email}</p>
                      <p className="text-sm text-slate-600 mt-2">{appointment.date} at {appointment.time}</p>
                      <p className="text-xs text-slate-500 mt-1">{appointment.reason}</p>
                    </button>
                  );
                })}
              </div>
            )}
          </div>

          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4 xl:col-span-1">
            <div className="flex items-center gap-2 text-slate-600 text-sm">
              <Sparkles size={16} className="text-indigo-500" />
              <span>Talk about symptoms for the selected doctor only.</span>
            </div>

            <div className="space-y-3 max-h-[440px] overflow-y-auto pr-1 min-h-[320px]">
              {!selectedAppointment ? (
                <p className="text-slate-500 text-sm">Choose an accepted appointment to begin.</p>
              ) : activeConversation.length === 0 ? (
                <p className="text-slate-500 text-sm">Start with a symptom, duration, or what you want the doctor to know.</p>
              ) : (
                activeConversation.map((line, index) => {
                  const isPatient = line.startsWith('Patient:');
                  const content = line.replace(/^Patient:\s*/i, '').replace(/^AI:\s*/i, '');
                  return (
                    <div
                      key={`${selectedAppointmentId}-${index}-${line}`}
                      className={`p-3 rounded-xl max-w-[92%] ${isPatient ? 'bg-indigo-50 text-slate-900 ml-auto' : 'bg-slate-50 text-slate-800 mr-auto'}`}
                    >
                      {content}
                    </div>
                  );
                })
              )}
            </div>

            <form onSubmit={sendMessage} className="pt-2 border-t border-slate-100">
              <div className="flex gap-3">
                <input
                  value={message}
                  onChange={(event) => setMessage(event.target.value)}
                  disabled={!selectedAppointment}
                  placeholder={selectedAppointment ? 'Type your message...' : 'Select an accepted appointment first'}
                  className="flex-1 px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:opacity-60"
                />
                <button
                  type="submit"
                  disabled={isSending || !selectedAppointment}
                  className="px-4 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold inline-flex items-center gap-2 disabled:opacity-60"
                >
                  <Send size={16} /> {isSending ? 'Sending...' : 'Send'}
                </button>
              </div>
              {errorMessage && <p className="mt-3 text-sm text-rose-600">{errorMessage}</p>}
            </form>
          </div>

          <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-4">
            <div className="flex items-center gap-2 text-slate-700 font-semibold">
              <ClipboardList size={18} className="text-indigo-500" />
              Pre-Consult Report
            </div>
            {!selectedAppointment ? (
              <p className="text-sm text-slate-500">Select an accepted appointment to generate a doctor-specific report.</p>
            ) : !activeReport ? (
              <p className="text-sm text-slate-500">No report yet for {formatDoctorLabel(selectedAppointment.doctor_email)}. Send a message to begin.</p>
            ) : (
              <div className="space-y-4">
                <div>
                  <p className="text-lg font-bold text-slate-900">{activeReport.doctor?.name ?? formatDoctorLabel(activeReport.doctor_email)}</p>
                  <p className="text-sm text-slate-500">{activeReport.doctor?.specialization ?? 'General'}</p>
                </div>

                <div className="bg-slate-50 rounded-xl p-4">
                  <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">Summary</p>
                  <p className="text-sm text-slate-800 whitespace-pre-line">{activeReport.summary}</p>
                </div>

                <div className="bg-slate-50 rounded-xl p-4">
                  <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">Latest AI Response</p>
                  <p className="text-sm text-slate-800 whitespace-pre-line">{activeReport.ai_response}</p>
                </div>

                <div className="text-xs text-slate-500 space-y-1">
                  <p>Appointment: {activeReport.appointment?.date ?? selectedAppointment.date} at {activeReport.appointment?.time ?? selectedAppointment.time}</p>
                  <p>Reason: {activeReport.appointment?.reason ?? selectedAppointment.reason}</p>
                  <p>Status: {activeReport.status}</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
