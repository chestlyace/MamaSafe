"""WHO Child Growth Standards — Weight-for-Age.

Stores WHO LMS parameters (L, M, S) for boys and girls 0–6 months
and provides a classify_weight() function returning z-score, percentile,
and WHO classification.
"""

import math

# WHO LMS parameters for weight-for-age (0–6 months)
# Source: WHO Child Growth Standards, https://www.who.int/tools/child-growth-standards
# L = Box-Cox power, M = median (kg), S = coefficient of variation
WHO_LMS = {
    "male": [
        # month, L,     M,     S
        (0,  0.3482, 3.5322, 0.14202),
        (1,  0.5249, 4.4151, 0.12678),
        (2,  0.3974, 5.3414, 0.11965),
        (3,  0.2199, 6.0360, 0.11644),
        (4,  0.1076, 6.5777, 0.11472),
        (5,  0.0228, 7.0081, 0.11466),
        (6, -0.0486, 7.3919, 0.11583),
    ],
    "female": [
        (0,  0.4103, 3.3596, 0.14396),
        (1,  0.4721, 4.1497, 0.13141),
        (2,  0.3823, 4.9070, 0.12455),
        (3,  0.2241, 5.5255, 0.12046),
        (4,  0.1081, 5.9945, 0.11885),
        (5,  0.0150, 6.3613, 0.11863),
        (6, -0.0624, 6.6939, 0.11969),
    ],
}

Z_THRESHOLDS = {
    "severely_underweight": (-3.0, -2.0),
    "underweight": (-2.0, -1.0),
    "normal": (-1.0, 1.0),
    "overweight": (1.0, 2.0),
    "obese": (2.0, 3.0),
}

PERCENTILE_LABELS = {
    "below_3rd": (-float("inf"), -1.881),
    "3rd_to_15th": (-1.881, -1.036),
    "15th_to_50th": (-1.036, 0.0),
    "50th_to_85th": (0.0, 1.036),
    "85th_to_97th": (1.036, 1.881),
    "above_97th": (1.881, float("inf")),
}


def _zscore_to_weight(z: float, L: float, M: float, S: float) -> float:
    """Convert z-score to weight (kg) using LMS formula."""
    if abs(L) < 1e-10:
        return M * math.exp(S * z)
    return M * (1 + L * S * z) ** (1.0 / L)


def _weight_to_zscore(weight: float, L: float, M: float, S: float) -> float:
    """Convert weight (kg) to z-score using LMS formula."""
    if abs(L) < 1e-10:
        return math.log(weight / M) / S
    return ((weight / M) ** L - 1) / (L * S)


def _interpolate_lms(sex: str, age_days: float):
    """Get interpolated L, M, S for a given age in days (0–183)."""
    age_months = age_days / 30.4375  # average days per month
    table = WHO_LMS["male" if sex == "male" else "female"]

    if age_months <= table[0][0]:
        return table[0][1], table[0][2], table[0][3]

    if age_months >= table[-1][0]:
        return table[-1][1], table[-1][2], table[-1][3]

    for i in range(len(table) - 1):
        m0, L0, M0, S0 = table[i]
        m1, L1, M1, S1 = table[i + 1]
        if m0 <= age_months <= m1:
            frac = (age_months - m0) / (m1 - m0) if m1 != m0 else 0
            L = L0 + (L1 - L0) * frac
            M = M0 + (M1 - M0) * frac
            S = S0 + (S1 - S0) * frac
            return L, M, S

    return table[-1][1], table[-1][2], table[-1][3]


# Precompute lookup tables at weekly resolution
def _build_lookup_tables():
    """Precompute weight-percentile tables at weekly resolution (0–26 weeks)."""
    tables = {}
    for sex in ("male", "female"):
        weekly = {}
        for week in range(0, 27):
            age_days = week * 7
            L, M, S = _interpolate_lms(sex, age_days)
            weekly[week] = {
                "age_days": age_days,
                "p3": round(_zscore_to_weight(-1.881, L, M, S), 3),
                "p15": round(_zscore_to_weight(-1.036, L, M, S), 3),
                "p50": round(_zscore_to_weight(0, L, M, S), 3),
                "p85": round(_zscore_to_weight(1.036, L, M, S), 3),
                "p97": round(_zscore_to_weight(1.881, L, M, S), 3),
            }
        tables[sex] = weekly
    return tables


WHO_WEEKLY_TABLES = _build_lookup_tables()


def get_percentile_values(sex: str, age_days: float) -> dict:
    """Get WHO percentile weight values for a given sex and age in days.

    Returns dict with p3, p15, p50, p85, p97 in kg.
    """
    week = min(int(age_days / 7), 26)
    sex_key = "male" if sex == "male" else "female"
    return dict(WHO_WEEKLY_TABLES[sex_key][week])


def classify_weight(sex: str, age_days: float, weight_kg: float) -> dict:
    """Classify a weight measurement against WHO standards.

    Returns:
        z_score: float
        percentile: str key (below_3rd, 3rd_to_15th, 15th_to_50th, 50th_to_85th, 85th_to_97th, above_97th)
        classification: str (severely_underweight, underweight, normal, overweight, obese)
        p3, p15, p50, p85, p97: float thresholds in kg
    """
    L, M, S = _interpolate_lms(sex, age_days)
    z = _weight_to_zscore(weight_kg, L, M, S)

    percentile = "below_3rd"
    for label, (lo, hi) in PERCENTILE_LABELS.items():
        if lo <= z < hi:
            percentile = label
            break

    classification = "normal"
    for label, (lo, hi) in Z_THRESHOLDS.items():
        if lo <= z < hi:
            classification = label
            break
    if z >= 3.0:
        classification = "obese"

    pvals = get_percentile_values(sex, age_days)

    return {
        "z_score": round(z, 3),
        "percentile": percentile,
        "classification": classification,
        **pvals,
    }
