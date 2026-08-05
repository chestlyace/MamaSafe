import test from "node:test";
import assert from "node:assert/strict";
import {
  eddFromLmp,
  gestationalAge,
  nextVisitDate,
  pncVisitDate,
  ANC_SCHEDULE_WEEKS,
  PNC_DAYS_AFTER_DELIVERY,
} from "../src/utils/dateCalc.js";

// Reference values verified against backend calculate_edd
// (dateutil.relativedelta(months=9, days=7)).
test("eddFromLmp matches backend Naegele rule", () => {
  const cases = [
    ["2024-01-15", "2024-10-22"],
    ["2024-05-31", "2025-03-07"],
    ["2023-11-30", "2024-09-06"],
    ["2024-02-29", "2024-12-06"],
    ["2024-08-31", "2025-06-07"],
    ["2023-03-31", "2024-01-07"],
    ["2022-06-15", "2023-03-22"],
    ["2025-12-31", "2026-10-07"],
  ];
  for (const [lmp, expected] of cases) {
    assert.equal(eddFromLmp(lmp), expected, `lmp=${lmp}`);
  }
});

test("gestationalAge computes floor weeks and clamps to 4-42", () => {
  assert.equal(gestationalAge("2024-01-15", "2024-04-15"), 13);
  assert.equal(gestationalAge("2024-01-15", "2024-01-15"), 4); // clamped min
  assert.equal(gestationalAge("2023-01-01", "2024-01-01"), 42); // clamped max
  assert.equal(gestationalAge("2024-01-15", "2024-01-22"), 4); // exactly 1 week -> 1, clamped
});

test("nextVisitDate picks the schedule week strictly after current GA", () => {
  assert.equal(ANC_SCHEDULE_WEEKS.length, 8);
  // GA 16 -> next week 20 -> lmp + 20 weeks
  assert.equal(nextVisitDate("2024-01-15", 16), "2024-06-03");
  // GA 19 -> next week 20 (strictly after)
  assert.equal(nextVisitDate("2024-01-15", 19), "2024-06-03");
  // GA 20 -> next week 26
  assert.equal(nextVisitDate("2024-01-15", 20), "2024-07-15");
  // GA 38 or above -> no further visits
  assert.equal(nextVisitDate("2024-01-15", 38), null);
  assert.equal(nextVisitDate("2024-01-15", 40), null);
});

test("pncVisitDate applies day 1/6/42 offsets", () => {
  assert.deepEqual(PNC_DAYS_AFTER_DELIVERY, [1, 6, 42]);
  assert.equal(pncVisitDate("2024-10-22", 1), "2024-10-23");
  assert.equal(pncVisitDate("2024-10-22", 2), "2024-10-28");
  assert.equal(pncVisitDate("2024-10-22", 3), "2024-12-03");
});
