import { useState, useEffect, useCallback } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getPatients } from "../api/client";

export default function PatientListPage() {
  const { t } = useTranslation();
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const fetchPatients = useCallback(async (term) => {
    setLoading(true);
    try {
      const data = await getPatients(term);
      setPatients(data);
    } catch {
      setPatients([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPatients(search);
  }, [search, fetchPatients]);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("patients")}</h1>
          <p className="text-sm text-text-muted mt-1">{t("patient_list")}</p>
        </div>
        <Link
          to="/patients/new"
          className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors inline-flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[18px]">person_add</span>
          {t("register_patient")}
        </Link>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
          search
        </span>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t("search_patients")}
          className="pl-10 pr-4 py-2.5 border border-border rounded-xl bg-white w-full text-sm focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
        />
      </div>

      {/* Patient list */}
      {loading ? (
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t("loading")}</span>
        </div>
      ) : patients.length > 0 ? (
        <div className="space-y-3">
          {patients.map((p) => (
            <Link
              key={p.id}
              to={`/patients/${p.id}`}
              className="block bg-white border border-border rounded-2xl p-4 hover:border-rose-primary/40 hover:shadow-sm transition-all"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-semibold text-text-heading">{p.full_name}</p>
                  <p className="text-sm text-text-muted mt-0.5">
                    {p.date_of_birth} &middot; {p.phone || "\u2014"} &middot; {p.facility || "\u2014"}
                  </p>
                </div>
                <span className="material-symbols-outlined text-text-muted">chevron_right</span>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-border rounded-2xl">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">people</span>
          <h3 className="text-lg font-semibold text-text-heading mb-1">
            {search ? t("no_patients_found") : t("no_patients_yet")}
          </h3>
          <p className="text-sm text-text-muted mb-6 max-w-xs">
            {search ? t("search_patients") : t("register_first_patient")}
          </p>
          {!search && (
            <Link
              to="/patients/new"
              className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors"
            >
              {t("register_patient")}
            </Link>
          )}
        </div>
      )}
    </main>
  );
}
