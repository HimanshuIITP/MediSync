import { ShieldCheck, Stethoscope, FileText, BellRing } from 'lucide-react';
import PublicPageLayout from '../components/PublicPageLayout';

const doctorBenefits = [
  {
    title: 'Fast approvals',
    description: 'Accept or reject appointment requests quickly and keep patients informed.',
    icon: ShieldCheck,
  },
  {
    title: 'Pre-consult context',
    description: 'Review patient symptoms before the visit and prepare a focused consultation.',
    icon: FileText,
  },
  {
    title: 'Follow-up scheduling',
    description: 'Schedule the next appointment directly from patient history when care continues.',
    icon: BellRing,
  },
];

export default function DoctorsPage() {
  return (
    <PublicPageLayout
      title="Keep consultations, prescriptions, and follow-ups in sync."
      subtitle="For doctors"
      ctaLabel="Join as doctor"
      ctaTo="/role"
      ctaSecondaryLabel="Home"
      ctaSecondaryTo="/"
    >
      <section className="mt-10 grid grid-cols-1 md:grid-cols-3 gap-8">
        {doctorBenefits.map((benefit) => {
          const Icon = benefit.icon;
          return (
            <div key={benefit.title} data-reveal className="reveal-on-scroll bg-white rounded-[1.75rem] border border-slate-100 p-6 shadow-sm hover:shadow-md transition">
              <div className="w-12 h-12 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4">
                <Icon size={24} />
              </div>
              <h2 className="text-xl font-bold">{benefit.title}</h2>
              <p className="mt-2 text-slate-600 leading-relaxed">{benefit.description}</p>
            </div>
          );
        })}
      </section>

      <section data-reveal className="reveal-on-scroll mt-10 bg-white rounded-[2rem] border border-slate-100 p-8 md:p-10 shadow-sm flex flex-col md:flex-row items-center gap-6">
        <div className="w-16 h-16 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
          <Stethoscope size={32} />
        </div>
        <div className="flex-1">
          <h2 className="text-2xl font-bold">A cleaner workflow for busy clinics</h2>
          <p className="text-slate-600 mt-2 leading-relaxed">
            Doctors can review pending requests, open patient histories, add prescriptions, and schedule the next appointment from a single dashboard.
          </p>
        </div>
      </section>
    </PublicPageLayout>
  );
}
