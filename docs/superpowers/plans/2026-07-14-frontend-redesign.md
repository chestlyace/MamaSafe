# MamaSafe Frontend Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign all 5 pages + NavBar + Layout with warm rose pink primary, clean minimalist design, mobile responsiveness, and proper spacing. Remove all AI slop patterns.

**Architecture:** Single-pass rewrite of every component file. No new files created. CSS overhaul in `index.css`. All i18n keys preserved (no structural changes to en.json/fr.json).

**Tech Stack:** React, Tailwind CSS v4, react-i18next, react-router-dom, Material Symbols

**Color System:**
- Primary: `#E8637A` (warm rose)
- Primary hover: `#D4526A`
- Primary light: `#FDF2F4` (tinted background)
- Neutral warm gray: `#3D3847` (text headings)
- Body text: `#5C5566`
- Muted text: `#8E8696`
- Border: `#E8E5EC`
- Surface: `#FAFAFA`
- Background: `#F8F6FA`

---

## Task 1: Overhaul `index.css` — Tailwind v4 + new color tokens

**Files:**
- Modify: `frontend/src/index.css`

- [ ] **Step 1: Replace entire `index.css` content**

```css
@import "tailwindcss";

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
}

body {
  margin: 0;
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background: var(--color-canvas);
  color: var(--color-text-body);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Material Symbols */
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

/* Focus ring utility */
.focus-ring:focus {
  outline: none;
  box-shadow: 0 0 0 2px var(--color-canvas), 0 0 0 4px var(--color-rose-primary);
}

/* Smooth scroll */
html {
  scroll-behavior: smooth;
}

/* Number input spinner hide */
input[type=number]::-webkit-inner-spin-button,
input[type=number]::-webkit-outer-spin-button {
  -webkit-appearance: none;
  margin: 0;
}
input[type=number] {
  -moz-appearance: textfield;
}
```

- [ ] **Step 2: Verify Tailwind still works**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 2: Rewrite `NavBar.jsx` — mobile hamburger + pink accent

**Files:**
- Modify: `frontend/src/components/NavBar.jsx`

- [ ] **Step 1: Replace entire NavBar.jsx**

```jsx
import { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from './LanguageToggle';

export default function NavBar() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  const navLinks = [
    { path: '/assess', label: t('new_assessment'), icon: 'assessment' },
    { path: '/history', label: t('history'), icon: 'history' },
    { path: '/dashboard', label: t('dashboard'), icon: 'monitoring' },
  ];

  const linkClass = (path) =>
    `text-sm transition-colors ${
      location.pathname === path
        ? 'text-rose-500 font-semibold'
        : 'text-text-body hover:text-rose-500'
    }`;

  return (
    <>
      <nav className="sticky top-0 z-50 bg-white border-b border-border">
        <div className="max-w-[1200px] mx-auto px-5 h-14 flex items-center justify-between">
          {/* Brand */}
          <Link to="/assess" className="flex items-center gap-2.5">
            <span className="text-xl">&#x1F931;</span>
            <span className="text-base font-bold text-text-heading tracking-tight">MamaSafe</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-8">
            {navLinks.map((link) => (
              <Link key={link.path} to={link.path} className={linkClass(link.path)}>
                {link.label}
              </Link>
            ))}
          </div>

          {/* Right side */}
          <div className="flex items-center gap-3">
            <LanguageToggle />
            <button
              onClick={logout}
              className="hidden md:block text-sm font-medium text-text-muted hover:text-rose-500 transition-colors"
            >
              {t('logout')}
            </button>
            {/* Mobile hamburger */}
            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="md:hidden p-1.5 -mr-1.5 text-text-body hover:text-rose-500 transition-colors"
              aria-label="Menu"
            >
              <span className="material-symbols-outlined text-[22px]">
                {mobileOpen ? 'close' : 'menu'}
              </span>
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile drawer */}
      {mobileOpen && (
        <>
          <div
            className="fixed inset-0 bg-black/20 z-40 md:hidden"
            onClick={() => setMobileOpen(false)}
          />
          <div className="fixed top-14 right-0 w-64 bg-white border-b border-border shadow-lg z-50 md:hidden">
            <div className="flex flex-col py-2">
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  to={link.path}
                  onClick={() => setMobileOpen(false)}
                  className={`flex items-center gap-3 px-5 py-3 text-sm transition-colors ${
                    location.pathname === link.path
                      ? 'text-rose-500 font-semibold bg-rose-50'
                      : 'text-text-body hover:bg-gray-50'
                  }`}
                >
                  <span className="material-symbols-outlined text-[20px]">{link.icon}</span>
                  {link.label}
                </Link>
              ))}
              <div className="border-t border-border mt-1 pt-1">
                <button
                  onClick={() => { setMobileOpen(false); logout(); }}
                  className="flex items-center gap-3 px-5 py-3 text-sm text-text-muted hover:text-rose-500 hover:bg-gray-50 w-full transition-colors"
                >
                  <span className="material-symbols-outlined text-[20px]">logout</span>
                  {t('logout')}
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 3: Rewrite `Layout.jsx` — clean background, no gradient

**Files:**
- Modify: `frontend/src/components/Layout.jsx`

- [ ] **Step 1: Replace entire Layout.jsx**

```jsx
import { Outlet } from 'react-router-dom';
import NavBar from './NavBar';

export default function Layout() {
  return (
    <div className="min-h-screen bg-canvas">
      <NavBar />
      <Outlet />
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 4: Rewrite `LanguageToggle.jsx` — match pink theme

**Files:**
- Modify: `frontend/src/components/LanguageToggle.jsx`

- [ ] **Step 1: Replace entire LanguageToggle.jsx**

```jsx
import { useTranslation } from 'react-i18next';

export default function LanguageToggle() {
  const { i18n } = useTranslation();
  const isEn = i18n.language === 'en';

  const toggle = () => {
    const next = isEn ? 'fr' : 'en';
    i18n.changeLanguage(next);
    localStorage.setItem('lang', next);
  };

  return (
    <button
      onClick={toggle}
      className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-border bg-white text-xs font-medium text-text-body hover:border-rose-200 hover:text-rose-500 transition-colors"
      aria-label={isEn ? 'Switch to French' : 'Passer a l\'anglais'}
    >
      <span className="material-symbols-outlined text-[16px]">translate</span>
      <span>{isEn ? 'EN' : 'FR'}</span>
    </button>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 5: Rewrite `LoginPage.jsx` — clean, no blobs, no glassmorphism

**Files:**
- Modify: `frontend/src/pages/LoginPage.jsx`

- [ ] **Step 1: Replace entire LoginPage.jsx**

```jsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { login } from '../api/client';
import LanguageToggle from '../components/LanguageToggle';

export default function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const data = await login(username, password);
      localStorage.setItem('token', data.access_token);
      navigate('/assess');
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      {/* Top bar */}
      <div className="flex justify-end p-5">
        <LanguageToggle />
      </div>

      {/* Center content */}
      <div className="flex-1 flex items-center justify-center px-5 pb-12">
        <div className="w-full max-w-[380px]">
          {/* Brand */}
          <div className="text-center mb-8">
            <span className="text-4xl block mb-3">&#x1F931;</span>
            <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('app_name')}</h1>
            <p className="text-sm text-text-muted mt-1">{t('tagline')}</p>
          </div>

          {/* Card */}
          <div className="bg-white rounded-2xl border border-border p-6 sm:p-8">
            {/* Error */}
            {error && (
              <div className="mb-5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Username */}
              <div>
                <label htmlFor="username" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
                  {t('username')}
                </label>
                <input
                  id="username"
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder={t('health_worker_id')}
                  required
                  className="w-full px-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/60 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                />
              </div>

              {/* Password */}
              <div>
                <label htmlFor="password" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
                  {t('password')}
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;"
                    required
                    className="w-full px-4 py-3 pr-11 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/60 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-rose-500 transition-colors"
                    tabIndex={-1}
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? 'visibility_off' : 'visibility'}
                    </span>
                  </button>
                </div>
              </div>

              {/* Submit */}
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
              >
                {loading ? (
                  <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
                ) : (
                  <>
                    <span>{t('login')}</span>
                    <span className="material-symbols-outlined text-lg group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Footer */}
          <p className="text-center text-xs text-text-muted mt-6">
            Developing Innovative Professionals — YIBS
          </p>
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 6: Rewrite `AssessmentPage.jsx` — clean form, pink accent

**Files:**
- Modify: `frontend/src/pages/AssessmentPage.jsx`

- [ ] **Step 1: Replace entire AssessmentPage.jsx**

```jsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { predict } from '../api/client';

export default function AssessmentPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    patient_ref: '',
    age: '',
    systolic_bp: '',
    diastolic_bp: '',
    blood_sugar: '',
    body_temp: '',
    heart_rate: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const update = (key, val) => setForm((prev) => ({ ...prev, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');
    try {
      const payload = {};
      if (form.patient_ref) payload.patient_ref = form.patient_ref;
      Object.keys(form).forEach((k) => {
        if (k !== 'patient_ref' && form[k] !== '') payload[k] = parseFloat(form[k]);
      });
      const data = await predict(payload);
      navigate('/result', { state: data });
    } catch {
      setError(t('error'));
    } finally {
      setSubmitting(false);
    }
  };

  const fields = [
    { key: 'age', min: 10, max: 60, step: 'any', placeholder: '25', icon: 'cake' },
    { key: 'systolic_bp', min: 70, max: 200, step: 'any', placeholder: '120', icon: 'monitor_heart' },
    { key: 'diastolic_bp', min: 40, max: 120, step: 'any', placeholder: '80', icon: 'favorite' },
    { key: 'blood_sugar', min: 4, max: 25, step: 0.1, placeholder: '7.0', icon: 'water_drop' },
    { key: 'body_temp', min: 95, max: 105, step: 0.1, placeholder: '98.6', icon: 'thermostat' },
    { key: 'heart_rate', min: 40, max: 100, step: 'any', placeholder: '72', icon: 'ecg' },
  ];

  const inputClass =
    'w-full pl-10 pr-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all';

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('new_assessment')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('enter_patient_data')}</p>
      </header>

      {/* Error */}
      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Patient Reference */}
        <div className="mb-6">
          <label htmlFor="patient_ref" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
            {t('patient_ref')}
          </label>
          <div className="relative">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-[20px]">
              badge
            </span>
            <input
              id="patient_ref"
              type="text"
              value={form.patient_ref}
              onChange={(e) => update('patient_ref', e.target.value)}
              placeholder={t('enter_patient_id')}
              className={inputClass}
            />
          </div>
        </div>

        {/* Clinical Fields */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t('enter_patient_data')}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {fields.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)}
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type="number"
                    min={f.min}
                    max={f.max}
                    step={f.step}
                    value={form[f.key]}
                    onChange={(e) => update(f.key, e.target.value)}
                    placeholder={f.placeholder}
                    required
                    className="w-full pl-10 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                  />
                </div>
                <span className="text-[11px] text-text-muted mt-1 block">
                  {f.min} – {f.max}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t('assessing')}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>analytics</span>
              <span>{t('assess_risk')}</span>
            </>
          )}
        </button>

        {/* Disclaimer */}
        <div className="mt-5 flex items-start gap-2.5 px-1">
          <span className="material-symbols-outlined text-amber-500 text-[18px] mt-0.5">info</span>
          <p className="text-xs text-text-muted leading-relaxed">
            {t('clinical_summary')}
          </p>
        </div>
      </form>
    </main>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 7: Rewrite `HistoryPage.jsx` — clean cards, pink links

**Files:**
- Modify: `frontend/src/pages/HistoryPage.jsx`

- [ ] **Step 1: Replace entire HistoryPage.jsx**

```jsx
import { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { getAssessments } from '../api/client';

const RISK_STYLES = {
  high: { dot: 'bg-red-500', text: 'text-red-600', bg: 'bg-red-50', border: 'border-red-200', i18nKey: 'high_risk' },
  mid: { dot: 'bg-amber-500', text: 'text-amber-600', bg: 'bg-amber-50', border: 'border-amber-200', i18nKey: 'moderate_risk' },
  low: { dot: 'bg-green-500', text: 'text-green-600', bg: 'bg-green-50', border: 'border-green-200', i18nKey: 'low_risk' },
};

function riskKey(level) {
  if (level === 'high risk') return 'high';
  if (level === 'mid risk') return 'mid';
  return 'low';
}

function formatDate(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    + ' \u2022 '
    + d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
}

export default function HistoryPage() {
  const { t } = useTranslation();
  const [assessments, setAssessments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    getAssessments(0, 100)
      .then((data) => setAssessments(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    if (!search.trim()) return assessments;
    const term = search.toLowerCase();
    return assessments.filter((a) => a.patient_ref?.toLowerCase().includes(term));
  }, [assessments, search]);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      </main>
    );
  }

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('assessment_history')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('manage_history')}</p>
        </div>
        <div className="relative">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">search</span>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('search_patient_id')}
            className="pl-10 pr-4 py-2.5 border border-border rounded-xl bg-white w-full sm:w-56 text-sm focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
          />
        </div>
      </div>

      {/* Cards */}
      {filtered.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filtered.map((a) => {
            const rk = riskKey(a.risk_level);
            const style = RISK_STYLES[rk];
            return (
              <div
                key={a.id}
                className="bg-white border border-border rounded-2xl p-5 hover:shadow-md hover:border-rose-100 transition-all"
              >
                {/* Top row */}
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t('patient_id')}</span>
                    <p className="text-lg font-semibold text-text-heading mt-0.5">{a.patient_ref || '\u2014'}</p>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    <span className="text-xs text-text-muted">{formatDate(a.created_at)}</span>
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${style.bg} ${style.border} ${style.text} border`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${style.dot}`} />
                      {t(style.i18nKey)}
                    </span>
                  </div>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-3 bg-surface rounded-xl p-3.5 mb-4">
                  <div>
                    <span className="text-[11px] text-text-muted block">{t('age')}</span>
                    <span className="text-sm font-semibold text-text-heading">{a.age}</span>
                  </div>
                  <div className="text-center border-x border-border px-3">
                    <span className="text-[11px] text-text-muted block">{t('systolic_bp')}</span>
                    <span className={`text-sm font-semibold ${rk === 'high' ? 'text-red-600' : 'text-text-heading'}`}>{a.systolic_bp}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-[11px] text-text-muted block">{t('blood_sugar')}</span>
                    <span className={`text-sm font-semibold ${rk === 'mid' ? 'text-amber-600' : 'text-text-heading'}`}>{a.blood_sugar}</span>
                  </div>
                </div>

                {/* Link */}
                <Link
                  to="/result"
                  state={{
                    risk_level: a.risk_level,
                    confidence: a.prob_high,
                    recommendation: '',
                    shap_values: [],
                    assessment_id: a.id,
                  }}
                  className="block text-center py-2 text-rose-500 text-sm font-semibold hover:bg-rose-50 rounded-lg transition-colors"
                >
                  {t('view_full_report')} &rarr;
                </Link>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty state */
        <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-border rounded-2xl">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">assignment</span>
          <h3 className="text-lg font-semibold text-text-heading mb-1">{t('no_assessments')}</h3>
          <p className="text-sm text-text-muted mb-6 max-w-xs">{t('history_empty_hint')}</p>
          <Link
            to="/assess"
            className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors"
          >
            {t('new_assessment')}
          </Link>
        </div>
      )}
    </main>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 8: Rewrite `DashboardPage.jsx` — clean stats, no heavy cards

**Files:**
- Modify: `frontend/src/pages/DashboardPage.jsx`

- [ ] **Step 1: Replace entire DashboardPage.jsx**

```jsx
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getDashboardSummary } from '../api/client';

function DonutChart({ high, mid, low, total }) {
  const { t } = useTranslation();
  const [hovered, setHovered] = useState(null);

  if (total === 0) return null;

  const highPct = (high / total) * 100;
  const midPct = (mid / total) * 100;
  const lowPct = (low / total) * 100;

  const segments = [
    { key: 'high', pct: highPct, color: '#ef4444', offset: 0 },
    { key: 'mid', pct: midPct, color: '#d97706', offset: -highPct },
    { key: 'low', pct: lowPct, color: '#16a34a', offset: -(highPct + midPct) },
  ];

  const formatTotal = (n) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(n));

  return (
    <div className="flex flex-col">
      <h3 className="text-sm font-semibold text-text-heading mb-1">{t('risk_distribution')}</h3>
      <p className="text-xs text-text-muted mb-5">{t('risk_distribution_desc')}</p>

      <div className="relative flex justify-center">
        <svg className="transform -rotate-90" height="180" width="180" viewBox="0 0 42 42">
          <circle cx="21" cy="21" fill="transparent" r="15.915" stroke="#E8E5EC" strokeWidth="3.5" />
          {segments.map((s) => (
            <circle
              key={s.key}
              cx="21" cy="21" fill="transparent" r="15.915"
              stroke={s.color}
              strokeWidth={hovered === s.key ? 5 : 3.5}
              strokeDasharray={`${s.pct} ${100 - s.pct}`}
              strokeDashoffset={s.offset}
              style={{
                transition: 'stroke-width 0.15s ease',
                cursor: 'pointer',
              }}
              onMouseEnter={() => setHovered(s.key)}
              onMouseLeave={() => setHovered(null)}
            />
          ))}
        </svg>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center">
          <div className="text-2xl font-bold text-text-heading">{formatTotal(total)}</div>
          <div className="text-[10px] font-medium text-text-muted uppercase">{t('total')}</div>
        </div>
      </div>

      {/* Legend */}
      <div className="flex justify-center gap-5 mt-5">
        {[
          { label: t('high_risk'), pct: highPct, color: 'bg-red-500' },
          { label: t('mid_risk'), pct: midPct, color: 'bg-amber-500' },
          { label: t('low_risk'), pct: lowPct, color: 'bg-green-500' },
        ].map((item) => (
          <div key={item.label} className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${item.color}`} />
            <span className="text-xs text-text-muted">{item.label} {item.pct.toFixed(0)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const { t } = useTranslation();
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDashboardSummary()
      .then((data) => setSummary(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      </main>
    );
  }

  if (!summary) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="text-center py-24 text-text-muted">{t('error')}</div>
      </main>
    );
  }

  const { total_assessments, high_risk_count, mid_risk_count, low_risk_count } = summary;

  const stats = [
    { label: t('total_assessments'), value: total_assessments.toLocaleString(), icon: 'assessment', color: 'text-rose-500', valueColor: 'text-text-heading', sub: null },
    { label: t('high_risk'), value: high_risk_count, dot: 'bg-red-500', color: 'text-red-500', valueColor: 'text-red-600', sub: t('requires_immediate') },
    { label: t('mid_risk'), value: mid_risk_count, dot: 'bg-amber-500', color: 'text-amber-500', valueColor: 'text-amber-600', sub: t('needs_followup') },
    { label: t('low_risk'), value: low_risk_count, dot: 'bg-green-500', color: 'text-green-500', valueColor: 'text-green-600', sub: t('regular_monitoring') },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('dashboard')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('clinical_summary')}</p>
      </header>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
        {stats.map((s) => (
          <div key={s.label} className="bg-white border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{s.label}</span>
              {s.icon ? (
                <span className={`material-symbols-outlined text-[18px] ${s.color}`}>{s.icon}</span>
              ) : (
                <span className={`w-2 h-2 rounded-full ${s.dot}`} />
              )}
            </div>
            <div className={`text-2xl font-bold ${s.valueColor}`}>{s.value}</div>
            {s.sub && <span className="text-xs text-text-muted mt-0.5 block">{s.sub}</span>}
          </div>
        ))}
      </div>

      {/* Donut + Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        {/* Donut */}
        <div className="bg-white border border-border rounded-xl p-5">
          <DonutChart high={high_risk_count} mid={mid_risk_count} low={low_risk_count} total={total_assessments} />
        </div>

        {/* Stacked bar */}
        {total_assessments > 0 && (
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-1">{t('weekly_trend')}</h3>
            <p className="text-xs text-text-muted mb-5">{t('weekly_trend_desc')}</p>
            <div className="w-full h-7 rounded-full overflow-hidden flex bg-surface">
              {high_risk_count > 0 && (
                <div
                  className="h-full bg-red-500 flex items-center justify-center"
                  style={{ width: `${(high_risk_count / total_assessments) * 100}%` }}
                >
                  {(high_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{high_risk_count}</span>
                  )}
                </div>
              )}
              {mid_risk_count > 0 && (
                <div
                  className="h-full bg-amber-500 flex items-center justify-center"
                  style={{ width: `${(mid_risk_count / total_assessments) * 100}%` }}
                >
                  {(mid_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{mid_risk_count}</span>
                  )}
                </div>
              )}
              {low_risk_count > 0 && (
                <div
                  className="h-full bg-green-500 flex items-center justify-center"
                  style={{ width: `${(low_risk_count / total_assessments) * 100}%` }}
                >
                  {(low_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{low_risk_count}</span>
                  )}
                </div>
              )}
            </div>
            <div className="flex justify-between mt-3">
              {[
                { label: t('high_risk'), pct: high_risk_count, color: 'bg-red-500' },
                { label: t('mid_risk'), pct: mid_risk_count, color: 'bg-amber-500' },
                { label: t('low_risk'), pct: low_risk_count, color: 'bg-green-500' },
              ].map((item) => (
                <div key={item.label} className="flex items-center gap-1.5">
                  <span className={`w-2 h-2 rounded-full ${item.color}`} />
                  <span className="text-xs text-text-muted">{item.label} ({((item.pct / total_assessments) * 100).toFixed(0)}%)</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Critical Alerts */}
      <div className="bg-white border border-border rounded-xl p-5">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-sm font-semibold text-text-heading">{t('critical_alerts')}</h3>
          <button className="text-rose-500 text-xs font-semibold hover:underline">{t('view_all')}</button>
        </div>
        {high_risk_count > 0 ? (
          <div className="flex items-center gap-4 p-4 bg-red-50 rounded-xl">
            <div className="w-9 h-9 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
              <span className="material-symbols-outlined text-red-600 text-[20px]">warning</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-text-heading">{t('high_risk_count_alert', { count: high_risk_count })}</p>
              <p className="text-xs text-text-muted">{t('high_risk_alert_desc')}</p>
            </div>
            <button className="bg-red-600 text-white px-3.5 py-1.5 rounded-lg text-xs font-semibold flex-shrink-0 hover:bg-red-700 transition-colors">
              {t('escalate')}
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-4 p-4 bg-green-50 rounded-xl">
            <div className="w-9 h-9 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
              <span className="material-symbols-outlined text-green-600 text-[20px]">check_circle</span>
            </div>
            <div>
              <p className="text-sm font-semibold text-text-heading">{t('no_critical_alerts')}</p>
              <p className="text-xs text-text-muted">{t('all_patients_safe')}</p>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 9: Rewrite `ResultPage.jsx` — clean layout, pink buttons, no side-stripe

**Files:**
- Modify: `frontend/src/pages/ResultPage.jsx`

- [ ] **Step 1: Replace entire ResultPage.jsx**

```jsx
import { useLocation, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const RISK_CONFIG = {
  'high risk': {
    heroBg: 'bg-red-50', heroBorder: 'border-red-200',
    accent: 'text-red-600', accentBg: 'bg-red-100',
    dot: 'bg-red-500', barColor: 'bg-red-500',
    titleKey: 'critical_result_title', descKey: 'critical_result_desc',
    recTitleKey: 'immediate_referral', recIcon: 'emergency_home',
    i18nLabel: 'high_risk',
  },
  'mid risk': {
    heroBg: 'bg-amber-50', heroBorder: 'border-amber-200',
    accent: 'text-amber-700', accentBg: 'bg-amber-100',
    dot: 'bg-amber-600', barColor: 'bg-amber-600',
    titleKey: 'moderate_result_title', descKey: 'moderate_result_desc',
    recTitleKey: 'clinical_followup', recIcon: 'monitor_heart',
    i18nLabel: 'moderate_risk',
  },
  'low risk': {
    heroBg: 'bg-green-50', heroBorder: 'border-green-200',
    accent: 'text-green-700', accentBg: 'bg-green-100',
    dot: 'bg-green-600', barColor: 'bg-green-600',
    titleKey: 'low_result_title', descKey: 'low_result_desc',
    recTitleKey: 'routine_monitoring', recIcon: 'check_circle',
    i18nLabel: 'low_risk',
  },
};

export default function ResultPage() {
  const { t } = useTranslation();
  const { state } = useLocation();

  if (!state) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="text-center py-24">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 block mb-4">analytics</span>
          <h2 className="text-lg font-semibold text-text-heading mb-1">{t('no_result_data')}</h2>
          <p className="text-sm text-text-muted mb-6">{t('no_result_hint')}</p>
          <Link to="/assess" className="inline-flex items-center gap-2 bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors">
            <span className="material-symbols-outlined text-[18px]">add_circle</span>
            {t('new_assessment')}
          </Link>
        </div>
      </main>
    );
  }

  const cfg = RISK_CONFIG[state.risk_level] || RISK_CONFIG['low risk'];
  const confidence = ((state.confidence || 0) * 100).toFixed(0);

  const shapValues = (state.shap_values || []).map((v) => ({ ...v, pct: Math.abs(v.shap_value) * 100 }));
  const maxPct = Math.max(...shapValues.map((v) => v.pct), 1);

  const probHigh = ((state.prob_high || 0) * 100).toFixed(0);
  const probMid = ((state.prob_mid || 0) * 100).toFixed(0);
  const probLow = ((state.prob_low || 0) * 100).toFixed(0);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-6 pb-24 md:pb-8">
      {/* Risk Hero */}
      <div className={`rounded-2xl ${cfg.heroBg} border ${cfg.heroBorder} p-6 sm:p-8 mb-6`}>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-5">
          <div>
            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${cfg.accentBg} ${cfg.accent} mb-3`}>
              <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
              {t(cfg.i18nLabel)}
            </span>
            <h1 className="text-xl sm:text-2xl font-bold text-text-heading">{t(cfg.titleKey)}</h1>
            <p className="text-sm text-text-body mt-1 max-w-lg">{t(cfg.descKey)}</p>
          </div>
          <div className="bg-white rounded-xl px-5 py-4 text-center shadow-sm border border-border flex-shrink-0">
            <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider block">{t('confidence')}</span>
            <span className={`text-3xl font-bold ${cfg.accent}`}>{confidence}%</span>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        {/* Left */}
        <div className="lg:col-span-7 space-y-5">
          {/* Recommendation */}
          <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
            <div className="flex items-start gap-3 mb-4">
              <div className={`${cfg.accentBg} ${cfg.accent} p-2 rounded-lg flex-shrink-0`}>
                <span className="material-symbols-outlined text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>{cfg.recIcon}</span>
              </div>
              <div>
                <h2 className={`text-base font-semibold ${cfg.accent}`}>{t(cfg.recTitleKey)}</h2>
                <p className="text-xs text-text-muted mt-0.5">{t('action_2hrs')}</p>
              </div>
            </div>
            <div className="bg-surface rounded-xl p-4 border border-border">
              <p className="text-sm text-text-body leading-relaxed">{state.recommendation || t('no_recommendation')}</p>
            </div>
          </section>

          {/* SHAP */}
          {shapValues.length > 0 && (
            <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
              <h3 className="text-base font-semibold text-text-heading mb-0.5">{t('feature_contributions')}</h3>
              <p className="text-xs text-text-muted mb-5">{t('shap_explanation')}</p>
              <div className="space-y-3.5">
                {shapValues.map((v, i) => {
                  const isPos = v.shap_value >= 0;
                  const widthPct = (v.pct / maxPct) * 100;
                  return (
                    <div key={i}>
                      <div className="flex justify-between text-sm mb-1">
                        <span className={`font-medium ${isPos ? 'text-text-heading' : 'text-text-muted'}`}>
                          {v.feature} {v.raw_value !== undefined && `(${v.raw_value})`}
                        </span>
                        <span className={`font-semibold text-xs ${isPos ? 'text-red-600' : 'text-green-600'}`}>
                          {isPos ? '+' : ''}{v.pct.toFixed(1)}%
                        </span>
                      </div>
                      <div className="h-1.5 w-full bg-surface rounded-full overflow-hidden flex">
                        {isPos ? (
                          <div className="h-full bg-red-500 rounded-full" style={{ width: `${widthPct}%`, marginLeft: 'auto' }} />
                        ) : (
                          <div className="h-full bg-green-500 rounded-full" style={{ width: `${widthPct}%` }} />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          )}
        </div>

        {/* Right */}
        <div className="lg:col-span-5 space-y-5">
          {/* Probability */}
          <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
            <h3 className="text-base font-semibold text-text-heading mb-5">{t('prob_distribution')}</h3>
            <div className="space-y-5">
              {[
                { label: t('high_risk'), val: probHigh, color: 'bg-red-500', text: 'text-red-600' },
                { label: t('mid_risk'), val: probMid, color: 'bg-amber-500', text: 'text-amber-600' },
                { label: t('low_risk'), val: probLow, color: 'bg-green-500', text: 'text-green-600' },
              ].map((p) => (
                <div key={p.label}>
                  <div className="flex justify-between items-end mb-1.5">
                    <span className={`text-xs font-semibold ${p.text}`}>{p.label}</span>
                    <span className="text-lg font-bold text-text-heading">{p.val}%</span>
                  </div>
                  <div className="h-2.5 w-full bg-surface rounded-full overflow-hidden">
                    <div className={`h-full ${p.color} rounded-full transition-all duration-700`} style={{ width: `${p.val}%` }} />
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-5 pt-4 border-t border-border">
              <p className="text-xs text-text-muted leading-relaxed">{t('model_info')}</p>
            </div>
          </section>

          {/* Actions */}
          <div className="flex flex-col gap-2.5">
            <Link
              to="/history"
              className="py-3 bg-rose-500 text-white rounded-xl text-sm font-semibold text-center hover:bg-rose-600 transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">history</span>
              {t('view_history')}
            </Link>
            <Link
              to="/assess"
              className="py-3 border border-rose-500 text-rose-500 bg-white rounded-xl text-sm font-semibold text-center hover:bg-rose-50 transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">add_circle</span>
              {t('new_assessment')}
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Verify build**

Run: `cd frontend && npx vite build 2>&1 | tail -5`
Expected: Build succeeds

---

## Task 10: Final build verification

- [ ] **Step 1: Full production build**

Run: `cd frontend && npx vite build 2>&1`
Expected: Build succeeds with no errors

- [ ] **Step 2: Check bundle size**

Run: `cd frontend && ls -lh dist/assets/`
Expected: JS bundle under 400KB (no recharts imported)
