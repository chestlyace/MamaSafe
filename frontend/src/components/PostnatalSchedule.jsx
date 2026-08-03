import { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import {
  getPostnatalSchedule,
  updateScheduledPNCVisit,
  reschedulePNCVisit,
} from "../api/client";
import FieldHelp from "./FieldHelp";

export default function PostnatalSchedule({ deliveryId }) {
  const { t } = useTranslation();
  const [schedule, setSchedule] = useState(null);
  const [loading, setLoading] = useState(true);
  const [rescheduleId, setRescheduleId] = useState(null);
  const [newDate, setNewDate] = useState("");

  useEffect(() => {
    if (!deliveryId) return;
    let cancelled = false;
    getPostnatalSchedule(deliveryId)
      .then((data) => { if (!cancelled) setSchedule(data); })
      .catch(() => { if (!cancelled) setSchedule(null); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [deliveryId]);

  const handleReschedule = async (visitId) => {
    if (!newDate) return;
    try {
      await reschedulePNCVisit(visitId, newDate);
      const updated = await getPostnatalSchedule(deliveryId);
      setSchedule(updated);
      setRescheduleId(null);
      setNewDate("");
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <span className="material-symbols-outlined text-2xl animate-spin text-rose-500 mr-2">progress_activity</span>
      </div>
    );
  }

  if (!schedule) return null;

  const { scheduled_visits, visits } = schedule;

  return (
    <div className="space-y-3">
      {scheduled_visits.map((sv) => {
        const completedVisit = sv.postnatal_visit_id
          ? visits.find((v) => v.id === sv.postnatal_visit_id)
          : null;

        const statusColors = {
          scheduled: "bg-blue-100 text-blue-700",
          completed: "bg-green-100 text-green-700",
          missed: "bg-red-100 text-red-700",
          cancelled: "bg-gray-100 text-gray-500",
          rescheduled: "bg-amber-100 text-amber-700",
        };

        return (
          <div key={sv.id} className="bg-surface rounded-xl p-4 border border-border">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <span className="text-sm font-semibold text-text-heading">{sv.label}</span>
                <span className={`text-[11px] font-medium px-2 py-0.5 rounded-full ${statusColors[sv.status] || ""}`}>
                  {t(sv.status)}
                </span>
              </div>
              <span className="text-xs text-text-muted">{sv.scheduled_date}</span>
            </div>

            {completedVisit && (
              <div className="bg-white rounded-lg p-3 mt-2 border border-border">
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
                  {completedVisit.mother_status && (
                    <div>
                      <p className="text-text-muted">{t("mother_status")}</p>
                      <p className="font-medium text-text-heading">{completedVisit.mother_status}</p>
                    </div>
                  )}
                  {completedVisit.systolic_bp != null && (
                    <div>
                      <p className="text-text-muted">BP</p>
                      <p className="font-medium text-text-heading">{completedVisit.systolic_bp}/{completedVisit.diastolic_bp}</p>
                    </div>
                  )}
                  {completedVisit.temperature != null && (
                    <div>
                      <p className="text-text-muted">{t("temperature")}</p>
                      <p className="font-medium text-text-heading">{completedVisit.temperature}°C</p>
                    </div>
                  )}
                  {completedVisit.hb_result != null && (
                    <div>
                      <p className="text-text-muted">{t("haemoglobin")}</p>
                      <p className="font-medium text-text-heading">{completedVisit.hb_result}</p>
                    </div>
                  )}
                </div>
              </div>
            )}

            {sv.status === "scheduled" && (
              <div className="flex items-center gap-2 mt-3">
                {rescheduleId === sv.id ? (
                    <div className="flex items-center gap-2">
                      <div className="flex items-center gap-1">
                        <input
                          type="date"
                          value={newDate}
                          min={new Date().toISOString().split("T")[0]}
                          onChange={(e) => setNewDate(e.target.value)}
                          className="text-xs border border-border rounded-lg px-2 py-1.5"
                        />
                        <FieldHelp text={t("new_date_help")} />
                      </div>
                      <button
                        onClick={() => handleReschedule(sv.id)}
                        className="text-xs bg-amber-500 text-white px-3 py-1.5 rounded-lg font-medium hover:bg-amber-600"
                      >
                      {t("save")}
                    </button>
                    <button
                      onClick={() => { setRescheduleId(null); setNewDate(""); }}
                      className="text-xs text-text-muted hover:text-text-heading"
                    >
                      {t("cancel")}
                    </button>
                  </div>
                ) : (
                  <>
                    <button
                      onClick={() => {
                        setRescheduleId(sv.id);
                        setNewDate(sv.scheduled_date?.slice(0, 10) || "");
                      }}
                      className="text-xs text-amber-600 hover:text-amber-700 font-medium"
                    >                      {t("reschedule")}
                    </button>
                    <span className="text-border">·</span>
                    <button
                      onClick={async () => {
                        await updateScheduledPNCVisit(sv.id, "missed");
                        const updated = await getPostnatalSchedule(deliveryId);
                        setSchedule(updated);
                      }}
                      className="text-xs text-red-500 hover:text-red-600 font-medium"
                    >
                      {t("mark_missed")}
                    </button>
                  </>
                )}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
