import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import Reveal from './Reveal';
import mobileLogo from '../../assets/logo.svg';

export default function MobileAppSection() {
  const { t } = useTranslation();
  return (
    <section className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-rose-primary">
            {t('landing.mobile.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-text-heading sm:text-5xl">
            {t('landing.mobile.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-3xl text-lg leading-relaxed text-text-body">
            {t('landing.mobile.p')}
          </p>
        </Reveal>

        <div className="mt-14 grid gap-10 lg:grid-cols-[1fr_1fr] items-center">
          <Reveal delay={300}>
            <div className="relative">
              <div className="relative mx-auto w-64 rounded-[3rem] border-8 border-text-heading bg-text-heading p-2 shadow-2xl">
                <div className="rounded-[2.5rem] overflow-hidden bg-white aspect-[9/19.5]">
                  <div className="flex flex-col items-center justify-center h-full bg-gradient-to-b from-rose-light to-white p-8">
                    <img src={mobileLogo} alt="MamaSafe Mobile" className="w-24 h-24 mb-4" />
                    <p className="font-display text-2xl font-bold text-text-heading text-center">
                      MamaSafe
                    </p>
                    <p className="text-sm text-text-body mt-2 text-center">
                      {t('landing.mobile.tagline')}
                    </p>
                    <div className="mt-8 w-full space-y-3">
                      <div className="h-3 bg-rose-100 rounded-full w-3/4 mx-auto"></div>
                      <div className="h-3 bg-rose-100 rounded-full w-1/2 mx-auto"></div>
                      <div className="h-3 bg-rose-100 rounded-full w-2/3 mx-auto"></div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </Reveal>

          <Reveal delay={400}>
            <div className="space-y-6">
              <div className="flex gap-4">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-primary/10 text-rose-primary">
                  <span className="material-symbols-outlined text-[24px]">smartphone</span>
                </span>
                <div>
                  <h3 className="font-display text-lg font-semibold text-text-heading">
                    {t('landing.mobile.f1_t')}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-text-body">
                    {t('landing.mobile.f1_d')}
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-primary/10 text-rose-primary">
                  <span className="material-symbols-outlined text-[24px]">wifi_off</span>
                </span>
                <div>
                  <h3 className="font-display text-lg font-semibold text-text-heading">
                    {t('landing.mobile.f2_t')}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-text-body">
                    {t('landing.mobile.f2_d')}
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-rose-primary/10 text-rose-primary">
                  <span className="material-symbols-outlined text-[24px]">notifications_active</span>
                </span>
                <div>
                  <h3 className="font-display text-lg font-semibold text-text-heading">
                    {t('landing.mobile.f3_t')}
                  </h3>
                  <p className="mt-1 text-sm leading-relaxed text-text-body">
                    {t('landing.mobile.f3_d')}
                  </p>
                </div>
              </div>

              <div className="pt-6">
                <Link
                  to="/download"
                  className="inline-flex items-center gap-2 rounded-full bg-rose-primary px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-rose-primary/25 hover:bg-rose-hover hover:-translate-y-0.5 transition-all"
                >
                  {t('landing.mobile.cta')}
                  <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                </Link>
              </div>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
