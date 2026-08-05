import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import HeartbeatLine from './HeartbeatLine';
import Reveal from './Reveal';
import logo from '../../assets/logo.svg';

export default function HeroSection() {
  const { t } = useTranslation();
  return (
    <section id="top" className="relative overflow-hidden bg-canvas pt-32 pb-20 sm:pt-40 sm:pb-28">
      <div
        className="pointer-events-none absolute -top-24 -right-24 h-96 w-96 rounded-full bg-rose-100/50 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute top-40 -left-32 h-80 w-80 rounded-full bg-rose-50/80 blur-3xl"
        aria-hidden="true"
      />
      <div className="relative mx-auto grid max-w-6xl items-center gap-14 px-5 lg:grid-cols-[1.1fr_0.9fr]">
        <div>
          <Reveal>
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-rose-primary/20 bg-white/80 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
              <span className="material-symbols-outlined text-[16px]">favorite</span>
              {t('landing.hero.kicker')}
            </p>
          </Reveal>
          <Reveal delay={100}>
            <h1 className="font-display text-5xl font-semibold leading-[1.05] text-text-heading sm:text-6xl lg:text-7xl">
              {t('landing.hero.h1')}
            </h1>
          </Reveal>
          <Reveal delay={200}>
            <p className="mt-6 max-w-xl text-lg leading-relaxed text-text-body">
              {t('landing.hero.sub')}
            </p>
          </Reveal>
          <Reveal delay={300}>
            <div className="mt-8 flex flex-wrap items-center gap-4">
              <Link
                to="/signup"
                className="rounded-full bg-rose-primary px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-rose-primary/25 hover:bg-rose-hover hover:-translate-y-0.5 transition-all"
              >
                {t('landing.hero.cta_primary')}
              </Link>
              <a
                href="#how"
                className="group inline-flex items-center gap-2 rounded-full border border-border bg-white/80 px-7 py-3.5 text-base font-semibold text-text-heading hover:border-rose-primary/40 hover:text-rose-primary transition-colors"
              >
                {t('landing.hero.cta_secondary')}
                <span className="material-symbols-outlined text-[20px] transition-transform group-hover:translate-y-0.5">
                  arrow_downward
                </span>
              </a>
            </div>
          </Reveal>
          <Reveal delay={400}>
            <ul className="mt-10 flex flex-wrap gap-x-6 gap-y-2">
              {[1, 2, 3].map((i) => (
                <li key={i} className="flex items-center gap-2 text-sm font-medium text-text-body">
                  <span className="material-symbols-outlined text-[18px] text-rose-primary">
                    check_circle
                  </span>
                  {t(`landing.hero.chip${i}`)}
                </li>
              ))}
            </ul>
          </Reveal>
        </div>

        <Reveal delay={250} className="relative">
          <div className="relative rounded-[2rem] border border-border/60 bg-white/90 p-8 shadow-xl shadow-rose-100/30 backdrop-blur">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-text-muted">
                {t('landing.hero.visual_label')}
              </p>
              <span className="relative flex h-2.5 w-2.5">
                <span className="absolute h-2.5 w-2.5 animate-ping rounded-full bg-rose-primary opacity-60" />
                <span className="relative h-2.5 w-2.5 rounded-full bg-rose-primary" />
              </span>
            </div>
            <HeartbeatLine className="mt-4 w-full text-rose-primary" />
            <div className="mt-6 grid grid-cols-2 gap-3">
              <div className="rounded-2xl bg-rose-light px-4 py-3">
                <p className="font-display text-lg font-semibold text-text-heading">
                  {t('landing.hero.visual_chip1')}
                </p>
                <p className="text-xs text-text-body">
                  {t('landing.hero.visual_chip1_sub')}
                </p>
              </div>
              <div className="rounded-2xl bg-surface px-4 py-3">
                <p className="font-display text-lg font-semibold text-text-heading">
                  {t('landing.hero.visual_chip2')}
                </p>
                <p className="text-xs text-text-body">
                  {t('landing.hero.visual_chip2_sub')}
                </p>
              </div>
            </div>
            <div className="mt-5 flex items-center gap-3 border-t border-border/50 pt-5">
              <img src={logo} alt="" className="h-10 w-10 rounded-xl" aria-hidden="true" />
              <div>
                <p className="text-sm font-semibold text-text-heading">MamaSafe</p>
                <p className="text-xs text-text-muted">{t('landing.hero.chip3')}</p>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
