import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const FEATURES = [
  { icon: 'monitor_heart', key: 'f1' },
  { icon: 'query_stats', key: 'f2' },
  { icon: 'event_upcoming', key: 'f3' },
  { icon: 'chat', key: 'f4' },
  { icon: 'show_chart', key: 'f5' },
  { icon: 'local_hospital', key: 'f6' },
  { icon: 'child_care', key: 'f7' },
  { icon: 'domain', key: 'f8' },
  { icon: 'translate', key: 'f9' },
];

export default function FeaturesSection() {
  const { t } = useTranslation();
  return (
    <section id="features" className="bg-canvas py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.features.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.features.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => (
            <Reveal key={f.key} delay={i * 80}>
              <div className="flex h-full flex-col rounded-3xl border border-border bg-white p-7">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-rose-light text-rose-primary">
                  <span className="material-symbols-outlined text-[22px]">{f.icon}</span>
                </span>
                <h3 className="mt-5 font-display text-lg font-semibold text-text-heading">
                  {t(`landing.features.${f.key}_t`)}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-text-body">
                  {t(`landing.features.${f.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
