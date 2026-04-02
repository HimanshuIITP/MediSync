import { Mail, MessageSquare, PhoneCall, MapPin } from 'lucide-react';
import PublicPageLayout from '../components/PublicPageLayout';

const contactMethods = [
  {
    title: 'Email support',
    value: 'support@medisync.local',
    icon: Mail,
  },
  {
    title: 'Phone',
    value: '+1 (555) 018-2026',
    icon: PhoneCall,
  },
  {
    title: 'Clinic coordination',
    value: 'For appointments, records, and department handoff',
    icon: MessageSquare,
  },
];

export default function ContactPage() {
  return (
    <PublicPageLayout
      title="Reach the team behind MediSync."
      subtitle="Contact"
      ctaLabel="Get access"
      ctaTo="/role"
      ctaSecondaryLabel="Home"
      ctaSecondaryTo="/"
    >
      <section className="mt-10 grid grid-cols-1 md:grid-cols-3 gap-8">
        {contactMethods.map((method) => {
          const Icon = method.icon;
          return (
            <div key={method.title} data-reveal className="reveal-on-scroll bg-white rounded-[1.75rem] border border-slate-100 p-6 shadow-sm hover:shadow-md transition">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                <Icon size={24} />
              </div>
              <h2 className="text-xl font-bold">{method.title}</h2>
              <p className="mt-2 text-slate-600 leading-relaxed">{method.value}</p>
            </div>
          );
        })}
      </section>

      <section data-reveal className="reveal-on-scroll mt-10 bg-white rounded-[2rem] border border-slate-100 p-8 md:p-10 shadow-sm flex items-start gap-4">
        <div className="w-12 h-12 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center flex-shrink-0">
          <MapPin size={24} />
        </div>
        <div>
          <h2 className="text-2xl font-bold">Deployment note</h2>
          <p className="text-slate-600 mt-2 leading-relaxed">
            Configure this section with your live clinic hours, branch locations, escalation contacts, and billing support lines so patients and care teams can reach the right desk quickly.
          </p>
        </div>
      </section>
    </PublicPageLayout>
  );
}
