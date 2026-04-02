import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Archive,
  ArrowLeftRight,
  CheckCircle2,
  FileText,
  Filter,
  FolderOpen,
  Search,
  UploadCloud,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import {
  ACTIVE_DEPARTMENT_KEY,
  DEPARTMENTS,
  DepartmentId,
  DepartmentRecord,
  DepartmentRecordStatus,
  formatBytes,
  formatDepartmentTime,
  getDepartmentById,
  loadActiveDepartment,
  setActiveDepartment,
} from '../utils/departmentStore';

type DepartmentWorkspaceSection = 'overview' | 'upload-reports' | 'patient-directory' | 'archives';

interface DepartmentWorkspaceProps {
  section?: DepartmentWorkspaceSection;
}

type ArchiveFilter = 'all' | DepartmentRecordStatus;

type DepartmentSummary = {
  total: number;
  pending: number;
  delivered: number;
  archived: number;
  uploaded_today: number;
  patient_count: number;
};

type DepartmentPatient = {
  key: string;
  name: string;
  email: string;
  count: number;
  latest?: {
    report_type: string;
    uploaded_at: string;
  };
};

type DoctorSummaryResponse = {
  doctor?: {
    name: string;
    email: string;
    specialization: string;
  };
};

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

function mapReport(raw: Record<string, unknown>): DepartmentRecord {
  return {
    id: String(raw._id ?? ''),
    departmentId: String(raw.department_id ?? '') as DepartmentId,
    patientName: String(raw.patient_name ?? ''),
    patientEmail: String(raw.patient_email ?? ''),
    reportType: String(raw.report_type ?? ''),
    fileName: String(raw.file_name ?? ''),
    fileSize: Number(raw.file_size ?? 0),
    fileType: String(raw.type ?? ''),
    notes: String(raw.notes ?? ''),
    status: String(raw.status ?? 'Pending Review') as DepartmentRecordStatus,
    uploadedAt: String(raw.uploaded_at ?? ''),
    uploadedBy: String(raw.uploaded_by ?? ''),
    fileUrl: String(raw.file_url ?? ''),
  };
}

export default function DepartmentWorkspace({ section = 'overview' }: DepartmentWorkspaceProps) {
  const [activeDepartment, setActiveDepartmentState] = useState<DepartmentId | null>(null);
  const [showDepartmentPicker, setShowDepartmentPicker] = useState(false);
  const [records, setRecords] = useState<DepartmentRecord[]>([]);
  const [summary, setSummary] = useState<DepartmentSummary>({
    total: 0,
    pending: 0,
    delivered: 0,
    archived: 0,
    uploaded_today: 0,
    patient_count: 0,
  });
  const [patients, setPatients] = useState<DepartmentPatient[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [archiveFilter, setArchiveFilter] = useState<ArchiveFilter>('all');
  const [patientName, setPatientName] = useState('');
  const [patientEmail, setPatientEmail] = useState('');
  const [reportType, setReportType] = useState('');
  const [notes, setNotes] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [feedback, setFeedback] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [selectedDoctor, setSelectedDoctor] = useState('');
  const [availableDoctors, setAvailableDoctors] = useState<Array<{ email: string; name: string; specialization: string }>>([]);

  const activeDepartmentDetails = getDepartmentById(activeDepartment);
  const isOverviewSection = section === 'overview';
  const isUploadSection = section === 'upload-reports';
  const isPatientDirectorySection = section === 'patient-directory';
  const isArchivesSection = section === 'archives';

  const loadDepartmentData = useCallback(async (departmentId: DepartmentId) => {
    try {
      setIsLoading(true);
      const [reportsRes, summaryRes, patientsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/department/reports/${departmentId}`),
        fetch(`${API_BASE_URL}/department/reports/${departmentId}/summary`),
        fetch(`${API_BASE_URL}/department/patients/${departmentId}`),
      ]);

      if (!reportsRes.ok || !summaryRes.ok || !patientsRes.ok) {
        throw new Error('Failed to load department data.');
      }

      const reportsJson = await reportsRes.json() as { reports?: Record<string, unknown>[] };
      const summaryJson = await summaryRes.json() as { summary?: DepartmentSummary };
      const patientsJson = await patientsRes.json() as { patients?: DepartmentPatient[] };

      setRecords((reportsJson.reports ?? []).map(mapReport));
      setSummary(summaryJson.summary ?? {
        total: 0,
        pending: 0,
        delivered: 0,
        archived: 0,
        uploaded_today: 0,
        patient_count: 0,
      });
      setPatients(patientsJson.patients ?? []);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unable to load department data.';
      setFeedback(message);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const currentDepartment = loadActiveDepartment();
    setActiveDepartmentState(currentDepartment);
    setShowDepartmentPicker(!currentDepartment);
  }, []);

  useEffect(() => {
    if (!activeDepartment) {
      return;
    }

    loadDepartmentData(activeDepartment);
    const pollId = window.setInterval(() => {
      loadDepartmentData(activeDepartment);
    }, 8000);

    return () => window.clearInterval(pollId);
  }, [activeDepartment, loadDepartmentData]);

  useEffect(() => {
    if (!activeDepartmentDetails) {
      return;
    }
    setReportType((current) => current || activeDepartmentDetails.reportTypes[0] || '');
  }, [activeDepartmentDetails]);

  const chooseDepartment = (departmentId: DepartmentId) => {
    setActiveDepartment(departmentId);
    setActiveDepartmentState(departmentId);
    setShowDepartmentPicker(false);
    setFeedback('');
    setSearchQuery('');
  };

  const openDepartmentPicker = () => {
    setShowDepartmentPicker(true);
  };

  const resetUploader = () => {
    setPatientName('');
    setPatientEmail('');
    setNotes('');
    setSelectedFile(null);
    setSelectedDoctor('');
    setAvailableDoctors([]);
  };

  const loadDoctorsForPatient = async (email: string) => {
    if (!email.trim()) {
      setAvailableDoctors([]);
      setSelectedDoctor('');
      return;
    }

    try {
      const response = await fetch(`${API_BASE_URL}/patient/doctors/${email}?accepted_only=true`);
      if (!response.ok) {
        setAvailableDoctors([]);
        setSelectedDoctor('');
        return;
      }

      const data = await response.json() as { doctors?: DoctorSummaryResponse[] };
      const doctors = (data.doctors || [])
        .map((summary) => summary.doctor)
        .filter((doctor): doctor is { email: string; name: string; specialization: string } => Boolean(doctor?.email));
      setAvailableDoctors(doctors);
      if (doctors.length > 0) {
        setSelectedDoctor(doctors[0].email);
      } else {
        setSelectedDoctor('');
      }
    } catch {
      setAvailableDoctors([]);
      setSelectedDoctor('');
    }
  };

  const handleUpload = async (event: React.FormEvent) => {
    event.preventDefault();
    setFeedback('');

    if (!activeDepartment) {
      setFeedback('Select a department first.');
      return;
    }

    if (!patientName.trim() || !patientEmail.trim() || !reportType.trim() || !selectedFile) {
      setFeedback('Fill all upload fields and choose a file.');
      return;
    }

    try {
      setIsLoading(true);
      const formData = new FormData();
      formData.append('department_id', activeDepartment);
      formData.append('patient_name', patientName.trim());
      formData.append('patient_email', patientEmail.trim());
      formData.append('report_type', reportType.trim());
      formData.append('uploaded_by', localStorage.getItem('medisync_name') || 'Department Desk');
      formData.append('notes', notes.trim());
      if (selectedDoctor) {
        formData.append('doctor_email', selectedDoctor);
      }
      formData.append('file', selectedFile);

      const response = await fetch(`${API_BASE_URL}/department/reports/upload`, {
        method: 'POST',
        body: formData,
      });

      const result = await response.json() as { error?: string; message?: string };
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Upload failed');
      }

      setFeedback(result.message ?? 'Report uploaded successfully.');
      resetUploader();
      await loadDepartmentData(activeDepartment);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Upload failed';
      setFeedback(message);
    } finally {
      setIsLoading(false);
    }
  };

  const updateStatus = async (recordId: string, status: DepartmentRecordStatus) => {
    try {
      const response = await fetch(`${API_BASE_URL}/department/reports/${recordId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });

      const result = await response.json() as { error?: string; message?: string };
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Status update failed');
      }

      setFeedback(result.message ?? `Status changed to ${status}`);
      if (activeDepartment) {
        await loadDepartmentData(activeDepartment);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Status update failed';
      setFeedback(message);
    }
  };

  const filteredOverviewRecords = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return records;
    }

    return records.filter((record) => (
      record.patientName.toLowerCase().includes(query) ||
      record.patientEmail.toLowerCase().includes(query) ||
      record.reportType.toLowerCase().includes(query)
    ));
  }, [records, searchQuery]);

  const filteredPatients = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) {
      return patients;
    }

    return patients.filter((patient) => (
      patient.name.toLowerCase().includes(query) ||
      patient.email.toLowerCase().includes(query)
    ));
  }, [patients, searchQuery]);

  const visibleArchiveRecords = useMemo(() => {
    if (archiveFilter === 'all') {
      return records;
    }
    return records.filter((record) => record.status === archiveFilter);
  }, [archiveFilter, records]);

  if (showDepartmentPicker || !activeDepartment) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Choose Department</h1>
          <p className="text-slate-500 mt-1">Select the department you are working in. Data will be fetched from the backend for that department.</p>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {DEPARTMENTS.map((department) => (
            <button
              key={department.id}
              type="button"
              onClick={() => chooseDepartment(department.id)}
              className="group text-left rounded-3xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition-all"
            >
              <div className={`h-2 rounded-full bg-gradient-to-r ${department.accent} mb-4`} />
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h2 className="text-lg font-bold text-slate-900">{department.label}</h2>
                  <p className="text-sm text-slate-500 mt-1">{department.description}</p>
                </div>
                <ArrowLeftRight size={18} className="text-slate-400 group-hover:text-indigo-500 transition" />
              </div>
            </button>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
      <div className="xl:col-span-2 space-y-6">
        <div className="bg-white rounded-3xl p-8 shadow-sm border border-slate-100">
          <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4 mb-6">
            <div>
              <h1 className="text-2xl font-bold text-slate-900">{activeDepartmentDetails?.label}</h1>
              <p className="text-slate-500 mt-1">{activeDepartmentDetails?.description}</p>
            </div>
            <button type="button" onClick={openDepartmentPicker} className="inline-flex items-center gap-2 px-4 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition">
              <ArrowLeftRight size={16} />
              Switch Department
            </button>
          </div>

          {(isOverviewSection || isUploadSection) && (
            <form onSubmit={handleUpload} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Patient Name</label>
                  <input type="text" value={patientName} onChange={(e) => setPatientName(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Patient Email</label>
                  <input type="email" value={patientEmail} onChange={(e) => { setPatientEmail(e.target.value); loadDoctorsForPatient(e.target.value); }} className="w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50" />
                </div>
              </div>

              {availableDoctors.length > 0 && (
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Associate with Doctor</label>
                  <select value={selectedDoctor} onChange={(e) => setSelectedDoctor(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50">
                    <option value="">Select a doctor...</option>
                    {availableDoctors.map((doc) => (
                      <option key={doc.email} value={doc.email}>
                        {doc.name} ({doc.specialization})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Report Type</label>
                  <select value={reportType} onChange={(e) => setReportType(e.target.value)} className="w-full px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50">
                    {activeDepartmentDetails?.reportTypes.map((type) => <option key={type} value={type}>{type}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Search Existing</label>
                  <div className="relative">
                    <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50" />
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Notes</label>
                <textarea rows={3} value={notes} onChange={(e) => setNotes(e.target.value)} className="w-full px-4 py-3 rounded-xl border border-slate-200 bg-slate-50" />
              </div>

              <div className="border-2 border-dashed rounded-2xl p-10 flex flex-col items-center justify-center bg-slate-50 border-slate-300">
                <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-sm mb-4">
                  <UploadCloud size={32} className="text-indigo-500" />
                </div>
                <label className="bg-indigo-600 text-white px-6 py-2.5 rounded-full font-bold shadow-sm hover:bg-indigo-700 transition cursor-pointer">
                  Browse Files
                  <input type="file" className="hidden" accept=".pdf,.jpg,.jpeg,.png,.dcm,.dicom" onChange={(event) => setSelectedFile(event.target.files?.[0] ?? null)} />
                </label>
                {selectedFile && <p className="mt-4 text-sm text-slate-600">{selectedFile.name} ({formatBytes(selectedFile.size)})</p>}
              </div>

              {feedback && <div className="rounded-xl border border-indigo-100 bg-indigo-50 px-4 py-3 text-sm text-indigo-700">{feedback}</div>}

              <div className="flex justify-end">
                <button type="submit" disabled={isLoading} className="bg-slate-900 text-white px-8 py-3 rounded-xl font-bold shadow-sm hover:bg-slate-800 transition flex items-center disabled:opacity-60">
                  <CheckCircle2 size={18} className="mr-2" />
                  Upload to {activeDepartmentDetails?.label}
                </button>
              </div>
            </form>
          )}

          {isPatientDirectorySection && (
            <div className="space-y-4">
              <div className="relative">
                <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input type="text" value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full pl-9 pr-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50" />
              </div>
              <div className="space-y-3">
                {filteredPatients.map((patient) => (
                  <div key={patient.key} className="rounded-2xl border border-slate-100 bg-slate-50 p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <h4 className="font-semibold text-slate-900 text-sm">{patient.name}</h4>
                        <p className="text-xs text-slate-500">{patient.email || 'No email available'}</p>
                      </div>
                      <span className="text-xs px-2 py-1 rounded-full bg-indigo-50 text-indigo-700 font-semibold">{patient.count} files</span>
                    </div>
                    {patient.latest?.uploaded_at && (
                      <p className="mt-3 text-xs text-slate-500">Latest: {patient.latest.report_type} on {formatDepartmentTime(patient.latest.uploaded_at)}</p>
                    )}
                  </div>
                ))}
                {filteredPatients.length === 0 && <p className="text-sm text-slate-500">No patient records returned by backend for this department.</p>}
              </div>
            </div>
          )}

          {isArchivesSection && (
            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                  <Archive className="text-indigo-500" size={20} />
                  Archive Manager
                </h3>
                <div className="max-w-full overflow-x-auto">
                  <div className="inline-flex rounded-xl border border-slate-200 bg-slate-50 p-1 min-w-max">
                    {(['all', 'Pending Review', 'Delivered', 'Archived'] as ArchiveFilter[]).map((filter) => (
                      <button key={filter} type="button" onClick={() => setArchiveFilter(filter)} className={`px-3 py-1.5 text-xs font-semibold rounded-lg whitespace-nowrap transition ${archiveFilter === filter ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}>
                        {filter === 'all' ? 'All' : filter}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              <div className="space-y-3">
                {visibleArchiveRecords.map((record) => (
                  <div key={record.id} className="rounded-2xl border border-slate-100 bg-slate-50 p-4">
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <h4 className="font-semibold text-slate-900 text-sm">{record.patientName}</h4>
                        <p className="text-xs text-slate-500 mt-0.5">{record.reportType}</p>
                        <p className="text-xs text-slate-400 mt-1">{record.fileName} • {formatBytes(record.fileSize)}</p>
                      </div>
                      <span className={`text-[10px] font-bold px-2 py-1 rounded-md ${record.status === 'Delivered' ? 'bg-emerald-100 text-emerald-700' : record.status === 'Archived' ? 'bg-slate-200 text-slate-700' : 'bg-amber-100 text-amber-700'}`}>{record.status}</span>
                    </div>

                    <div className="flex flex-wrap gap-2 mt-4">
                      {record.status === 'Pending Review' && (
                        <button type="button" onClick={() => updateStatus(record.id, 'Delivered')} className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition">Mark Delivered</button>
                      )}
                      {record.status === 'Delivered' && (
                        <button type="button" onClick={() => updateStatus(record.id, 'Archived')} className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 transition">Move to Archive</button>
                      )}
                      {record.status === 'Archived' && (
                        <span className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-slate-200 text-slate-700">Archived record</span>
                      )}
                      {record.fileUrl && (
                        <a href={record.fileUrl} target="_blank" rel="noreferrer" className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-indigo-50 text-indigo-700 hover:bg-indigo-100 transition">
                          Open File
                        </a>
                      )}
                    </div>
                  </div>
                ))}
                {visibleArchiveRecords.length === 0 && <p className="text-sm text-slate-500">No archive records returned by backend for this filter.</p>}
              </div>
            </div>
          )}
        </div>

        {(isOverviewSection || isUploadSection) && (
          <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <FileText className="text-indigo-500" size={20} />
                Recent Uploads
              </h3>
              <span className="text-sm text-slate-500">Live backend feed</span>
            </div>

            <div className="space-y-4">
              {filteredOverviewRecords.slice(0, 5).map((record) => (
                <div key={record.id} className="p-4 rounded-2xl border border-slate-100 bg-slate-50">
                  <div className="flex justify-between items-start gap-4 mb-3">
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">{record.patientName}</h4>
                      <p className="text-xs text-slate-500 mt-0.5">{record.reportType}</p>
                    </div>
                    <span className={`text-[10px] font-bold px-2 py-1 rounded-md ${record.status === 'Delivered' ? 'bg-emerald-100 text-emerald-700' : record.status === 'Archived' ? 'bg-slate-200 text-slate-700' : 'bg-amber-100 text-amber-700'}`}>{record.status}</span>
                  </div>
                  <div className="flex items-center justify-between gap-3 border-t border-slate-200 pt-3 text-xs text-slate-500">
                    <div className="flex items-center gap-2"><FolderOpen size={12} /> {record.fileName}</div>
                    <span>{formatDepartmentTime(record.uploadedAt)}</span>
                  </div>
                </div>
              ))}
              {filteredOverviewRecords.length === 0 && <p className="text-sm text-slate-500">No reports found from backend for this department.</p>}
            </div>
          </div>
        )}
      </div>

      <div className="space-y-6">
        <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-3xl p-6 text-white shadow-lg">
          <h3 className="font-bold mb-4 text-slate-200">Today's Activity</h3>
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white/10 p-4 rounded-2xl border border-white/10"><p className="text-3xl font-bold">{summary.total}</p><p className="text-xs text-slate-300 mt-1">Reports Uploaded</p></div>
            <div className="bg-white/10 p-4 rounded-2xl border border-white/10"><p className="text-3xl font-bold">{summary.pending}</p><p className="text-xs text-slate-300 mt-1">Pending Review</p></div>
            <div className="bg-white/10 p-4 rounded-2xl border border-white/10"><p className="text-3xl font-bold">{summary.delivered}</p><p className="text-xs text-slate-300 mt-1">Delivered</p></div>
            <div className="bg-white/10 p-4 rounded-2xl border border-white/10"><p className="text-3xl font-bold">{summary.uploaded_today}</p><p className="text-xs text-slate-300 mt-1">Uploaded Today</p></div>
          </div>
        </div>

        {(isOverviewSection || isUploadSection) && (
          <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
            <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2 mb-4"><Filter className="text-indigo-500" size={20} />Quick Metrics</h3>
            <div className="grid grid-cols-2 gap-4">
              <div className="rounded-2xl bg-slate-50 p-4 border border-slate-100"><p className="text-2xl font-bold text-slate-900">{summary.archived}</p><p className="text-xs text-slate-500 mt-1">Archived</p></div>
              <div className="rounded-2xl bg-slate-50 p-4 border border-slate-100"><p className="text-2xl font-bold text-slate-900">{summary.patient_count}</p><p className="text-xs text-slate-500 mt-1">Patients in Department</p></div>
            </div>
          </div>
        )}

        <div className="bg-white rounded-3xl p-6 shadow-sm border border-slate-100">
          <p className="text-sm text-slate-600">Department context is saved on this device. Clear it by signing out or by switching department.</p>
          <button onClick={() => { localStorage.removeItem(ACTIVE_DEPARTMENT_KEY); setShowDepartmentPicker(true); }} className="inline-flex mt-4 px-4 py-2 rounded-lg bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition">Change Department</button>
          <Link to="/department-dashboard" className="inline-flex mt-4 ml-3 px-4 py-2 rounded-lg border border-slate-200 text-slate-700 text-sm font-semibold hover:bg-slate-50 transition">Back to Dashboard</Link>
        </div>
      </div>
    </div>
  );
}
