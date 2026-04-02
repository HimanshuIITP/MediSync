import { HeartPulse, ArrowRight, User, Stethoscope, Building2 } from 'lucide-react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';

export default function RoleSelection() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const mode = searchParams.get('mode') === 'login' ? 'login' : 'signup';

  const handleRoleSelect = (role: 'patient' | 'doctor' | 'department') => {
    navigate(`/auth?mode=${mode}&role=${role}`);
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <div className="flex justify-center py-8">
        <Link to="/" className="flex items-center space-x-2 text-indigo-600 font-bold text-xl">
          <HeartPulse size={28} />
          <span>MediSync</span>
        </Link>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center px-4">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-extrabold text-slate-900 mb-2">{mode === 'login' ? 'Log in' : 'Register'}</h1>
          <p className="text-slate-500 font-medium">Choose whether you are a patient, doctor, or hospital / clinic.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl w-full">
          {/* Doctor Card */}
          <button 
            onClick={() => handleRoleSelect('doctor')}
            className="group bg-blue-100 hover:bg-blue-200 transition-colors rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-md border border-blue-200"
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? "I'm a doctor logging in" : "I'm a doctor"}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-1 transition-transform" />
            </div>
            
            <div className="absolute bottom-[-20px] left-[-20px] w-64 h-64 bg-blue-200/50 rounded-full blur-2xl pointer-events-none"></div>
            
            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-blue-50 relative group-hover:scale-105 transition-transform duration-300">
                 <Stethoscope size={64} className="text-blue-500" />
                 <div className="absolute top-0 right-0 bg-indigo-500 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute bottom-4 left-0 bg-sky-400 w-3 h-3 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>

          {/* Hospital / Clinic Card */}
          <button 
            onClick={() => handleRoleSelect('department')}
            className="group bg-emerald-100 hover:bg-emerald-200 transition-colors rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-md border border-emerald-200"
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? 'Hospital / clinic login' : 'Hospital / clinic signup'}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-1 transition-transform" />
            </div>

            <div className="absolute bottom-[-20px] left-[-20px] w-64 h-64 bg-emerald-200/50 rounded-full blur-2xl pointer-events-none"></div>

            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-emerald-50 relative group-hover:scale-105 transition-transform duration-300">
                 <Building2 size={64} className="text-emerald-500" />
                 <div className="absolute top-0 right-0 bg-indigo-500 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute bottom-4 left-0 bg-sky-400 w-3 h-3 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>

          {/* Patient Card */}
          <button 
            onClick={() => handleRoleSelect('patient')}
            className="group bg-yellow-100 hover:bg-yellow-200 transition-colors rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-md border border-yellow-200"
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? "I'm a patient logging in" : "I'm a patient"}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-1 transition-transform" />
            </div>
            
            <div className="absolute bottom-[-20px] right-[-20px] w-64 h-64 bg-yellow-200/50 rounded-full blur-2xl pointer-events-none"></div>

            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-yellow-50 relative group-hover:scale-105 transition-transform duration-300">
                 <User size={64} className="text-amber-500" />
                 <div className="absolute top-2 right-2 bg-green-400 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute top-1/2 -left-2 bg-rose-400 w-4 h-4 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>
        </div>

        <div className="mt-12 text-center">
          <Link to={`/role?mode=${mode === 'login' ? 'signup' : 'login'}`} className="text-sm font-semibold text-slate-600 hover:text-slate-900 border-b border-slate-300 pb-1">
            {mode === 'login' ? 'Need to create an account?' : 'I already have an account'}
          </Link>
        </div>
      </div>
    </div>
  );
}
