import { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import {
  getNewbornGrowth,
  getPatientGrowthSummaries,
} from "../api/client";
import GrowthChart from "../components/GrowthChart";
import GrowthStatus from "../components/GrowthStatus";
import GrowthAlertCard from "../components/GrowthAlertCard";

export default function GrowthPage() {
  const { t } = useTranslation();
  const { id: patientId, newbornId } = useParams();
  const [growthData, setGrowthData] = useState(null);
  const [summaries, setSummaries] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (newbornId) {
      getNewbornGrowth(newbornId)
        .then(setGrowthData)
        .catch(() => setGrowthData(null))
        .finally(() => setLoading(false));
    } else if (patientId) {
      getPatientGrowthSummaries(patientId)
        .then(setSummaries)
        .catch(() => setSummaries(null))
        .finally(() => setLoading(false));
    }
  }, [patientId, newbornId]);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t("loading")}</span>
        </div>
      </main>
    );
  }

  if (newbornId && growthData) {
    return (
      <GrowthDetailView
        data={growthData}
        patientId={patientId}
        t={t}
        onAlertResolved={() => {
          getNewbornGrowth(newbornId).then(setGrowthData).catch(() => {});
        }}
      />
    );
  }

  if (summaries && summaries.length > 0) {
    return (
      <GrowthListView
        summaries={summaries}
        patientId={patientId}
        t={t}
      />
    );
  }

  return (
    <main className="max-w-[1200px] mx-auto px-5 py-12">
      <Link to={`/patients/${patientId}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patient")}
      </Link>
      <div className="text-center py-24 text-text-muted">{t("no_growth_data")}</div>
    </main>
  );
}

function GrowthDetailView({ data, patientId, t, onAlertResolved }) {
  const newbornName = data.newborn_name || t("newborn");

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24">
      <Link to={`/patients/${patientId}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patient")}
      </Link>

      <div className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">
          {t("growth_tracker")} — {newbornName}
        </h1>
        <p className="text-sm text-text-muted mt-1">
          {data.sex === "female" ? t("female") : t("male")}
          {data.birth_weight_g ? ` — ${t("birth_weight_g")}: ${data.birth_weight_g}g` : ""}
        </p>
      </div>

      {/* Alerts */}
      {data.alerts && data.alerts.length > 0 && (
        <div className="mb-6 space-y-3">
          <h2 className="text-sm font-semibold text-text-heading uppercase tracking-wider">{t("alerts")}</h2>
          {data.alerts.map((alert) => (
            <GrowthAlertCard key={alert.id} alert={alert} onResolved={onAlertResolved} />
          ))}
        </div>
      )}

      {/* Chart */}
      <div className="bg-white rounded-2xl border border-border p-5 mb-6">
        <h2 className="text-sm font-semibold text-text-heading uppercase tracking-wider mb-4">{t("growth_chart")}</h2>
        <GrowthChart measurements={data.measurements} sex={data.sex} />
      </div>

      {/* Measurement table */}
      {data.measurements && data.measurements.length > 0 && (
        <div className="bg-white rounded-2xl border border-border p-5">
          <h2 className="text-sm font-semibold text-text-heading uppercase tracking-wider mb-4">{t("measurements")}</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead>
                <tr className="text-text-muted border-b border-border">
                  <th className="text-left py-2 pr-4">{t("visit")}</th>
                  <th className="text-left py-2 pr-4">{t("date")}</th>
                  <th className="text-left py-2 pr-4">{t("age_days")}</th>
                  <th className="text-left py-2 pr-4">{t("weight_kg")}</th>
                  <th className="text-left py-2 pr-4">{t("percentile")}</th>
                  <th className="text-left py-2">{t("classification")}</th>
                </tr>
              </thead>
              <tbody>
                {data.measurements.map((m, i) => (
                  <tr key={m.visit_id} className="border-b border-border/50">
                    <td className="py-2 pr-4 font-medium text-text-heading">{m.visit_number}</td>
                    <td className="py-2 pr-4 text-text-muted">{m.visit_date}</td>
                    <td className="py-2 pr-4 text-text-muted">{m.age_days}</td>
                    <td className="py-2 pr-4 font-medium text-text-heading">{m.weight_kg}</td>
                    <td className="py-2 pr-4">{m.percentile?.replace(/_/g, " ")}</td>
                    <td className="py-2">
                      <GrowthStatus
                        classification={m.classification}
                        percentile={m.percentile}
                        zScore={m.z_score}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </main>
  );
}

function GrowthListView({ summaries, patientId, t }) {
  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24">
      <Link to={`/patients/${patientId}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patient")}
      </Link>

      <h1 className="text-2xl font-bold text-text-heading tracking-tight mb-6">{t("growth_tracker")}</h1>

      <div className="grid gap-4">
        {summaries.map((s) => (
          <Link
            key={s.newborn_id}
            to={`/patients/${patientId}/growth/${s.newborn_id}`}
            className="bg-white rounded-2xl border border-border p-5 hover:shadow-md transition-shadow block"
          >
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-semibold text-text-heading">
                {s.newborn_name || t("newborn")}
              </h3>
              <span className="text-xs text-text-muted">
                {s.sex === "female" ? t("female") : t("male")}
              </span>
            </div>
            <div className="flex items-center gap-3 text-xs text-text-muted">
              <span>{t("birth_weight_g")}: {s.birth_weight_g ? `${s.birth_weight_g}g` : "\u2014"}</span>
              {s.latest_weight_kg != null && (
                <span>{t("latest_weight")}: {s.latest_weight_kg}kg</span>
              )}
              <span>{s.measurement_count} {t("visits")}</span>
            </div>
            {s.active_alerts && s.active_alerts.length > 0 && (
              <div className="mt-2 flex gap-1 flex-wrap">
                {s.active_alerts.map((a) => (
                  <span
                    key={a.id}
                    className={`text-[11px] font-medium px-2 py-0.5 rounded-full ${
                      a.severity === "critical"
                        ? "bg-red-100 text-red-700"
                        : "bg-amber-100 text-amber-700"
                    }`}
                  >
                    {t(a.alert_type)}
                  </span>
                ))}
              </div>
            )}
            {s.latest_classification && (
              <div className="mt-2">
                <GrowthStatus
                  classification={s.latest_classification}
                  percentile={s.latest_percentile}
                  zScore={s.latest_z_score}
                />
              </div>
            )}
          </Link>
        ))}
      </div>
    </main>
  );
}
