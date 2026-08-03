import { useState } from "react";
import { useTranslation } from "react-i18next";
import { recordPostnatalVisit } from "../api/client";
import DateField from "./DateField";
import FieldHelp from "./FieldHelp";
import { pncVisitDate } from "../utils/dateCalc";

export default function PostnatalVisitForm({ deliveryId, deliveryDate, nextVisitNumber, newborns = [], onCreated, onCancel }) {
  const { t } = useTranslation();
  const [form, setForm] = useState({
    visit_date: new Date().toISOString().split("T")[0],
    mother_status: "good",
    uterus_firm: true,
    lochia_normal: true,
    temperature: "",
    systolic_bp: "",
    diastolic_bp: "",
    breast_exam: "",
    perineal_exam: "",
    hb_result: "",
    malaria_test: false,
    hiv_test: false,
    mental_health: "normal",
    notes: "",
    newborn_weight_kg: "",
    newborn_id: newborns.length === 1 ? newborns[0].id : "",
    breastfeeding_status: "",
  });
  const [saving, setSaving] = useState(false);

  const suggestedVisitDate =
    deliveryDate && nextVisitNumber ? pncVisitDate(deliveryDate, nextVisitNumber) : null;

  const inputClass =
    "w-full text-sm border border-border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  const handleChange = (field, value) => {
    setForm({ ...form, [field]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await recordPostnatalVisit({
        delivery_id: deliveryId,
        visit_number: nextVisitNumber,
        ...form,
        temperature: form.temperature ? parseFloat(form.temperature) : null,
        systolic_bp: form.systolic_bp ? parseFloat(form.systolic_bp) : null,
        diastolic_bp: form.diastolic_bp ? parseFloat(form.diastolic_bp) : null,
        hb_result: form.hb_result ? parseFloat(form.hb_result) : null,
        newborn_weight_kg: form.newborn_weight_kg || null,
        newborn_id: form.newborn_id || null,
        breastfeeding_status: form.breastfeeding_status || null,
      });
      onCreated?.();
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-2xl border border-border p-5">
      <h3 className="text-base font-semibold text-text-heading mb-4">
        {t("record_postnatal_visit")} — {t("pnc")} {nextVisitNumber}
      </h3>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
        <DateField
          label={t("visit_date")}
          value={form.visit_date}
          onChange={(v) => handleChange("visit_date", v)}
          computed={suggestedVisitDate}
          min={deliveryDate}
          required
          help={t("visit_date_help")}
          inputClass={inputClass}
        />
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("mother_status")}
            <FieldHelp text={t("mother_status_help")} />
          </label>
          <select
            value={form.mother_status}
            onChange={(e) => handleChange("mother_status", e.target.value)}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          >
            <option value="good">{t("good")}</option>
            <option value="complications">{t("complications")}</option>
          </select>
        </div>
      </div>

      {/* Newborn growth fields */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4">
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("newborn")} <span className="text-rose-500">*</span>
            <FieldHelp text={t("newborn_id_help")} />
          </label>
          {newborns.length === 0 ? (
            <p className="text-xs text-text-muted italic">{t("no_newborns")}</p>
          ) : (
            <select
              value={form.newborn_id}
              onChange={(e) => handleChange("newborn_id", Number(e.target.value))}
              className="w-full text-sm border border-border rounded-lg px-3 py-2"
            >
              <option value="">{t("select_newborn")}</option>
              {newborns.map((nb) => (
                <option key={nb.id} value={nb.id}>
                  {nb.name || t("newborn")} — {nb.sex === "female" ? t("female") : t("male")}
                  {nb.birth_weight ? ` (${nb.birth_weight}g)` : ""}
                </option>
              ))}
            </select>
          )}
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("newborn_weight_kg")}
            <FieldHelp text={t("newborn_weight_kg_help")} />
          </label>
          <input
            type="number"
            step="0.01"
            min="0"
            value={form.newborn_weight_kg}
            onChange={(e) => handleChange("newborn_weight_kg", e.target.value ? parseFloat(e.target.value) : "")}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
            placeholder="e.g. 4.5"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("breastfeeding_status")}
            <FieldHelp text={t("breastfeeding_status_help")} />
          </label>
          <select
            value={form.breastfeeding_status}
            onChange={(e) => handleChange("breastfeeding_status", e.target.value)}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          >
            <option value="">{t("select")}</option>
            <option value="exclusive">{t("exclusive")}</option>
            <option value="mixed">{t("mixed")}</option>
            <option value="not">{t("not_breastfeeding")}</option>
          </select>
        </div>
      </div>

      {/* Physical Exam */}
      <div className="mb-4">
        <h4 className="text-xs font-semibold text-text-heading uppercase tracking-wider mb-2">{t("physical_exam")}</h4>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <label className="flex items-center gap-2 text-xs text-text-muted">
            <input type="checkbox" checked={form.uterus_firm} onChange={(e) => handleChange("uterus_firm", e.target.checked)} className="rounded border-border" />
            <span className="inline-flex items-center gap-1">
              {t("uterus_firm")}
              <FieldHelp text={t("uterus_firm_help")} />
            </span>
          </label>
          <label className="flex items-center gap-2 text-xs text-text-muted">
            <input type="checkbox" checked={form.lochia_normal} onChange={(e) => handleChange("lochia_normal", e.target.checked)} className="rounded border-border" />
            <span className="inline-flex items-center gap-1">
              {t("lochia_normal")}
              <FieldHelp text={t("lochia_normal_help")} />
            </span>
          </label>
          <div>
            <label className="block text-[11px] text-text-muted mb-0.5">
              {t("temperature")}
              <FieldHelp text={t("temperature_help")} />
            </label>
            <input type="number" step="0.1" value={form.temperature} onChange={(e) => handleChange("temperature", e.target.value)} className="w-full text-xs border border-border rounded-lg px-2 py-1.5" />
          </div>
          <div className="col-span-2 sm:col-span-1">
            <label className="block text-[11px] text-text-muted mb-0.5">
              BP (sys/dia)
              <FieldHelp text={`${t("systolic_bp_help")} / ${t("diastolic_bp_help")}`} />
            </label>
            <div className="flex gap-1">
              <input type="number" value={form.systolic_bp} onChange={(e) => handleChange("systolic_bp", e.target.value)} className="w-1/2 text-xs border border-border rounded-lg px-2 py-1.5" placeholder="sys" />
              <input type="number" value={form.diastolic_bp} onChange={(e) => handleChange("diastolic_bp", e.target.value)} className="w-1/2 text-xs border border-border rounded-lg px-2 py-1.5" placeholder="dia" />
            </div>
          </div>
        </div>
      </div>

      {/* Labs & Tests */}
      <div className="mb-4">
        <h4 className="text-xs font-semibold text-text-heading uppercase tracking-wider mb-2">{t("labs_tests")}</h4>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div>
            <label className="block text-[11px] text-text-muted mb-0.5">
              {t("haemoglobin")}
              <FieldHelp text={t("haemoglobin_help")} />
            </label>
            <input type="number" step="0.1" value={form.hb_result} onChange={(e) => handleChange("hb_result", e.target.value)} className="w-full text-xs border border-border rounded-lg px-2 py-1.5" />
          </div>
          <label className="flex items-center gap-2 text-xs text-text-muted">
            <input type="checkbox" checked={form.malaria_test} onChange={(e) => handleChange("malaria_test", e.target.checked)} className="rounded border-border" />
            <span className="inline-flex items-center gap-1">
              {t("malaria_test")}
              <FieldHelp text={t("malaria_test_help")} />
            </span>
          </label>
          <label className="flex items-center gap-2 text-xs text-text-muted">
            <input type="checkbox" checked={form.hiv_test} onChange={(e) => handleChange("hiv_test", e.target.checked)} className="rounded border-border" />
            <span className="inline-flex items-center gap-1">
              {t("hiv_test")}
              <FieldHelp text={t("hiv_test_help")} />
            </span>
          </label>
          <div>
            <label className="block text-[11px] text-text-muted mb-0.5">
              {t("mental_health")}
              <FieldHelp text={t("mental_health_help")} />
            </label>
            <select value={form.mental_health} onChange={(e) => handleChange("mental_health", e.target.value)} className="w-full text-xs border border-border rounded-lg px-2 py-1.5">
              <option value="normal">{t("normal")}</option>
              <option value="concern">{t("concern")}</option>
            </select>
          </div>
        </div>
      </div>

      {/* Exam notes */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("breast_exam")}
            <FieldHelp text={t("breast_exam_help")} />
          </label>
          <input type="text" value={form.breast_exam} onChange={(e) => handleChange("breast_exam", e.target.value)} className="w-full text-sm border border-border rounded-lg px-3 py-2" />
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">
            {t("perineal_exam")}
            <FieldHelp text={t("perineal_exam_help")} />
          </label>
          <input type="text" value={form.perineal_exam} onChange={(e) => handleChange("perineal_exam", e.target.value)} className="w-full text-sm border border-border rounded-lg px-3 py-2" />
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-xs font-medium text-text-muted mb-1">
          {t("notes")}
          <FieldHelp text={t("notes_help")} />
        </label>
        <textarea value={form.notes} onChange={(e) => handleChange("notes", e.target.value)} placeholder={t("notes_placeholder")} className="w-full text-sm border border-border rounded-lg px-3 py-2" rows={2} />
      </div>

      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={saving}
          className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors disabled:opacity-50"
        >
          {saving ? t("saving") : t("save_visit")}
        </button>
        {onCancel && (
          <button type="button" onClick={onCancel} className="text-sm text-text-muted hover:text-text-heading">
            {t("cancel")}
          </button>
        )}
      </div>
    </form>
  );
}
