// Date-math helpers mirroring the backend's rules (see backend/app/routers/anc.py
// calculate_edd, backend/app/routers/schedule.py VISIT_SCHEDULE, and
// backend/app/routers/postnatal.py PNC_SCHEDULE). All dates are YYYY-MM-DD strings.

export const ANC_SCHEDULE_WEEKS = [8, 16, 20, 26, 30, 34, 36, 38];
export const PNC_DAYS_AFTER_DELIVERY = [1, 6, 42];

function parseDate(s) {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function toIso(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// Add whole calendar months, clamping the day to the target month's length,
// mirroring Python's dateutil.relativedelta(months=n).
function addMonthsClamped(date, months) {
  const y = date.getFullYear();
  const m = date.getMonth() + months;
  const target = new Date(y, m, 1);
  const lastDay = new Date(target.getFullYear(), target.getMonth() + 1, 0).getDate();
  target.setDate(Math.min(date.getDate(), lastDay));
  return target;
}

// Naegele's rule: EDD = LMP + 9 months + 7 days (calendar months).
export function eddFromLmp(lmp) {
  const base = addMonthsClamped(parseDate(lmp), 9);
  base.setDate(base.getDate() + 7);
  return toIso(base);
}

// Gestational age in weeks as of `asOf`, clamped to the web form's 4-42 range.
export function gestationalAge(lmp, asOf) {
  const days = Math.floor((parseDate(asOf) - parseDate(lmp)) / 86400000);
  return Math.max(4, Math.min(42, Math.floor(days / 7)));
}

// Next scheduled ANC visit: the first week in the 8-visit schedule strictly after
// currentGa, i.e. lmp + week*7 days. Returns null when GA >= 38 (no further visits).
export function nextVisitDate(lmp, currentGa) {
  const nextWeek = ANC_SCHEDULE_WEEKS.find((w) => w > currentGa);
  if (nextWeek === undefined) return null;
  const d = parseDate(lmp);
  d.setDate(d.getDate() + nextWeek * 7);
  return toIso(d);
}

// PNC visit date: delivery + days after delivery (visits at day 1, 6, 42).
export function pncVisitDate(deliveryDate, visitNumber) {
  const offset = PNC_DAYS_AFTER_DELIVERY[visitNumber - 1] ?? PNC_DAYS_AFTER_DELIVERY[0];
  const d = parseDate(deliveryDate);
  d.setDate(d.getDate() + offset);
  return toIso(d);
}
