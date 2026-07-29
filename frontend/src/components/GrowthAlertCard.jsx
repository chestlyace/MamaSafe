import { useState } from "react";
import { useTranslation } from "react-i18next";
import { resolveGrowthAlert } from "../api/client";

const ALERT_ICONS = {
  below_3rd_percentile: "priority_high",
  growth_faltering: "trending_down",
  failed_to_regain_birth_weight: "monitor_weight",
};

const ALERT_COLORS = {
  warning: "border-amber-200 bg-amber-50",
  critical: "border-red-200 bg-red-50",
};

export default function GrowthAlertCard({ alert, onResolved }) {
  const { t, i18n } = useTranslation();
  const [resolving, setResolving] = useState(false);

  const lang = i18n.language?.startsWith("fr") ? "fr" : "en";
  const message = lang === "fr" ? alert.message_fr : alert.message_en;

  const handleResolve = async () => {
    setResolving(true);
    try {
      await resolveGrowthAlert(alert.id);
      onResolved?.(alert.id);
    } catch (err) {
      console.error(err);
    } finally {
      setResolving(false);
    }
  };

  return (
    <div className={`rounded-xl border p-4 ${ALERT_COLORS[alert.severity] || "border-border bg-white"}`}>
      <div className="flex items-start gap-3">
        <span className={`material-symbols-outlined text-xl mt-0.5 ${alert.severity === "critical" ? "text-red-500" : "text-amber-500"}`}>
          {ALERT_ICONS[alert.alert_type] || "warning"}
        </span>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1">
            <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${alert.severity === "critical" ? "bg-red-100 text-red-700" : "bg-amber-100 text-amber-700"}`}>
              {t(alert.alert_type)}
            </span>
            {alert.z_score != null && (
              <span className="text-[11px] text-text-muted">z-score: {alert.z_score.toFixed(2)}</span>
            )}
          </div>
          <p className="text-sm text-text-heading">{message}</p>
          <div className="flex items-center gap-3 mt-2">
            <button
              onClick={handleResolve}
              disabled={resolving}
              className="text-xs bg-white border border-border text-text-heading font-medium px-3 py-1 rounded-lg hover:bg-surface transition-colors disabled:opacity-50"
            >
              {resolving ? t("resolving") : t("mark_resolved")}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
