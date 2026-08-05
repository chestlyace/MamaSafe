import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { riskScore } from '../../utils/riskScore';
import Reveal from './Reveal';

const SLIDERS = [
  { key: 'age', field: 'age', min: 15, max: 49, step: 1, default: 25 },
  { key: 'sbp', field: 'systolicBP', min: 90, max: 180, step: 1, default: 110 },
  { key: 'sugar', field: 'bloodSugar', min: 2.5, max: 11, step: 0.1, default: 5 },
  { key: 'temp', field: 'bodyTemp', min: 35.5, max: 40, step: 0.1, default: 36.8 },
  { key: 'hr', field: 'heartRate', min: 60, max: 120, step: 1, default: 80 },
];

const LEVEL_COLORS = {
  low: 'var(--color-risk-low)',
  mid: 'var(--color-risk-mid)',
  high: 'var(--color-risk-high)',
};

function polar(score, r = 80) {
  const a = Math.PI - score * Math.PI;
  return [100 + r * Math.cos(a), 100 - r * Math.sin(a)];
}

function arcPath(s0, s1) {
  const [x0, y0] = polar(s0);
  const [x1, y1] = polar(s1);
  return `M ${x0} ${y0} A 80 80 0 0 1 ${x1} ${y1}`;
}

function Gauge({ score, level }) {
  const [nx, ny] = polar(score, 62);
  return (
    <svg viewBox="0 0 200 120" className="w-full max-w-[280px]" aria-hidden="true">
      <path d={arcPath(0, 0.34)} stroke="var(--color-risk-low)" strokeWidth="14" fill="none" strokeLinecap="round" />
      <path d={arcPath(0.34, 0.67)} stroke="var(--color-risk-mid)" strokeWidth="14" fill="none" />
      <path d={arcPath(0.67, 1)} stroke="var(--color-risk-high)" strokeWidth="14" fill="none" strokeLinecap="round" />
      <line
        x1="100" y1="100" x2={nx} y2={ny}
        stroke={LEVEL_COLORS[level]}
        strokeWidth="3"
        strokeLinecap="round"
        style={{ transition: 'all 0.5s ease-out' }}
      />
      <circle cx="100" cy="100" r="5" fill={LEVEL_COLORS[level]} style={{ transition: 'fill 0.5s ease-out' }} />
    </svg>
  );
}

export default function RiskSimulator() {
  const { t } = useTranslation();
  const [values, setValues] = useState(() =>
    Object.fromEntries(SLIDERS.map((s) => [s.field, s.default]))
  );

  const result = useMemo(() => riskScore(values), [values]);

  const update = (field, raw) => {
    setValues((prev) => ({ ...prev, [field]: parseFloat(raw) }));
  };

  const guidanceKey = `landing.sim.g_${result.level}`;
  const levelKey = `landing.sim.${result.level}`;

  return (
    <section id="sim" className="bg-rose-50 py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.sim.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.sim.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-text-body">
            {t('landing.sim.p')}
          </p>
        </Reveal>

        <Reveal delay={300}>
          <div className="mt-12 grid gap-10 lg:grid-cols-[1fr_auto]">
            <div className="space-y-6">
              {SLIDERS.map((s) => (
                <div key={s.key}>
                  <div className="flex items-center justify-between">
                    <label htmlFor={`sim-${s.key}`} className="text-sm font-semibold text-text-heading">
                      {t(`landing.sim.${s.key}`)}
                    </label>
                    <span className="rounded-full bg-white px-3 py-1 text-sm font-bold tabular-nums text-rose-primary border border-border">
                      {values[s.field]}
                    </span>
                  </div>
                  <input
                    id={`sim-${s.key}`}
                    type="range"
                    className="landing-range mt-2 h-2 w-full cursor-pointer appearance-none rounded-full bg-border"
                    min={s.min}
                    max={s.max}
                    step={s.step}
                    value={values[s.field]}
                    onChange={(e) => update(s.field, e.target.value)}
                  />
                </div>
              ))}
            </div>

            <div className="flex flex-col items-center rounded-3xl bg-white border border-border p-8 shadow-sm">
              <Gauge score={result.score} level={result.level} />
              <p
                className="mt-4 font-display text-2xl font-bold"
                style={{ color: LEVEL_COLORS[result.level], transition: 'color 0.5s ease-out' }}
              >
                {t(levelKey)}
              </p>
              <p className="mt-2 max-w-xs text-center text-sm leading-relaxed text-text-body">
                {t(guidanceKey)}
              </p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={400}>
          <p className="mt-8 text-xs leading-relaxed text-text-muted">
            {t('landing.sim.disclaimer')}
          </p>
        </Reveal>
      </div>
    </section>
  );
}
