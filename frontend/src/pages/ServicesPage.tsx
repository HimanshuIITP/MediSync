import { CalendarCheck2, FileText, MessageSquareHeart, Shield } from 'lucide-react';
import PublicPageLayout from '../components/PublicPageLayout';

const services = [
  {
    title: 'Appointment booking',
    description: 'Patients can search doctors and request appointments based on availability.',
    icon: CalendarCheck2,
  },
  {
    title: 'AI pre-consultation',
    description: 'Patients share symptoms before the consultation, helping doctors prepare faster.',
    icon: MessageSquareHeart,
  },
  {
    title: 'Records & prescriptions',
    description: 'Doctors and departments can write notes, share prescriptions, and upload reports.',
    icon: FileText,
  },
  {
    title: 'Secure coordination',
    description: 'Role-based dashboards keep the right tools visible to the right person.',
    icon: Shield,
  },
];

export default function ServicesPage() {
  return (
    <PublicPageLayout
      title="A full set of tools for bookings, pre-consults, records, and follow-ups."
      subtitle="Services"
      ctaLabel="Start now"
      ctaTo="/role"
      ctaSecondaryLabel="Home"
      ctaSecondaryTo="/"
    >
      <section className="mt-10 grid grid-cols-1 md:grid-cols-2 gap-8">
        {services.map((service) => {
          const Icon = service.icon;
          return (
            <div key={service.title} data-reveal className="reveal-on-scroll bg-white rounded-[1.75rem] border border-slate-100 p-6 shadow-sm hover:shadow-md transition">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                <Icon size={24} />
              </div>
              <h2 className="text-xl font-bold">{service.title}</h2>
              <p className="mt-2 text-slate-600 leading-relaxed">{service.description}</p>
            </div>
          );
        })}
      </section>
    </PublicPageLayout>
  );
}
