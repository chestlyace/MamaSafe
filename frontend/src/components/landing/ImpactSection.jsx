import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

export default function ImpactSection() {
  const { t } = useTranslation();
  return (
    <section className="bg-canvas py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.impact.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.impact.h2')}
          </h2>
        </Reveal>
        <div className="mt-10 grid gap-10 lg:grid-cols-[1.2fr_0.8fr]">
          <Reveal delay={200}>
            <div className="space-y-5">
              <p className="text-lg leading-relaxed text-text-body">{t('landing.impact.p1')}</p>
              <p className="text-lg leading-relaxed text-text-body">{t('landing.impact.p2')}</p>
            </div>
          </Reveal>
          <Reveal delay={300}>
            <blockquote className="flex h-full flex-col justify-center rounded-3xl border-l-4 border-rose-primary bg-white p-8">
              <span className="material-symbols-outlined text-3xl text-rose-primary">format_quote</span>
              <p className="mt-4 font-display text-2xl font-semibold leading-snug text-text-heading">
                {t('landing.impact.quote')}
              </p>
            </blockquote>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
