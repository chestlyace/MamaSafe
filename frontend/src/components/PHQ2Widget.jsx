import { useState } from "react";
import { useTranslation } from "react-i18next";
import { createMentalHealthScreening } from "../api/client";

export default function PHQ2Widget({ patientId, postnatalVisitId, onCreated }) {
  const { t } = useTranslation();
  const [q1, setQ1] = useState(null);
  const [q2, setQ2] = useState(null);
  const [saving, setSaving] = useState(false);
  const [result, setResult] = useState(null);

  const score = q1 !== null && q2 !== null ? q1 + q2 : null;

  const handleSubmit = async () => {
    if (score === null) return;
    setSaving(true);
    try {
      const payload = {
        patient_id: patientId,
        phq2_score: score,
        phq2_q1: q1,
        phq2_q2: q2,
      };
      if (postnatalVisitId) {
        payload.postnatal_visit_id = postnatalVisitId;
      }
      const data = await createMentalHealthScreening(payload);
      setResult(data);
      onCreated?.(data);
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  if (result) {
    return (
      <div className={`rounded-xl p-4 ${result.risk_level === "high" ? "bg-red-50 border border-red-200" : "bg-green-50 border border-green-200"}`}>
        <div className="flex items-center gap-2 mb-1">
          <span className="material-symbols-outlined text-[18px]">
            {result.risk_level === "high" ? "warning" : "check_circle"}
          </span>
          <span className="text-sm font-semibold text-text-heading">
            {result.risk_level === "high" ? t("high_risk") : t("low_risk")}
          </span>
        </div>
        <p className="text-xs text-text-muted">
          {t("phq2_score")}: {result.phq2_score}/6
        </p>
      </div>
    );
  }

  const options = [
    { value: 0, label: t("phq2_not_at_all") },
    { value: 1, label: t("phq2_several_days") },
    { value: 2, label: t("phq2_more_than_half") },
    { value: 3, label: t("phq2_nearly_every") },
  ];

  return (
    <div className="bg-white rounded-xl border border-border p-4">
      <div className="flex items-center gap-2 mb-4">
        <span className="material-symbols-outlined text-[18px] text-rose-500">psychology</span>
        <h4 className="text-sm font-semibold text-text-heading">{t("phq2_screening")}</h4>
      </div>

      <div className="space-y-4">
        <div>
          <p className="text-xs font-medium text-text-heading mb-2">{t("phq2_q1")}</p>
          <div className="grid grid-cols-2 gap-2">
            {options.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setQ1(opt.value)}
                className={`text-left text-xs rounded-lg px-3 py-2 border transition-colors ${
                  q1 === opt.value
                    ? "bg-rose-50 border-rose-300 text-rose-700 font-medium"
                    : "border-border text-text-muted hover:border-rose-200"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        <div>
          <p className="text-xs font-medium text-text-heading mb-2">{t("phq2_q2")}</p>
          <div className="grid grid-cols-2 gap-2">
            {options.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setQ2(opt.value)}
                className={`text-left text-xs rounded-lg px-3 py-2 border transition-colors ${
                  q2 === opt.value
                    ? "bg-rose-50 border-rose-300 text-rose-700 font-medium"
                    : "border-border text-text-muted hover:border-rose-200"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {score !== null && (
        <div className="mt-4 pt-3 border-t border-border">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs text-text-muted">{t("phq2_score")}</span>
            <span className={`text-sm font-bold ${score >= 3 ? "text-red-600" : "text-green-600"}`}>
              {score}/6
            </span>
          </div>
          <button
            onClick={handleSubmit}
            disabled={saving}
            className="w-full bg-rose-500 text-white text-xs font-semibold rounded-lg py-2.5 hover:bg-rose-600 transition-colors disabled:opacity-50"
          >
            {saving ? t("saving") : t("submit_screening")}
          </button>
        </div>
      )}
    </div>
  );
}
