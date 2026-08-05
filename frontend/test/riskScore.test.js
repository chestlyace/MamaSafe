import test from 'node:test';
import assert from 'node:assert/strict';
import { riskScore, riskSubscores } from '../src/utils/riskScore.js';

const NORMAL = { age: 25, systolicBP: 110, bloodSugar: 5, bodyTemp: 36.8, heartRate: 80 };

test('normal measurements score 0 and low risk', () => {
  const { score, level } = riskScore(NORMAL);
  assert.equal(score, 0);
  assert.equal(level, 'low');
});

test('severely high blood pressure alone raises risk to mid', () => {
  const { level } = riskScore({ ...NORMAL, systolicBP: 170 });
  assert.equal(level, 'mid');
});

test('all-dangerous inputs score high risk', () => {
  const { score, level } = riskScore({
    age: 45, systolicBP: 180, bloodSugar: 11, bodyTemp: 40, heartRate: 120,
  });
  assert.equal(level, 'high');
  assert.ok(score >= 0.9);
});

test('subscores clamp to 0..1', () => {
  const sub = riskSubscores({
    age: 30, systolicBP: 300, bloodSugar: 99, bodyTemp: 45, heartRate: 220,
  });
  for (const v of Object.values(sub)) {
    assert.ok(v >= 0 && v <= 1, `subscore ${v} out of range`);
  }
});

test('age under 18 elevates risk', () => {
  const young = riskScore({ ...NORMAL, age: 16 });
  const adult = riskScore(NORMAL);
  assert.ok(young.score > adult.score);
});

test('score is monotonic in systolic BP', () => {
  const a = riskScore({ ...NORMAL, systolicBP: 120 }).score;
  const b = riskScore({ ...NORMAL, systolicBP: 150 }).score;
  assert.ok(b > a);
});
