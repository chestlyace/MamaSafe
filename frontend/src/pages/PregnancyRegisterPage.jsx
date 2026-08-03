import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { registerPregnancy } from "../api/client";
import DateField from "../components/DateField";
import FieldHelp from "../components/FieldHelp";
import { eddFromLmp } from "../utils/dateCalc";

export default function PregnancyRegisterPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const [form, setForm] = useState({ lmp_date: "", edd_date: "", gravida: 1, parity: 0 });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const computedEdd = form.lmp_date ? eddFromLmp(form.lmp_date) : null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      await registerPregnancy({ ...form, patient_id: parseInt(id) });
      navigate(`/patients/${id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to start pregnancy");
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
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("start_pregnancy")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <div className="space-y-4">
            <DateField
              label={t("lmp_date")}
              value={form.lmp_date}
              onChange={(v) => set("lmp_date", v)}
              required
              help={t("lmp_date_help")}
              inputClass={inputClass}
            />

            <DateField
              label={t("edd_date")}
              value={form.edd_date}
              onChange={(v) => set("edd_date", v)}
              computed={computedEdd}
              help={t("edd_date_help")}
              icon="event_available"
              inputClass={inputClass}
            />

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t("gravida")}
                  <FieldHelp text={t("gravida_help")} />
                </label>
                <input
                  type="number"
                  min="1"
                  value={form.gravida}
                  onChange={(e) => set("gravida", parseInt(e.target.value) || 1)}
                  placeholder={t("gravida_placeholder")}
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t("parity")}
                  <FieldHelp text={t("parity_help")} />
                </label>
                <input
                  type="number"
                  min="0"
                  value={form.parity}
                  onChange={(e) => set("parity", parseInt(e.target.value) || 0)}
                  placeholder={t("parity_placeholder")}
                  className={inputClass}
                />
              </div>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t("start_pregnancy")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">add</span>
              <span>{t("start_pregnancy")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
