import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const STEPS = [
  { icon: 'person_add', key: 's1' },
  { icon: 'monitor_heart', key: 's2' },
  { icon: 'calendar_month', key: 's3' },
  { icon: 'chat', key: 's4' },
  { icon: 'show_chart', key: 's5' },
  { icon: 'local_hospital', key: 's6' },
];

const VISITS = [8, 16, 20, 26, 30, 34, 36, 38];

function ANCTimeline() {
  const { t } = useTranslation();
  const [selected, setSelected] = useState(0);
  const week = VISITS[selected];

  return (
    <div className="mt-16 rounded-3xl border border-border bg-white p-8 shadow-sm">
      <Reveal>
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
          {t('landing.how.timeline_kicker')}
        </p>
      </Reveal>
      <Reveal delay={100}>
        <h3 className="mt-2 font-display text-2xl font-semibold text-text-heading">
          {t('landing.how.timeline_h3')}
        </h3>
      </Reveal>

      <Reveal delay={200}>
        <div className="relative mt-10 min-h-20 overflow-x-auto no-scrollbar pt-8 pb-4">
          <div className="relative mx-4 h-1 rounded-full bg-border" style={{ minWidth: 600 }}>
            {VISITS.map((w, i) => {
              const left = `${(w / 40) * 100}%`;
              const active = i === selected;
              return (
                <button
                  key={w}
                  type="button"
                  onClick={() => setSelected(i)}
                  className="absolute -top-3 flex -translate-x-1/2 flex-col items-center gap-1"
                  style={{ left }}
                  aria-label={`${t('landing.how.week_label')} ${w}`}
                >
                  <span
                    className={`flex h-7 w-7 items-center justify-center rounded-full border-2 text-xs font-bold transition-all ${
                      active
                        ? 'border-rose-primary bg-rose-primary text-white scale-125'
                        : 'border-rose-primary/40 bg-white text-rose-primary hover:scale-110'
                    }`}
                  >
                    {w}
                  </span>
                </button>
              );
            })}
            <div
              className="absolute -top-3 -translate-x-1/2"
              style={{ left: '100%' }}
            >
              <span className="flex h-7 items-center rounded-full bg-rose-light px-2 text-[10px] font-bold uppercase tracking-wide text-rose-primary">
                {t('landing.how.edd')}
              </span>
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal delay={300}>
        <div className="mt-8 rounded-2xl bg-canvas p-6">
          <p className="text-xs font-semibold uppercase tracking-wide text-rose-primary">
            {t('landing.how.week_label')} {week}
          </p>
          <p className="mt-2 text-base leading-relaxed text-text-heading">
            {t(`landing.how.v${week}`)}
          </p>
        </div>
      </Reveal>
    </div>
  );
}

export default function HowItWorksSection() {
  const { t } = useTranslation();
  return (
    <section id="how" className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.how.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.how.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {STEPS.map((s, i) => (
            <Reveal key={s.key} delay={i * 100}>
              <div className="flex gap-4 rounded-3xl border border-border bg-canvas p-6">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-primary/10 text-rose-primary">
                  <span className="material-symbols-outlined text-[24px]">{s.icon}</span>
                </span>
                <div>
                  <p className="text-xs font-bold text-rose-primary">0{i + 1}</p>
                  <h3 className="mt-1 font-display text-lg font-semibold text-text-heading">
                    {t(`landing.how.${s.key}_t`)}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-text-body">
                    {t(`landing.how.${s.key}_d`)}
                  </p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        <ANCTimeline />
      </div>
    </section>
  );
}
