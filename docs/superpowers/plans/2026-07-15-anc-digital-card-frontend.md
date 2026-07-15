# ANC Digital Card — Frontend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the ANC Digital Card frontend — patient list, registration, ANC card view with tabbed pregnancies and vertical visit timeline, pregnancy/visit forms, and assessment integration.

**Architecture:** Five new React pages + two modified pages, using existing Tailwind v4 design tokens, Material Symbols icons, and Axios API client. All under existing ProtectedRoute + Layout wrapper. Local state only (useState).

**Tech Stack:** React 19, React Router v7, Tailwind CSS v4, Axios, i18next

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `frontend/src/i18n/en.json` | Add EN translation keys |
| Modify | `frontend/src/i18n/fr.json` | Add FR translation keys |
| Modify | `frontend/src/api/client.js` | Add patient/pregnancy/visit API functions |
| Create | `frontend/src/pages/PatientListPage.jsx` | Patient search + list |
| Create | `frontend/src/pages/PatientRegisterPage.jsx` | Register new patient form |
| Create | `frontend/src/pages/PatientDetailPage.jsx` | Full ANC card view with timeline |
| Create | `frontend/src/pages/PregnancyRegisterPage.jsx` | Start new pregnancy form |
| Create | `frontend/src/pages/VisitLogPage.jsx` | Log ANC visit form |
| Modify | `frontend/src/pages/AssessmentPage.jsx` | Add patient selector field |
| Modify | `frontend/src/pages/ResultPage.jsx` | Add patient card link |
| Modify | `frontend/src/App.jsx` | Add 5 new routes |
| Modify | `frontend/src/components/NavBar.jsx` | Add "Patients" nav link |

---

### Task 1: Add i18n Translation Keys

**Files:**
- Modify: `frontend/src/i18n/en.json`
- Modify: `frontend/src/i18n/fr.json`

- [ ] **Step 1: Add English translations**

Open `frontend/src/i18n/en.json`. Find the last key before the closing `}` and add a comma, then paste these new keys:

```json
    "patients": "Patients",
    "register_patient": "Register Patient",
    "patient_list": "Patient List",
    "full_name": "Full Name",
    "date_of_birth": "Date of Birth",
    "phone": "Phone",
    "address": "Address",
    "blood_group": "Blood Group",
    "allergies": "Allergies",
    "emergency_contact": "Emergency Contact",
    "emergency_contact_name": "Contact Name",
    "emergency_contact_phone": "Contact Phone",
    "search_patients": "Search patients...",
    "no_patients_found": "No patients found",
    "no_patients_yet": "No patients registered yet",
    "register_first_patient": "Register your first patient",
    "start_pregnancy": "Start New Pregnancy",
    "lmp_date": "Last Menstrual Period",
    "edd_date": "Est. Due Date",
    "gravida": "Gravida",
    "parity": "Parity",
    "active_pregnancy": "Active Pregnancy",
    "past_pregnancies": "Past Pregnancies",
    "no_active_pregnancy": "No active pregnancy",
    "no_past_pregnancies": "No past pregnancies yet",
    "log_visit": "Log ANC Visit",
    "visit_number": "Visit Number",
    "visit_date": "Visit Date",
    "gestational_age": "Gestational Age (weeks)",
    "weight_kg": "Weight (kg)",
    "fundal_height_cm": "Fundal Height (cm)",
    "foetal_hr": "Fetal Heart Rate (bpm)",
    "presentation": "Presentation",
    "oedema": "Oedema",
    "urinalysis_protein": "Urinalysis Protein",
    "urinalysis_glucose": "Urinalysis Glucose",
    "haemoglobin": "Haemoglobin (g/dL)",
    "tt_vaccine": "TT Vaccine",
    "malaria_prophylaxis": "Malaria Prophylaxis",
    "iron_supplements": "Iron Supplements",
    "notes": "Notes",
    "next_visit_date": "Next Visit Date",
    "cephalic": "Cephalic",
    "breech": "Breech",
    "transverse": "Transverse",
    "negative": "Negative",
    "trace": "Trace",
    "delivery_outcome": "Delivery Outcome",
    "delivery_date": "Delivery Date",
    "delivery_location": "Delivery Location",
    "live_birth": "Live Birth",
    "stillbirth": "Stillbirth",
    "miscarriage": "Miscarriage",
    "visit_count": "visits",
    "back_to_patients": "Back to Patients",
    "back_to_card": "Back to Patient Card",
    "no_visits_recorded": "No visits recorded yet",
    "select_patient": "Select Patient (optional)",
    "search_select_patient": "Search patient name...",
    "no_patient_selected": "No patient — standalone assessment",
    "view_patient_card": "View Patient Card",
    "patient_name": "Patient Name"
```

- [ ] **Step 2: Add French translations**

Open `frontend/src/i18n/fr.json`. Find the last key before the closing `}` and add a comma, then paste these new keys:

```json
    "patients": "Patientes",
    "register_patient": "Enregistrer une Patiente",
    "patient_list": "Liste des Patientes",
    "full_name": "Nom Complet",
    "date_of_birth": "Date de Naissance",
    "phone": "Téléphone",
    "address": "Adresse",
    "blood_group": "Groupe Sanguin",
    "allergies": "Allergies",
    "emergency_contact": "Contact d'Urgence",
    "emergency_contact_name": "Nom du Contact",
    "emergency_contact_phone": "Téléphone du Contact",
    "search_patients": "Rechercher des patientes...",
    "no_patients_found": "Aucune patiente trouvée",
    "no_patients_yet": "Aucune patiente enregistrée",
    "register_first_patient": "Enregistrer votre première patiente",
    "start_pregnancy": "Commencer une Grossesse",
    "lmp_date": "Dernières Règles",
    "edd_date": "Date Prévue d'Accouchement",
    "gravida": "Gravité",
    "parity": "Parité",
    "active_pregnancy": "Grossesse Active",
    "past_pregnancies": "Grossesses Passées",
    "no_active_pregnancy": "Aucune grossesse active",
    "no_past_pregnancies": "Aucune grossesse passée",
    "log_visit": "Enregistrer une Visite",
    "visit_number": "Numéro de Visite",
    "visit_date": "Date de Visite",
    "gestational_age": "Âge Gestationnel (semaines)",
    "weight_kg": "Poids (kg)",
    "fundal_height_cm": "Hauteur Utérine (cm)",
    "foetal_hr": "Fréquence Cardiaque Fœtale (bpm)",
    "presentation": "Présentation",
    "oedema": "Œdème",
    "urinalysis_protein": "Protéines Urinaires",
    "urinalysis_glucose": "Glucose Urinaire",
    "haemoglobin": "Hémoglobine (g/dL)",
    "tt_vaccine": "Vaccin TT",
    "malaria_prophylaxis": "Prophylaxie Paludisme",
    "iron_supplements": "Compléments de Fer",
    "notes": "Notes",
    "next_visit_date": "Prochaine Visite",
    "cephalic": "Céphalique",
    "breech": "Siège",
    "transverse": "Transverse",
    "negative": "Négatif",
    "trace": "Traces",
    "delivery_outcome": "Résultat de l'Accouchement",
    "delivery_date": "Date d'Accouchement",
    "delivery_location": "Lieu d'Accouchement",
    "live_birth": "Naissance Vivante",
    "stillbirth": "Mort-Né",
    "miscarriage": "Fausse Couche",
    "visit_count": "visites",
    "back_to_patients": "Retour aux Patientes",
    "back_to_card": "Retour à la Carte",
    "no_visits_recorded": "Aucune visite enregistrée",
    "select_patient": "Sélectionner une Patiente (optionnel)",
    "search_select_patient": "Rechercher le nom...",
    "no_patient_selected": "Pas de patiente — évaluation autonome",
    "view_patient_card": "Voir la Carte Patiente",
    "patient_name": "Nom de la Patiente"
```

- [ ] **Step 3: Verify both files are valid JSON**

```bash
cd /home/ace/Projects/MamaSafe/frontend
node -e "JSON.parse(require('fs').readFileSync('src/i18n/en.json')); console.log('en.json OK')"
node -e "JSON.parse(require('fs').readFileSync('src/i18n/fr.json')); console.log('fr.json OK')"
```

Expected: Both print `OK`.

- [ ] **Step 4: Commit**

```bash
git add frontend/src/i18n/en.json frontend/src/i18n/fr.json
git commit -m "feat(i18n): add EN/FR translations for ANC Digital Card"
```

---

### Task 2: Add API Client Functions

**Files:**
- Modify: `frontend/src/api/client.js`

- [ ] **Step 1: Add patient, pregnancy, and visit API functions**

Open `frontend/src/api/client.js`. At the end of the file, before the closing, add:

```js
// ── PATIENTS ─────────────────────────────────────────────
export const getPatients = async (search = '', skip = 0, limit = 50) => {
  const params = { skip, limit };
  if (search) params.search = search;
  const res = await client.get('/api/v1/patients', { params });
  return res.data;
};

export const getPatient = async (id) => {
  const res = await client.get(`/api/v1/patients/${id}`);
  return res.data;
};

export const getPatientCard = async (id) => {
  const res = await client.get(`/api/v1/patients/${id}/card`);
  return res.data;
};

export const createPatient = async (data) => {
  const res = await client.post('/api/v1/patients', data);
  return res.data;
};

// ── PREGNANCIES ──────────────────────────────────────────
export const registerPregnancy = async (data) => {
  const res = await client.post('/api/v1/pregnancies', data);
  return res.data;
};

export const recordDelivery = async (pregnancyId, data) => {
  const res = await client.patch(`/api/v1/pregnancies/${pregnancyId}/delivery`, data);
  return res.data;
};

// ── ANC VISITS ───────────────────────────────────────────
export const recordVisit = async (data) => {
  const res = await client.post('/api/v1/anc-visits', data);
  return res.data;
};

export const getVisit = async (id) => {
  const res = await client.get(`/api/v1/anc-visits/${id}`);
  return res.data;
};

export const listVisits = async (pregnancyId) => {
  const res = await client.get(`/api/v1/pregnancies/${pregnancyId}/visits`);
  return res.data;
};
```

- [ ] **Step 2: Verify imports**

Read `frontend/src/api/client.js` and confirm all new functions are present and use the existing `client` instance.

- [ ] **Step 3: Commit**

```bash
git add frontend/src/api/client.js
git commit -m "feat(api): add patient, pregnancy, and visit API functions"
```

---

### Task 3: Create PatientListPage

**Files:**
- Create: `frontend/src/pages/PatientListPage.jsx`

- [ ] **Step 1: Create the page**

```jsx
import { useState, useEffect, useCallback } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getPatients } from "../api/client";

export default function PatientListPage() {
  const { t } = useTranslation();
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  const fetchPatients = useCallback(async (term) => {
    setLoading(true);
    try {
      const data = await getPatients(term);
      setPatients(data);
    } catch {
      setPatients([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPatients(search);
  }, [search, fetchPatients]);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("patients")}</h1>
          <p className="text-sm text-text-muted mt-1">{t("patient_list")}</p>
        </div>
        <Link
          to="/patients/new"
          className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors inline-flex items-center gap-2"
        >
          <span className="material-symbols-outlined text-[18px]">person_add</span>
          {t("register_patient")}
        </Link>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
          search
        </span>
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t("search_patients")}
          className="pl-10 pr-4 py-2.5 border border-border rounded-xl bg-white w-full text-sm focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
        />
      </div>

      {/* Patient list */}
      {loading ? (
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t("loading")}</span>
        </div>
      ) : patients.length > 0 ? (
        <div className="space-y-3">
          {patients.map((p) => (
            <Link
              key={p.id}
              to={`/patients/${p.id}`}
              className="block bg-white border border-border rounded-2xl p-4 hover:border-rose-primary/40 hover:shadow-sm transition-all"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-semibold text-text-heading">{p.full_name}</p>
                  <p className="text-sm text-text-muted mt-0.5">
                    {p.date_of_birth} &middot; {p.phone || "\u2014"} &middot; {p.facility || "\u2014"}
                  </p>
                </div>
                <span className="material-symbols-outlined text-text-muted">chevron_right</span>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-border rounded-2xl">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">people</span>
          <h3 className="text-lg font-semibold text-text-heading mb-1">
            {search ? t("no_patients_found") : t("no_patients_yet")}
          </h3>
          <p className="text-sm text-text-muted mb-6 max-w-xs">
            {search ? t("search_patients") : t("register_first_patient")}
          </p>
          {!search && (
            <Link
              to="/patients/new"
              className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors"
            >
              {t("register_patient")}
            </Link>
          )}
        </div>
      )}
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/PatientListPage.jsx
git commit -m "feat(ui): add PatientListPage with search and empty state"
```

---

### Task 4: Create PatientRegisterPage

**Files:**
- Create: `frontend/src/pages/PatientRegisterPage.jsx`

- [ ] **Step 1: Create the page**

```jsx
import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { createPatient } from "../api/client";

const BLOOD_GROUPS = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];

export default function PatientRegisterPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    full_name: "",
    date_of_birth: "",
    phone: "",
    address: "",
    facility: "",
    blood_group: "",
    allergies: "",
    emergency_contact_name: "",
    emergency_contact_phone: "",
  });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const payload = { ...form };
      Object.keys(payload).forEach((k) => {
        if (payload[k] === "") delete payload[k];
      });
      const patient = await createPatient(payload);
      navigate(`/patients/${patient.id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to register patient");
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass =
    "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  const fields = [
    { key: "full_name", type: "text", required: true, icon: "badge" },
    { key: "date_of_birth", type: "date", required: true, icon: "cake" },
    { key: "phone", type: "tel", icon: "phone" },
    { key: "address", type: "text", icon: "home" },
    { key: "facility", type: "text", icon: "local_hospital" },
    { key: "allergies", type: "text", icon: "warning" },
    { key: "emergency_contact_name", type: "text", icon: "person" },
    { key: "emergency_contact_phone", type: "tel", icon: "phone_in_talk" },
  ];

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patients")}
      </Link>

      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("register_patient")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t("patient_name")}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {fields.map((f) => (
              <div key={f.key} className={f.key === "full_name" || f.key === "date_of_birth" ? "sm:col-span-2" : ""}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)} {f.required && <span className="text-red-500">*</span>}
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type={f.type}
                    value={form[f.key]}
                    onChange={(e) => set(f.key, e.target.value)}
                    required={f.required}
                    className={`${inputClass} pl-10`}
                  />
                </div>
              </div>
            ))}

            {/* Blood group select */}
            <div className="sm:col-span-2">
              <label className="block text-xs font-medium text-text-muted mb-1.5">{t("blood_group")}</label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                  bloodtype
                </span>
                <select
                  value={form.blood_group}
                  onChange={(e) => set("blood_group", e.target.value)}
                  className={`${inputClass} pl-10`}
                >
                  <option value="">—</option>
                  {BLOOD_GROUPS.map((bg) => (
                    <option key={bg} value={bg}>{bg}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t("register_patient")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">person_add</span>
              <span>{t("register_patient")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/PatientRegisterPage.jsx
git commit -m "feat(ui): add PatientRegisterPage with form"
```

---

### Task 5: Create PatientDetailPage — The ANC Card

**Files:**
- Create: `frontend/src/pages/PatientDetailPage.jsx`

This is the largest component. It includes the patient header, tabbed pregnancy view, and vertical visit timeline.

- [ ] **Step 1: Create the page**

```jsx
import { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getPatientCard } from "../api/client";

export default function PatientDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("current");

  useEffect(() => {
    getPatientCard(id)
      .then((data) => setCard(data))
      .catch(() => setCard(null))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t("loading")}</span>
        </div>
      </main>
    );
  }

  if (!card) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
          <span className="material-symbols-outlined text-[16px]">arrow_back</span>
          {t("back_to_patients")}
        </Link>
        <div className="text-center py-24 text-text-muted">{t("patient_not_found")}</div>
      </main>
    );
  }

  const { patient, pregnancy, visits } = card;
  const hasActivePregnancy = pregnancy && pregnancy.is_active;

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Back link */}
      <Link to="/patients" className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_patients")}
      </Link>

      {/* Patient Header */}
      <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
        <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">
          <div>
            <h1 className="text-2xl font-bold text-text-heading tracking-tight">{patient.full_name}</h1>
            <p className="text-sm text-text-muted mt-1">
              {patient.date_of_birth} &middot; {patient.phone || "\u2014"} &middot; {patient.facility || "\u2014"}
            </p>
          </div>
          {!hasActivePregnancy && (
            <Link
              to={`/patients/${id}/pregnancies/new`}
              className="bg-rose-500 text-white text-sm font-semibold rounded-xl px-5 py-2.5 hover:bg-rose-600 transition-colors inline-flex items-center gap-2 flex-shrink-0"
            >
              <span className="material-symbols-outlined text-[18px]">add</span>
              {t("start_pregnancy")}
            </Link>
          )}
        </div>

        {/* Info row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-4 pt-4 border-t border-border">
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("blood_group")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.blood_group || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("allergies")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.allergies || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("emergency_contact_name")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.emergency_contact_name || "\u2014"}</p>
          </div>
          <div>
            <p className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t("emergency_contact_phone")}</p>
            <p className="text-sm font-medium text-text-heading mt-0.5">{patient.emergency_contact_phone || "\u2014"}</p>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 bg-surface rounded-xl p-1 w-fit">
        <button
          onClick={() => setActiveTab("current")}
          className={`px-5 py-2 rounded-lg text-sm font-semibold transition-colors ${
            activeTab === "current"
              ? "bg-white text-text-heading shadow-sm"
              : "text-text-muted hover:text-text-body"
          }`}
        >
          {t("active_pregnancy")}
        </button>
        <button
          onClick={() => setActiveTab("past")}
          className={`px-5 py-2 rounded-lg text-sm font-semibold transition-colors ${
            activeTab === "past"
              ? "bg-white text-text-heading shadow-sm"
              : "text-text-muted hover:text-text-body"
          }`}
        >
          {t("past_pregnancies")}
        </button>
      </div>

      {/* Tab content */}
      {activeTab === "current" ? (
        hasActivePregnancy ? (
          <PregnancySection pregnancy={pregnancy} visits={visits} patientId={id} t={t} />
        ) : (
          <div className="bg-white rounded-2xl border border-border p-8 text-center">
            <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">pregnant_woman</span>
            <h3 className="text-lg font-semibold text-text-heading mb-1">{t("no_active_pregnancy")}</h3>
            <p className="text-sm text-text-muted mb-6">{t("register_first_patient")}</p>
            <Link
              to={`/patients/${id}/pregnancies/new`}
              className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors inline-flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">add</span>
              {t("start_pregnancy")}
            </Link>
          </div>
        )
      ) : (
        <div>
          {card.pregnancies && card.pregnancies.length > 0 ? (
            card.pregnancies
              .filter((p) => !p.is_active)
              .map((p) => (
                <PregnancySection key={p.id} pregnancy={p} visits={p.visits || []} patientId={id} t={t} />
              ))
          ) : (
            <div className="bg-white rounded-2xl border border-border p-8 text-center">
              <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">history</span>
              <h3 className="text-lg font-semibold text-text-heading mb-1">{t("no_past_pregnancies")}</h3>
            </div>
          )}
        </div>
      )}
    </main>
  );
}

function PregnancySection({ pregnancy, visits, patientId, t }) {
  const [expanded, setExpanded] = useState(true);

  return (
    <div className="bg-white rounded-2xl border border-border p-5 mb-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <div className="flex items-center gap-2 flex-wrap">
            <h3 className="font-semibold text-text-heading">
              {t("lmp_date")}: {pregnancy.lmp_date}
            </h3>
            {pregnancy.is_active && (
              <span className="bg-green-100 text-green-700 text-xs font-medium px-2.5 py-0.5 rounded-full">
                {t("active_pregnancy")}
              </span>
            )}
            {!pregnancy.is_active && pregnancy.delivery_outcome && (
              <span className="bg-surface text-text-heading text-xs font-medium px-2.5 py-0.5 rounded-full border border-border">
                {t(pregnancy.delivery_outcome === "live_birth" ? "live_birth" : pregnancy.delivery_outcome === "stillbirth" ? "stillbirth" : "miscarriage")}
              </span>
            )}
          </div>
          <p className="text-sm text-text-muted mt-1">
            {t("edd_date")}: {pregnancy.edd_date || "\u2014"} &middot; G{pregnancy.gravida} P{pregnancy.parity}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-sm text-text-muted">
            {visits.length} {t("visit_count")}
          </span>
          <button
            onClick={() => setExpanded(!expanded)}
            className="text-text-muted hover:text-text-heading transition-colors"
          >
            <span className="material-symbols-outlined">
              {expanded ? "expand_less" : "expand_more"}
            </span>
          </button>
        </div>
      </div>

      {/* Delivery info */}
      {!pregnancy.is_active && pregnancy.delivery_date && (
        <div className="bg-surface rounded-xl p-3 mb-4">
          <p className="text-xs text-text-muted">{t("delivery_date")}: {pregnancy.delivery_date}</p>
        </div>
      )}

      {/* Expanded content */}
      {expanded && (
        <div className="pt-4 border-t border-border">
          {/* Log visit button */}
          {pregnancy.is_active && (
            <Link
              to={`/patients/${patientId}/pregnancies/${pregnancy.id}/visits/new`}
              className="inline-flex items-center gap-2 bg-rose-500 text-white text-xs font-semibold rounded-lg px-4 py-2 mb-6 hover:bg-rose-600 transition-colors"
            >
              <span className="material-symbols-outlined text-[16px]">add</span>
              {t("log_visit")}
            </Link>
          )}

          {/* Visit timeline */}
          {visits.length === 0 ? (
            <div className="text-center py-8">
              <span className="material-symbols-outlined text-[36px] text-text-muted/40 mb-2">event_note</span>
              <p className="text-sm text-text-muted">{t("no_visits_recorded")}</p>
            </div>
          ) : (
            <div className="relative">
              {/* Vertical line */}
              <div className="absolute left-[15px] top-0 bottom-0 w-0.5 bg-border" />

              <div className="space-y-0">
                {visits.map((visit, idx) => (
                  <div key={visit.id} className="relative flex gap-4 pb-6 last:pb-0">
                    {/* Circle marker */}
                    <div className="relative z-10 flex-shrink-0 w-[31px] h-[31px] rounded-full bg-rose-500 border-4 border-white flex items-center justify-center">
                      <span className="text-[10px] font-bold text-white">{visit.visit_number}</span>
                    </div>

                    {/* Visit card */}
                    <div className="flex-1 bg-surface rounded-xl p-4 -mt-1">
                      <div className="flex items-center justify-between mb-3">
                        <h4 className="text-sm font-semibold text-text-heading">
                          {t("visit_number")} {visit.visit_number}
                        </h4>
                        <span className="text-xs text-text-muted">{visit.visit_date}</span>
                      </div>

                      {/* Vitals grid */}
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
                        {visit.gestational_age != null && (
                          <div>
                            <p className="text-text-muted">{t("gestational_age")}</p>
                            <p className="font-medium text-text-heading">{visit.gestational_age}w</p>
                          </div>
                        )}
                        {visit.weight != null && (
                          <div>
                            <p className="text-text-muted">{t("weight_kg")}</p>
                            <p className="font-medium text-text-heading">{visit.weight}</p>
                          </div>
                        )}
                        {visit.systolic_bp != null && (
                          <div>
                            <p className="text-text-muted">BP</p>
                            <p className="font-medium text-text-heading">
                              {visit.systolic_bp}/{visit.diastolic_bp}
                            </p>
                          </div>
                        )}
                        {visit.haemoglobin != null && (
                          <div>
                            <p className="text-text-muted">{t("haemoglobin")}</p>
                            <p className="font-medium text-text-heading">{visit.haemoglobin}</p>
                          </div>
                        )}
                        {visit.fundal_height != null && (
                          <div>
                            <p className="text-text-muted">{t("fundal_height_cm")}</p>
                            <p className="font-medium text-text-heading">{visit.fundal_height}</p>
                          </div>
                        )}
                        {visit.foetal_hr != null && (
                          <div>
                            <p className="text-text-muted">{t("foetal_hr")}</p>
                            <p className="font-medium text-text-heading">{visit.foetal_hr}</p>
                          </div>
                        )}
                        {visit.presentation && (
                          <div>
                            <p className="text-text-muted">{t("presentation")}</p>
                            <p className="font-medium text-text-heading">{visit.presentation}</p>
                          </div>
                        )}
                        {visit.oedema && (
                          <div>
                            <p className="text-text-muted">{t("oedema")}</p>
                            <p className="font-medium text-red-600">Yes</p>
                          </div>
                        )}
                      </div>

                      {/* Treatment badges */}
                      <div className="flex flex-wrap gap-1.5 mt-3">
                        {visit.tt_vaccine && (
                          <span className="bg-green-100 text-green-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("tt_vaccine")}</span>
                        )}
                        {visit.malaria_prophylaxis && (
                          <span className="bg-blue-100 text-blue-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("malaria_prophylaxis")}</span>
                        )}
                        {visit.iron_supplements && (
                          <span className="bg-amber-100 text-amber-700 text-[11px] font-medium px-2 py-0.5 rounded-full">{t("iron_supplements")}</span>
                        )}
                        {visit.risk_assessment_id && (
                          <span className="bg-rose-100 text-rose-700 text-[11px] font-medium px-2 py-0.5 rounded-full">
                            Assessment linked
                          </span>
                        )}
                      </div>

                      {/* Notes */}
                      {visit.notes && (
                        <p className="text-xs text-text-muted mt-3 italic">{visit.notes}</p>
                      )}

                      {/* Next visit */}
                      {visit.next_visit_date && (
                        <p className="text-xs text-text-muted mt-2">
                          {t("next_visit_date")}: <span className="font-medium text-text-heading">{visit.next_visit_date}</span>
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/PatientDetailPage.jsx
git commit -m "feat(ui): add PatientDetailPage with ANC card and vertical timeline"
```

---

### Task 6: Create PregnancyRegisterPage

**Files:**
- Create: `frontend/src/pages/PregnancyRegisterPage.jsx`

- [ ] **Step 1: Create the page**

```jsx
import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { registerPregnancy } from "../api/client";

export default function PregnancyRegisterPage() {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const [form, setForm] = useState({ lmp_date: "", gravida: 1, parity: 0 });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      await registerPregnancy({ ...form, patient_id: parseInt(id) });
      navigate(`/patients/${id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to start pregnancy");
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass =
    "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to={`/patients/${id}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_card")}
      </Link>

      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("start_pregnancy")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-text-muted mb-1.5">
                {t("lmp_date")} <span className="text-red-500">*</span>
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                  calendar_today
                </span>
                <input
                  type="date"
                  value={form.lmp_date}
                  onChange={(e) => set("lmp_date", e.target.value)}
                  required
                  className={`${inputClass} pl-10`}
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-medium text-text-muted mb-1.5">{t("gravida")}</label>
                <input
                  type="number"
                  min="1"
                  value={form.gravida}
                  onChange={(e) => set("gravida", parseInt(e.target.value) || 1)}
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-text-muted mb-1.5">{t("parity")}</label>
                <input
                  type="number"
                  min="0"
                  value={form.parity}
                  onChange={(e) => set("parity", parseInt(e.target.value) || 0)}
                  className={inputClass}
                />
              </div>
            </div>
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t("start_pregnancy")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">add</span>
              <span>{t("start_pregnancy")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/PregnancyRegisterPage.jsx
git commit -m "feat(ui): add PregnancyRegisterPage form"
```

---

### Task 7: Create VisitLogPage

**Files:**
- Create: `frontend/src/pages/VisitLogPage.jsx`

- [ ] **Step 1: Create the page**

```jsx
import { useState } from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { recordVisit } from "../api/client";

const CLINICAL_FIELDS = [
  { key: "visit_number", type: "number", required: true, min: 1, max: 8, icon: "tag" },
  { key: "visit_date", type: "date", required: true, icon: "calendar_today" },
  { key: "gestational_age", type: "number", min: 4, max: 42, icon: "schedule" },
  { key: "weight", type: "number", step: "0.1", icon: "monitor_weight" },
  { key: "systolic_bp", type: "number", icon: "monitor_heart" },
  { key: "diastolic_bp", type: "number", icon: "favorite" },
  { key: "fundal_height", type: "number", step: "0.1", icon: "straighten" },
  { key: "foetal_hr", type: "number", icon: "ecg" },
];

const SELECT_FIELDS = [
  { key: "presentation", options: ["cephalic", "breech", "transverse"] },
  { key: "urinalysis_protein", options: ["negative", "trace", "+1", "+2", "+3"] },
  { key: "urinalysis_glucose", options: ["negative", "trace", "+1", "+2", "+3"] },
];

const CHECKBOX_FIELDS = [
  { key: "oedema", icon: "swelling" },
  { key: "tt_vaccine", icon: "vaccines" },
  { key: "malaria_prophylaxis", icon: "mosquito" },
  { key: "iron_supplements", icon: "medication" },
];

export default function VisitLogPage() {
  const { t } = useTranslation();
  const { id, pregnancyId } = useParams();
  const navigate = useNavigate();
  const [form, setForm] = useState({ visit_date: new Date().toISOString().slice(0, 10) });
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const set = (key, val) => setForm((f) => ({ ...f, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setSubmitting(true);
    try {
      const payload = { ...form, pregnancy_id: parseInt(pregnancyId) };
      Object.keys(payload).forEach((k) => {
        if (payload[k] === "" || payload[k] === null) delete payload[k];
      });
      await recordVisit(payload);
      navigate(`/patients/${id}`);
    } catch (err) {
      setError(err.response?.data?.detail || "Failed to log visit");
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass =
    "w-full bg-surface border border-border rounded-xl px-4 py-2.5 text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to={`/patients/${id}`} className="text-rose-500 text-sm font-semibold hover:underline mb-6 inline-flex items-center gap-1">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t("back_to_card")}
      </Link>

      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t("log_visit")}</h1>
      </header>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Clinical readings */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t("enter_patient_data")}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {CLINICAL_FIELDS.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)} {f.required && <span className="text-red-500">*</span>}
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type={f.type}
                    min={f.min}
                    max={f.max}
                    step={f.step}
                    value={form[f.key] ?? ""}
                    onChange={(e) =>
                      set(f.key, f.type === "number" ? (e.target.value === "" ? null : Number(e.target.value)) : e.target.value)
                    }
                    required={f.required}
                    className={`${inputClass} pl-10`}
                  />
                </div>
              </div>
            ))}

            {SELECT_FIELDS.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">{t(f.key)}</label>
                <select
                  value={form[f.key] || ""}
                  onChange={(e) => set(f.key, e.target.value)}
                  className={inputClass}
                >
                  <option value="">—</option>
                  {f.options.map((o) => (
                    <option key={o} value={o}>{o}</option>
                  ))}
                </select>
              </div>
            ))}
          </div>
        </div>

        {/* Treatments */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">Treatments</h2>
          <div className="flex flex-wrap gap-5">
            {CHECKBOX_FIELDS.map((f) => (
              <label key={f.key} className="flex items-center gap-2.5 text-sm text-text-body cursor-pointer">
                <input
                  type="checkbox"
                  checked={form[f.key] || false}
                  onChange={(e) => set(f.key, e.target.checked)}
                  className="w-4 h-4 rounded border-border text-rose-500 focus:ring-rose-primary"
                />
                {t(f.key)}
              </label>
            ))}
          </div>
        </div>

        {/* Notes & Next Visit */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <div className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-text-muted mb-1.5">{t("notes")}</label>
              <textarea
                value={form.notes || ""}
                onChange={(e) => set("notes", e.target.value)}
                rows={3}
                className={`${inputClass} resize-none`}
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-text-muted mb-1.5">{t("next_visit_date")}</label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                  event
                </span>
                <input
                  type="date"
                  value={form.next_visit_date || ""}
                  onChange={(e) => set("next_visit_date", e.target.value)}
                  className={`${inputClass} pl-10`}
                />
              </div>
            </div>
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
              <span>{t("log_visit")}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]">save</span>
              <span>{t("log_visit")}</span>
            </>
          )}
        </button>
      </form>
    </main>
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/VisitLogPage.jsx
git commit -m "feat(ui): add VisitLogPage with clinical readings form"
```

---

### Task 8: Add Patient Selector to AssessmentPage

**Files:**
- Modify: `frontend/src/pages/AssessmentPage.jsx`

- [ ] **Step 1: Add patient search state and imports**

Open `frontend/src/pages/AssessmentPage.jsx`.

Add import at the top:
```js
import { getPatients } from "../api/client";
```

Add new state variables inside the component (after the existing `form` state):
```js
const [patientSearch, setPatientSearch] = useState("");
const [patientResults, setPatientResults] = useState([]);
const [selectedPatient, setSelectedPatient] = useState(null);
const [showPatientDropdown, setShowPatientDropdown] = useState(false);
```

- [ ] **Step 2: Add patient search effect and handler**

After the existing `update` function, add:

```js
const searchPatients = async (term) => {
  setPatientSearch(term);
  setSelectedPatient(null);
  if (term.length < 2) {
    setPatientResults([]);
    setShowPatientDropdown(false);
    return;
  }
  try {
    const results = await getPatients(term);
    setPatientResults(results);
    setShowPatientDropdown(true);
  } catch {
    setPatientResults([]);
  }
};

const selectPatient = (patient) => {
  setSelectedPatient(patient);
  setPatientSearch(patient.full_name);
  setShowPatientDropdown(false);
};
```

- [ ] **Step 3: Add patient selector UI in the form**

Before the existing "Patient Reference" field, add this block:

```jsx
{/* Patient Selector */}
<div className="mb-6">
  <label className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
    {t("select_patient")}
  </label>
  <div className="relative">
    <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-[20px]">
      person_search
    </span>
    <input
      type="text"
      value={patientSearch}
      onChange={(e) => searchPatients(e.target.value)}
      onFocus={() => patientResults.length > 0 && setShowPatientDropdown(true)}
      placeholder={t("search_select_patient")}
      className={`${inputClass} pl-10`}
    />
    {showPatientDropdown && patientResults.length > 0 && (
      <div className="absolute z-20 top-full mt-1 w-full bg-white border border-border rounded-xl shadow-lg max-h-48 overflow-y-auto">
        {patientResults.map((p) => (
          <button
            key={p.id}
            type="button"
            onClick={() => selectPatient(p)}
            className="w-full text-left px-4 py-2.5 text-sm hover:bg-rose-50 transition-colors border-b border-border last:border-0"
          >
            <span className="font-medium text-text-heading">{p.full_name}</span>
            <span className="text-text-muted ml-2">{p.date_of_birth}</span>
          </button>
        ))}
      </div>
    )}
  </div>
  {selectedPatient && (
    <p className="text-xs text-green-600 mt-1.5 flex items-center gap-1">
      <span className="material-symbols-outlined text-[14px]">check_circle</span>
      {selectedPatient.full_name} — {t("patient_id")}: {selectedPatient.id}
    </p>
  )}
  {!selectedPatient && (
    <p className="text-xs text-text-muted mt-1.5">{t("no_patient_selected")}</p>
  )}
</div>
```

- [ ] **Step 4: Add patient_id to the predict payload**

In the `handleSubmit` function, after building `payload`, add:

```js
if (selectedPatient) payload.patient_id = selectedPatient.id;
```

- [ ] **Step 5: Commit**

```bash
git add frontend/src/pages/AssessmentPage.jsx
git commit -m "feat(ui): add patient selector to AssessmentPage"
```

---

### Task 9: Add Patient Card Link to ResultPage

**Files:**
- Modify: `frontend/src/pages/ResultPage.jsx`

- [ ] **Step 1: Add patient card link**

Open `frontend/src/pages/ResultPage.jsx`. Find the section with navigation links (after the assessment results). Add a conditional link:

```jsx
{assessment.patient_id && (
  <Link
    to={`/patients/${assessment.patient_id}`}
    className="block text-center py-2 text-rose-500 text-sm font-semibold hover:bg-rose-50 rounded-lg transition-colors"
  >
    {t("view_patient_card")} →
  </Link>
)}
```

Also ensure `useTranslation` is imported if not already, and add `view_patient_card` to the `t()` call.

- [ ] **Step 2: Commit**

```bash
git add frontend/src/pages/ResultPage.jsx
git commit -m "feat(ui): add patient card link on ResultPage"
```

---

### Task 10: Wire Up Routes and Navigation

**Files:**
- Modify: `frontend/src/App.jsx`
- Modify: `frontend/src/components/NavBar.jsx`

- [ ] **Step 1: Add routes to App.jsx**

Open `frontend/src/App.jsx`. Add imports for the new pages:

```jsx
import PatientListPage from "./pages/PatientListPage";
import PatientRegisterPage from "./pages/PatientRegisterPage";
import PatientDetailPage from "./pages/PatientDetailPage";
import PregnancyRegisterPage from "./pages/PregnancyRegisterPage";
import VisitLogPage from "./pages/VisitLogPage";
```

Inside the `<Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>` block, before the catch-all `*` route, add:

```jsx
<Route path="/patients" element={<PatientListPage />} />
<Route path="/patients/new" element={<PatientRegisterPage />} />
<Route path="/patients/:id" element={<PatientDetailPage />} />
<Route path="/patients/:id/pregnancies/new" element={<PregnancyRegisterPage />} />
<Route path="/patients/:id/pregnancies/:pregnancyId/visits/new" element={<VisitLogPage />} />
```

- [ ] **Step 2: Add nav link to NavBar.jsx**

Open `frontend/src/components/NavBar.jsx`. Find the `navLinks` array and add the Patients link:

```js
const navLinks = [
  { path: '/assess', label: t('new_assessment'), icon: 'assessment' },
  { path: '/patients', label: t('patients'), icon: 'people' },
  { path: '/history', label: t('history'), icon: 'history' },
  { path: '/dashboard', label: t('dashboard'), icon: 'monitoring' },
];
```

Update the `linkClass` function to match on `/patients` prefix:

```js
const linkClass = (path) =>
  `text-sm transition-colors ${
    path === '/patients'
      ? location.pathname.startsWith('/patients')
        ? 'text-rose-500 font-semibold'
        : 'text-text-body hover:text-rose-500'
      : location.pathname === path
        ? 'text-rose-500 font-semibold'
        : 'text-text-body hover:text-rose-500'
  }`;
```

- [ ] **Step 3: Commit**

```bash
git add frontend/src/App.jsx frontend/src/components/NavBar.jsx
git commit -m "feat(ui): wire up ANC card routes and Patients nav link"
```

---

### Task 11: Verify End-to-End

- [ ] **Step 1: Start the backend**

```bash
cd /home/ace/Projects/MamaSafe/backend
source venv/bin/activate
uvicorn app.main:app --reload
```

Confirm the server starts without errors.

- [ ] **Step 2: Start the frontend**

```bash
cd /home/ace/Projects/MamaSafe/frontend
npm run dev
```

Confirm it compiles without errors.

- [ ] **Step 3: Manual test flow**

1. Navigate to `/patients` — should show empty state
2. Click "Register Patient" — fill form, submit
3. Patient detail page loads — shows patient info, no active pregnancy
4. Click "Start New Pregnancy" — enter LMP date, submit
5. Card shows active pregnancy tab with 0 visits
6. Click "Log Visit" — fill vitals, submit
7. Visit appears in the vertical timeline
8. Go back to patient list — search works
9. Go to Assess page — patient selector appears, search works
10. Assess with patient selected — result shows "View Patient Card" link

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat(anc-card): complete ANC Digital Card frontend"
```
