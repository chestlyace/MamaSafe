import { useTranslation } from "react-i18next";
import FieldHelp from "./FieldHelp";
import useComputedValue from "../hooks/useComputedValue";

const DEFAULT_INPUT_CLASS =
  "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

// Date input that auto-fills from a `computed` value until the user manually
// edits it (then it "sticks"). A "revert to suggested" link restores the
// computed value and re-enables auto-fill.
export default function DateField({
  label,
  value = "",
  onChange,
  computed = null,
  min,
  max,
  required = false,
  icon = "calendar_today",
  inputClass = DEFAULT_INPUT_CLASS,
  help = null,
}) {
  const { t } = useTranslation();
  const { handleChange, showRevert, revert } = useComputedValue(value, computed, onChange);

  return (
    <div>
      <label className="block text-xs font-medium text-text-muted mb-1.5">
        {label}
        {required && <span className="text-red-500"> *</span>}
        <FieldHelp text={help} />
      </label>
      <div className="relative">
        <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
          {icon}
        </span>
        <input
          type="date"
          value={value}
          onChange={(e) => handleChange(e.target.value)}
          min={min}
          max={max}
          required={required}
          className={`${inputClass} pl-10`}
        />
      </div>
      {showRevert && (
        <button
          type="button"
          onClick={revert}
          className="mt-1.5 text-xs text-rose-500 font-medium hover:underline flex items-center gap-1"
        >
          <span className="material-symbols-outlined text-[14px]">undo</span>
          {t("revert_to_suggested")}
        </button>
      )}
    </div>
  );
}
