import { useEffect, useMemo, useState } from 'react';
import { FileText, UserRound, ClipboardList } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface PreConsult {
  id: string;
  status: string;
  date: string;
  time: string;
  reason: string;
  doctor_email?: string;
  appointment_id?: string;
  appointment?: {
    id?: string;
    date?: string;
    time?: string;
    reason?: string;
    status?: string;
  };
  doctor?: {
    name?: string;
    email?: string;
    specialization?: string;
  };
  summary?: string;
  conversation?: string[];
  patient: {
    name: string;
    email: string;
    age: number | null;
    gender: string | null;
  };
}

export default function DoctorPreConsults() {
  const location = useLocation();
  const doctorEmail = localStorage.getItem('medisync_email') ?? '';
  const token = localStorage.getItem('medisync_token') ?? '';
  const [items, setItems] = useState<PreConsult[]>([]);
  const [errorMessage, setErrorMessage] = useState('');
  const [selectedItem, setSelectedItem] = useState<PreConsult | null>(null);
  const [medications, setMedications] = useState('');
  const [timing, setTiming] = useState('Follow doctor instructions');
  const [prescriptionStatus, setPrescriptionStatus] = useState('active');
  const [notes, setNotes] = useState('');
  const [saveMessage, setSaveMessage] = useState('');

  useEffect(() => {
    const load = async () => {
      if (!doctorEmail || !token) {
        setErrorMessage('Please login as doctor first.');
        return;
      }

      try {
        const response = await fetch(`${API_BASE_URL}/doctor/preconsults/${doctorEmail}`, { headers: { Authorization: token } });
        const result = await response.json() as { preconsults?: PreConsult[]; error?: string };
        if (!response.ok || result.error) {
          throw new Error(result.error ?? 'Failed to load pre-consults');
        }
        setItems(result.preconsults ?? []);
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Failed to load pre-consults';
        setErrorMessage(message);
      }
    };

    load();
  }, [doctorEmail, token]);

  const filtered = useMemo(() => {
    const query = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
    if (!query) {
      return items;
    }
    return items.filter((item) =>
      [
        item.id,
        item.patient.name,
        item.patient.email,
        item.reason,
        item.status,
        item.appointment_id ?? '',
        item.appointment?.id ?? '',
      ].some((value) => value.toLowerCase().includes(query)),
    );
  }, [items, location.search]);

  useEffect(() => {
    if (!selectedItem && filtered.length > 0) {
      setSelectedItem(filtered[0]);
    }
  }, [filtered, selectedItem]);

  useEffect(() => {
    if (!selectedItem) {
      return;
    }
    setMedications(Array.isArray((selectedItem as PreConsult & { medications?: string[] }).medications) ? ((selectedItem as PreConsult & { medications?: string[] }).medications ?? []).join(', ') : '');
    setTiming((selectedItem as PreConsult & { medication_timing?: string }).medication_timing ?? 'Follow doctor instructions');
    setPrescriptionStatus((selectedItem as PreConsult & { medication_status?: string }).medication_status ?? 'active');
    setNotes((selectedItem as PreConsult & { medication_notes?: string }).medication_notes ?? '');
    setSaveMessage('');
  }, [selectedItem]);

  const savePrescription = async () => {
    if (!selectedItem) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/doctor/preconsults/${selectedItem.id}/medications`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: token,
        },
        body: JSON.stringify({
          medications,
          timing,
          status: prescriptionStatus,
          notes,
        }),
      });

      const result = await response.json() as { preconsult?: PreConsult; error?: string };
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Failed to save prescription');
      }

      setSaveMessage('Prescription saved successfully.');
      setItems((current) => current.map((item) => (item.id === selectedItem.id ? { ...item, ...(result.preconsult ?? {}) } : item)));
      setSelectedItem((current) => current ? { ...current, ...(result.preconsult ?? {}) } : current);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to save prescription';
      setErrorMessage(message);
    }
  };

  return (
    <DashboardLayout role="doctor">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">My Pre-consults</h1>
          <p className="text-slate-500 mt-1">Doctor-specific reports generated from accepted patient appointments.</p>
        </div>

        {errorMessage && <div className="bg-rose-50 border border-rose-100 rounded-2xl p-4 text-sm text-rose-700">{errorMessage}</div>}

        <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
          <div className="xl:col-span-1 bg-white border border-slate-100 rounded-2xl p-5 shadow-sm space-y-3 max-h-[70vh] overflow-y-auto">
            {filtered.length === 0 ? (
              <div className="text-slate-600">No pre-consults available.</div>
            ) : (
              filtered.map((item) => (
                <button
                  key={item.id}
                  onClick={() => setSelectedItem(item)}
                  className={`w-full text-left p-4 rounded-xl border transition ${selectedItem?.id === item.id ? 'border-indigo-300 bg-indigo-50' : 'border-slate-100 hover:bg-slate-50'}`}
                >
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-semibold text-slate-900 inline-flex items-center gap-2"><UserRound size={16} /> {item.patient.name}</p>
                      <p className="text-sm text-slate-600 mt-1">{item.patient.email}</p>
                    </div>
                    <span className="text-xs px-2.5 py-1 rounded-lg bg-indigo-50 text-indigo-700 capitalize">{item.status}</span>
                  </div>
                  <p className="text-xs text-slate-500 mt-2">{item.date}</p>
                </button>
              ))
            )}
          </div>

          <div className="xl:col-span-2 bg-white border border-slate-100 rounded-2xl p-6 shadow-sm">
            {!selectedItem ? (
              <p className="text-slate-500">Select a pre-consult receipt to view the full AI-generated summary.</p>
            ) : (
              <div className="space-y-5">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h2 className="text-xl font-bold text-slate-900 inline-flex items-center gap-2"><ClipboardList size={18} /> {selectedItem.patient.name}</h2>
                    <p className="text-sm text-slate-600 mt-1">{selectedItem.patient.email}</p>
                    <p className="text-xs text-slate-500 mt-1">{selectedItem.appointment?.date ?? selectedItem.date} at {selectedItem.appointment?.time ?? selectedItem.time}</p>
                  </div>
                  <span className="text-xs px-2.5 py-1 rounded-lg bg-indigo-50 text-indigo-700 capitalize">{selectedItem.status}</span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="border border-slate-100 rounded-xl p-4 bg-slate-50">
                    <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">AI Receipt Summary</p>
                    <p className="text-slate-800 text-sm whitespace-pre-line">{selectedItem.summary || selectedItem.reason || 'No summary available.'}</p>
                  </div>
                  <div className="border border-slate-100 rounded-xl p-4 bg-slate-50">
                    <p className="text-xs uppercase font-semibold tracking-wide text-slate-500 mb-1">Patient Details</p>
                    <p className="text-slate-800 text-sm">Age: {selectedItem.patient.age ?? 'n/a'}</p>
                    <p className="text-slate-800 text-sm mt-1">Gender: {selectedItem.patient.gender ?? 'n/a'}</p>
                    <p className="text-slate-800 text-sm mt-1">Doctor: {selectedItem.doctor?.name ?? selectedItem.doctor_email ?? 'n/a'}</p>
                    <p className="text-slate-800 text-sm mt-1">Specialization: {selectedItem.doctor?.specialization ?? 'General'}</p>
                    <p className="text-slate-800 text-sm mt-1">Date: {selectedItem.appointment?.date ?? selectedItem.date}</p>
                    <p className="text-slate-800 text-sm mt-1">Time: {(selectedItem.appointment?.time ?? selectedItem.time) || 'n/a'}</p>
                  </div>
                </div>

                <div>
                  <h3 className="font-semibold text-slate-900 mb-3 inline-flex items-center gap-2"><FileText size={16} /> Conversation</h3>
                  <div className="space-y-2 max-h-[320px] overflow-y-auto pr-1">
                    {(selectedItem.conversation ?? []).length === 0 ? (
                      <p className="text-sm text-slate-500">No conversation stored yet.</p>
                    ) : (
                      (selectedItem.conversation ?? []).map((line, index) => (
                        <div key={`${selectedItem.id}-${index}`} className={`p-3 rounded-xl ${line.startsWith('Patient:') ? 'bg-indigo-50' : 'bg-slate-50'}`}>
                          <p className="text-sm text-slate-800">{line}</p>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div className="border border-slate-100 rounded-2xl p-4 bg-slate-50 space-y-3">
                  <div>
                    <h3 className="font-semibold text-slate-900">Prescription / Medications</h3>
                    <p className="text-xs text-slate-500 mt-1">Enter the medications you want shown to the patient.</p>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <label className="block">
                      <span className="text-xs font-semibold text-slate-600">Medications</span>
                      <textarea
                        value={medications}
                        onChange={(event) => setMedications(event.target.value)}
                        rows={3}
                        placeholder="Amoxicillin 500mg, Lisinopril 10mg"
                        className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white"
                      />
                    </label>
                    <label className="block">
                      <span className="text-xs font-semibold text-slate-600">Timing</span>
                      <input
                        value={timing}
                        onChange={(event) => setTiming(event.target.value)}
                        placeholder="Morning, after meals"
                        className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white"
                      />
                    </label>
                    <label className="block">
                      <span className="text-xs font-semibold text-slate-600">Status</span>
                      <select
                        value={prescriptionStatus}
                        onChange={(event) => setPrescriptionStatus(event.target.value)}
                        className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white"
                      >
                        <option value="active">active</option>
                        <option value="completed">completed</option>
                        <option value="stopped">stopped</option>
                        <option value="changed">changed</option>
                      </select>
                    </label>
                    <label className="block">
                      <span className="text-xs font-semibold text-slate-600">Notes</span>
                      <input
                        value={notes}
                        onChange={(event) => setNotes(event.target.value)}
                        placeholder="Take after meals"
                        className="mt-1 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm bg-white"
                      />
                    </label>
                  </div>
                  <div className="flex items-center gap-3">
                    <button
                      onClick={savePrescription}
                      className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-semibold text-sm"
                    >
                      Save Prescription
                    </button>
                    {saveMessage && <p className="text-sm text-emerald-600">{saveMessage}</p>}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
