import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { createPatient } from "../api/client";

const BLOOD_GROUPS = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

export default function PatientRegisterPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    full_name: "",
    date_of_birth: "",
    phone: "",
    address: "",
    facility: "",
    blood_group: "",
    allergies: "",
    emergency_contact_name: "",
    emergency_contact_phone: "",
  });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const payload = { ...form };
      Object.keys(payload).forEach((k) => {
        if (payload[k] === "") delete payload[k];
      });
      const patient = await createPatient(payload);
      navigate(`/patients/${patient.id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to register patient");
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass =
    "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  const fields = [
    { key: "full_name", type: "text", required: true, icon: "badge" },
    { key: "date_of_birth", type: "date", required: true, icon: "cake" },
    { key: "phone", type: "tel", icon: "phone" },
    { key: "address", type: "text", icon: "home" },
    { key: "facility", type: "text", icon: "local_hospital" },
    { key: "allergies", type: "text", icon: "warning" },
    { key: "emergency_contact_name", type: "text", icon: "person" },
    { key: "emergency_contact_phone", type: "tel", icon: "phone_in_talk" },
  ];

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patients")}
      </Link>

      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("register_patient")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t("patient_name")}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {fields.map((f) => (
              <div key={f.key} className={f.key === "full_name" || f.key === "date_of_birth" ? "sm:col-span-2" : ""}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)} {f.required && <span className="text-red-500">*</span>}
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type={f.type}
                    value={form[f.key]}
                    onChange={(e) => set(f.key, e.target.value)}
                    required={f.required}
                    className={`${inputClass} pl-10`}
                  />
                </div>
              </div>
            ))}

            {/* Blood group select */}
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium text-text-muted mb-1.5">{t("blood_group")}</label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                  bloodtype
                </span>
                <select
                  value={form.blood_group}
                  onChange={(e) => set("blood_group", e.target.value)}
                  className={`${inputClass} pl-10`}
                >
                  <option value="">—</option>
                  {BLOOD_GROUPS.map((bg) => (
                    <option key={bg} value={bg}>{bg}</option>
                  ))}
                </select>
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
              <span>{t("register_patient")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">person_add</span>
              <span>{t("register_patient")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
