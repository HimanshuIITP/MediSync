import { Link, useParams } from 'react-router-dom';
import DashboardLayout from '../components/DashboardLayout';
import DepartmentWorkspace from '../components/DepartmentWorkspace';

interface DashboardSectionProps {
  role: 'patient' | 'doctor' | 'department';
}

const sectionLabels: Record<string, string> = {
  appointments: 'Appointments',
  doctors: 'My Doctors',
  records: 'Medical Records',
  'ai-consult': 'AI Consult',
  messages: 'Messages',
  patients: 'My Patients',
  schedule: 'Schedule',
  'pre-consults': 'Pre-consults',
  'upload-reports': 'Upload Reports',
  'patient-directory': 'Patient Directory',
  archives: 'Archives',
};

const roleDashboardPath: Record<DashboardSectionProps['role'], string> = {
  patient: '/patient-dashboard',
  doctor: '/doctor-dashboard',
  department: '/department-dashboard',
};

export default function DashboardSection({ role }: DashboardSectionProps) {
  const params = useParams();
  const section = params.section ?? '';
  const title = sectionLabels[section] ?? 'Section';

  if (role === 'department') {
    const departmentSection = section === 'upload-reports'
      ? 'upload-reports'
      : section === 'patient-directory'
        ? 'patient-directory'
        : section === 'archives'
          ? 'archives'
          : 'overview';

    return (
      <DashboardLayout role={role}>
        <DepartmentWorkspace section={departmentSection} />
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout role={role}>
      <div className="max-w-3xl space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
          <p className="text-slate-500 mt-1">
            This section is active in navigation. Use the dashboard summary for live metrics and actions.
          </p>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-sm">
          <p className="text-slate-700">
            Open the main dashboard to access real-time appointment, patient, and report data for your role.
          </p>
          <Link
            to={roleDashboardPath[role]}
            className="inline-flex mt-4 px-4 py-2 rounded-lg bg-indigo-600 text-white text-sm font-semibold hover:bg-indigo-700 transition"
          >
            Back to Dashboard
          </Link>
        </div>
      </div>
    </DashboardLayout>
  );
}
