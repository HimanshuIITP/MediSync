import DashboardLayout from '../components/DashboardLayout';

export default function PatientMessages() {
  return (
    <DashboardLayout role="patient">
      <div className="space-y-6 max-w-3xl">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Messages</h1>
          <p className="text-slate-500 mt-1">This area is ready for doctor-patient messaging integration.</p>
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-sm">
          <p className="text-slate-700">No conversation threads yet. After a booking flow is completed, this can be connected to real-time chat.</p>
        </div>
      </div>
    </DashboardLayout>
  );
}
