import { useEffect } from 'react';
import { HeartPulse, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';

type PublicPageLayoutProps = {
	title: string;
	subtitle: string;
	children: React.ReactNode;
	ctaLabel?: string;
	ctaTo?: string;
	ctaSecondaryLabel?: string;
	ctaSecondaryTo?: string;
};

export default function PublicPageLayout({
	title,
	subtitle,
	children,
	ctaLabel = 'Get started',
	ctaTo = '/role',
	ctaSecondaryLabel = 'Home',
	ctaSecondaryTo = '/',
}: PublicPageLayoutProps) {
	useEffect(() => {
		const elements = Array.from(document.querySelectorAll<HTMLElement>('[data-reveal]'));
		if (elements.length === 0) {
			return;
		}

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

		return () => observer.disconnect();
	}, []);

	return (
		<div className="min-h-screen bg-slate-50 text-slate-900 relative overflow-hidden">
			<div className="pointer-events-none absolute inset-0 overflow-hidden">
				<div className="animate-drift absolute -top-24 -left-24 h-64 w-64 rounded-full bg-indigo-300/14 blur-[72px]"></div>
				<div className="animate-drift absolute top-36 -right-20 h-72 w-72 rounded-full bg-emerald-300/12 blur-[80px] [animation-delay:3s]"></div>
				<div className="animate-glow-pulse absolute bottom-12 left-1/3 h-56 w-56 rounded-full bg-sky-300/14 blur-[72px] [animation-delay:1.5s]"></div>
			</div>

			<header className="relative z-10 max-w-7xl mx-auto px-8 py-6 flex items-center justify-between gap-4">
				<Link to="/" className="flex items-center gap-2 text-indigo-600 font-bold text-2xl animate-float-medium">
					<HeartPulse size={30} className="drop-shadow-sm" />
					<span>MediSync</span>
				</Link>
					<div className="flex items-center gap-3 flex-wrap justify-end">
					<Link to={ctaSecondaryTo} className="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-white/80 px-5 py-2.5 text-slate-700 font-semibold hover:bg-slate-100 transition">
						<ArrowLeft size={18} />
						{ctaSecondaryLabel}
					</Link>
					<Link to={ctaTo} className="inline-flex items-center gap-2 rounded-full bg-slate-900 px-5 py-2.5 text-white font-semibold hover:bg-slate-800 transition shadow-lg">
						{ctaLabel}
					</Link>
				</div>
			</header>

				<main className="relative z-10 max-w-7xl mx-auto px-8 pb-20 pt-2 space-y-12">
					<section data-reveal className="reveal-on-scroll bg-white/90 backdrop-blur-xl rounded-[2rem] border border-slate-100 shadow-sm p-8 md:p-12 overflow-hidden relative">
					<div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(99,102,241,0.08),transparent_30%),radial-gradient(circle_at_bottom_right,rgba(16,185,129,0.06),transparent_28%)]"></div>
					<div className="relative z-10 max-w-4xl">
							<div className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/80 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-slate-600 shadow-sm">
								<Link to="/" className="inline-flex items-center gap-2 text-indigo-600 hover:text-indigo-700 transition-normal">
									<ArrowLeft size={14} /> Home
								</Link>
							</div>
						<p className="text-indigo-600 font-semibold uppercase tracking-[0.2em] text-sm">{subtitle}</p>
						<h1 className="mt-3 text-4xl md:text-5xl font-extrabold leading-tight">{title}</h1>
					</div>
				</section>

				{children}
			</main>
		</div>
	);
}