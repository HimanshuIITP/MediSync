import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Landing from './pages/Landing';
import AboutPage from './pages/AboutPage';
import DoctorsPage from './pages/DoctorsPage';
import ServicesPage from './pages/ServicesPage';
import ContactPage from './pages/ContactPage';
import RoleSelection from './pages/RoleSelection';
import Auth from './pages/Auth';
import PatientDashboard from './pages/PatientDashboard';
import PatientAppointments from './pages/PatientAppointments';
import PatientDoctors from './pages/PatientDoctors';
import PatientRecords from './pages/PatientRecords';
import PatientAiConsult from './pages/PatientAiConsult';
import PatientMessages from './pages/PatientMessages';
import PatientSettings from './pages/PatientSettings';
import DoctorDashboard from './pages/DoctorDashboard';
import DoctorPatients from './pages/DoctorPatients';
import DoctorSchedule from './pages/DoctorSchedule';
import DoctorPreConsults from './pages/DoctorPreConsults';
import DoctorMessages from './pages/DoctorMessages';
import DoctorSettings from './pages/DoctorSettings';
import DepartmentDashboard from './pages/DepartmentDashboard';
import DashboardSection from './pages/DashboardSection';

type Role = 'patient' | 'doctor' | 'department';

function ProtectedRoute({ role, children }: { role: Role; children: JSX.Element }) {
  const token = localStorage.getItem('medisync_token');
  const sessionRole = localStorage.getItem('medisync_role');

  const hasSession = role === 'department'
    ? sessionRole === 'department'
    : Boolean(token) && sessionRole === role;

  if (!hasSession) {
    return <Navigate to={`/auth?mode=login&role=${role}`} replace />;
  }

  return children;
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Landing />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/doctors" element={<DoctorsPage />} />
        <Route path="/services" element={<ServicesPage />} />
        <Route path="/contact" element={<ContactPage />} />
        <Route path="/role" element={<RoleSelection />} />
        <Route path="/auth" element={<Auth />} />
        
        {/* Dashboards */}
        <Route path="/patient-dashboard" element={<ProtectedRoute role="patient"><PatientDashboard /></ProtectedRoute>} />
        <Route path="/patient-dashboard/appointments" element={<ProtectedRoute role="patient"><PatientAppointments /></ProtectedRoute>} />
        <Route path="/patient-dashboard/doctors" element={<ProtectedRoute role="patient"><PatientDoctors /></ProtectedRoute>} />
        <Route path="/patient-dashboard/records" element={<ProtectedRoute role="patient"><PatientRecords /></ProtectedRoute>} />
        <Route path="/patient-dashboard/ai-consult" element={<ProtectedRoute role="patient"><PatientAiConsult /></ProtectedRoute>} />
        <Route path="/patient-dashboard/messages" element={<ProtectedRoute role="patient"><PatientMessages /></ProtectedRoute>} />
        <Route path="/patient-dashboard/settings" element={<ProtectedRoute role="patient"><PatientSettings /></ProtectedRoute>} />
        <Route path="/patient-dashboard/:section" element={<ProtectedRoute role="patient"><DashboardSection role="patient" /></ProtectedRoute>} />
        <Route path="/doctor-dashboard" element={<ProtectedRoute role="doctor"><DoctorDashboard /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/patients" element={<ProtectedRoute role="doctor"><DoctorPatients /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/schedule" element={<ProtectedRoute role="doctor"><DoctorSchedule /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/pre-consults" element={<ProtectedRoute role="doctor"><DoctorPreConsults /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/messages" element={<ProtectedRoute role="doctor"><DoctorMessages /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/settings" element={<ProtectedRoute role="doctor"><DoctorSettings /></ProtectedRoute>} />
        <Route path="/doctor-dashboard/:section" element={<ProtectedRoute role="doctor"><DashboardSection role="doctor" /></ProtectedRoute>} />
        <Route path="/department-dashboard" element={<ProtectedRoute role="department"><DepartmentDashboard /></ProtectedRoute>} />
        <Route path="/department-dashboard/:section" element={<ProtectedRoute role="department"><DashboardSection role="department" /></ProtectedRoute>} />
        
        {/* Catch all */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
