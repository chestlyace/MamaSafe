export function formatReferralMessage(data) {
  const name = data.patient_name || 'Unknown';
  const age = data.patient_age || '?';
  const bp =
    data.systolic_bp && data.diastolic_bp
      ? `${Math.round(data.systolic_bp)}/${Math.round(data.diastolic_bp)}`
      : '?';
  const hr = data.heart_rate || '?';
  const temp = data.body_temp ? data.body_temp.toFixed(1) : '?';
  const sugar = data.blood_sugar ? data.blood_sugar.toFixed(1) : '?';
  const risk = (data.risk_level || 'UNKNOWN').toUpperCase();
  const prob = data.risk_probability
    ? `${Math.round(data.risk_probability * 100)}%`
    : 'N/A';
  const complication = data.complication_type || 'N/A';
  const notes = (data.chw_notes || '').slice(0, 80) || 'None';
  const facility = data.facility_name || 'N/A';
  const sent = data.sent_at || new Date().toISOString();
  const blood = data.patient_blood_group || 'N/A';
  const allergies = data.patient_allergies || 'None';
  const gravida = data.gravida || '?';
  const parity = data.parity || '?';
  const edd = data.edd_date || 'N/A';
  const ga = data.gestational_age || '?';
  const refId = data.referral_id ? ` #${String(data.referral_id).padStart(4, '0')}` : '';

  const msg = [
    `🚨 *MAMASAFE URGENT REFERRAL${refId}*`,
    '',
    `👤 *Patient:* ${name}, ${age} years`,
    `📞 *Phone:* ${data.patient_phone || 'N/A'}`,
    `🩸 *Blood Group:* ${blood}`,
    `⚕️ *Allergies:* ${allergies}`,
    '',
    `🤰 *Pregnancy:* G${gravida}P${parity}, EDD: ${edd}`,
    `📊 *Gestational Age:* ${ga} weeks`,
    '',
    `💓 *Vitals:*`,
    `  BP: ${bp} mmHg`,
    `  HR: ${hr} bpm`,
    `  Temp: ${temp} °C`,
    `  Blood Sugar: ${sugar} mmol/L`,
    '',
    `⚠️ *Risk Level:* ${risk} (${prob} confidence)`,
    `🔴 *Complication:* ${complication}`,
    '',
    `📝 *CHW Notes:* ${notes}`,
    '',
    `📍 *Referred to:* ${facility}`,
    `🕐 *Sent:* ${sent}`,
    '',
    `Reply *RECEIVED* to confirm.`,
  ].join('\n');

  return msg;
}
