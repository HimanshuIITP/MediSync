import { ChangeEvent, useEffect, useState } from 'react';
import { FileText, UploadCloud, ExternalLink } from 'lucide-react';
import DashboardLayout from '../components/DashboardLayout';
import { useLocation } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

interface PatientReport {
  _id: string;
  file_url: string;
  file_name: string;
  type: string;
}

interface DoctorOption {
  name: string;
  email: string;
  specialization: string;
}

interface DoctorSummaryResponse {
  doctor?: DoctorOption;
}

export default function PatientRecords() {
  const location = useLocation();
  const patientEmail = localStorage.getItem('medisync_email') ?? '';
  const [reports, setReports] = useState<PatientReport[]>([]);
  const [doctors, setDoctors] = useState<DoctorOption[]>([]);
  const [selectedDoctor, setSelectedDoctor] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isUploading, setIsUploading] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  const searchQuery = new URLSearchParams(location.search).get('q')?.trim().toLowerCase() ?? '';
  const filteredReports = reports.filter((report) => {
    if (!searchQuery) {
      return true;
    }
    return [report.file_name, report.type].some((value) => value.toLowerCase().includes(searchQuery));
  });

  const formatDoctorLabel = (doctor: DoctorOption) => {
    const emailValue = String(doctor.email ?? '').trim();
    const displayName = String(doctor.name ?? '').trim() || (emailValue.includes('@') ? emailValue.split('@')[0] : emailValue) || 'Unknown doctor';
    const specialization = String(doctor.specialization ?? '').trim() || 'General';
    return `Dr. ${displayName} (${specialization})`;
  };

  const loadReports = async () => {
    if (!patientEmail) {
      setIsLoading(false);
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/patient/reports/${patientEmail}`);
      if (!response.ok) {
        throw new Error('Failed to fetch records.');
      }
      const result = (await response.json()) as { reports?: PatientReport[] };
      setReports(result.reports ?? []);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to load records';
      setErrorMessage(message);
    } finally {
      setIsLoading(false);
    }
  };

  const loadDoctors = async () => {
    if (!patientEmail) {
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/patient/doctors/${patientEmail}`);
      if (!response.ok) {
        setDoctors([]);
        setSelectedDoctor('');
        return;
      }
      const result = (await response.json()) as { doctors?: DoctorSummaryResponse[] };
      const doctorsList = (result.doctors ?? [])
        .map((summary) => summary.doctor)
        .filter((doctor): doctor is DoctorOption => Boolean(doctor?.email));
      setDoctors(doctorsList);
      if (doctorsList.length > 0) {
        setSelectedDoctor(doctorsList[0].email);
      }
    } catch {
      setDoctors([]);
      setSelectedDoctor('');
    }
  };

  useEffect(() => {
    loadReports();
    loadDoctors();
  }, [patientEmail]);

  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0] ?? null;
    setSelectedFile(file);
    setErrorMessage('');
    setSuccessMessage('');
  };

  const handleUpload = async () => {
    if (!patientEmail) {
      setErrorMessage('Please login as patient first.');
      return;
    }
    if (!selectedFile) {
      setErrorMessage('Please select a file first.');
      return;
    }
    if (!selectedDoctor) {
      setErrorMessage('Please choose the doctor you want to send this file to.');
      return;
    }

    setIsUploading(true);
    setErrorMessage('');
    setSuccessMessage('');

    try {
      const formData = new FormData();
      formData.append('file', selectedFile);

      const uploadUrl = `${API_BASE_URL}/report/upload?patient_email=${encodeURIComponent(patientEmail)}&doctor_email=${encodeURIComponent(selectedDoctor)}`;

      const response = await fetch(uploadUrl, {
        method: 'POST',
        body: formData,
      });

      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error ?? result.message ?? 'Upload failed');
      }

      setSelectedFile(null);
      setSuccessMessage('Report uploaded successfully.');
      await loadReports();
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Upload failed';
      setErrorMessage(message);
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Medical Records</h1>
          <p className="text-slate-500 mt-1">View uploaded reports and add new files to your health records.</p>
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
          <h2 className="font-bold text-slate-900 mb-4">Upload New Report</h2>
          
          <div className="mb-4">
            <label className="block text-sm font-medium text-slate-700 mb-2">Send this report to Doctor</label>
            <select
              value={selectedDoctor}
              onChange={(e) => setSelectedDoctor(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-white text-slate-900"
              disabled={doctors.length === 0}
            >
              <option value="">Choose a doctor...</option>
              {doctors.map((doctor) => (
                <option key={doctor.email} value={doctor.email}>
                  {formatDoctorLabel(doctor)}
                </option>
              ))}
            </select>
            <p className="text-xs text-slate-500 mt-1">
              {doctors.length > 0
                ? 'Pick the doctor linked to this appointment so the file appears in that doctor\'s portal.'
                : 'No doctors found for this patient yet.'}
            </p>
          </div>

          <div className="flex flex-col sm:flex-row gap-3 items-start sm:items-center">
            <label className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 cursor-pointer hover:bg-slate-100">
              <UploadCloud size={16} /> Choose file
              <input type="file" className="hidden" onChange={handleFileChange} />
            </label>
            <span className="text-sm text-slate-500">{selectedFile ? selectedFile.name : 'No file selected'}</span>
            <button
              onClick={handleUpload}
              disabled={isUploading || !selectedDoctor}
              className="px-4 py-2 rounded-xl bg-indigo-600 text-white font-semibold disabled:opacity-60"
            >
              {isUploading ? 'Uploading...' : 'Upload'}
            </button>
          </div>
          {errorMessage && <p className="mt-3 text-sm text-rose-600">{errorMessage}</p>}
          {successMessage && <p className="mt-3 text-sm text-emerald-600">{successMessage}</p>}
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-5 shadow-sm">
          <h2 className="font-bold text-slate-900 mb-4">Your Reports</h2>
          {isLoading ? (
            <p className="text-slate-600">Loading records...</p>
          ) : filteredReports.length === 0 ? (
            <p className="text-slate-600">No records found yet.</p>
          ) : (
            <div className="space-y-3">
              {filteredReports.map((report) => (
                <a
                  key={report._id}
                  href={report.file_url}
                  target="_blank"
                  rel="noreferrer"
                  className="flex items-center justify-between p-4 border border-slate-100 rounded-xl hover:bg-slate-50"
                >
                  <div className="flex items-center gap-3">
                    <FileText size={18} className="text-indigo-600" />
                    <div>
                      <p className="font-semibold text-slate-900">{report.file_name}</p>
                      <p className="text-xs text-slate-500">{report.type}</p>
                    </div>
                  </div>
                  <span className="text-indigo-600 text-sm font-semibold inline-flex items-center gap-1">
                    Open <ExternalLink size={14} />
                  </span>
                </a>
              ))}
            </div>
          )}
        </div>
      </div>
    </DashboardLayout>
  );
}
