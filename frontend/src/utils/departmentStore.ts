export type DepartmentId = 'radiology' | 'pathology' | 'cardiology' | 'neurology' | 'orthopedics';

export type DepartmentRecordStatus = 'Pending Review' | 'Delivered' | 'Archived';

export interface DepartmentDefinition {
  id: DepartmentId;
  label: string;
  description: string;
  accent: string;
  reportTypes: string[];
}

export interface DepartmentRecord {
  id: string;
  departmentId: DepartmentId;
  patientName: string;
  patientEmail: string;
  reportType: string;
  fileName: string;
  fileSize: number;
  fileType: string;
  notes: string;
  status: DepartmentRecordStatus;
  uploadedAt: string;
  uploadedBy: string;
  fileUrl?: string;
}

export const ACTIVE_DEPARTMENT_KEY = 'medisync_active_department';

export const DEPARTMENTS: DepartmentDefinition[] = [
  {
    id: 'radiology',
    label: 'Radiology',
    description: 'X-rays, MRI, CT scans, and imaging reports.',
    accent: 'from-indigo-500 to-violet-500',
    reportTypes: ['X-Ray', 'MRI Scan', 'CT Scan', 'Ultrasound'],
  },
  {
    id: 'pathology',
    label: 'Pathology',
    description: 'Blood tests, lab panels, and specimen reports.',
    accent: 'from-emerald-500 to-teal-500',
    reportTypes: ['Blood Work', 'Biopsy Report', 'Urine Analysis', 'Culture Test'],
  },
  {
    id: 'cardiology',
    label: 'Cardiology',
    description: 'ECGs, echocardiograms, and heart health records.',
    accent: 'from-rose-500 to-red-500',
    reportTypes: ['ECG', 'ECHO', 'Stress Test', 'Cardiac Report'],
  },
  {
    id: 'neurology',
    label: 'Neurology',
    description: 'Brain scans, nerve assessments, and neuro reports.',
    accent: 'from-sky-500 to-blue-500',
    reportTypes: ['Brain MRI', 'EEG', 'Nerve Study', 'Neuro Report'],
  },
  {
    id: 'orthopedics',
    label: 'Orthopedics',
    description: 'Bone scans, fracture follow-ups, and joint care.',
    accent: 'from-amber-500 to-orange-500',
    reportTypes: ['Bone X-Ray', 'Joint Scan', 'Fracture Review', 'Follow-up Report'],
  },
];

export function getDepartmentById(id: string | null | undefined) {
  return DEPARTMENTS.find((department) => department.id === id) ?? null;
}

export function getDepartmentLabel(id: string | null | undefined) {
  return getDepartmentById(id)?.label ?? 'Department';
}

export function loadActiveDepartment(): DepartmentId | null {
  const value = localStorage.getItem(ACTIVE_DEPARTMENT_KEY);
  return getDepartmentById(value)?.id ?? null;
}

export function setActiveDepartment(departmentId: DepartmentId | null) {
  if (!departmentId) {
    localStorage.removeItem(ACTIVE_DEPARTMENT_KEY);
  } else {
    localStorage.setItem(ACTIVE_DEPARTMENT_KEY, departmentId);
  }
}

export function formatBytes(bytes: number) {
  if (!bytes) {
    return '0 B';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  const unitIndex = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), units.length - 1);
  const size = bytes / Math.pow(1024, unitIndex);
  return `${size.toFixed(size >= 10 || unitIndex === 0 ? 0 : 1)} ${units[unitIndex]}`;
}

export function formatDepartmentTime(value: string) {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(new Date(value));
}
