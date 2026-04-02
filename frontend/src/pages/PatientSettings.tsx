import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import DashboardLayout from '../components/DashboardLayout';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';

export default function PatientSettings() {
  const navigate = useNavigate();
  const [name, setName] = useState(localStorage.getItem('medisync_name') ?? '');
  const [deleteConfirmation, setDeleteConfirmation] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);
  const [message, setMessage] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  const saveName = () => {
    localStorage.setItem('medisync_name', name.trim() || 'Patient');
    setMessage('Profile name updated.');
    setErrorMessage('');
  };

  const handleDeleteAccount = async () => {
    if (deleteConfirmation.trim().toUpperCase() !== 'DELETE') {
      setErrorMessage('Type DELETE to confirm account deletion.');
      setMessage('');
      return;
    }

    const token = localStorage.getItem('medisync_token');
    if (!token) {
      setErrorMessage('Please login again to continue.');
      setMessage('');
      return;
    }

    setIsDeleting(true);
    setErrorMessage('');
    setMessage('');

    try {
      const response = await fetch(`${API_BASE_URL}/account`, {
        method: 'DELETE',
        headers: { Authorization: token },
      });

      const result = await response.json();
      if (!response.ok || result.error) {
        throw new Error(result.error ?? 'Failed to delete account');
      }

      localStorage.removeItem('medisync_token');
      localStorage.removeItem('medisync_email');
      localStorage.removeItem('medisync_name');
      localStorage.removeItem('medisync_role');
      navigate('/auth?mode=login&role=patient', { replace: true });
    } catch (error) {
      const messageText = error instanceof Error ? error.message : 'Failed to delete account';
      setErrorMessage(messageText);
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <DashboardLayout role="patient">
      <div className="space-y-6 max-w-2xl">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Settings</h1>
          <p className="text-slate-500 mt-1">Update your local profile preferences.</p>
        </div>

        <div className="bg-white border border-slate-100 rounded-2xl p-6 shadow-sm space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Display name</label>
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500"
              placeholder="Your name"
            />
          </div>

          <button
            onClick={saveName}
            className="px-4 py-2.5 rounded-xl bg-indigo-600 text-white font-semibold"
          >
            Save
          </button>

          {message && <p className="text-sm text-emerald-600">{message}</p>}
          {errorMessage && <p className="text-sm text-rose-600">{errorMessage}</p>}
        </div>

        <div className="bg-white border border-rose-100 rounded-2xl p-6 shadow-sm space-y-4">
          <div>
            <h2 className="text-lg font-bold text-rose-700">Delete Account</h2>
            <p className="text-sm text-slate-600 mt-1">
              This permanently deletes your patient account and associated appointments/reports.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Type DELETE to confirm</label>
            <input
              value={deleteConfirmation}
              onChange={(event) => setDeleteConfirmation(event.target.value)}
              className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-rose-500"
              placeholder="DELETE"
            />
          </div>

          <button
            onClick={handleDeleteAccount}
            disabled={isDeleting}
            className="px-4 py-2.5 rounded-xl bg-rose-600 text-white font-semibold disabled:opacity-60"
          >
            {isDeleting ? 'Deleting...' : 'Delete My Account'}
          </button>
        </div>
      </div>
    </DashboardLayout>
  );
}
