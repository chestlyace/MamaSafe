import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';
import useCountUp from './useCountUp';

function Stat({ value, decimals = 0, prefix = '', suffix = '', label, source, start }) {
  const n = useCountUp(value, { start, decimals });
  return (
    <div className="rounded-3xl border border-border bg-white p-7 shadow-sm">
      <p className="font-display text-5xl font-semibold text-rose-primary">
        {prefix}
        {decimals ? n.toFixed(decimals) : Math.round(n)}
        {suffix}
      </p>
      <p className="mt-3 text-sm leading-relaxed text-text-body">{label}</p>
      <p className="mt-2 text-[11px] uppercase tracking-wide text-text-muted">{source}</p>
    </div>
  );
}

export default function ProblemSection() {
  const { t } = useTranslation();
  const ref = useRef(null);
  const [start, setStart] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { setStart(true); io.disconnect(); } },
      { threshold: 0.25 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <section id="problem" ref={ref} className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.problem.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.problem.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-3xl text-lg leading-relaxed text-text-body">
            {t('landing.problem.p1')}
          </p>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          <Reveal delay={100}>
            <Stat
              value={t('landing.problem.stat1_value')}
              label={t('landing.problem.stat1_label')}
              source={t('landing.problem.stat1_source')}
              start={start}
            />
          </Reveal>
          <Reveal delay={200}>
            <Stat
              value={t('landing.problem.stat2_value')}
              prefix={t('landing.problem.stat2_prefix')}
              suffix={t('landing.problem.stat2_suffix')}
              label={t('landing.problem.stat2_label')}
              source={t('landing.problem.stat2_source')}
              start={start}
            />
          </Reveal>
          <Reveal delay={300}>
            <Stat
              value={t('landing.problem.stat3_value')}
              label={t('landing.problem.stat3_label')}
              source={t('landing.problem.stat3_source')}
              start={start}
            />
          </Reveal>
        </div>

        <Reveal delay={400}>
          <div className="mt-10 flex flex-col items-start gap-4 rounded-3xl border border-border bg-canvas px-8 py-7 sm:flex-row sm:items-center sm:gap-8">
            <p className="font-display text-3xl font-semibold text-rose-primary">
              {t('landing.problem.progress_title')}
            </p>
            <div>
              <p className="text-sm leading-relaxed text-text-body">
                {t('landing.problem.progress_caption')}
              </p>
              <p className="mt-1 text-[11px] uppercase tracking-wide text-text-muted">
                {t('landing.problem.progress_source')}
              </p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
