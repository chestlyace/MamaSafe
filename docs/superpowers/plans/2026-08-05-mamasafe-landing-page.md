# MamaSafe Landing Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public bilingual landing page at `/` that advertises MamaSafe and explains what it is, what it does, how it's used, and why it matters — with interactive visuals and layered messaging for CHWs, mothers/families, and officials/partners.

**Architecture:** Long-scroll editorial page in the existing React 19 + Vite + Tailwind 4 app. New `LandingPage` at route `/`, assembled from focused section components in `src/components/landing/`. Extends the existing design tokens (rose → warm maternal palette), reuses `LanguageToggle` and i18next setup, adds Fraunces display font. No backend changes. No new npm dependencies.

**Tech Stack:** React 19, Vite, Tailwind 4, i18next, Material Symbols icons, node:test (for TDD on the risk scoring util).

**Spec:** `docs/superpowers/specs/2026-08-05-mamasafe-landing-page-design.md`

**Git note:** Commit steps are included per plan format. The project's system prompt requires explicit user confirmation before any git mutation — executor must ask before running `git commit`.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Modify | `frontend/index.html` | Add Fraunces font + meta description |
| Modify | `frontend/src/index.css` | Extend `@theme` tokens, import landing.css |
| Create | `frontend/src/components/landing/landing.css` | Keyframes + reveal + heartbeat + reduced-motion |
| Create | `frontend/src/utils/riskScore.js` | Deterministic risk scoring (TDD) |
| Create | `frontend/test/riskScore.test.js` | Tests for riskScore |
| Modify | `frontend/src/i18n/en.json` | Add `landing` key (EN copy deck) |
| Modify | `frontend/src/i18n/fr.json` | Add `landing` key (FR copy deck) |
| Create | `frontend/src/components/landing/Reveal.jsx` | Scroll-reveal wrapper |
| Create | `frontend/src/components/landing/useCountUp.js` | Animated counter hook |
| Create | `frontend/src/components/landing/HeartbeatLine.jsx` | Animated SVG pulse |
| Create | `frontend/src/components/landing/LandingNav.jsx` | Sticky nav |
| Create | `frontend/src/components/landing/HeroSection.jsx` | Hero |
| Create | `frontend/src/components/landing/ProblemSection.jsx` | Stats + counters |
| Create | `frontend/src/components/landing/WhatItIsSection.jsx` | 3 pillars |
| Create | `frontend/src/components/landing/HowItWorksSection.jsx` | 6 steps + ANC timeline |
| Create | `frontend/src/components/landing/RiskSimulator.jsx` | Interactive demo |
| Create | `frontend/src/components/landing/FeaturesSection.jsx` | 9-feature grid |
| Create | `frontend/src/components/landing/AudienceSection.jsx` | 3 audience cards |
| Create | `frontend/src/components/landing/ImpactSection.jsx` | Editorial closer |
| Create | `frontend/src/components/landing/CTASection.jsx` | CTA band + footer |
| Create | `frontend/src/pages/LandingPage.jsx` | Page assembly |
| Modify | `frontend/src/App.jsx` | Add `/` route, change catch-all |

---

### Task 1: Design tokens, fonts, and landing.css

**Files:**
- Modify: `frontend/index.html`
- Modify: `frontend/src/index.css`
- Create: `frontend/src/components/landing/landing.css`

- [ ] **Step 1: Add Fraunces font and meta description to index.html**

Replace the existing `<link>` for Inter with both Inter and Fraunces, and add a meta description:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="MamaSafe helps community health workers predict maternal risk, schedule every antenatal visit, and act in time — from the first visit to the baby's first steps." />
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,500;9..144,600;9..144,700&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet" />
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap" rel="stylesheet" />
    <title>MamaSafe — Maternal health, protected</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
```

- [ ] **Step 2: Extend @theme tokens and import landing.css in index.css**

Replace `frontend/src/index.css` with:

```css
@import "tailwindcss";
@import "./components/landing/landing.css";

@theme {
  --color-rose-primary: #E8637A;
  --color-rose-hover: #D4526A;
  --color-rose-light: #FDF2F4;
  --color-rose-50: #FDF2F4;
  --color-rose-100: #F9D5DC;
  --color-rose-200: #F2A8B5;
  --color-rose-500: #E8637A;
  --color-rose-600: #D4526A;
  --color-rose-700: #B8435A;

  --color-surface: #FAFAFA;
  --color-canvas: #F8F6FA;
  --color-border: #E8E5EC;
  --color-text-heading: #3D3847;
  --color-text-body: #5C5566;
  --color-text-muted: #8E8696;

  --color-cream: #FBF6EF;
  --color-sand: #F3E7D7;
  --color-terracotta: #C4552B;
  --color-terracotta-deep: #A03F1C;
  --color-teal-deep: #155E56;
  --color-teal-soft: #DCEDEA;
  --color-gold: #D9A03F;
  --color-ink: #2E2430;
  --color-plum-soft: #4A3E4C;
  --color-risk-low: #2F9E6E;
  --color-risk-mid: #E8A93F;
  --color-risk-high: #E8637A;

  --font-display: 'Fraunces', Georgia, serif;
}

body {
  margin: 0;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background: var(--color-canvas);
  color: var(--color-text-body);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

.material-symbols-outlined {
  font-family: 'Material Symbols Outlined';
  font-weight: normal;
  font-style: normal;
  font-size: 24px;
  line-height: 1;
  letter-spacing: normal;
  text-transform: none;
  display: inline-block;
  white-space: nowrap;
  word-wrap: normal;
  direction: ltr;
  -webkit-font-feature-settings: 'liga';
  font-feature-settings: 'liga';
  -webkit-font-smoothing: antialiased;
}

.focus-ring:focus {
  outline: none;
  box-shadow: 0 0 0 2px var(--color-canvas), 0 0 0 4px var(--color-rose-primary);
}

html { scroll-behavior: smooth; }

.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }

input[type=number]::-webkit-inner-spin-button,
input[type=number]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type=number] { -moz-appearance: textfield; }
```

- [ ] **Step 3: Create landing.css with keyframes and reveal styles**

Create `frontend/src/components/landing/landing.css`:

```css
.reveal {
  opacity: 0;
  transform: translateY(16px);
  transition: opacity 0.6s ease-out, transform 0.6s ease-out;
}
.reveal.is-visible {
  opacity: 1;
  transform: none;
}

.heartbeat-path {
  stroke-dasharray: 620;
  stroke-dashoffset: 620;
  animation: heartbeat-draw 2.8s ease-in-out infinite;
}
@keyframes heartbeat-draw {
  0%   { stroke-dashoffset: 620; opacity: 0.35; }
  45%  { stroke-dashoffset: 0;   opacity: 1; }
  75%  { stroke-dashoffset: 0;   opacity: 1; }
  100% { stroke-dashoffset: -620; opacity: 0.35; }
}

.float-slow { animation: float-y 6s ease-in-out infinite; }
@keyframes float-y {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.landing-range { accent-color: var(--color-terracotta); }
.landing-range::-webkit-slider-thumb { cursor: pointer; }

@media (prefers-reduced-motion: reduce) {
  .reveal { opacity: 1; transform: none; transition: none; }
  .heartbeat-path { animation: none; stroke-dashoffset: 0; }
  .float-slow { animation: none; }
  html { scroll-behavior: auto; }
}
```

- [ ] **Step 4: Verify build still passes**

Run: `cd frontend && npm run build`
Expected: BUILD SUCCESS with no errors.

---

### Task 2: TDD the risk scoring utility

**Files:**
- Create: `frontend/src/utils/riskScore.js`
- Create: `frontend/test/riskScore.test.js`
- Modify: `frontend/package.json` (add test script)

- [ ] **Step 1: Write the failing test**

Create `frontend/test/riskScore.test.js`:

```js
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd frontend && node --test test/riskScore.test.js`
Expected: FAIL — module `../src/utils/riskScore.js` not found.

- [ ] **Step 3: Implement riskScore.js**

Create `frontend/src/utils/riskScore.js`:

```js
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd frontend && node --test test/riskScore.test.js`
Expected: 6 tests passing.

- [ ] **Step 5: Add test script to package.json**

In `frontend/package.json`, add to `"scripts"`:

```json
"test": "node --test test/"
```

Run: `cd frontend && npm test`
Expected: All tests pass (dateCalc + riskScore).

---

### Task 3: EN i18n copy deck

**Files:**
- Modify: `frontend/src/i18n/en.json`

- [ ] **Step 1: Add the `landing` key to en.json**

In `frontend/src/i18n/en.json`, add a comma after the last line (`"reason_optional_help": "Why the visit is being moved (optional)"`) and insert the following `landing` object before the closing `}`:

```json
  "landing": {
    "nav": {
      "problem": "The problem",
      "what": "What it is",
      "how": "How it works",
      "features": "Features",
      "audiences": "Who it's for",
      "login": "Log in",
      "cta": "Get started"
    },
    "hero": {
      "kicker": "Maternal health, protected",
      "h1": "Every mother deserves a safe journey.",
      "sub": "MamaSafe helps community health workers spot danger early, keep every appointment, and act in time — from the first antenatal visit to the baby's first steps.",
      "cta_primary": "Get started",
      "cta_secondary": "See how it works",
      "chip1": "8 WHO-aligned visits",
      "chip2": "EN · FR",
      "chip3": "Built for CHWs",
      "visual_label": "Live monitoring",
      "visual_chip1": "Risk assessed",
      "visual_chip1_sub": "in seconds",
      "visual_chip2": "Reminders",
      "visual_chip2_sub": "on WhatsApp"
    },
    "problem": {
      "kicker": "The problem",
      "h2": "Too many mothers are lost to causes we can prevent.",
      "p1": "Most maternal deaths are preventable. Yet danger signs — rising blood pressure, anaemia, a fever — are often missed when visits are skipped and records stay on paper. A mother who seems fine at one visit can be at risk by the next, and no one sees the trend.",
      "stat1_value": 258,
      "stat1_label": "mothers die per 100,000 live births in Cameroon",
      "stat1_source": "World Bank, 2023",
      "stat2_value": 70,
      "stat2_prefix": "~",
      "stat2_suffix": "%",
      "stat2_label": "of global maternal deaths occur in sub-Saharan Africa",
      "stat2_source": "WHO / UN trends",
      "stat3_value": 8,
      "stat3_label": "antenatal visits recommended by WHO — many mothers never complete them",
      "stat3_source": "WHO, 2016",
      "progress_title": "372 → 258",
      "progress_caption": "Cameroon's maternal mortality ratio, 2017 → 2023. Progress is possible — and every prevented death begins with timely care.",
      "progress_source": "World Bank"
    },
    "what": {
      "kicker": "What is MamaSafe?",
      "h2": "A companion that watches over every pregnancy.",
      "p": "MamaSafe is a maternal health platform for community health workers (CHWs). It turns a few simple measurements into an early-warning system: predicting risk, scheduling care, and making sure no mother falls through the cracks.",
      "p1_t": "Assess the risk",
      "p1_d": "Enter simple measurements — blood pressure, blood sugar, temperature, heart rate — and MamaSafe's machine-learning model estimates the mother's risk level in seconds, with a clear explanation of what drove it.",
      "p2_t": "Never miss a visit",
      "p2_d": "The moment a pregnancy is registered, MamaSafe builds the full WHO 8-visit schedule automatically and reminds the mother on WhatsApp before every appointment.",
      "p3_t": "Act in time",
      "p3_d": "Risk is tracked across the whole pregnancy. When it rises, the CHW is alerted immediately and can refer the mother to the right facility — before it becomes an emergency."
    },
    "how": {
      "kicker": "How it works",
      "h2": "From first visit to first steps — six simple steps.",
      "s1_t": "Register the mother",
      "s1_d": "The CHW records the pregnancy and last menstrual period. MamaSafe calculates the due date instantly.",
      "s2_t": "Assess the risk",
      "s2_d": "A short guided assessment produces a clear risk level — low, mid or high — with the reasons behind it.",
      "s3_t": "Get the schedule",
      "s3_d": "All 8 WHO antenatal visits are planned automatically, mapped to the right weeks of pregnancy.",
      "s4_t": "Remind, automatically",
      "s4_d": "The mother receives WhatsApp reminders 48 hours and 2 hours before each visit. The CHW gets a daily list of who's due.",
      "s5_t": "Watch the trend",
      "s5_d": "Every assessment is plotted over time. If risk escalates between visits, the CHW is alerted the same day.",
      "s6_t": "Refer & follow up",
      "s6_d": "High-risk mothers are referred to facilities, delivery is recorded, and care continues postnatally — for mother and baby.",
      "timeline_kicker": "The 8-visit journey",
      "timeline_h3": "Tap a visit to see what happens",
      "week_label": "Week",
      "edd": "Due date",
      "v8": "Booking visit — full history, blood tests, first screening",
      "v16": "Blood pressure, urine, foetal heartbeat, weight",
      "v20": "Anomaly scan, foetal movements, BP check",
      "v26": "Glucose screening, anaemia check, fundal height",
      "v30": "Foetal presentation, haemoglobin, birth plan",
      "v34": "Presentation, birth plan review, danger signs",
      "v36": "Presentation confirmed, birth plan finalised",
      "v38": "Readiness for labour, emergency contacts, facility"
    },
    "sim": {
      "kicker": "Interactive demo",
      "h2": "See risk prediction in action.",
      "p": "Move the sliders. MamaSafe turns a handful of simple measurements into a risk signal a health worker can act on — in seconds.",
      "age": "Age (years)",
      "sbp": "Systolic BP (mmHg)",
      "sugar": "Blood sugar (mmol/L)",
      "temp": "Body temperature (°C)",
      "hr": "Heart rate (bpm)",
      "low": "Low risk",
      "mid": "Medium risk",
      "high": "High risk",
      "g_low": "Routine care — keep the schedule and keep watching.",
      "g_mid": "Closer follow-up — recheck soon and watch the trend.",
      "g_high": "Act now — escalate and refer for clinical evaluation.",
      "disclaimer": "Illustrative demo only. The real MamaSafe model is a validated machine-learning model that also explains which factors drove each prediction."
    },
    "features": {
      "kicker": "Features",
      "h2": "Everything a health worker needs, in one place.",
      "f1_t": "ML risk prediction",
      "f1_d": "Validated machine-learning model estimates maternal risk from simple measurements.",
      "f2_t": "Explained predictions",
      "f2_d": "SHAP charts show exactly which factors pushed each prediction — no black box.",
      "f3_t": "Auto visit scheduling",
      "f3_d": "The full WHO 8-visit ANC schedule, calculated from LMP the moment a pregnancy is registered.",
      "f4_t": "WhatsApp reminders",
      "f4_d": "Mothers are reminded before every visit; CHWs get a daily due-list each morning.",
      "f5_t": "Trend tracking & alerts",
      "f5_d": "Risk plotted across the pregnancy, with same-day escalation alerts when it rises.",
      "f6_t": "Referral system",
      "f6_d": "Refer high-risk mothers to the right facility and track every referral to completion.",
      "f7_t": "Postnatal & infant care",
      "f7_d": "Postnatal visit tracking, PHQ-2 wellbeing screening, and infant growth monitoring.",
      "f8_t": "Facility management",
      "f8_d": "Districts, facilities and teams organised in one directory supervisors can actually use.",
      "f9_t": "Bilingual, anywhere",
      "f9_d": "Full English and French interface, on web and mobile — built for the field."
    },
    "audiences": {
      "kicker": "Who it's for",
      "h2": "Built for everyone who protects a mother.",
      "a1_t": "CHWs & health workers",
      "a1_d": "Your daily companion: guided assessments, automatic schedules, and a clear list of who needs you today — even on a basic phone.",
      "a2_t": "Mothers & families",
      "a2_d": "Gentle WhatsApp reminders, follow-up after every visit, and the reassurance that someone is watching over the whole journey.",
      "a3_t": "Officials & partners",
      "a3_d": "Real-time visibility across districts: risk trends, referral completion, and visit coverage — maternal health you can measure."
    },
    "impact": {
      "kicker": "Why it matters",
      "h2": "The trend that saves a life is rarely visible in a single visit.",
      "p1": "A blood pressure that creeps up over three visits. A haemoglobin that quietly falls. On paper, each reading looks ordinary. Together, they are a warning — and catching it early is the difference between a routine referral and an emergency.",
      "p2": "MamaSafe exists so that no warning goes unseen: every visit remembered, every risk explained, every mother followed — from her first appointment to her baby's first steps.",
      "quote": "Every visit remembered. Every risk explained. Every mother followed."
    },
    "cta": {
      "h2": "Start protecting mothers today.",
      "p": "Join the health workers using MamaSafe to catch danger early and keep every mother on schedule.",
      "primary": "Create your CHW account",
      "secondary": "Log in",
      "footer_tagline": "Maternal health, protected",
      "rights": "© 2026 MamaSafe"
    }
  }
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cd frontend && node -e "require('./src/i18n/en.json'); console.log('OK')"`
Expected: `OK`

---

### Task 4: FR i18n copy deck

**Files:**
- Modify: `frontend/src/i18n/fr.json`

- [ ] **Step 1: Add the `landing` key to fr.json**

In `frontend/src/i18n/fr.json`, add a comma after the last line (`"reason_optional_help": "Raison du déplacement de la visite (facultatif)"`) and insert the following `landing` object before the closing `}`:

```json
  "landing": {
    "nav": {
      "problem": "Le problème",
      "what": "Qu'est-ce que c'est ?",
      "how": "Comment ça marche",
      "features": "Fonctionnalités",
      "audiences": "Pour qui ?",
      "login": "Se connecter",
      "cta": "Commencer"
    },
    "hero": {
      "kicker": "La santé maternelle, protégée",
      "h1": "Chaque mère mérite un voyage en toute sécurité.",
      "sub": "MamaSafe aide les agents de santé communautaire à détecter les dangers le plus tôt possible, à ne manquer aucun rendez-vous et à agir à temps — de la première visite prénatale aux premiers pas du bébé.",
      "cta_primary": "Commencer",
      "cta_secondary": "Voir comment ça marche",
      "chip1": "8 visites conformes à l'OMS",
      "chip2": "FR · EN",
      "chip3": "Conçu pour les ASC",
      "visual_label": "Suivi en direct",
      "visual_chip1": "Risque évalué",
      "visual_chip1_sub": "en quelques secondes",
      "visual_chip2": "Rappels",
      "visual_chip2_sub": "sur WhatsApp"
    },
    "problem": {
      "kicker": "Le problème",
      "h2": "Trop de mères meurent de causes que l'on peut prévenir.",
      "p1": "La plupart des décès maternels sont évitables. Pourtant, les signes de danger — tension artérielle qui monte, anémie, fièvre — passent souvent inaperçus lorsque les visites sont manquées et que les dossiers restent sur papier. Une mère qui semble en bonne santé à une visite peut être en danger à la suivante, sans que personne ne voie la tendance.",
      "stat1_value": 258,
      "stat1_label": "mères meurent pour 100 000 naissances vivantes au Cameroun",
      "stat1_source": "Banque mondiale, 2023",
      "stat2_value": 70,
      "stat2_prefix": "~",
      "stat2_suffix": "%",
      "stat2_label": "des décès maternels dans le monde surviennent en Afrique subsaharienne",
      "stat2_source": "OMS / tendances ONU",
      "stat3_value": 8,
      "stat3_label": "visites prénatales recommandées par l'OMS — beaucoup de mères ne les complètent jamais",
      "stat3_source": "OMS, 2016",
      "progress_title": "372 → 258",
      "progress_caption": "Taux de mortalité maternelle du Cameroun, 2017 → 2023. Le progrès est possible — et chaque décès évité commence par des soins prodigués à temps.",
      "progress_source": "Banque mondiale"
    },
    "what": {
      "kicker": "Qu'est-ce que MamaSafe ?",
      "h2": "Un compagnon qui veille sur chaque grossesse.",
      "p": "MamaSafe est une plateforme de santé maternelle conçue pour les agents de santé communautaire (ASC). Elle transforme quelques mesures simples en un système d'alerte précoce : prédire le risque, planifier les soins et faire en sorte qu'aucune mère ne soit oubliée.",
      "p1_t": "Évaluer le risque",
      "p1_d": "Saisissez des mesures simples — tension artérielle, glycémie, température, fréquence cardiaque — et le modèle d'apprentissage automatique de MamaSafe estime le niveau de risque de la mère en quelques secondes, avec une explication claire des facteurs en cause.",
      "p2_t": "Ne manquer aucune visite",
      "p2_d": "Dès l'enregistrement d'une grossesse, MamaSafe génère automatiquement le calendrier complet des 8 visites recommandées par l'OMS et rappelle chaque rendez-vous à la mère sur WhatsApp.",
      "p3_t": "Agir à temps",
      "p3_d": "Le risque est suivi tout au long de la grossesse. Lorsqu'il augmente, l'ASC est alerté immédiatement et peut référer la mère vers la bonne structure de santé — avant que cela ne devienne une urgence."
    },
    "how": {
      "kicker": "Comment ça marche",
      "h2": "De la première visite aux premiers pas — six étapes simples.",
      "s1_t": "Enregistrer la mère",
      "s1_d": "L'ASC enregistre la grossesse et la date des dernières règles. MamaSafe calcule instantanément la date prévue d'accouchement.",
      "s2_t": "Évaluer le risque",
      "s2_d": "Une courte évaluation guidée produit un niveau de risque clair — faible, moyen ou élevé — avec les raisons derrière chaque résultat.",
      "s3_t": "Obtenir le calendrier",
      "s3_d": "Les 8 visites prénatales recommandées par l'OMS sont planifiées automatiquement, aux bonnes semaines de grossesse.",
      "s4_t": "Rappeler, automatiquement",
      "s4_d": "La mère reçoit des rappels WhatsApp 48 heures et 2 heures avant chaque visite. L'ASC reçoit chaque matin la liste des patientes attendues.",
      "s5_t": "Suivre la tendance",
      "s5_d": "Chaque évaluation est tracée dans le temps. Si le risque s'aggrave entre deux visites, l'ASC est alerté le jour même.",
      "s6_t": "Référer et assurer le suivi",
      "s6_d": "Les mères à haut risque sont référées vers des structures de santé, l'accouchement est enregistré, et le suivi se poursuit après la naissance — pour la mère et le bébé.",
      "timeline_kicker": "Le parcours des 8 visites",
      "timeline_h3": "Touchez une visite pour voir ce qui s'y passe",
      "week_label": "Semaine",
      "edd": "Date prévue",
      "v8": "Visite de référence — historique complet, analyses de sang, premier dépistage",
      "v16": "Tension artérielle, urine, rythme cardiaque du fœtus, poids",
      "v20": "Échographie morphologique, mouvements du fœtus, tension",
      "v26": "Dépistage du diabète, contrôle de l'anémie, hauteur utérine",
      "v30": "Présentation du fœtus, hémoglobine, plan de naissance",
      "v34": "Présentation, révision du plan de naissance, signes de danger",
      "v36": "Présentation confirmée, plan de naissance finalisé",
      "v38": "Préparation à l'accouchement, contacts d'urgence, structure de santé"
    },
    "sim": {
      "kicker": "Démo interactive",
      "h2": "Voyez la prédiction du risque en action.",
      "p": "Déplacez les curseurs. MamaSafe transforme quelques mesures simples en un signal de risque exploitable par un agent de santé — en quelques secondes.",
      "age": "Âge (ans)",
      "sbp": "Tension systolique (mmHg)",
      "sugar": "Glycémie (mmol/L)",
      "temp": "Température (°C)",
      "hr": "Fréquence cardiaque (bpm)",
      "low": "Risque faible",
      "mid": "Risque moyen",
      "high": "Risque élevé",
      "g_low": "Soins de routine — respectez le calendrier et restez attentif.",
      "g_mid": "Suivi rapproché — revérifiez bientôt et surveillez la tendance.",
      "g_high": "Agissez maintenant — escaladez et référez pour une évaluation clinique.",
      "disclaimer": "Démo illustrative uniquement. Le véritable modèle MamaSafe est un modèle d'apprentissage automatique validé, qui explique aussi les facteurs derrière chaque prédiction."
    },
    "features": {
      "kicker": "Fonctionnalités",
      "h2": "Tout ce dont un agent de santé a besoin, au même endroit.",
      "f1_t": "Prédiction du risque par IA",
      "f1_d": "Un modèle d'apprentissage automatique validé estime le risque maternel à partir de mesures simples.",
      "f2_t": "Prédictions expliquées",
      "f2_d": "Des graphiques SHAP montrent exactement quels facteurs ont influencé chaque prédiction — aucune boîte noire.",
      "f3_t": "Planification automatique",
      "f3_d": "Le calendrier complet des 8 visites prénatales OMS, calculé à partir des dernières règles dès l'enregistrement.",
      "f4_t": "Rappels WhatsApp",
      "f4_d": "Les mères sont rappelées avant chaque visite ; les ASC reçoivent chaque matin la liste des patientes attendues.",
      "f5_t": "Tendances et alertes",
      "f5_d": "Le risque tracé sur toute la grossesse, avec des alertes d'escalade le jour même en cas d'aggravation.",
      "f6_t": "Système de référence",
      "f6_d": "Référez les mères à haut risque vers la bonne structure et suivez chaque référence jusqu'à sa conclusion.",
      "f7_t": "Suivi postnatal et infantile",
      "f7_d": "Visites postnatales, dépistage du bien-être PHQ-2 et suivi de la croissance du nourrisson.",
      "f8_t": "Gestion des structures",
      "f8_d": "Districts, structures de santé et équipes organisés dans un répertoire réellement utile pour les superviseurs.",
      "f9_t": "Bilingue, partout",
      "f9_d": "Interface complète en français et en anglais, sur le web et le mobile — conçue pour le terrain."
    },
    "audiences": {
      "kicker": "Pour qui ?",
      "h2": "Conçu pour tous ceux qui protègent une mère.",
      "a1_t": "ASC et agents de santé",
      "a1_d": "Votre compagnon quotidien : évaluations guidées, calendriers automatiques et une liste claire des patientes qui ont besoin de vous aujourd'hui — même sur un téléphone basique.",
      "a2_t": "Mères et familles",
      "a2_d": "Des rappels WhatsApp bienveillants, un suivi après chaque visite, et la certitude que quelqu'un veille sur tout le parcours.",
      "a3_t": "Décideurs et partenaires",
      "a3_d": "Une visibilité en temps réel sur les districts : tendances des risques, références abouties, couverture des visites — une santé maternelle mesurable."
    },
    "impact": {
      "kicker": "Pourquoi c'est important",
      "h2": "La tendance qui sauve une vie est rarement visible en une seule visite.",
      "p1": "Une tension artérielle qui grimpe sur trois visites. Une hémoglobine qui baisse silencieusement. Sur le papier, chaque mesure semble ordinaire. Ensemble, elles forment un avertissement — et le détecter tôt fait la différence entre une référence de routine et une urgence.",
      "p2": "MamaSafe existe pour qu'aucun avertissement ne passe inaperçu : chaque visite mémorisée, chaque risque expliqué, chaque mère suivie — de son premier rendez-vous aux premiers pas de son bébé.",
      "quote": "Chaque visite mémorisée. Chaque risque expliqué. Chaque mère suivie."
    },
    "cta": {
      "h2": "Commencez à protéger les mères dès aujourd'hui.",
      "p": "Rejoignez les agents de santé qui utilisent MamaSafe pour détecter le danger tôt et maintenir chaque mère sur la bonne trajectoire.",
      "primary": "Créer votre compte ASC",
      "secondary": "Se connecter",
      "footer_tagline": "La santé maternelle, protégée",
      "rights": "© 2026 MamaSafe"
    }
  }
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cd frontend && node -e "require('./src/i18n/fr.json'); console.log('OK')"`
Expected: `OK`

---

### Task 5: Shared primitives (Reveal, useCountUp, HeartbeatLine)

**Files:**
- Create: `frontend/src/components/landing/Reveal.jsx`
- Create: `frontend/src/components/landing/useCountUp.js`
- Create: `frontend/src/components/landing/HeartbeatLine.jsx`

- [ ] **Step 1: Create Reveal.jsx**

```jsx
import { useEffect, useRef, useState } from 'react';

export default function Reveal({ children, delay = 0, className = '', as: Tag = 'div' }) {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setVisible(true);
      return;
    }
    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          io.disconnect();
        }
      },
      { threshold: 0.15 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <Tag
      ref={ref}
      className={`reveal ${visible ? 'is-visible' : ''} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </Tag>
  );
}
```

- [ ] **Step 2: Create useCountUp.js**

```js
import { useEffect, useRef, useState } from 'react';

export default function useCountUp(target, { duration = 1400, decimals = 0, start = false } = {}) {
  const [value, setValue] = useState(0);
  const raf = useRef(null);

  useEffect(() => {
    if (!start) return undefined;
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      setValue(target);
      return undefined;
    }
    const t0 = performance.now();
    const tick = (now) => {
      const p = Math.min((now - t0) / duration, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      setValue(parseFloat((target * eased).toFixed(decimals)));
      if (p < 1) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, [start, target, duration, decimals]);

  return value;
}
```

- [ ] **Step 3: Create HeartbeatLine.jsx**

```jsx
export default function HeartbeatLine({ className = '' }) {
  return (
    <svg
      viewBox="0 0 600 160"
      className={`heartbeat ${className}`}
      fill="none"
      aria-hidden="true"
      preserveAspectRatio="none"
    >
      <path
        className="heartbeat-path"
        d="M0 80 H120 L145 80 160 45 175 115 190 80 H230 L250 80 262 60 274 100 286 80 H360 L375 80 390 30 408 130 424 80 H600"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}
```

- [ ] **Step 4: Verify build**

Run: `cd frontend && npm run build`
Expected: BUILD SUCCESS.

---

### Task 6: LandingNav

**Files:**
- Create: `frontend/src/components/landing/LandingNav.jsx`

- [ ] **Step 1: Create LandingNav.jsx**

```jsx
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from '../LanguageToggle';

export default function LandingNav() {
  const { t } = useTranslation();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const links = [
    ['problem', '#problem'],
    ['what', '#what'],
    ['how', '#how'],
    ['features', '#features'],
    ['audiences', '#audiences'],
  ];

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'bg-cream/90 backdrop-blur-md shadow-[0_1px_0_0_rgba(46,36,48,0.08)]'
          : 'bg-transparent'
      }`}
    >
      <nav
        className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-4"
        aria-label="Main"
      >
        <a href="#top" className="flex items-center gap-2">
          <span className="material-symbols-outlined text-terracotta text-[28px]">
            cardiology
          </span>
          <span className="font-display text-xl font-semibold text-ink">
            MamaSafe
          </span>
        </a>
        <ul className="hidden items-center gap-6 lg:flex">
          {links.map(([key, href]) => (
            <li key={key}>
              <a
                href={href}
                className="text-sm font-medium text-plum-soft hover:text-terracotta transition-colors"
              >
                {t(`landing.nav.${key}`)}
              </a>
            </li>
          ))}
        </ul>
        <div className="flex items-center gap-2">
          <LanguageToggle />
          <Link
            to="/login"
            className="hidden sm:inline-flex rounded-full px-4 py-2 text-sm font-semibold text-ink hover:text-terracotta transition-colors"
          >
            {t('landing.nav.login')}
          </Link>
          <Link
            to="/signup"
            className="inline-flex rounded-full bg-terracotta px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-terracotta-deep transition-colors"
          >
            {t('landing.nav.cta')}
          </Link>
        </div>
      </nav>
    </header>
  );
}
```

---

### Task 7: HeroSection

**Files:**
- Create: `frontend/src/components/landing/HeroSection.jsx`

- [ ] **Step 1: Create HeroSection.jsx**

```jsx
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import HeartbeatLine from './HeartbeatLine';
import Reveal from './Reveal';

export default function HeroSection() {
  const { t } = useTranslation();
  return (
    <section id="top" className="relative overflow-hidden bg-cream pt-32 pb-20 sm:pt-40 sm:pb-28">
      <div
        className="pointer-events-none absolute -top-24 -right-24 h-96 w-96 rounded-full bg-rose-100/60 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute top-40 -left-32 h-80 w-80 rounded-full bg-teal-soft/70 blur-3xl"
        aria-hidden="true"
      />
      <div className="relative mx-auto grid max-w-6xl items-center gap-14 px-5 lg:grid-cols-[1.1fr_0.9fr]">
        <div>
          <Reveal>
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-terracotta/25 bg-white/70 px-4 py-1.5 text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
              <span className="material-symbols-outlined text-[16px]">favorite</span>
              {t('landing.hero.kicker')}
            </p>
          </Reveal>
          <Reveal delay={100}>
            <h1 className="font-display text-5xl font-semibold leading-[1.05] text-ink sm:text-6xl lg:text-7xl">
              {t('landing.hero.h1')}
            </h1>
          </Reveal>
          <Reveal delay={200}>
            <p className="mt-6 max-w-xl text-lg leading-relaxed text-plum-soft">
              {t('landing.hero.sub')}
            </p>
          </Reveal>
          <Reveal delay={300}>
            <div className="mt-8 flex flex-wrap items-center gap-4">
              <Link
                to="/signup"
                className="rounded-full bg-terracotta px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-terracotta/25 hover:bg-terracotta-deep hover:-translate-y-0.5 transition-all"
              >
                {t('landing.hero.cta_primary')}
              </Link>
              <a
                href="#how"
                className="group inline-flex items-center gap-2 rounded-full border border-ink/15 bg-white/70 px-7 py-3.5 text-base font-semibold text-ink hover:border-terracotta/40 hover:text-terracotta transition-colors"
              >
                {t('landing.hero.cta_secondary')}
                <span className="material-symbols-outlined text-[20px] transition-transform group-hover:translate-y-0.5">
                  arrow_downward
                </span>
              </a>
            </div>
          </Reveal>
          <Reveal delay={400}>
            <ul className="mt-10 flex flex-wrap gap-x-6 gap-y-2">
              {[1, 2, 3].map((i) => (
                <li key={i} className="flex items-center gap-2 text-sm font-medium text-plum-soft">
                  <span className="material-symbols-outlined text-[18px] text-teal-deep">
                    check_circle
                  </span>
                  {t(`landing.hero.chip${i}`)}
                </li>
              ))}
            </ul>
          </Reveal>
        </div>

        <Reveal delay={250} className="relative">
          <div className="relative rounded-[2rem] border border-white/70 bg-white/80 p-8 shadow-xl shadow-rose-100/40 backdrop-blur">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-text-muted">
                {t('landing.hero.visual_label')}
              </p>
              <span className="relative flex h-2.5 w-2.5">
                <span className="absolute h-2.5 w-2.5 animate-ping rounded-full bg-rose-primary opacity-60" />
                <span className="relative h-2.5 w-2.5 rounded-full bg-rose-primary" />
              </span>
            </div>
            <HeartbeatLine className="mt-4 w-full text-rose-primary" />
            <div className="mt-6 grid grid-cols-2 gap-3">
              <div className="rounded-2xl bg-rose-light px-4 py-3">
                <p className="font-display text-lg font-semibold text-ink">
                  {t('landing.hero.visual_chip1')}
                </p>
                <p className="text-xs text-text-body">
                  {t('landing.hero.visual_chip1_sub')}
                </p>
              </div>
              <div className="rounded-2xl bg-teal-soft px-4 py-3">
                <p className="font-display text-lg font-semibold text-ink">
                  {t('landing.hero.visual_chip2')}
                </p>
                <p className="text-xs text-text-body">
                  {t('landing.hero.visual_chip2_sub')}
                </p>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
```

---

### Task 8: ProblemSection

**Files:**
- Create: `frontend/src/components/landing/ProblemSection.jsx`

- [ ] **Step 1: Create ProblemSection.jsx**

```jsx
import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';
import useCountUp from './useCountUp';

function Stat({ value, decimals = 0, prefix = '', suffix = '', label, source, start }) {
  const n = useCountUp(value, { start, decimals });
  return (
    <div className="rounded-3xl border border-border bg-white p-7 shadow-sm">
      <p className="font-display text-5xl font-semibold text-terracotta">
        {prefix}
        {decimals ? n.toFixed(decimals) : Math.round(n)}
        {suffix}
      </p>
      <p className="mt-3 text-sm leading-relaxed text-plum-soft">{label}</p>
      <p className="mt-2 text-[11px] uppercase tracking-wide text-text-muted">{source}</p>
    </div>
  );
}

export default function ProblemSection() {
  const { t } = useTranslation();
  const ref = useRef(null);
  const [start, setStart] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(
      ([e]) => { if (e.isIntersecting) { setStart(true); io.disconnect(); } },
      { threshold: 0.25 }
    );
    io.observe(el);
    return () => io.disconnect();
  }, []);

  return (
    <section id="problem" ref={ref} className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.problem.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.problem.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-3xl text-lg leading-relaxed text-plum-soft">
            {t('landing.problem.p1')}
          </p>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          <Reveal delay={100}>
            <Stat
              value={t('landing.problem.stat1_value')}
              label={t('landing.problem.stat1_label')}
              source={t('landing.problem.stat1_source')}
              start={start}
            />
          </Reveal>
          <Reveal delay={200}>
            <Stat
              value={t('landing.problem.stat2_value')}
              prefix={t('landing.problem.stat2_prefix')}
              suffix={t('landing.problem.stat2_suffix')}
              label={t('landing.problem.stat2_label')}
              source={t('landing.problem.stat2_source')}
              start={start}
            />
          </Reveal>
          <Reveal delay={300}>
            <Stat
              value={t('landing.problem.stat3_value')}
              label={t('landing.problem.stat3_label')}
              source={t('landing.problem.stat3_source')}
              start={start}
            />
          </Reveal>
        </div>

        <Reveal delay={400}>
          <div className="mt-10 flex flex-col items-start gap-4 rounded-3xl border border-border bg-cream px-8 py-7 sm:flex-row sm:items-center sm:gap-8">
            <p className="font-display text-3xl font-semibold text-teal-deep">
              {t('landing.problem.progress_title')}
            </p>
            <div>
              <p className="text-sm leading-relaxed text-plum-soft">
                {t('landing.problem.progress_caption')}
              </p>
              <p className="mt-1 text-[11px] uppercase tracking-wide text-text-muted">
                {t('landing.problem.progress_source')}
              </p>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
```

---

### Task 9: WhatItIsSection

**Files:**
- Create: `frontend/src/components/landing/WhatItIsSection.jsx`

- [ ] **Step 1: Create WhatItIsSection.jsx**

```jsx
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const PILLARS = [
  { key: 'p1', icon: 'monitor_heart', bg: 'bg-rose-light' },
  { key: 'p2', icon: 'event_upcoming', bg: 'bg-teal-soft' },
  { key: 'p3', icon: 'notification_important', bg: 'bg-sand' },
];

export default function WhatItIsSection() {
  const { t } = useTranslation();
  return (
    <section id="what" className="bg-cream py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.what.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.what.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-3xl text-lg leading-relaxed text-plum-soft">
            {t('landing.what.p')}
          </p>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          {PILLARS.map((p, i) => (
            <Reveal key={p.key} delay={i * 120}>
              <div className={`flex h-full flex-col rounded-3xl ${p.bg} p-8`}>
                <span className="material-symbols-outlined text-4xl text-terracotta">
                  {p.icon}
                </span>
                <h3 className="mt-5 font-display text-xl font-semibold text-ink">
                  {t(`landing.what.${p.key}_t`)}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-plum-soft">
                  {t(`landing.what.${p.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
```

---

### Task 10: HowItWorksSection (6 steps + ANC timeline)

**Files:**
- Create: `frontend/src/components/landing/HowItWorksSection.jsx`

- [ ] **Step 1: Create HowItWorksSection.jsx**

```jsx
import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const STEPS = [
  { icon: 'person_add', key: 's1' },
  { icon: 'monitor_heart', key: 's2' },
  { icon: 'calendar_month', key: 's3' },
  { icon: 'chat', key: 's4' },
  { icon: 'show_chart', key: 's5' },
  { icon: 'local_hospital', key: 's6' },
];

const VISITS = [8, 16, 20, 26, 30, 34, 36, 38];

function ANCTimeline() {
  const { t } = useTranslation();
  const [selected, setSelected] = useState(0);
  const week = VISITS[selected];

  return (
    <div className="mt-16 rounded-3xl border border-border bg-white p-8 shadow-sm">
      <Reveal>
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
          {t('landing.how.timeline_kicker')}
        </p>
      </Reveal>
      <Reveal delay={100}>
        <h3 className="mt-2 font-display text-2xl font-semibold text-ink">
          {t('landing.how.timeline_h3')}
        </h3>
      </Reveal>

      <Reveal delay={200}>
        <div className="relative mt-10 h-20 overflow-x-auto no-scrollbar">
          <div className="relative mx-4 h-1 rounded-full bg-border" style={{ minWidth: 600 }}>
            {VISITS.map((w, i) => {
              const left = `${(w / 40) * 100}%`;
              const active = i === selected;
              return (
                <button
                  key={w}
                  type="button"
                  onClick={() => setSelected(i)}
                  className="absolute -top-3 flex -translate-x-1/2 flex-col items-center gap-1"
                  style={{ left }}
                  aria-label={`${t('landing.how.week_label')} ${w}`}
                >
                  <span
                    className={`flex h-7 w-7 items-center justify-center rounded-full border-2 text-xs font-bold transition-all ${
                      active
                        ? 'border-terracotta bg-terracotta text-white scale-125'
                        : 'border-terracotta/40 bg-white text-terracotta hover:scale-110'
                    }`}
                  >
                    {w}
                  </span>
                </button>
              );
            })}
            <div
              className="absolute -top-3 -translate-x-1/2"
              style={{ left: '100%' }}
            >
              <span className="flex h-7 items-center rounded-full bg-gold/20 px-2 text-[10px] font-bold uppercase tracking-wide text-gold">
                {t('landing.how.edd')}
              </span>
            </div>
          </div>
        </div>
      </Reveal>

      <Reveal delay={300}>
        <div className="mt-8 rounded-2xl bg-cream p-6">
          <p className="text-xs font-semibold uppercase tracking-wide text-terracotta">
            {t('landing.how.week_label')} {week}
          </p>
          <p className="mt-2 text-base leading-relaxed text-ink">
            {t(`landing.how.v${week}`)}
          </p>
        </div>
      </Reveal>
    </div>
  );
}

export default function HowItWorksSection() {
  const { t } = useTranslation();
  return (
    <section id="how" className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.how.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.how.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {STEPS.map((s, i) => (
            <Reveal key={s.key} delay={i * 100}>
              <div className="flex gap-4 rounded-3xl border border-border bg-cream p-6">
                <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-terracotta/10 text-terracotta">
                  <span className="material-symbols-outlined text-[24px]">{s.icon}</span>
                </span>
                <div>
                  <p className="text-xs font-bold text-terracotta">0{i + 1}</p>
                  <h3 className="mt-1 font-display text-lg font-semibold text-ink">
                    {t(`landing.how.${s.key}_t`)}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-plum-soft">
                    {t(`landing.how.${s.key}_d`)}
                  </p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        <ANCTimeline />
      </div>
    </section>
  );
}
```

---

### Task 11: RiskSimulator

**Files:**
- Create: `frontend/src/components/landing/RiskSimulator.jsx`

- [ ] **Step 1: Create RiskSimulator.jsx**

```jsx
import { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { riskScore } from '../../utils/riskScore';
import Reveal from './Reveal';

const SLIDERS = [
  { key: 'age', field: 'age', min: 15, max: 49, step: 1, default: 25 },
  { key: 'sbp', field: 'systolicBP', min: 90, max: 180, step: 1, default: 110 },
  { key: 'sugar', field: 'bloodSugar', min: 2.5, max: 11, step: 0.1, default: 5 },
  { key: 'temp', field: 'bodyTemp', min: 35.5, max: 40, step: 0.1, default: 36.8 },
  { key: 'hr', field: 'heartRate', min: 60, max: 120, step: 1, default: 80 },
];

const LEVEL_COLORS = {
  low: 'var(--color-risk-low)',
  mid: 'var(--color-risk-mid)',
  high: 'var(--color-risk-high)',
};

function polar(score, r = 80) {
  const a = Math.PI - score * Math.PI;
  return [100 + r * Math.cos(a), 100 - r * Math.sin(a)];
}

function arcPath(s0, s1) {
  const [x0, y0] = polar(s0);
  const [x1, y1] = polar(s1);
  return `M ${x0} ${y0} A 80 80 0 0 1 ${x1} ${y1}`;
}

function Gauge({ score, level }) {
  const [nx, ny] = polar(score, 62);
  return (
    <svg viewBox="0 0 200 120" className="w-full max-w-[280px]" aria-hidden="true">
      <path d={arcPath(0, 0.34)} stroke="var(--color-risk-low)" strokeWidth="14" fill="none" strokeLinecap="round" />
      <path d={arcPath(0.34, 0.67)} stroke="var(--color-risk-mid)" strokeWidth="14" fill="none" />
      <path d={arcPath(0.67, 1)} stroke="var(--color-risk-high)" strokeWidth="14" fill="none" strokeLinecap="round" />
      <line
        x1="100" y1="100" x2={nx} y2={ny}
        stroke={LEVEL_COLORS[level]}
        strokeWidth="3"
        strokeLinecap="round"
        style={{ transition: 'all 0.5s ease-out' }}
      />
      <circle cx="100" cy="100" r="5" fill={LEVEL_COLORS[level]} style={{ transition: 'fill 0.5s ease-out' }} />
    </svg>
  );
}

export default function RiskSimulator() {
  const { t } = useTranslation();
  const [values, setValues] = useState(() =>
    Object.fromEntries(SLIDERS.map((s) => [s.field, s.default]))
  );

  const result = useMemo(() => riskScore(values), [values]);

  const update = (field, raw) => {
    setValues((prev) => ({ ...prev, [field]: parseFloat(raw) }));
  };

  const guidanceKey = `landing.sim.g_${result.level}`;
  const levelKey = `landing.sim.${result.level}`;

  return (
    <section id="sim" className="bg-sand py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.sim.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.sim.h2')}
          </h2>
        </Reveal>
        <Reveal delay={200}>
          <p className="mt-6 max-w-2xl text-lg leading-relaxed text-plum-soft">
            {t('landing.sim.p')}
          </p>
        </Reveal>

        <Reveal delay={300}>
          <div className="mt-12 grid gap-10 lg:grid-cols-[1fr_auto]">
            <div className="space-y-6">
              {SLIDERS.map((s) => (
                <div key={s.key}>
                  <div className="flex items-center justify-between">
                    <label htmlFor={`sim-${s.key}`} className="text-sm font-semibold text-ink">
                      {t(`landing.sim.${s.key}`)}
                    </label>
                    <span className="rounded-full bg-white px-3 py-1 text-sm font-bold tabular-nums text-terracotta">
                      {values[s.field]}
                    </span>
                  </div>
                  <input
                    id={`sim-${s.key}`}
                    type="range"
                    className="landing-range mt-2 h-2 w-full cursor-pointer appearance-none rounded-full bg-border"
                    min={s.min}
                    max={s.max}
                    step={s.step}
                    value={values[s.field]}
                    onChange={(e) => update(s.field, e.target.value)}
                  />
                </div>
              ))}
            </div>

            <div className="flex flex-col items-center rounded-3xl bg-white p-8 shadow-sm">
              <Gauge score={result.score} level={result.level} />
              <p
                className="mt-4 font-display text-2xl font-bold"
                style={{ color: LEVEL_COLORS[result.level], transition: 'color 0.5s ease-out' }}
              >
                {t(levelKey)}
              </p>
              <p className="mt-2 max-w-xs text-center text-sm leading-relaxed text-plum-soft">
                {t(guidanceKey)}
              </p>
            </div>
          </div>
        </Reveal>

        <Reveal delay={400}>
          <p className="mt-8 text-xs leading-relaxed text-text-muted">
            {t('landing.sim.disclaimer')}
          </p>
        </Reveal>
      </div>
    </section>
  );
}
```

---

### Task 12: FeaturesSection

**Files:**
- Create: `frontend/src/components/landing/FeaturesSection.jsx`

- [ ] **Step 1: Create FeaturesSection.jsx**

```jsx
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const FEATURES = [
  { icon: 'monitor_heart', key: 'f1' },
  { icon: 'query_stats', key: 'f2' },
  { icon: 'event_upcoming', key: 'f3' },
  { icon: 'chat', key: 'f4' },
  { icon: 'show_chart', key: 'f5' },
  { icon: 'local_hospital', key: 'f6' },
  { icon: 'child_care', key: 'f7' },
  { icon: 'domain', key: 'f8' },
  { icon: 'translate', key: 'f9' },
];

export default function FeaturesSection() {
  const { t } = useTranslation();
  return (
    <section id="features" className="bg-cream py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.features.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.features.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f, i) => (
            <Reveal key={f.key} delay={i * 80}>
              <div className="flex h-full flex-col rounded-3xl border border-border bg-white p-7">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-teal-soft text-teal-deep">
                  <span className="material-symbols-outlined text-[22px]">{f.icon}</span>
                </span>
                <h3 className="mt-5 font-display text-lg font-semibold text-ink">
                  {t(`landing.features.${f.key}_t`)}
                </h3>
                <p className="mt-2 text-sm leading-relaxed text-plum-soft">
                  {t(`landing.features.${f.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
```

---

### Task 13: AudienceSection + ImpactSection

**Files:**
- Create: `frontend/src/components/landing/AudienceSection.jsx`
- Create: `frontend/src/components/landing/ImpactSection.jsx`

- [ ] **Step 1: Create AudienceSection.jsx**

```jsx
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

const AUDIENCES = [
  { icon: 'health_and_safety', key: 'a1', bg: 'bg-rose-light' },
  { icon: 'family_restroom', key: 'a2', bg: 'bg-teal-soft' },
  { icon: 'account_balance', key: 'a3', bg: 'bg-sand' },
];

export default function AudienceSection() {
  const { t } = useTranslation();
  return (
    <section id="audiences" className="bg-white py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.audiences.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.audiences.h2')}
          </h2>
        </Reveal>

        <div className="mt-14 grid gap-6 sm:grid-cols-3">
          {AUDIENCES.map((a, i) => (
            <Reveal key={a.key} delay={i * 120}>
              <div className={`flex h-full flex-col rounded-3xl ${a.bg} p-8`}>
                <span className="material-symbols-outlined text-4xl text-terracotta">
                  {a.icon}
                </span>
                <h3 className="mt-5 font-display text-xl font-semibold text-ink">
                  {t(`landing.audiences.${a.key}_t`)}
                </h3>
                <p className="mt-3 text-sm leading-relaxed text-plum-soft">
                  {t(`landing.audiences.${a.key}_d`)}
                </p>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
```

- [ ] **Step 2: Create ImpactSection.jsx**

```jsx
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

export default function ImpactSection() {
  const { t } = useTranslation();
  return (
    <section className="bg-cream py-24 sm:py-32">
      <div className="mx-auto max-w-6xl px-5">
        <Reveal>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-terracotta">
            {t('landing.impact.kicker')}
          </p>
        </Reveal>
        <Reveal delay={100}>
          <h2 className="mt-3 max-w-3xl font-display text-4xl font-semibold leading-tight text-ink sm:text-5xl">
            {t('landing.impact.h2')}
          </h2>
        </Reveal>
        <div className="mt-10 grid gap-10 lg:grid-cols-[1.2fr_0.8fr]">
          <Reveal delay={200}>
            <div className="space-y-5">
              <p className="text-lg leading-relaxed text-plum-soft">{t('landing.impact.p1')}</p>
              <p className="text-lg leading-relaxed text-plum-soft">{t('landing.impact.p2')}</p>
            </div>
          </Reveal>
          <Reveal delay={300}>
            <blockquote className="flex h-full flex-col justify-center rounded-3xl border-l-4 border-terracotta bg-white p-8">
              <span className="material-symbols-outlined text-3xl text-terracotta">format_quote</span>
              <p className="mt-4 font-display text-2xl font-semibold leading-snug text-ink">
                {t('landing.impact.quote')}
              </p>
            </blockquote>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
```

---

### Task 14: CTASection

**Files:**
- Create: `frontend/src/components/landing/CTASection.jsx`

- [ ] **Step 1: Create CTASection.jsx**

```jsx
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import Reveal from './Reveal';

export default function CTASection() {
  const { t } = useTranslation();
  return (
    <>
      <section className="bg-teal-deep py-24 sm:py-32">
        <div className="mx-auto max-w-4xl px-5 text-center">
          <Reveal>
            <h2 className="font-display text-4xl font-semibold leading-tight text-white sm:text-5xl">
              {t('landing.cta.h2')}
            </h2>
          </Reveal>
          <Reveal delay={100}>
            <p className="mx-auto mt-6 max-w-2xl text-lg leading-relaxed text-white/80">
              {t('landing.cta.p')}
            </p>
          </Reveal>
          <Reveal delay={200}>
            <div className="mt-10 flex flex-wrap items-center justify-center gap-4">
              <Link
                to="/chw-signup"
                className="rounded-full bg-white px-8 py-4 text-base font-semibold text-teal-deep shadow-lg hover:-translate-y-0.5 transition-all"
              >
                {t('landing.cta.primary')}
              </Link>
              <Link
                to="/login"
                className="rounded-full border border-white/30 px-8 py-4 text-base font-semibold text-white hover:bg-white/10 transition-colors"
              >
                {t('landing.cta.secondary')}
              </Link>
            </div>
          </Reveal>
        </div>
      </section>

      <footer className="bg-ink py-10">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-5 sm:flex-row">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-terracotta text-[22px]">cardiology</span>
            <span className="font-display text-base font-semibold text-white">MamaSafe</span>
            <span className="text-xs text-white/50">· {t('landing.cta.footer_tagline')}</span>
          </div>
          <p className="text-xs text-white/50">{t('landing.cta.rights')}</p>
        </div>
      </footer>
    </>
  );
}
```

---

### Task 15: LandingPage assembly + App.jsx routing

**Files:**
- Create: `frontend/src/pages/LandingPage.jsx`
- Modify: `frontend/src/App.jsx`

- [ ] **Step 1: Create LandingPage.jsx**

```jsx
import LandingNav from '../components/landing/LandingNav';
import HeroSection from '../components/landing/HeroSection';
import ProblemSection from '../components/landing/ProblemSection';
import WhatItIsSection from '../components/landing/WhatItIsSection';
import HowItWorksSection from '../components/landing/HowItWorksSection';
import RiskSimulator from '../components/landing/RiskSimulator';
import FeaturesSection from '../components/landing/FeaturesSection';
import AudienceSection from '../components/landing/AudienceSection';
import ImpactSection from '../components/landing/ImpactSection';
import CTASection from '../components/landing/CTASection';

export default function LandingPage() {
  return (
    <main className="min-h-screen bg-cream text-ink">
      <LandingNav />
      <HeroSection />
      <ProblemSection />
      <WhatItIsSection />
      <HowItWorksSection />
      <RiskSimulator />
      <FeaturesSection />
      <AudienceSection />
      <ImpactSection />
      <CTASection />
    </main>
  );
}
```

- [ ] **Step 2: Update App.jsx routing**

In `frontend/src/App.jsx`:

1. Add import at the top (after the existing page imports):
```jsx
import LandingPage from './pages/LandingPage';
```

2. Add the public route BEFORE the protected routes block (after `<Routes>`):
```jsx
<Route path="/" element={<LandingPage />} />
```

3. Change the catch-all redirect from `/assess` to `/`:
```jsx
<Route path="*" element={<Navigate to="/" replace />} />
```

---

### Task 16: Verification

- [ ] **Step 1: Run tests**

Run: `cd frontend && npm test`
Expected: All tests pass (dateCalc + riskScore).

- [ ] **Step 2: Run lint**

Run: `cd frontend && npm run lint`
Expected: No errors.

- [ ] **Step 3: Run build**

Run: `cd frontend && npm run build`
Expected: BUILD SUCCESS.

- [ ] **Step 4: Manual smoke test**

Run: `cd frontend && npm run dev`

Verify in browser at `http://localhost:5173/`:
- [ ] Landing page renders at `/`
- [ ] All 10 sections visible
- [ ] EN/FR toggle switches all copy
- [ ] Nav links scroll to sections
- [ ] "Get started" → `/signup`, "Log in" → `/login`, "Create your CHW account" → `/chw-signup`
- [ ] Stat counters animate when scrolled into view
- [ ] ANC timeline markers are clickable and show visit details
- [ ] Risk simulator sliders update the gauge in real time
- [ ] `prefers-reduced-motion` disables animations (DevTools → Rendering → Emulate CSS media feature)
- [ ] Unknown URL (e.g., `/foo`) redirects to `/`
- [ ] Existing `/login` and protected routes still work
- [ ] Mobile responsive (resize to 375px width)
