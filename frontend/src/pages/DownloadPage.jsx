import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import Reveal from '../components/landing/Reveal';
import mobileLogo from '../assets/logo.svg';

export default function DownloadPage() {
  const { t } = useTranslation();
  return (
    <main className="min-h-screen bg-canvas text-text-body">
      <div className="mx-auto max-w-4xl px-5 py-20 sm:py-32">
        <Reveal>
          <div className="text-center">
            <img src={mobileLogo} alt="MamaSafe" className="mx-auto h-24 w-24 mb-6" />
            <h1 className="font-display text-5xl font-semibold leading-tight text-text-heading sm:text-6xl">
              {t('download.h1')}
            </h1>
            <p className="mt-6 text-xl leading-relaxed text-text-body">
              {t('download.sub')}
            </p>
          </div>
        </Reveal>

        <Reveal delay={200}>
          <div className="mt-16 rounded-3xl border border-border bg-white p-8 sm:p-12 shadow-sm">
            <div className="flex items-center gap-3 mb-6">
              <span className="material-symbols-outlined text-3xl text-rose-primary">
                schedule
              </span>
              <h2 className="font-display text-2xl font-semibold text-text-heading">
                {t('download.coming_soon')}
              </h2>
            </div>
            <p className="text-lg leading-relaxed text-text-body">
              {t('download.coming_soon_text')}
            </p>
          </div>
        </Reveal>

        <Reveal delay={300}>
          <div className="mt-12 grid gap-6 sm:grid-cols-2">
            <div className="rounded-3xl border border-border bg-white p-8 text-center">
              <span className="material-symbols-outlined text-5xl text-text-muted">
                phone_iphone
              </span>
              <h3 className="mt-4 font-display text-xl font-semibold text-text-heading">
                {t('download.ios')}
              </h3>
              <p className="mt-2 text-sm text-text-body">
                {t('download.ios_status')}
              </p>
              <button
                disabled
                className="mt-6 inline-flex items-center gap-2 rounded-full bg-surface px-6 py-3 text-sm font-semibold text-text-muted cursor-not-allowed"
              >
                {t('download.available_soon')}
              </button>
            </div>

            <div className="rounded-3xl border border-border bg-white p-8 text-center">
              <span className="material-symbols-outlined text-5xl text-text-muted">
                android
              </span>
              <h3 className="mt-4 font-display text-xl font-semibold text-text-heading">
                {t('download.android')}
              </h3>
              <p className="mt-2 text-sm text-text-body">
                {t('download.android_status')}
              </p>
              <button
                disabled
                className="mt-6 inline-flex items-center gap-2 rounded-full bg-surface px-6 py-3 text-sm font-semibold text-text-muted cursor-not-allowed"
              >
                {t('download.available_soon')}
              </button>
            </div>
          </div>
        </Reveal>

        <Reveal delay={400}>
          <div className="mt-16 rounded-3xl bg-rose-light p-8 sm:p-12">
            <h3 className="font-display text-2xl font-semibold text-text-heading mb-6">
              {t('download.features_title')}
            </h3>
            <div className="grid gap-6 sm:grid-cols-2">
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat1')}</p>
              </div>
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat2')}</p>
              </div>
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat3')}</p>
              </div>
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat4')}</p>
              </div>
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat5')}</p>
              </div>
              <div className="flex gap-3">
                <span className="material-symbols-outlined text-rose-primary">check_circle</span>
                <p className="text-sm text-text-body">{t('download.feat6')}</p>
              </div>
            </div>
          </div>
        </Reveal>

        <Reveal delay={500}>
          <div className="mt-16 text-center">
            <p className="text-text-body mb-6">{t('download.use_web')}</p>
            <Link
              to="/signup"
              className="inline-flex items-center gap-2 rounded-full bg-rose-primary px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-rose-primary/25 hover:bg-rose-hover hover:-translate-y-0.5 transition-all"
            >
              {t('download.web_cta')}
              <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
            </Link>
            <div className="mt-8">
              <Link
                to="/"
                className="text-sm text-text-muted hover:text-rose-primary transition-colors"
              >
                ← {t('download.back_home')}
              </Link>
            </div>
          </div>
        </Reveal>
      </div>
    </main>
  );
}
