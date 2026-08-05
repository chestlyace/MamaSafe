import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const AUDIENCES = [
  { icon: 'health_and_safety', key: 'a1', bg: 'bg-rose-light' },
  { icon: 'favorite', key: 'a2', bg: 'bg-surface' },
  { icon: 'insights', key: 'a3', bg: 'bg-rose-50' },
];

export default function AudienceSection() {
  const { t } = useTranslation();
  return (
    <section id="audiences" className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.audiences.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.audiences.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          {AUDIENCES.map((a, i) => (
            <Reveal key={a.key} delay={i * 120}>
              <div className={`flex h-full flex-col rounded-3xl ${a.bg} p-8`}>
                <span className="material-symbols-outlined text-4xl text-rose-primary">
                  {a.icon}
                </span>
                <h3 className="mt-5 font-display text-xl font-semibold text-text-heading">
                  {t(`landing.audiences.${a.key}_t`)}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-text-body">
                  {t(`landing.audiences.${a.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
