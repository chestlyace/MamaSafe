const clamp01 = (v) => Math.min(Math.max(v, 0), 1);

export function riskSubscores({ age, systolicBP, bloodSugar, bodyTemp, heartRate }) {
  const ageSub = age < 18
    ? clamp01((18 - age) / 8)
    : age >= 35
      ? clamp01((age - 34) / 15)
      : 0;
  return {
    age: ageSub,
    systolicBP: clamp01((systolicBP - 110) / 60),
    bloodSugar: clamp01((bloodSugar - 5) / 5),
    bodyTemp: clamp01((bodyTemp - 36.8) / 1.7),
    heartRate: clamp01((heartRate - 80) / 40),
  };
}

export const RISK_WEIGHTS = {
  age: 0.15,
  systolicBP: 0.35,
  bloodSugar: 0.2,
  bodyTemp: 0.15,
  heartRate: 0.15,
};

export function riskScore(inputs) {
  const sub = riskSubscores(inputs);
  const score = Object.entries(RISK_WEIGHTS).reduce(
    (acc, [k, w]) => acc + w * sub[k], 0
  );
  const rounded = Math.round(score * 1000) / 1000;
  const level = rounded < 0.34 ? 'low' : rounded < 0.67 ? 'mid' : 'high';
  return { score: rounded, level };
}
