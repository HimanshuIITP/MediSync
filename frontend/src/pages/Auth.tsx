import { useState, useEffect } from 'react';
import { HeartPulse, Eye, EyeOff, CheckSquare, Square } from 'lucide-react';
import { Link, useSearchParams, useNavigate } from 'react-router-dom';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000';
const DEPARTMENT_PROFILE_KEY = 'medisync_department_profile';
const ACTIVE_DEPARTMENT_KEY = 'medisync_active_department';

type Role = 'patient' | 'doctor' | 'department';

type DepartmentProfile = {
  name: string;
  email: string;
  password: string;
};

type MedicalFact = {
  title: string;
  fact: string;
  tag: string;
};

const MEDICAL_FACTS: MedicalFact[] = [
  {
    title: 'Hydration matters',
    fact: 'Even mild dehydration can affect concentration, energy, and recovery after illness.',
    tag: 'Wellness',
  },
  {
    title: 'Sleep supports immunity',
    fact: 'Consistent sleep helps the body regulate stress hormones and immune response.',
    tag: 'Prevention',
  },
  {
    title: 'Movement improves circulation',
    fact: 'Short walks during the day can reduce stiffness and support healthy blood flow.',
    tag: 'Lifestyle',
  },
  {
    title: 'Regular checkups catch issues early',
    fact: 'Routine screening can detect problems before they become harder to treat.',
    tag: 'Care',
  },
];

function getStoredDepartmentProfile(): DepartmentProfile | null {
  const raw = localStorage.getItem(DEPARTMENT_PROFILE_KEY);
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as DepartmentProfile;
    if (parsed?.name && parsed?.email && parsed?.password) {
      return parsed;
    }
  } catch {
    return null;
  }

  return null;
}

export default function Auth() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  
  const initialMode = searchParams.get('mode') === 'signup' ? 'signup' : 'login';
  const role = (searchParams.get('role') || 'patient') as Role;
  const roleLabel = role === 'department' ? 'Hospital / clinic' : role === 'doctor' ? 'Doctor' : 'Patient';
  
  const [isLogin, setIsLogin] = useState(initialMode === 'login');
  const [showPassword, setShowPassword] = useState(false);
  const [agree, setAgree] = useState(false);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [age, setAge] = useState('');
  const [gender, setGender] = useState('male');
  const [specialization, setSpecialization] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState('');
  const [factIndex, setFactIndex] = useState(0);

  useEffect(() => {
    setIsLogin(searchParams.get('mode') !== 'signup');
  }, [searchParams]);

  useEffect(() => {
    const timer = window.setInterval(() => {
      setFactIndex((currentIndex) => (currentIndex + 1) % MEDICAL_FACTS.length);
    }, 4500);

    return () => window.clearInterval(timer);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage('');

    setIsSubmitting(true);

    try {
      if (role === 'department') {
        if (!name.trim() || !email.trim() || !password) {
          throw new Error('Please fill hospital / clinic name, email, and password.');
        }

        const storedProfile = getStoredDepartmentProfile();

        if (isLogin) {
          const profile = storedProfile ?? { name: name.trim(), email: email.trim(), password };
          const isValid = profile.email.toLowerCase() === email.trim().toLowerCase() && profile.password === password;
          if (!isValid) {
            throw new Error('Invalid hospital / clinic credentials.');
          }

          localStorage.setItem(DEPARTMENT_PROFILE_KEY, JSON.stringify(profile));
          localStorage.setItem('medisync_role', 'department');
          localStorage.setItem('medisync_name', profile.name);
          localStorage.setItem('medisync_email', profile.email);
          localStorage.setItem('medisync_token', 'department-session');
          localStorage.removeItem(ACTIVE_DEPARTMENT_KEY);
          navigate('/department-dashboard');
          return;
        }

        const profile: DepartmentProfile = { name: name.trim(), email: email.trim(), password };
        localStorage.setItem(DEPARTMENT_PROFILE_KEY, JSON.stringify(profile));
        localStorage.setItem('medisync_role', 'department');
        localStorage.setItem('medisync_name', profile.name);
        localStorage.setItem('medisync_email', profile.email);
        localStorage.setItem('medisync_token', 'department-session');
        localStorage.removeItem(ACTIVE_DEPARTMENT_KEY);
        navigate('/department-dashboard');
        return;
      }

      const endpoint = (() => {
        if (isLogin) {
          return role === 'doctor' ? '/login/doctor' : '/login';
        }
        return role === 'doctor' ? '/register/doctor' : '/register';
      })();

      const payload: Record<string, unknown> = isLogin
        ? { email, password }
        : role === 'doctor'
          ? { name, specialization, email, password }
          : { name, age: Number(age), gender, email, password };

      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const result = await response.json();
      const resultError = result.error ?? result.message;
      const loginFailed = isLogin && result.message !== 'Login successful';
      if (!response.ok || result.error || loginFailed) {
        throw new Error(typeof resultError === 'string' ? resultError : 'Authentication failed');
      }

      if (isLogin) {
        if (!result.token) {
          throw new Error('Token missing in response');
        }

        localStorage.setItem('medisync_token', result.token);
        localStorage.setItem('medisync_email', email);
        localStorage.setItem('medisync_role', role);
        const resolvedName = name.trim() || result?.doctor?.name || result?.patient?.name;
        if (resolvedName) {
          localStorage.setItem('medisync_name', resolvedName);
        }

        navigate(role === 'doctor' ? '/doctor-dashboard' : '/patient-dashboard');
      } else {
        setIsLogin(true);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Something went wrong';
      setErrorMessage(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-slate-50 font-sans overflow-hidden animate-page-fade">
      {/* Left side: Form */}
      <div className="w-full md:w-1/2 flex flex-col justify-center px-8 md:px-20 bg-white relative animate-slide-in-left">
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="animate-drift absolute -top-20 -left-20 h-56 w-56 rounded-full bg-indigo-200/30 blur-[80px]"></div>
          <div className="animate-glow-pulse absolute bottom-0 right-0 h-72 w-72 rounded-full bg-sky-200/25 blur-[90px] [animation-delay:1.2s]"></div>
        </div>

        <div className="mb-10 relative z-10 animate-fade-in-up" style={{ animationDelay: '90ms' }}>
          <Link to="/" className="flex items-center space-x-2 text-slate-900 font-bold text-xl hover:scale-[1.02] transition-transform">
            <HeartPulse size={28} className="text-indigo-600"/>
            <span>MediSync</span>
          </Link>
        </div>

        <div className="max-w-md w-full mx-auto md:mx-0 relative z-10">
          <h2 className="text-3xl font-bold text-slate-900 mb-2 animate-fade-in-up" style={{ animationDelay: '180ms' }}>
            {isLogin ? 'Sign in to account' : 'Create an account'}
          </h2>
          <p className="text-slate-500 mb-8 animate-fade-in-up" style={{ animationDelay: '240ms' }}>
            {isLogin ? 'Welcome back! Please enter your details.' : `Join as a ${roleLabel}. Fill the form below.`}
          </p>

          <form onSubmit={handleSubmit} className="space-y-5 animate-fade-in-up" style={{ animationDelay: '320ms' }}>
            {!isLogin && (
              <div className="animate-fade-in-up" style={{ animationDelay: '380ms' }}>
                <label className="block text-sm font-medium text-slate-700 mb-1">
                  {role === 'department' ? 'Hospital / clinic name' : 'Name'}
                </label>
                <input 
                  type="text" 
                  placeholder={role === 'department' ? 'Enter hospital / clinic name' : 'Enter your name'}
                  className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                  value={name}
                  onChange={(event) => setName(event.target.value)}
                  required
                />
              </div>
            )}

            {!isLogin && role === 'department' && (
              <p className="text-sm text-slate-500 -mt-2 animate-fade-in-up" style={{ animationDelay: '430ms' }}>
                Use this for hospital / clinic access to manage reports, uploads, and coordination.
              </p>
            )}

            {!isLogin && role === 'patient' && (
              <>
                <div className="animate-fade-in-up" style={{ animationDelay: '430ms' }}>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Age</label>
                  <input
                    type="number"
                    min={0}
                    placeholder="Enter your age"
                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                    value={age}
                    onChange={(event) => setAge(event.target.value)}
                    required
                  />
                </div>
                <div className="animate-fade-in-up" style={{ animationDelay: '470ms' }}>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Gender</label>
                  <select
                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                    value={gender}
                    onChange={(event) => setGender(event.target.value)}
                  >
                    <option value="male">Male</option>
                    <option value="female">Female</option>
                    <option value="other">Other</option>
                  </select>
                </div>
              </>
            )}

            {!isLogin && role === 'doctor' && (
              <>
                <div className="animate-fade-in-up" style={{ animationDelay: '430ms' }}>
                  <label className="block text-sm font-medium text-slate-700 mb-1">Specialization</label>
                  <input
                    type="text"
                    placeholder="e.g. Cardiology"
                    className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                    value={specialization}
                    onChange={(event) => setSpecialization(event.target.value)}
                    required
                  />
                </div>
              </>
            )}

            <div className="animate-fade-in-up" style={{ animationDelay: '510ms' }}>
              <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
              <input 
                type="email" 
                placeholder="Enter your mail" 
                className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                required
              />
            </div>

            <div className="animate-fade-in-up" style={{ animationDelay: '560ms' }}>
              <label className="block text-sm font-medium text-slate-700 mb-1">Password</label>
              <div className="relative">
                <input 
                  type={showPassword ? 'text' : 'password'} 
                  placeholder="Enter your password" 
                  className="w-full px-4 py-3 rounded-xl bg-slate-50 border border-slate-200 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:bg-white transition"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  required
                />
                <button 
                  type="button" 
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                >
                  {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between text-sm animate-fade-in-up" style={{ animationDelay: '610ms' }}>
              <div 
                className="flex items-center space-x-2 cursor-pointer transition-transform hover:translate-x-0.5"
                onClick={() => setAgree(!agree)}
              >
                {agree ? <CheckSquare size={18} className="text-indigo-600"/> : <Square size={18} className="text-slate-400"/>}
                <span className="text-slate-600">
                  {isLogin ? 'Remember me' : 'I agree to all the Terms & Conditions'}
                </span>
              </div>
              {isLogin && (
                <a href="#" className="text-indigo-600 font-medium hover:underline">Forgot Password?</a>
              )}
            </div>

            {errorMessage && (
              <p className="text-sm text-rose-600 bg-rose-50 border border-rose-100 px-3 py-2 rounded-lg animate-fade-in-up">
                {errorMessage}
              </p>
            )}

            <button 
              type="submit" 
              className="w-full bg-slate-900 text-white font-medium py-3 rounded-xl hover:bg-slate-800 transition-all duration-300 shadow-lg mt-4 disabled:opacity-60 disabled:cursor-not-allowed hover:-translate-y-0.5 animate-fade-in-up"
              style={{ animationDelay: '690ms' }}
              disabled={isSubmitting}
            >
              {isSubmitting ? 'Please wait...' : isLogin ? 'Sign in' : 'Sign up'}
            </button>
          </form>

          <div className="mt-8 flex items-center justify-between animate-fade-in-up" style={{ animationDelay: '740ms' }}>
            <hr className="w-full border-slate-200" />
            <span className="px-4 text-slate-400 text-sm">Or</span>
            <hr className="w-full border-slate-200" />
          </div>

          <div className="mt-6 grid grid-cols-2 gap-4 animate-fade-in-up" style={{ animationDelay: '790ms' }}>
            <button className="flex items-center justify-center space-x-2 border border-slate-200 rounded-xl py-2.5 hover:bg-slate-50 hover:-translate-y-0.5 transition-all duration-300">
              <img src="https://www.svgrepo.com/show/475656/google-color.svg" alt="Google" className="w-5 h-5" />
              <span className="text-sm font-medium text-slate-700">Google</span>
            </button>
            <button className="flex items-center justify-center space-x-2 border border-slate-200 rounded-xl py-2.5 hover:bg-slate-50 hover:-translate-y-0.5 transition-all duration-300">
              <img src="https://www.svgrepo.com/show/475647/facebook-color.svg" alt="Facebook" className="w-5 h-5" />
              <span className="text-sm font-medium text-slate-700">Facebook</span>
            </button>
          </div>

          <p className="mt-8 text-center text-sm text-slate-600 animate-fade-in-up" style={{ animationDelay: '840ms' }}>
            {isLogin ? "Don't have an account? " : "Already have an account? "}
            <Link to={`/auth?mode=${isLogin ? 'signup' : 'login'}&role=${role}`} className="text-indigo-600 font-bold hover:underline">
              {isLogin ? 'Sign up' : 'Log in'}
            </Link>
          </p>

          <div className="mt-8 text-center animate-fade-in-up" style={{ animationDelay: '900ms' }}>
            <Link to="/role?mode=login" className="text-xs text-slate-400 hover:text-slate-600 border-b border-transparent hover:border-slate-400 pb-0.5 transition-colors">
              Hospital / clinic login
            </Link>
          </div>
        </div>
      </div>

      {/* Right side: Visuals */}
      <div className="hidden md:flex w-1/2 bg-[#0f172a] p-12 flex-col justify-center items-center relative overflow-hidden animate-slide-in-right">
        {/* Abstract background shapes */}
        <div className="absolute top-0 right-0 w-96 h-96 bg-indigo-500 rounded-full blur-[100px] opacity-20 translate-x-1/2 -translate-y-1/2 animate-drift"></div>
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-emerald-500 rounded-full blur-[100px] opacity-20 -translate-x-1/2 translate-y-1/2 animate-drift [animation-delay:2.5s]"></div>
        
        <div className="z-10 text-center max-w-md animate-page-fade">
          <div className="w-24 h-24 bg-white/10 backdrop-blur-md rounded-3xl mx-auto mb-8 flex items-center justify-center border border-white/20 shadow-2xl animate-float-medium">
            <HeartPulse size={48} className="text-indigo-400" />
          </div>
          <h2 className="text-4xl font-bold text-white mb-4 animate-fade-in-up" style={{ animationDelay: '140ms' }}>
            Welcome to MediSync
          </h2>
          <p className="text-slate-300 text-lg animate-fade-in-up" style={{ animationDelay: '220ms' }}>
             Manage appointments, access AI health insights, and keep all your medical records organized in one seamless platform.
          </p>

          <div className="mt-12 bg-white/10 backdrop-blur-md p-6 rounded-2xl border border-white/20 text-left transition-all duration-500 animate-scale-in" style={{ animationDelay: '320ms' }}>
             <div className="flex items-center justify-between mb-4">
               <span className="text-white font-medium">Medical fact of the moment</span>
               <span className="bg-indigo-500 text-white text-xs px-2 py-1 rounded-full">Rotating</span>
             </div>

             <div className="space-y-4">
               <div>
                 <p className="text-xs uppercase tracking-[0.25em] text-indigo-200 mb-2">
                   {MEDICAL_FACTS[factIndex].tag}
                 </p>
                 <h3 className="text-xl font-bold text-white mb-2">
                   {MEDICAL_FACTS[factIndex].title}
                 </h3>
                 <p className="text-slate-300 leading-relaxed">
                   {MEDICAL_FACTS[factIndex].fact}
                 </p>
               </div>

               <div className="flex items-center gap-2">
                 {MEDICAL_FACTS.map((fact, index) => (
                   <span
                     key={fact.title}
                     className={`h-2 rounded-full transition-all duration-300 ${index === factIndex ? 'w-8 bg-indigo-400' : 'w-2 bg-white/30'}`}
                   />
                 ))}
               </div>

               <p className="text-xs text-slate-400">
                 This card updates automatically with quick health tips and care reminders.
               </p>
             </div>
          </div>
        </div>
      </div>
    </div>
  );
}
