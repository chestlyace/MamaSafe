export interface LoginResponse {
  access_token: string;
  token_type: string;
}

export interface PredictionResult {
  risk_level: "high risk" | "mid risk" | "low risk";
  confidence: number;
  prob_high: number;
  prob_mid: number;
  prob_low: number;
  recommendation: string;
  shap_values: ShapValue[];
  assessment_id?: number;
}

export interface ShapValue {
  feature: string;
  shap_value: number;
  raw_value?: number;
}

export interface Assessment {
  id: number;
  patient_ref?: string;
  age: number;
  systolic_bp: number;
  diastolic_bp: number;
  blood_sugar: number;
  body_temp: number;
  heart_rate: number;
  risk_level: string;
  prob_high: number;
  prob_mid: number;
  prob_low: number;
  created_at: string;
}

export interface DashboardSummary {
  total_assessments: number;
  high_risk_count: number;
  mid_risk_count: number;
  low_risk_count: number;
}

export interface AssessmentPayload {
  patient_ref?: string;
  age: number;
  systolic_bp: number;
  diastolic_bp: number;
  blood_sugar: number;
  body_temp: number;
  heart_rate: number;
}

// ── FACILITIES ──────────────────────────────────────────
export interface Facility {
  id: number;
  name: string;
  facility_type: string;
  phone?: string;
  whatsapp?: string;
  latitude?: number;
  longitude?: number;
  is_approved: boolean;
  suggested_by?: number;
  created_at: string;
}

// ── REFERRALS ──────────────────────────────────────────
export interface Referral {
  id: number;
  patient_id?: number;
  patient_name: string;
  assessment_id?: number;
  facility_id?: number;
  facility_name: string;
  clinical_summary: string;
  delivery_method: "sms" | "whatsapp" | "app";
  status: "sent" | "received" | "patient_arrived";
  sent_at: string;
  received_at?: string;
  arrived_at?: string;
  created_by: number;
  created_at: string;
}

export interface ReferralStats {
  total: number;
  pending: number;
  delivered: number;
  by_status: Record<string, number>;
}

export interface CreateReferralPayload {
  patient_id?: number;
  patient_name: string;
  assessment_id?: number;
  facility_id?: number;
  clinical_summary: string;
  delivery_method: "sms" | "whatsapp" | "app";
}

export interface QuickReferralPayload {
  patient_id?: number;
  assessment_id?: number;
  facility_id?: number;
  clinical_summary: string;
  delivery_method: "sms" | "whatsapp" | "app";
}
