import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getMonthlyReport, downloadMonthlyReportCsv } from '../api/client';

const MONTH_NAMES = Array.from({ length: 12 }, (_, i) =>
  new Intl.DateTimeFormat(undefined, { month: 'long' }).format(new Date(2000, i, 1))
);

export default function MonthlyReportPage() {
  const { t } = useTranslation();
  const now = new Date();
  const [year, setYear] = useState(now.getFullYear());
  const [month, setMonth] = useState(now.getMonth()); // 0-indexed
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);

  const load = () => {
    setLoading(true);
    getMonthlyReport(year, month + 1)
      .then(setData)
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, [year, month]);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('monthly_report')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('ministry_of_health_report')}</p>
        </div>
        <div className="flex items-center gap-2">
          <select value={month} onChange={(e) => setMonth(Number(e.target.value))}
            className="px-3 py-2 bg-white border border-border rounded-lg text-sm text-text-heading">
            {MONTH_NAMES.map((name, i) => (
              <option key={i} value={i}>{name}</option>
            ))}
          </select>
          <select value={year} onChange={(e) => setYear(Number(e.target.value))}
            className="px-3 py-2 bg-white border border-border rounded-lg text-sm text-text-heading">
            {[2024, 2025, 2026].map((y) => (
              <option key={y} value={y}>{y}</option>
            ))}
          </select>
          {data && (
            <button onClick={() => downloadMonthlyReportCsv(year, month + 1)}
              className="bg-rose-500 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-rose-600 transition-colors flex items-center gap-1.5">
              <span className="material-symbols-outlined text-[18px]">download</span>
              {t('download_csv')}
            </button>
          )}
        </div>
      </header>

      {loading ? (
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      ) : !data ? (
        <div className="text-center py-24 text-text-muted">{t('error')}</div>
      ) : (
        <div className="space-y-6">
          {/* Period header */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h2 className="text-lg font-bold text-text-heading">{data.reporting_period}</h2>
            <p className="text-sm text-text-muted">{data.district}{data.region ? ` — ${data.region}` : ''}</p>
          </div>

          {/* Workforce */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('workforce')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('total_chws')}</div><div className="text-lg font-bold">{data.total_chws}</div></div>
              <div><div className="text-xs text-text-muted">{t('active_chws')}</div><div className="text-lg font-bold">{data.active_chws}</div></div>
            </div>
          </div>

          {/* Patients */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('patient_overview')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('total_registered')}</div><div className="text-lg font-bold">{data.total_patients_registered}</div></div>
              <div><div className="text-xs text-text-muted">{t('new_this_month')}</div><div className="text-lg font-bold">{data.new_patients_this_month}</div></div>
            </div>
          </div>

          {/* Assessments */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('risk_assessments')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('total_assessments')}</div><div className="text-lg font-bold">{data.total_assessments}</div></div>
              <div><div className="text-xs text-text-muted">{t('high_risk')}</div><div className="text-lg font-bold text-red-600">{data.high_risk_detected}</div></div>
              <div><div className="text-xs text-text-muted">{t('mid_risk')}</div><div className="text-lg font-bold text-amber-600">{data.mid_risk_detected}</div></div>
              <div><div className="text-xs text-text-muted">{t('low_risk')}</div><div className="text-lg font-bold text-green-600">{data.low_risk_detected}</div></div>
            </div>
          </div>

          {/* Referrals */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('referrals')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('total_referrals')}</div><div className="text-lg font-bold">{data.total_referrals}</div></div>
              <div><div className="text-xs text-text-muted">{t('completion_rate')}</div><div className="text-lg font-bold">{data.referral_completion_rate}%</div></div>
            </div>
          </div>

          {/* Deliveries */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('deliveries')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('total_deliveries')}</div><div className="text-lg font-bold">{data.total_deliveries}</div></div>
              <div><div className="text-xs text-text-muted">{t('live_births')}</div><div className="text-lg font-bold text-green-600">{data.live_births}</div></div>
              <div><div className="text-xs text-text-muted">{t('stillbirths')}</div><div className="text-lg font-bold text-red-600">{data.stillbirths}</div></div>
            </div>
          </div>

          {/* Postnatal */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('postnatal_care')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('pnc1_completion')}</div><div className="text-lg font-bold">{data.pnc1_completion_rate}%</div></div>
              <div><div className="text-xs text-text-muted">{t('pnc2_completion')}</div><div className="text-lg font-bold">{data.pnc2_completion_rate}%</div></div>
              <div><div className="text-xs text-text-muted">{t('pnc3_completion')}</div><div className="text-lg font-bold">{data.pnc3_completion_rate}%</div></div>
              <div><div className="text-xs text-text-muted">{t('exclusive_breastfeeding')}</div><div className="text-lg font-bold">{data.exclusive_breastfeeding_rate}%</div></div>
            </div>
          </div>

          {/* Mental Health & Growth */}
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-3">{t('mental_health_and_growth')}</h3>
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <div><div className="text-xs text-text-muted">{t('phq2_screens')}</div><div className="text-lg font-bold">{data.phq2_screens_performed}</div></div>
              <div><div className="text-xs text-text-muted">{t('phq2_positive')}</div><div className="text-lg font-bold text-red-600">{data.phq2_positive_count}</div></div>
              <div><div className="text-xs text-text-muted">{t('growth_alerts')}</div><div className="text-lg font-bold">{data.growth_alerts_generated}</div></div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
