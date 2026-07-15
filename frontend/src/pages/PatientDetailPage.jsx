import { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getPatientCard } from "../api/client";

export default function PatientDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("current");

  useEffect(() => {
    getPatientCard(id)
      .then((data) => setCard(data))
      .catch(() => setCard(null))
      .finally(() => setLoading(false));
  }, [id]);

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

  if (!card) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
          <span className="material-symbols-outlined text-[16px]">arrow_back</span>
          {t("back_to_patients")}
        </Link>
        <div className="text-center py-24 text-text-muted">{t("patient_not_found")}</div>
      </main>
    );
  }

  const { patient, pregnancy, visits } = card;
  const hasActivePregnancy = pregnancy && pregnancy.is_active;

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Back link */}
      <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patients")}
      </Link>

      {/* Patient Header */}
      <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-text-heading tracking-tight">{patient.full_name}</h1>
            <p className="text-sm text-text-muted mt-1">
              {patient.date_of_birth} &middot; {patient.phone || "\u2014"} &middot; {patient.facility || "\u2014"}
            </p>
          </div>
          {!hasActivePregnancy && (
            <Link
              to={`/patients/${id}/pregnancies/new`}
              className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors inline-flex items-center gap-2 flex-shrink-0"
            >
              <span className="material-symbols-outlined text-[18px]">add</span>
              {t("start_pregnancy")}
            </Link>
          )}
        </div>

        {/* Info row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-4 pt-4 border-t border-border">
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("blood_group")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.blood_group || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("allergies")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.allergies || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("emergency_contact_name")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.emergency_contact_name || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("emergency_contact_phone")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.emergency_contact_phone || "\u2014"}</p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-surface rounded-xl p-1 w-fit">
        <button
          onClick={() => setActiveTab("current")}
          className={`px-5 py-2 rounded-lg text-sm font-semibold transition-colors ${
            activeTab === "current"
              ? "bg-white text-text-heading shadow-sm"
              : "text-text-muted hover:text-text-body"
          }`}
        >
          {t("active_pregnancy")}
        </button>
        <button
          onClick={() => setActiveTab("past")}
          className={`px-5 py-2 rounded-lg text-sm font-semibold transition-colors ${
            activeTab === "past"
              ? "bg-white text-text-heading shadow-sm"
              : "text-text-muted hover:text-text-body"
          }`}
        >
          {t("past_pregnancies")}
        </button>
      </div>

      {/* Tab content */}
      {activeTab === "current" ? (
        hasActivePregnancy ? (
          <PregnancySection pregnancy={pregnancy} visits={visits} patientId={id} t={t} />
        ) : (
          <div className="bg-white rounded-2xl border border-border p-8 text-center">
            <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">pregnant_woman</span>
            <h3 className="text-lg font-semibold text-text-heading mb-1">{t("no_active_pregnancy")}</h3>
            <p className="text-sm text-text-muted mb-6">{t("register_first_patient")}</p>
            <Link
              to={`/patients/${id}/pregnancies/new`}
              className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors inline-flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">add</span>
              {t("start_pregnancy")}
            </Link>
          </div>
        )
      ) : (
        <div>
          {card.pregnancies && card.pregnancies.length > 0 ? (
            card.pregnancies
              .filter((p) => !p.is_active)
              .map((p) => (
                <PregnancySection key={p.id} pregnancy={p} visits={p.visits || []} patientId={id} t={t} />
              ))
          ) : (
            <div className="bg-white rounded-2xl border border-border p-8 text-center">
              <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">history</span>
              <h3 className="text-lg font-semibold text-text-heading mb-1">{t("no_past_pregnancies")}</h3>
            </div>
          )}
        </div>
      )}
    </main>
  );
}

function PregnancySection({ pregnancy, visits, patientId, t }) {
  const [expanded, setExpanded] = useState(true);

  return (
    <div className="bg-white rounded-2xl border border-border p-5 mb-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="flex items-center gap-2 flex-wrap">
            <h3 className="font-semibold text-text-heading">
              {t("lmp_date")}: {pregnancy.lmp_date}
            </h3>
            {pregnancy.is_active && (
              <span className="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                {t("active_pregnancy")}
              </span>
            )}
            {!pregnancy.is_active && pregnancy.delivery_outcome && (
              <span className="bg-surface text-text-heading text-xs font-medium px-2.5 py-0.5 rounded-full border border-border">
                {t(pregnancy.delivery_outcome === "live_birth" ? "live_birth" : pregnancy.delivery_outcome === "stillbirth" ? "stillbirth" : "miscarriage")}
              </span>
            )}
          </div>
          <p className="text-sm text-text-muted mt-1">
            {t("edd_date")}: {pregnancy.edd_date || "\u2014"} &middot; G{pregnancy.gravida} P{pregnancy.parity}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-text-muted">
            {visits.length} {t("visit_count")}
          </span>
          <button
            onClick={() => setExpanded(!expanded)}
            className="text-text-muted hover:text-text-heading transition-colors"
          >
            <span className="material-symbols-outlined">
              {expanded ? "expand_less" : "expand_more"}
            </span>
          </button>
        </div>
      </div>

      {/* Delivery info */}
      {!pregnancy.is_active && pregnancy.delivery_date && (
        <div className="bg-surface rounded-xl p-3 mb-4">
          <p className="text-xs text-text-muted">{t("delivery_date")}: {pregnancy.delivery_date}</p>
        </div>
      )}

      {/* Expanded content */}
      {expanded && (
        <div className="pt-4 border-t border-border">
          {/* Log visit button */}
          {pregnancy.is_active && (
            <Link
              to={`/patients/${patientId}/pregnancies/${pregnancy.id}/visits/new`}
              className="inline-flex items-center gap-2 bg-rose-500 text-white text-xs font-semibold rounded-lg px-4 py-2 mb-6 hover:bg-rose-600 transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">add</span>
              {t("log_visit")}
            </Link>
          )}

          {/* Visit timeline */}
          {visits.length === 0 ? (
            <div className="text-center py-8">
              <span className="material-symbols-outlined text-[36px] text-text-muted/40 mb-2">event_note</span>
              <p className="text-sm text-text-muted">{t("no_visits_recorded")}</p>
            </div>
          ) : (
            <div className="relative">
              {/* Vertical line */}
              <div className="absolute left-[15px] top-0 bottom-0 w-0.5 bg-border" />

              <div className="space-y-0">
                {visits.map((visit, idx) => (
                  <div key={visit.id} className="relative flex gap-4 pb-6 last:pb-0">
                    {/* Circle marker */}
                    <div className="relative z-10 flex-shrink-0 w-[31px] h-[31px] rounded-full bg-rose-500 border-4 border-white flex items-center justify-center">
                      <span className="text-[10px] font-bold text-white">{visit.visit_number}</span>
                    </div>

                    {/* Visit card */}
                    <div className="flex-1 bg-surface rounded-xl p-4 -mt-1">
                      <div className="flex items-center justify-between mb-3">
                        <h4 className="text-sm font-semibold text-text-heading">
                          {t("visit_number")} {visit.visit_number}
                        </h4>
                        <span className="text-xs text-text-muted">{visit.visit_date}</span>
                      </div>

                      {/* Vitals grid */}
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                        {visit.gestational_age != null && (
                          <div>
                            <p className="text-text-muted">{t("gestational_age")}</p>
                            <p className="font-medium text-text-heading">{visit.gestational_age}w</p>
                          </div>
                        )}
                        {visit.weight != null && (
                          <div>
                            <p className="text-text-muted">{t("weight_kg")}</p>
                            <p className="font-medium text-text-heading">{visit.weight}</p>
                          </div>
                        )}
                        {visit.systolic_bp != null && (
                          <div>
                            <p className="text-text-muted">BP</p>
                            <p className="font-medium text-text-heading">
                              {visit.systolic_bp}/{visit.diastolic_bp}
                            </p>
                          </div>
                        )}
                        {visit.haemoglobin != null && (
                          <div>
                            <p className="text-text-muted">{t("haemoglobin")}</p>
                            <p className="font-medium text-text-heading">{visit.haemoglobin}</p>
                          </div>
                        )}
                        {visit.fundal_height != null && (
                          <div>
                            <p className="text-text-muted">{t("fundal_height_cm")}</p>
                            <p className="font-medium text-text-heading">{visit.fundal_height}</p>
                          </div>
                        )}
                        {visit.foetal_hr != null && (
                          <div>
                            <p className="text-text-muted">{t("foetal_hr")}</p>
                            <p className="font-medium text-text-heading">{visit.foetal_hr}</p>
                          </div>
                        )}
                        {visit.presentation && (
                          <div>
                            <p className="text-text-muted">{t("presentation")}</p>
                            <p className="font-medium text-text-heading">{visit.presentation}</p>
                          </div>
                        )}
                        {visit.oedema && (
                          <div>
                            <p className="text-text-muted">{t("oedema")}</p>
                            <p className="font-medium text-red-600">Yes</p>
                          </div>
                        )}
                      </div>

                      {/* Treatment badges */}
                      <div className="flex flex-wrap gap-1.5 mt-3">
                        {visit.tt_vaccine && (
                          <span className="bg-green-100 text-green-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("tt_vaccine")}</span>
                        )}
                        {visit.malaria_prophylaxis && (
                          <span className="bg-blue-100 text-blue-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("malaria_prophylaxis")}</span>
                        )}
                        {visit.iron_supplements && (
                          <span className="bg-amber-100 text-amber-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("iron_supplements")}</span>
                        )}
                        {visit.risk_assessment_id && (
                          <span className="bg-rose-100 text-rose-700 text-[11px] font-medium px-2 py-0.5 rounded-full">
                            Assessment linked
                          </span>
                        )}
                      </div>

                      {/* Notes */}
                      {visit.notes && (
                        <p className="text-xs text-text-muted mt-3 italic">{visit.notes}</p>
                      )}

                      {/* Next visit */}
                      {visit.next_visit_date && (
                        <p className="text-xs text-text-muted mt-2">
                          {t("next_visit_date")}: <span className="font-medium text-text-heading">{visit.next_visit_date}</span>
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
