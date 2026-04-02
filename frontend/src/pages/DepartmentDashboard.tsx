import DashboardLayout from '../components/DashboardLayout';
import DepartmentWorkspace from '../components/DepartmentWorkspace';

export default function DepartmentDashboard() {
  return (
    <DashboardLayout role="department">
      <DepartmentWorkspace section="overview" />
    </DashboardLayout>
  );
}
