import { useEffect, useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getPatientCard, recordVisit } from "../api/client";
import DateField from "../components/DateField";
import FieldHelp from "../components/FieldHelp";
import useComputedValue from "../hooks/useComputedValue";
import { gestationalAge, nextVisitDate } from "../utils/dateCalc";

const CLINICAL_FIELDS = [
  { key: "visit_number", type: "number", required: true, min: 1, max: 8, icon: "tag", help: "visit_number_help" },
  { key: "gestational_age", type: "number", min: 4, max: 42, icon: "schedule", help: "gestational_age_help" },
  { key: "weight", type: "number", step: "0.1", icon: "monitor_weight", placeholder: "weight_kg_placeholder", help: "weight_kg_help" },
  { key: "systolic_bp", type: "number", icon: "monitor_heart", placeholder: "systolic_bp_placeholder", help: "systolic_bp_help" },
  { key: "diastolic_bp", type: "number", icon: "favorite", placeholder: "diastolic_bp_placeholder", help: "diastolic_bp_help" },
  { key: "fundal_height", type: "number", step: "0.1", icon: "straighten", placeholder: "fundal_height_cm_placeholder", help: "fundal_height_cm_help" },
  { key: "foetal_hr", type: "number", icon: "ecg", placeholder: "foetal_hr_placeholder", help: "foetal_hr_help" },
];

const SELECT_FIELDS = [
  { key: "presentation", options: ["cephalic", "breech", "transverse"], help: "presentation_help" },
  { key: "urinalysis_protein", options: ["negative", "trace", "+1", "+2", "+3"], help: "urinalysis_protein_help" },
  { key: "urinalysis_glucose", options: ["negative", "trace", "+1", "+2", "+3"], help: "urinalysis_glucose_help" },
];

const CHECKBOX_FIELDS = [
  { key: "oedema", icon: "swelling", help: "oedema_help" },
  { key: "tt_vaccine", icon: "vaccines", help: "tt_vaccine_help" },
  { key: "malaria_prophylaxis", icon: "mosquito", help: "malaria_prophylaxis_help" },
  { key: "iron_supplements", icon: "medication", help: "iron_supplements_help" },
];

export default function VisitLogPage() {
  const { t } = useTranslation();
  const { id, pregnancyId } = useParams();
  const navigate = useNavigate();
  const [form, setForm] = useState({ visit_date: new Date().toISOString().slice(0, 10) });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [lmp, setLmp] = useState(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const card = await getPatientCard(id);
        const preg = (card.pregnancies || []).find(
          (p) => String(p.id) === String(pregnancyId)
        );
        if (!cancelled && preg?.lmp_date) setLmp(preg.lmp_date);
      } catch {
        /* ignore — form works without auto-fill */
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id, pregnancyId]);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const visitDate = form.visit_date || new Date().toISOString().slice(0, 10);
  const suggestedGa = lmp ? gestationalAge(lmp, visitDate) : null;
  const effectiveGa = form.gestational_age ?? suggestedGa;
  const suggestedNextVisit = lmp && effectiveGa ? nextVisitDate(lmp, effectiveGa) : null;

  const {
    handleChange: handleGaChange,
    showRevert: showGaRevert,
    revert: revertGa,
  } = useComputedValue(form.gestational_age ?? "", suggestedGa, (v) =>
    set("gestational_age", v === "" ? null : Number(v))
  );

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const payload = { ...form, pregnancy_id: parseInt(pregnancyId) };
      Object.keys(payload).forEach((k) => {
        if (payload[k] === "" || payload[k] === null) delete payload[k];
      });
      await recordVisit(payload);
      navigate(`/patients/${id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to log visit");
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass =
    "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to={`/patients/${id}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_card")}
      </Link>

      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("log_visit")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Clinical readings */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t("enter_patient_data")}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <DateField
              label={t("visit_date")}
              value={form.visit_date || ""}
              onChange={(v) => set("visit_date", v)}
              required
              help={t("visit_date_help")}
              inputClass={inputClass}
            />

            {CLINICAL_FIELDS.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)} {f.required && <span className="text-red-500">*</span>}
                  <FieldHelp text={t(f.help)} />
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type={f.type}
                    min={f.min}
                    max={f.max}
                    step={f.step}
                    value={form[f.key] ?? ""}
                    onChange={(e) =>
                      f.key === "gestational_age"
                        ? handleGaChange(e.target.value === "" ? "" : Number(e.target.value))
                        : set(f.key, f.type === "number" ? (e.target.value === "" ? null : Number(e.target.value)) : e.target.value)
                    }
                    required={f.required}
                    placeholder={f.placeholder ? t(f.placeholder) : undefined}
                    className={`${inputClass} pl-10`}
                  />
                </div>
                {f.key === "gestational_age" && showGaRevert && (
                  <button
                    type="button"
                    onClick={revertGa}
                    className="mt-1.5 text-xs text-rose-500 font-medium hover:underline flex items-center gap-1"
                  >
                    <span className="material-symbols-outlined text-[14px]">undo</span>
                    {t("revert_to_suggested")}
                  </button>
                )}
              </div>
            ))}

            {SELECT_FIELDS.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)}
                  <FieldHelp text={t(f.help)} />
                </label>
                <select
                  value={form[f.key] || ""}
                  onChange={(e) => set(f.key, e.target.value)}
                  className={inputClass}
                >
                  <option value="">—</option>
                  {f.options.map((o) => (
                    <option key={o} value={o}>{o}</option>
                  ))}
                </select>
              </div>
            ))}
          </div>
        </div>

        {/* Treatments */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">Treatments</h2>
          <div className="flex flex-wrap gap-5">
            {CHECKBOX_FIELDS.map((f) => (
              <label key={f.key} className="flex items-center gap-2.5 text-sm text-text-body cursor-pointer">
                <input
                  type="checkbox"
                  checked={form[f.key] || false}
                  onChange={(e) => set(f.key, e.target.checked)}
                  className="w-4 h-4 rounded border-border text-rose-500 focus:ring-rose-primary"
                />
                <span className="inline-flex items-center gap-1">
                  {t(f.key)}
                  <FieldHelp text={t(f.help)} />
                </span>
              </label>
            ))}
          </div>
        </div>

        {/* Notes & Next Visit */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-text-muted mb-1.5">
                {t("notes")}
                <FieldHelp text={t("notes_help")} />
              </label>
              <textarea
                value={form.notes || ""}
                onChange={(e) => set("notes", e.target.value)}
                rows={3}
                placeholder={t("notes_placeholder")}
                className={`${inputClass} resize-none`}
              />
            </div>
            <div className="sm:col-span-2">
              <DateField
                label={t("next_visit_date")}
                value={form.next_visit_date || ""}
                onChange={(v) => set("next_visit_date", v)}
                computed={suggestedNextVisit}
                help={t("next_visit_date_help")}
                icon="event"
                inputClass={inputClass}
              />
            </div>
          </div>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t("log_visit")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">save</span>
              <span>{t("log_visit")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
