# MamaSafe — Public Landing Page Design

**Date:** 2026-08-05
**Status:** Approved by user (Approach A — Editorial Journey)
**Scope:** `frontend/` React web app only. No backend, mobile, or ML changes.

---

## 1. Goal

Build a public landing page that advertises MamaSafe and explains — in plain,
layered detail — what the app is, what it does, how it is used, and why it
matters. The page is the front door of the product: warm, maternal,
credible, and interactive, serving three audiences at once (CHWs & health
workers, mothers & families, NGOs/donors/officials).

## 2. Decisions (from brainstorming)

| Question | Decision |
|---|---|
| Placement | Public route `/` in the existing React 19 + Vite + Tailwind 4 app |
| Audience | All — layered messaging (hero for everyone, a "who it's for" section per audience) |
| Language | Bilingual EN/FR via the existing i18next setup + `LanguageToggle` |
| Approach | Approach A: long-scroll editorial story with interactive visuals |

## 3. Verified facts used in copy (fact-checked 2026-08-05)

- Cameroon MMR (World Bank, SH.STA.MMRT, API updated 2026-07-13):
  2017 = 372, 2020 = 316, 2023 = **258** deaths per 100,000 live births.
  Used as: headline stat (258) and progress trend (372 → 258, 2017–2023).
- Sub-Saharan Africa accounts for ~70% of global maternal deaths
  (WHO/UN MMR trends reports).
- "Most maternal deaths are preventable" — WHO maternal mortality fact sheet.
- WHO recommends **8 ANC contacts** (2016 guidelines), adopted by Cameroon's
  Ministry of Public Health — matches `ANC_VISIT_SCHEDULER.md`.
- Feature claims are taken from the repo's own module docs: ML risk
  assessment with SHAP explanations, auto 8-visit ANC schedule from LMP,
  WhatsApp reminders (48h + 2h + daily CHW list), longitudinal risk trends
  with escalation alerts, referrals, postnatal tracking with PHQ-2, infant
  growth tracking, facility management, EN/FR UI.

Numbers on the page cite their source inline (small caption text).

## 4. Architecture

### Routing (`frontend/src/App.jsx`)

- Add `<Route path="/" element={<LandingPage />} />` (public, outside
  `ProtectedRoute`).
- The catch-all `*` currently redirects to `/assess`; change it to redirect
  to `/` so unknown URLs land on the landing page.
- No other routes change. Authenticated users hitting `/` see the landing
  page with CTAs; the existing nav is untouched.

### New files

```
frontend/src/pages/LandingPage.jsx           — page assembly only
frontend/src/components/landing/
  LandingNav.jsx       — sticky nav: logo, section links, LanguageToggle, CTAs
  HeroSection.jsx      — headline, sub, CTAs, HeartbeatLine visual
  ProblemSection.jsx   — animated stat counters + progress trend
  WhatItIsSection.jsx  — plain-language explainer, 3 pillars
  HowItWorksSection.jsx— 6-step CHW journey + interactive ANC timeline
  RiskSimulator.jsx    — interactive demo widget (sliders → risk gauge)
  FeaturesSection.jsx  — feature grid (9 real features)
  AudienceSection.jsx  — 3 audience cards
  ImpactSection.jsx    — importance/editorial + closing argument
  CTASection.jsx       — get-started band + footer
  Reveal.jsx           — IntersectionObserver scroll-reveal wrapper
  HeartbeatLine.jsx    — animated SVG pulse line (hero motif)
  useCountUp.js        — animated counter hook
frontend/src/components/landing/landing.css  — keyframes only (no Tailwind plugin)
```

### Modified files

- `frontend/src/App.jsx` — add `/` route, change catch-all to `/`.
- `frontend/src/i18n/en.json`, `fr.json` — add a top-level `landing` key
  with all page copy (no existing keys touched).
- `frontend/src/index.css` — extend `@theme` with landing tokens (below),
  import `landing.css`.
- `frontend/index.html` — add Google Fonts: Fraunces (display serif, weights
  500;600;700). Inter + Material Symbols already loaded.

No new npm dependencies. Motion uses IntersectionObserver + CSS transitions
(recharts/GSAP deliberately avoided for the landing page bundle).

## 5. Design system

Extends the existing rose identity (`--color-rose-primary: #E8637A`) into a
warmer maternal palette:

```css
@theme {
  /* existing tokens unchanged */
  --color-cream:       #FBF6EF;  /* page background */
  --color-sand:        #F3E7D7;  /* alt section band */
  --color-terracotta:  #C4552B;  /* primary accent (CTAs, highlights) */
  --color-terracotta-deep: #A03F1C;
  --color-teal-deep:   #155E56;  /* secondary (trust, clinical) */
  --color-teal-soft:   #DCEDEA;
  --color-gold:        #D9A03F;  /* small accents */
  --color-ink:         #2E2430;  /* headings */
  --color-plum-soft:   #4A3E4C;  /* body on cream */
  --font-display: 'Fraunces', Georgia, serif;
}
```

- Headings: Fraunces (warm editorial serif). Body: Inter (existing).
- Motifs: heartbeat/pulse line (life + monitoring), organic rounded shapes
  (border-radius 24–32px cards), thin SVG line illustrations, generous
  whitespace. Risk colors on the simulator: green `#2F9E6E`, amber
  `#E8A93F`, rose `#E8637A` (matches app's risk semantics).
- Sections alternate cream / white / sand bands so the long page breathes.

## 6. Page sections & copy outline

All copy lives in `landing.*` i18n keys (EN + FR). Outline:

1. **LandingNav** — "MamaSafe" mark (heart+pulse glyph), links: The problem,
   What it is, How it works, Features, Who it's for; LanguageToggle;
   "Log in" (ghost) + "Get started" (solid terracotta) → `/login`, `/signup`.
2. **HeroSection** — kicker "Maternal health, protected"; H1
   "Every mother deserves a safe journey."; 2-sentence plain-language sub;
   CTAs "Get started" / "See how it works" (anchor); trust strip
   (WHO-aligned 8 visits · EN/FR · Built for CHWs). Right: soft rounded
   panel with animated `HeartbeatLine` + floating stat chips.
3. **ProblemSection** — "The problem" — counters: 258 (Cameroon MMR, 2023),
   ~70% (SSA share of global maternal deaths), 8 (WHO-recommended visits
   many mothers never complete); progress line 372→258 (2017–2023) "progress
   is possible — every prevented death starts with timely care"; short
   paragraph: most maternal deaths are preventable; danger signs are missed
   when visits are skipped and records stay on paper. Source captions.
4. **WhatItIsSection** — "What is MamaSafe?" — one plain paragraph + 3
   pillar cards: **Assess the risk** (ML risk prediction from simple
   measurements, explained with SHAP), **Never miss a visit** (auto WHO
   8-visit schedule + WhatsApp reminders), **Act in time** (escalation
   alerts + referrals to facilities).
5. **HowItWorksSection** — "How it works" — 6 steps: Register the mother &
   pregnancy (LMP) → ML risk assessment → Auto 8-visit schedule → WhatsApp
   reminders to mother + daily CHW list → Track risk across visits
   (escalation alerts) → Refer, deliver, follow up postnatally + infant
   growth. Below: interactive ANC timeline — a 40-week bar with 8 visit
   markers (8, 16, 20, 26, 30, 34, 36, 38 wks); tapping a marker shows that
   visit's clinical focus in a detail card.
6. **RiskSimulator** — "See risk prediction in action" — sliders: age
   (15–49), systolic BP (90–180), blood sugar (2.5–11 mmol/L), body temp
   (35.5–40 °C), heart rate (60–120); deterministic weighted score →
   animated gauge (Low / Medium / High) + dynamic plain-language guidance
   line. Caption: "Illustrative demo only — the real model is a validated ML
   model that explains its predictions."
7. **FeaturesSection** — grid of 9 with Material Symbols icons: ML risk
   prediction; SHAP explainability; ANC scheduler + WhatsApp reminders;
   longitudinal trends + escalation alerts; referral system; postnatal care
   + PHQ-2 wellbeing; infant growth tracking; facility management;
   bilingual EN/FR + works on any device.
8. **AudienceSection** — "Who MamaSafe is for" — 3 cards: CHWs & health
   workers (your daily companion…), Mothers & families (reminders, follow-up,
   someone watching…), Health officials & partners (real-time district
   visibility, measurable impact).
9. **ImpactSection** — editorial closer: why timing matters; the quiet-
   escalation story (trend catches what one visit misses); pull-quote
   styling; mini-repeat of the 3 pillars as outcome statements.
10. **CTASection** — "Start protecting mothers today." — "Create your CHW
    account" → `/chw-signup`, "Log in" → `/login`; footer: MamaSafe ·
    Maternal health, protected · EN/FR · © 2026.

## 7. Motion & interaction

- `Reveal`: IntersectionObserver (threshold 0.15, once) adds
  `.is-visible` → opacity 0→1, translateY 16→0, 600ms ease-out; stagger via
  `transition-delay` prop.
- `useCountUp`: starts when visible, ~1.4s ease-out, formats decimals/%.
- `HeartbeatLine`: SVG path with `stroke-dasharray` draw loop (~2.4s) +
  soft glow dot traveling the line.
- ANC timeline & risk simulator: controlled React state, CSS transitions on
  markers/gauge (300–500ms).
- All animation suppressed under `prefers-reduced-motion` (global CSS
  override + hook guard); sliders get `<label>` + aria; sections use
  semantic landmarks (`header`, `main`, `section` with `aria-labelledby`,
  `footer`); contrast ≥ 4.5:1 for body text; focus-visible rings reuse
  `.focus-ring`.

## 8. i18n

- New top-level `landing` namespace inside existing `en.json` / `fr.json`
  (project convention: single `translation` namespace).
- FR copy is idiomatic (Cameroonian francophone context), not literal
  translation. `LanguageToggle` reused as-is in `LandingNav`.

## 9. Error handling & edge cases

- No network calls on the page → no error states needed.
- If fonts fail to load, fallbacks (Georgia/system serif, Inter) apply.
- `localStorage` lang read already handled by existing i18n init.
- Small screens: hero stacks, timeline scrolls horizontally with snap,
  sliders full-width; nav collapses to logo + language + CTA.

## 10. Verification

- `npm run build` passes; `npm run lint` passes.
- Manual smoke: `/` renders all sections in EN and FR (toggle), CTAs route
  to `/login`, `/signup`, `/chw-signup`; catch-all URL redirects to `/`;
  simulator + timeline + counters animate; `prefers-reduced-motion` disables
  animation (DevTools emulation); existing `/login` and protected routes
  still work.

## 11. Out of scope (YAGNI)

- Backend changes, real model wiring for the simulator, new auth flows,
  blog/CMS, analytics/tracking, SEO meta beyond title/description, dark
  mode, standalone HTML export.
