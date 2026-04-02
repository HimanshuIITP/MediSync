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
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans relative overflow-hidden animate-page-fade">
      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="animate-drift absolute -top-20 -left-20 h-60 w-60 rounded-full bg-indigo-300/15 blur-[72px]"></div>
        <div className="animate-drift absolute top-32 -right-24 h-72 w-72 rounded-full bg-emerald-300/12 blur-[84px] [animation-delay:3s]"></div>
        <div className="animate-glow-pulse absolute bottom-12 left-1/3 h-64 w-64 rounded-full bg-amber-300/12 blur-[80px] [animation-delay:1.5s]"></div>
      </div>

      <div className="relative z-10 flex justify-center py-8 animate-fade-in-up" style={{ animationDelay: '80ms' }}>
        <Link to="/" className="flex items-center space-x-2 text-indigo-600 font-bold text-xl hover:scale-[1.02] transition-transform">
          <HeartPulse size={28} />
          <span>MediSync</span>
        </Link>
      </div>

      <div className="relative z-10 flex-1 flex flex-col items-center justify-center px-4 pb-10">
        <div className="text-center mb-12 animate-fade-in-up" style={{ animationDelay: '180ms' }}>
          <p className="mx-auto mb-4 inline-flex items-center rounded-full border border-slate-200 bg-white/80 px-4 py-2 text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 shadow-sm">
            Portal access
          </p>
          <h1 className="text-4xl md:text-5xl font-extrabold text-slate-900 mb-2">{mode === 'login' ? 'Log in' : 'Register'}</h1>
          <p className="text-slate-500 font-medium">Choose whether you are a patient, doctor, or hospital / clinic.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl w-full">
          {/* Doctor Card */}
          <button 
            onClick={() => handleRoleSelect('doctor')}
            className="group bg-blue-100/90 hover:bg-blue-200 transition-all duration-500 rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-xl hover:-translate-y-1 border border-blue-200 animate-scale-in focus:outline-none focus:ring-2 focus:ring-blue-400"
            style={{ animationDelay: '220ms' }}
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? "I'm a doctor logging in" : "I'm a doctor"}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-2 transition-transform duration-300" />
            </div>
            
            <div className="absolute bottom-[-20px] left-[-20px] w-64 h-64 bg-blue-200/50 rounded-full blur-2xl pointer-events-none animate-float-slow"></div>
            
            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-blue-50 relative group-hover:scale-110 transition-transform duration-300 animate-float-medium">
                 <Stethoscope size={64} className="text-blue-500" />
                 <div className="absolute top-0 right-0 bg-indigo-500 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute bottom-4 left-0 bg-sky-400 w-3 h-3 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>

          {/* Hospital / Clinic Card */}
          <button 
            onClick={() => handleRoleSelect('department')}
            className="group bg-emerald-100/90 hover:bg-emerald-200 transition-all duration-500 rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-xl hover:-translate-y-1 border border-emerald-200 animate-scale-in focus:outline-none focus:ring-2 focus:ring-emerald-400"
            style={{ animationDelay: '320ms' }}
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? 'Hospital / clinic login' : 'Hospital / clinic signup'}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-2 transition-transform duration-300" />
            </div>

            <div className="absolute bottom-[-20px] left-[-20px] w-64 h-64 bg-emerald-200/50 rounded-full blur-2xl pointer-events-none animate-float-slow"></div>

            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-emerald-50 relative group-hover:scale-110 transition-transform duration-300 animate-float-medium">
                 <Building2 size={64} className="text-emerald-500" />
                 <div className="absolute top-0 right-0 bg-indigo-500 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute bottom-4 left-0 bg-sky-400 w-3 h-3 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>

          {/* Patient Card */}
          <button 
            onClick={() => handleRoleSelect('patient')}
            className="group bg-yellow-100/90 hover:bg-yellow-200 transition-all duration-500 rounded-3xl p-8 flex flex-col justify-between h-80 relative overflow-hidden text-left shadow-sm hover:shadow-xl hover:-translate-y-1 border border-yellow-200 animate-scale-in focus:outline-none focus:ring-2 focus:ring-amber-400"
            style={{ animationDelay: '420ms' }}
          >
            <div className="flex justify-between items-center z-10 relative">
              <h2 className="text-2xl font-bold text-slate-900">{mode === 'login' ? "I'm a patient logging in" : "I'm a patient"}</h2>
              <ArrowRight className="text-slate-900 group-hover:translate-x-2 transition-transform duration-300" />
            </div>
            
            <div className="absolute bottom-[-20px] right-[-20px] w-64 h-64 bg-yellow-200/50 rounded-full blur-2xl pointer-events-none animate-float-slow"></div>

            <div className="z-10 mt-auto flex justify-center">
              <div className="bg-white p-6 rounded-full shadow-lg border-4 border-yellow-50 relative group-hover:scale-110 transition-transform duration-300 animate-float-medium">
                 <User size={64} className="text-amber-500" />
                 <div className="absolute top-2 right-2 bg-green-400 w-4 h-4 rounded-full border-2 border-white"></div>
                 <div className="absolute top-1/2 -left-2 bg-rose-400 w-4 h-4 rounded-full border-2 border-white"></div>
              </div>
            </div>
          </button>
        </div>

        <div className="mt-12 text-center animate-fade-in-up" style={{ animationDelay: '520ms' }}>
          <Link to={`/role?mode=${mode === 'login' ? 'signup' : 'login'}`} className="text-sm font-semibold text-slate-600 hover:text-slate-900 border-b border-slate-300 pb-1 transition-colors">
            {mode === 'login' ? 'Need to create an account?' : 'I already have an account'}
          </Link>
        </div>
      </div>
    </div>
  );
}
