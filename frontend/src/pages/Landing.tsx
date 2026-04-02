import { useEffect, useState } from 'react';
import { ArrowRight, HeartPulse, ShieldCheck, Clock, CalendarCheck2, FileText, MessageSquareHeart, Users, Sparkles, Stethoscope, Shield, Activity, BadgeCheck, BellRing, Layers3 } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';

const featureCards = [
  {
    title: 'Smart Booking',
    description: 'Find doctors, check availability, and book appointments without bouncing between apps.',
    icon: CalendarCheck2,
  },
  {
    title: 'AI Pre-Consultation',
    description: 'Patients can share symptoms before the visit so doctors start with the right context.',
    icon: Sparkles,
  },
  {
    title: 'Doctor Notes & Prescriptions',
    description: 'Doctors can save prescriptions, follow-ups, and visit notes that patients can revisit later.',
    icon: FileText,
  },
  {
    title: 'Live Notifications',
    description: 'Appointment approvals, rejections, and follow-ups trigger patient notifications in real time.',
    icon: MessageSquareHeart,
  },
];

const audienceCards = [
  {
    title: 'For Patients',
    icon: Users,
    points: [
      'Book appointments and track request status',
      'Complete AI pre-checks before the visit',
      'View prescriptions and follow-up history',
    ],
  },
  {
    title: 'For Doctors',
    icon: Stethoscope,
    points: [
      'Approve or reject requests instantly',
      'Capture pre-consults and upload medication plans',
      'Schedule the next appointment from patient history',
    ],
  },
  {
    title: 'For Departments',
    icon: Shield,
    points: [
      'Upload reports and scans in one place',
      'Keep records organized and searchable',
      'Support secure handoff across teams',
    ],
  },
];

const steps = [
  {
    title: 'Choose a role',
    description: 'Log in or create a patient, doctor, or department account based on what you need to do.',
  },
  {
    title: 'Book or review care',
    description: 'Patients book appointments and complete pre-consults; doctors review requests and outcomes.',
  },
  {
    title: 'Continue the care loop',
    description: 'Follow-ups, notifications, prescriptions, and records stay connected across visits.',
  },
];

export default function Landing() {
  const navigate = useNavigate();
  const [showSplash, setShowSplash] = useState(true);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setShowSplash(false);
    }, 2000);

    const elements = Array.from(document.querySelectorAll<HTMLElement>('[data-reveal]'));

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.08, rootMargin: '0px 0px -4% 0px' },
    );

    elements.forEach((element, index) => {
      element.style.setProperty('--reveal-delay', `${Math.min(index * 40, 180)}ms`);
      observer.observe(element);
    });

    return () => {
      window.clearTimeout(timer);
      observer.disconnect();
    };
  }, []);

  return (
    <div className="min-h-screen bg-slate-50 font-sans relative overflow-hidden">
      {showSplash && (
        <div className="fixed inset-0 z-50 bg-white flex items-center justify-center animate-page-fade">
          <div className="flex flex-col items-center justify-center gap-4 animate-scale-in">
            <img
              src="/medisync_logo.png"
              alt="MediSync"
              className="w-[78vw] max-w-[920px] h-auto object-contain select-none"
            />
          </div>
        </div>
      )}

      <div className="pointer-events-none absolute inset-0 overflow-hidden">
        <div className="animate-drift absolute -top-24 -left-24 h-64 w-64 rounded-full bg-indigo-300/14 blur-[72px]"></div>
        <div className="animate-drift absolute top-40 -right-20 h-72 w-72 rounded-full bg-emerald-300/12 blur-[80px] [animation-delay:3s]"></div>
        <div className="animate-glow-pulse absolute bottom-10 left-1/3 h-56 w-56 rounded-full bg-sky-300/14 blur-[72px] [animation-delay:1.5s]"></div>
      </div>
      {/* Navigation */}
      <nav className="relative z-10 flex items-center justify-between px-8 py-6 max-w-7xl mx-auto bg-transparent">
        <div className="flex items-center space-x-2 text-indigo-600 font-bold text-2xl animate-float-medium">
          <HeartPulse size={32} className="drop-shadow-sm" />
          <span>MediSync</span>
        </div>
        
        <div className="hidden md:flex space-x-8 text-slate-600 font-medium">
          <Link to="/about" className="hover:text-indigo-600 transition">About</Link>
          <Link to="/doctors" className="hover:text-indigo-600 transition">Doctors</Link>
          <Link to="/services" className="hover:text-indigo-600 transition">Services</Link>
          <Link to="/contact" className="hover:text-indigo-600 transition">Contact</Link>
        </div>

        <div className="flex items-center space-x-4">
          <Link to="/role?mode=login" className="px-5 py-2.5 rounded-full border border-slate-300 text-slate-700 font-medium hover:bg-slate-100 transition">
            Log in
          </Link>
          <Link to="/role" className="px-5 py-2.5 rounded-full bg-slate-900 text-white font-medium hover:bg-slate-800 transition shadow-lg flex items-center">
            Create an account
          </Link>
        </div>
      </nav>

      {/* Hero Section */}
      <main className="max-w-7xl mx-auto px-8 pt-12 pb-24">
          <div id="about" data-reveal className="reveal-on-scroll scroll-mt-24 bg-white/90 backdrop-blur-xl rounded-[2.5rem] p-12 shadow-[0_24px_80px_rgba(15,23,42,0.08)] border border-slate-100/80 flex flex-col md:flex-row items-center justify-between overflow-hidden relative">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(99,102,241,0.08),transparent_28%),radial-gradient(circle_at_bottom_right,rgba(16,185,129,0.07),transparent_28%)] pointer-events-none"></div>
          <div className="absolute -top-16 -right-8 h-52 w-52 rounded-full bg-indigo-400/10 blur-[90px] animate-glow-pulse"></div>
          <div className="absolute -bottom-20 left-10 h-48 w-48 rounded-full bg-emerald-400/10 blur-[90px] animate-glow-pulse [animation-delay:1.5s]"></div>
          
          <div className="md:w-1/2 z-10 relative animate-float-slow" data-reveal>
            <div className="inline-flex items-center gap-2 rounded-full border border-indigo-100 bg-indigo-50/80 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-indigo-600 mb-6 shadow-sm">
              <Sparkles size={14} /> Connected care workflow
            </div>
            <h1 className="text-5xl md:text-6xl font-extrabold text-slate-900 leading-tight mb-6 drop-shadow-[0_1px_0_rgba(255,255,255,0.8)]">
              Empowering Lives Through <span className="text-indigo-600">Health</span>
              <HeartPulse className="inline-block ml-3 text-indigo-600" size={48} />
            </h1>
            <p className="text-lg text-slate-500 mb-10 max-w-md">
              MediSync connects patients, doctors, and departments in one workflow: smart booking, AI pre-consults, prescriptions, follow-ups, and live medical records.
            </p>
            <button 
              onClick={() => navigate('/role')}
              className="flex items-center space-x-2 bg-indigo-600 text-white px-8 py-4 rounded-full font-semibold hover:bg-indigo-700 transition shadow-xl shadow-indigo-200 hover:-translate-y-0.5"
            >
              <span>Get started now</span>
              <ArrowRight size={20} />
            </button>
          </div>

          <div className="md:w-1/2 mt-12 md:mt-0 relative z-10" data-reveal>
             <div className="bg-slate-50/90 backdrop-blur-sm rounded-[2rem] p-8 relative h-[400px] flex items-center justify-center border border-slate-100 shadow-inner overflow-hidden">
               <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,rgba(255,255,255,0.72),transparent_50%)]"></div>
               <div className="absolute top-10 left-10 bg-white/90 backdrop-blur-xl p-4 rounded-2xl shadow-lg flex items-center space-x-3 animate-float-medium border border-white/60">
                  <div className="bg-green-100 p-2 rounded-full text-green-600">
                    <ShieldCheck size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Verified</p>
                    <p className="text-sm font-bold text-slate-800">Top Doctors</p>
                  </div>
               </div>

               <div className="absolute bottom-10 right-10 bg-white/90 backdrop-blur-xl p-4 rounded-2xl shadow-lg flex items-center space-x-3 animate-float-slow border border-white/60 [animation-delay:1s]">
                  <div className="bg-indigo-100 p-2 rounded-full text-indigo-600">
                    <Clock size={24} />
                  </div>
                  <div>
                    <p className="text-xs text-slate-400 font-medium">Save Time</p>
                    <p className="text-sm font-bold text-slate-800">AI Pre-check</p>
                  </div>
               </div>

               <img src="https://images.unsplash.com/photo-1638202993928-7267aad84c31?auto=format&fit=crop&w=600&q=80" alt="Doctor and Patient" className="rounded-3xl object-cover h-64 w-64 shadow-2xl border-4 border-white animate-float-medium" />
             </div>
          </div>
          
          {/* Decorative background shapes */}
          <div className="absolute top-0 right-0 w-[800px] h-[800px] bg-indigo-50 rounded-full blur-3xl opacity-50 -translate-y-1/2 translate-x-1/3 z-0 pointer-events-none"></div>
        </div>

        {/* Stats Section */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
           <div data-reveal className="reveal-on-scroll bg-white/90 backdrop-blur-xl p-8 rounded-3xl shadow-sm border border-slate-100 flex flex-col justify-center hover:-translate-y-1 transition duration-300">
             <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
               <Layers3 size={24} />
             </div>
             <h3 className="text-2xl font-bold text-slate-900 mb-2">One connected flow</h3>
             <p className="text-slate-500 mb-6">Booking, pre-consult, prescriptions, follow-ups, and records stay linked in one place.</p>
             <button onClick={() => navigate('/role')} className="bg-slate-900 text-white rounded-full py-3 px-6 font-medium w-fit flex items-center text-sm">
                Explore the flow <ArrowRight size={16} className="ml-2"/>
             </button>
          </div>
          
           <div data-reveal className="reveal-on-scroll bg-indigo-50/90 backdrop-blur-xl p-8 rounded-3xl shadow-sm border border-indigo-100 flex items-center justify-between hover:-translate-y-1 transition duration-300">
             <div>
               <p className="text-slate-500 font-medium mb-1">Role-based access</p>
               <h4 className="text-3xl font-extrabold text-indigo-700">Patients, doctors, departments</h4>
               <p className="text-sm text-indigo-600/70 mt-1">Each role sees what it needs and nothing extra.</p>
             </div>
             <div className="w-12 h-12 rounded-2xl bg-white text-indigo-600 flex items-center justify-center shadow-sm">
               <BadgeCheck size={24} />
             </div>
          </div>

          <div data-reveal className="reveal-on-scroll bg-emerald-50/90 backdrop-blur-xl p-8 rounded-3xl shadow-sm border border-emerald-100 flex flex-col items-center justify-center text-center hover:-translate-y-1 transition duration-300">
             <div className="w-12 h-12 rounded-2xl bg-white text-emerald-600 flex items-center justify-center shadow-sm mb-4">
               <BellRing size={24} />
             </div>
             <h3 className="mt-0 font-bold text-emerald-800 text-xl">Live updates</h3>
             <p className="text-emerald-700/80 mt-2">Approvals, rejections, and follow-ups show up as notifications in the patient flow.</p>
          </div>
        </div>

        {/* Product Features */}
        <section id="services" className="mt-20 scroll-mt-24">
          <div className="max-w-3xl mb-8">
            <p className="text-indigo-600 font-semibold uppercase tracking-[0.2em] text-sm">What MediSync does</p>
            <h2 className="text-3xl md:text-4xl font-extrabold text-slate-900 mt-3">Everything needed to run a modern appointment flow.</h2>
            <p className="text-slate-500 mt-4 text-lg">Instead of a single booking page, MediSync handles the full care loop from first click to follow-up.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {featureCards.map((feature) => {
              const Icon = feature.icon;
              return (
                <div key={feature.title} data-reveal className="reveal-on-scroll bg-white/85 backdrop-blur-xl rounded-[1.75rem] border border-slate-100 p-6 shadow-sm hover:shadow-xl hover:-translate-y-1 transition duration-300">
                  <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                    <Icon size={24} />
                  </div>
                  <h3 className="text-xl font-bold text-slate-900">{feature.title}</h3>
                  <p className="text-slate-500 mt-2 leading-relaxed">{feature.description}</p>
                </div>
              );
            })}
          </div>
        </section>

        {/* Audience Split */}
        <section id="doctors" className="mt-20 scroll-mt-24">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {audienceCards.map((audience) => {
              const Icon = audience.icon;
              return (
                <div key={audience.title} data-reveal className="reveal-on-scroll bg-slate-900 text-white rounded-[1.75rem] p-7 shadow-xl shadow-slate-200/50 relative overflow-hidden hover:-translate-y-1 transition duration-300">
                  <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent pointer-events-none"></div>
                  <div className="absolute -right-10 -top-10 h-32 w-32 rounded-full bg-indigo-400/10 blur-3xl animate-drift"></div>
                  <div className="relative z-10">
                    <div className="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center mb-5">
                      <Icon size={24} />
                    </div>
                    <h3 className="text-2xl font-bold">{audience.title}</h3>
                    <ul className="mt-4 space-y-3 text-slate-300">
                      {audience.points.map((point) => (
                        <li key={point} className="flex items-start gap-3">
                          <Activity size={16} className="mt-1 text-indigo-300" />
                          <span>{point}</span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        {/* How It Works */}
        <section className="mt-20 bg-white/90 backdrop-blur-xl rounded-[2rem] border border-slate-100 p-8 md:p-10 shadow-sm relative overflow-hidden">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(99,102,241,0.05),transparent_30%),radial-gradient(circle_at_bottom_left,rgba(16,185,129,0.05),transparent_30%)]"></div>
          <div className="relative z-10">
          <div className="max-w-3xl mb-8">
            <p className="text-emerald-600 font-semibold uppercase tracking-[0.2em] text-sm">How it works</p>
            <h2 className="text-3xl md:text-4xl font-extrabold text-slate-900 mt-3">A simple flow for patients and doctors.</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {steps.map((step, index) => (
              <div key={step.title} data-reveal className="reveal-on-scroll rounded-[1.5rem] bg-slate-50/90 p-6 border border-slate-100 hover:-translate-y-1 transition duration-300 shadow-sm">
                <div className="w-12 h-12 rounded-full bg-indigo-600 text-white font-bold flex items-center justify-center mb-4">
                  0{index + 1}
                </div>
                <h3 className="text-xl font-bold text-slate-900">{step.title}</h3>
                <p className="text-slate-500 mt-2 leading-relaxed">{step.description}</p>
              </div>
            ))}
          </div>
          </div>
        </section>

        {/* Final CTA */}
        <section id="contact" className="mt-20 mb-6 scroll-mt-24 bg-indigo-600 rounded-[2rem] p-8 md:p-10 text-white shadow-xl shadow-indigo-200/50 flex flex-col md:flex-row items-start md:items-center justify-between gap-6 overflow-hidden relative">
          <div className="absolute -left-24 -top-24 h-72 w-72 rounded-full bg-white/10 blur-[100px] animate-drift"></div>
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.18),transparent_35%),radial-gradient(circle_at_bottom_left,rgba(255,255,255,0.10),transparent_30%)] pointer-events-none"></div>
          <div className="relative z-10 max-w-2xl">
            <h2 className="text-3xl md:text-4xl font-extrabold">Built to turn appointments into a connected care experience.</h2>
            <p className="text-indigo-100 mt-3 text-lg">Start with role selection, then move through booking, pre-consult, treatment, follow-up, and records without losing context.</p>
          </div>
          <button onClick={() => navigate('/role')} className="relative z-10 bg-white text-indigo-700 px-6 py-3 rounded-full font-bold shadow-lg hover:shadow-xl transition">
            Explore MediSync
          </button>
        </section>
      </main>
    </div>
  );
}
