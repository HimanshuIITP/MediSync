import { Sparkles, CalendarCheck2, MessageSquareHeart } from 'lucide-react';
import PublicPageLayout from '../components/PublicPageLayout';

const pillars = [
  {
    title: 'Connected care flow',
    description: 'Patients, doctors, and departments share one workflow from booking to follow-up.',
    icon: CalendarCheck2,
  },
  {
    title: 'AI pre-consult support',
    description: 'Patients can record symptoms before the appointment so doctors begin with context.',
    icon: Sparkles,
  },
  {
    title: 'Real-time updates',
    description: 'Approvals, rejections, prescriptions, and follow-ups are pushed through the system as they happen.',
    icon: MessageSquareHeart,
  },
];

export default function AboutPage() {
  return (
    <PublicPageLayout
      title="Built to connect booking, pre-consultation, prescriptions, and follow-ups in one place."
      subtitle="About MediSync"
      ctaLabel="Open dashboard"
      ctaTo="/role"
      ctaSecondaryLabel="Home"
      ctaSecondaryTo="/"
    >
      <section className="mt-10 grid grid-cols-1 md:grid-cols-3 gap-6">
        {pillars.map((pillar) => {
          const Icon = pillar.icon;
          return (
            <div key={pillar.title} data-reveal className="reveal-on-scroll bg-white rounded-[1.75rem] border border-slate-100 p-6 shadow-sm hover:shadow-md transition">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                <Icon size={24} />
              </div>
              <h2 className="text-xl font-bold">{pillar.title}</h2>
              <p className="mt-2 text-slate-600 leading-relaxed">{pillar.description}</p>
            </div>
          );
        })}
      </section>
    </PublicPageLayout>
  );
}
