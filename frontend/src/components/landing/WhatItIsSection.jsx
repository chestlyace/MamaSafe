import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const PILLARS = [
  { key: 'p1', icon: 'monitor_heart', bg: 'bg-rose-light' },
  { key: 'p2', icon: 'event_upcoming', bg: 'bg-surface' },
  { key: 'p3', icon: 'notification_important', bg: 'bg-rose-50' },
];

export default function WhatItIsSection() {
  const { t } = useTranslation();
  return (
    <section id="what" className="bg-canvas py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.what.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.what.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-3xl text-lg leading-relaxed text-text-body">
            {t('landing.what.p')}
          </p>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          {PILLARS.map((p, i) => (
            <Reveal key={p.key} delay={i * 120}>
              <div className={`flex h-full flex-col rounded-3xl ${p.bg} p-8`}>
                <span className="material-symbols-outlined text-4xl text-rose-primary">
                  {p.icon}
                </span>
                <h3 className="mt-5 font-display text-xl font-semibold text-text-heading">
                  {t(`landing.what.${p.key}_t`)}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-text-body">
                  {t(`landing.what.${p.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
