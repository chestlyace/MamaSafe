import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';
import navLogo from '../../assets/nav_logo.svg';

export default function CTASection() {
  const { t } = useTranslation();
  return (
    <>
      <section className="relative overflow-hidden bg-gradient-to-br from-rose-primary to-rose-hover py-24 sm:py-32">
        <div
          className="pointer-events-none absolute -top-20 -right-20 h-72 w-72 rounded-full bg-white/10 blur-3xl"
          aria-hidden="true"
        />
        <div className="relative mx-auto max-w-4xl px-5 text-center">
          <Reveal>
            <h2 className="font-display text-4xl font-semibold leading-tight text-white sm:text-5xl">
              {t('landing.cta.h2')}
            </h2>
          </Reveal>
          <Reveal delay={100}>
            <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-white/85">
              {t('landing.cta.p')}
            </p>
          </Reveal>
          <Reveal delay={200}>
            <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
              <Link
                to="/chw-signup"
                className="rounded-full bg-white px-8 py-4 text-base font-semibold text-rose-primary shadow-lg hover:-translate-y-0.5 transition-all"
              >
                {t('landing.cta.primary')}
              </Link>
              <Link
                to="/login"
                className="rounded-full border border-white/30 px-8 py-4 text-base font-semibold text-white hover:bg-white/10 transition-colors"
              >
                {t('landing.cta.secondary')}
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      <footer className="bg-text-heading py-10">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-5 sm:flex-row">
          <div className="flex items-center gap-3">
            <img src={navLogo} alt="MamaSafe" className="h-8 w-auto brightness-0 invert" />
            <span className="text-xs text-white/50">· {t('landing.cta.footer_tagline')}</span>
          </div>
          <p className="text-xs text-white/50">{t('landing.cta.rights')}</p>
        </div>
      </footer>
    </>
  );
}
