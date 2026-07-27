import { useNavigate } from 'react-router-dom';

const ESCALATION_CONFIG = {
  low_risk_to_mid_risk: {
    bg: 'bg-amber-50',
    border: 'border-amber-300',
    text: 'text-amber-700',
    icon: 'warning',
    label: 'Risk escalated: LOW → MID',
    action: 'Increase visit frequency and monitor closely.',
  },
  mid_risk_to_high_risk: {
    bg: 'bg-red-50',
    border: 'border-red-300',
    text: 'text-red-700',
    icon: 'error',
    label: 'Risk escalated: MID → HIGH',
    action: 'Refer to district hospital immediately.',
  },
  low_risk_to_high_risk: {
    bg: 'bg-red-50',
    border: 'border-red-400',
    text: 'text-red-800',
    icon: 'error',
    label: 'CRITICAL: Risk jumped LOW → HIGH',
    action: 'EMERGENCY REFERRAL required immediately.',
  },
};

export default function EscalationBadge({ escalation, assessmentId }) {
  const navigate = useNavigate();
  if (!escalation) return null;

  const cfg = ESCALATION_CONFIG[escalation.type];
  if (!cfg) return null;

  const showRefer = escalation.type === 'mid_risk_to_high_risk'
    || escalation.type === 'low_risk_to_high_risk';

  return (
    <div className={`rounded-2xl border-2 p-4 ${cfg.bg} ${cfg.border}`}>
      <div className="flex items-start gap-3">
        <span className={`material-symbols-outlined text-2xl ${cfg.text}`}>{cfg.icon}</span>
        <div className="flex-1">
          <p className={`font-black text-sm ${cfg.text}`}>{cfg.label}</p>
          <p className={`text-xs mt-1 ${cfg.text} opacity-80`}>
            Detected on {escalation.date}
          </p>
          <p className={`text-sm font-medium mt-2 ${cfg.text}`}>
            {cfg.action}
          </p>
        </div>
      </div>
      {showRefer && (
        <button
          onClick={() => navigate(assessmentId ? `/refer/${assessmentId}` : '/referrals')}
          className="mt-3 w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold rounded-xl text-sm transition-colors flex items-center justify-center gap-2"
        >
          <span className="material-symbols-outlined text-[18px]">local_hospital</span>
          Emergency Refer Patient
        </button>
      )}
    </div>
  );
}
