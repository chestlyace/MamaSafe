import { useState } from "react";
import { useTranslation } from "react-i18next";
import { recordDelivery } from "../api/client";

export default function DeliveryForm({ pregnancyId, onCreated, onCancel }) {
  const { t } = useTranslation();
  const [form, setForm] = useState({
    delivery_date: new Date().toISOString().split("T")[0],
    delivery_location: "",
    delivered_by: "",
    complications: "",
    notes: "",
  });
  const [newborns, setNewborns] = useState([
    { name: "", sex: "female", birth_weight: "", apgar_score: "", crying_at_birth: true, breastfeeding: false, status: "alive" },
  ]);
  const [saving, setSaving] = useState(false);

  const updateNewborn = (idx, field, value) => {
    const updated = [...newborns];
    updated[idx][field] = value;
    setNewborns(updated);
  };

  const addNewborn = () => {
    setNewborns([...newborns, { name: "", sex: "female", birth_weight: "", apgar_score: "", crying_at_birth: true, breastfeeding: false, status: "alive" }]);
  };

  const removeNewborn = (idx) => {
    setNewborns(newborns.filter((_, i) => i !== idx));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const payload = {
        pregnancy_id: pregnancyId,
        ...form,
        newborns: newborns.map((nb) => ({
          ...nb,
          birth_weight: nb.birth_weight ? parseFloat(nb.birth_weight) : null,
          apgar_score: nb.apgar_score ? parseInt(nb.apgar_score) : null,
        })),
      };
      await recordDelivery(payload);
      onCreated?.();
    } catch (err) {
      console.error(err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-2xl border border-border p-5">
      <h3 className="text-base font-semibold text-text-heading mb-4">{t("record_delivery")}</h3>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">{t("delivery_date")} *</label>
          <input
            type="date"
            required
            value={form.delivery_date}
            onChange={(e) => setForm({ ...form, delivery_date: e.target.value })}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">{t("delivery_location")}</label>
          <input
            type="text"
            value={form.delivery_location}
            onChange={(e) => setForm({ ...form, delivery_location: e.target.value })}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">{t("delivered_by")}</label>
          <input
            type="text"
            value={form.delivered_by}
            onChange={(e) => setForm({ ...form, delivered_by: e.target.value })}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-text-muted mb-1">{t("complications")}</label>
          <input
            type="text"
            value={form.complications}
            onChange={(e) => setForm({ ...form, complications: e.target.value })}
            className="w-full text-sm border border-border rounded-lg px-3 py-2"
          />
        </div>
      </div>

      <div className="mb-4">
        <label className="block text-xs font-medium text-text-muted mb-1">{t("notes")}</label>
        <textarea
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
          className="w-full text-sm border border-border rounded-lg px-3 py-2"
          rows={2}
        />
      </div>

      {/* Newborns */}
      <div className="mb-4">
        <div className="flex items-center justify-between mb-2">
          <h4 className="text-sm font-semibold text-text-heading">{t("newborns")}</h4>
          <button type="button" onClick={addNewborn} className="text-xs text-rose-500 font-medium hover:text-rose-600 flex items-center gap-1">
            <span className="material-symbols-outlined text-[14px]">add</span>
            {t("add_newborn")}
          </button>
        </div>

        {newborns.map((nb, idx) => (
          <div key={idx} className="bg-surface rounded-xl p-3 mb-2 border border-border">
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-medium text-text-muted">{t("newborn")} {idx + 1}</span>
              {newborns.length > 1 && (
                <button type="button" onClick={() => removeNewborn(idx)} className="text-red-500 hover:text-red-600">
                  <span className="material-symbols-outlined text-[14px]">close</span>
                </button>
              )}
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <input
                type="text"
                placeholder={t("name")}
                value={nb.name}
                onChange={(e) => updateNewborn(idx, "name", e.target.value)}
                className="text-xs border border-border rounded-lg px-2 py-1.5"
              />
              <select
                value={nb.sex}
                onChange={(e) => updateNewborn(idx, "sex", e.target.value)}
                className="text-xs border border-border rounded-lg px-2 py-1.5"
              >
                <option value="female">{t("female")}</option>
                <option value="male">{t("male")}</option>
              </select>
              <input
                type="number"
                placeholder={t("birth_weight_g")}
                value={nb.birth_weight}
                onChange={(e) => updateNewborn(idx, "birth_weight", e.target.value)}
                className="text-xs border border-border rounded-lg px-2 py-1.5"
              />
              <input
                type="number"
                placeholder={t("apgar_score")}
                min="0"
                max="10"
                value={nb.apgar_score}
                onChange={(e) => updateNewborn(idx, "apgar_score", e.target.value)}
                className="text-xs border border-border rounded-lg px-2 py-1.5"
              />
            </div>
            <div className="flex items-center gap-4 mt-2">
              <label className="flex items-center gap-1.5 text-xs text-text-muted">
                <input
                  type="checkbox"
                  checked={nb.crying_at_birth}
                  onChange={(e) => updateNewborn(idx, "crying_at_birth", e.target.checked)}
                  className="rounded border-border"
                />
                {t("crying_at_birth")}
              </label>
              <label className="flex items-center gap-1.5 text-xs text-text-muted">
                <input
                  type="checkbox"
                  checked={nb.breastfeeding}
                  onChange={(e) => updateNewborn(idx, "breastfeeding", e.target.checked)}
                  className="rounded border-border"
                />
                {t("breastfeeding")}
              </label>
              <select
                value={nb.status}
                onChange={(e) => updateNewborn(idx, "status", e.target.value)}
                className="text-xs border border-border rounded-lg px-2 py-1"
              >
                <option value="alive">{t("alive")}</option>
                <option value="stillbirth">{t("stillbirth")}</option>
                <option value="neonatal_death">{t("neonatal_death")}</option>
              </select>
            </div>
          </div>
        ))}
      </div>

      <div className="flex items-center gap-3">
        <button
          type="submit"
          disabled={saving}
          className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors disabled:opacity-50"
        >
          {saving ? t("saving") : t("record_delivery")}
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
