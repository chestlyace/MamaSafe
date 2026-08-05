# Form Placeholders + Field Help Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add placeholders to clinical forms missing them and a per-field help description — hover info-icon tooltip on web, tap info-icon tooltip on mobile.

**Architecture:** A shared `FieldHelp` component (pure-CSS Tailwind tooltip) on web and a shared `HelpIcon` widget (Flutter `Tooltip` with tap trigger) on mobile. Web `DateField` gains a `help` prop; mobile `AppTextField`/`DateField` gain a `help` param that renders the icon beside the label. Raw `TextFormField`s and `DropdownButtonFormField`s get `hintText` + `suffixIcon: HelpIcon`. Flat i18n maps extended on both platforms (EN + FR mirrored).

**Tech Stack:** React + Tailwind + react-i18next (web); Flutter + flutter_riverpod + drift (mobile).

**Spec:** `docs/superpowers/specs/2026-08-03-form-placeholders-help-design.md`

---

## Copy (single source — reuse verbatim on both platforms)

Web flat keys: `{field}_placeholder`, `{field}_help`. Mobile keys: `{ns}.{field}Help` and gap `*Hint`s. EN value / FR value pairs below.

### Patient register
| key | EN | FR |
|---|---|---|
| full_name_placeholder | e.g. Aisha Nkem | ex. Aisha Nkem |
| full_name_help | Legal name as shown on the patient's ID | Nom officiel tel qu'il figure sur la pièce d'identité |
| date_of_birth_help | Used to calculate age and gestational age | Sert à calculer l'âge et l'âge gestationnel |
| phone_placeholder | e.g. +237 6XX XXX XXX | ex. +237 6XX XXX XXX |
| phone_help | Include the country code if known | Inclure l'indicatif du pays si connu |
| address_placeholder | Village, quarter or landmark | Village, quartier ou repère |
| address_help | Home location for follow-up visits | Lieu de domicile pour les visites de suivi |
| facility_placeholder | e.g. Buea District Hospital | ex. Hôpital de district de Buéa |
| facility_help | Facility the patient usually attends | Formation sanitaire habituellement fréquentée |
| allergies_placeholder | e.g. penicillin | ex. pénicilline |
| allergies_help | List known allergies or drug reactions | Indiquer les allergies ou réactions connues |
| emergency_contact_name_placeholder | e.g. Jean Nkem | ex. Jean Nkem |
| emergency_contact_name_help | Relative to contact in an emergency | Proche à contacter en cas d'urgence |
| emergency_contact_phone_placeholder | e.g. +237 6XX XXX XXX | ex. +237 6XX XXX XXX |
| emergency_contact_phone_help | Reachable phone number of the contact | Numéro de téléphone joignable du contact |
| blood_group_help | Select the patient's blood type | Sélectionner le groupe sanguin de la patiente |

### Pregnancy register
| key | EN | FR |
|---|---|---|
| lmp_date_help | First day of the last menstrual period | Premier jour des dernières règles |
| edd_date_help | Auto-calculated from the LMP; adjust only if known | Calculé automatiquement d'après les règles ; à ajuster uniquement si connu |
| gravida_placeholder | e.g. 2 | ex. 2 |
| gravida_help | Total pregnancies including this one | Nombre total de grossesses, y compris celle-ci |
| parity_placeholder | e.g. 1 | ex. 1 |
| parity_help | Number of previous births after 20 weeks | Nombre d'accouchements antérieurs après 20 semaines |

### Visit log (ANC)
| key | EN | FR |
|---|---|---|
| visit_date_help | Date this ANC visit took place | Date de cette consultation prénatale |
| visit_number_help | Visit number for this pregnancy (1–8) | Numéro de consultation de cette grossesse (1–8) |
| gestational_age_help | Weeks of pregnancy; auto-filled from the LMP | Semaines de grossesse ; rempli automatiquement d'après les règles |
| weight_kg_placeholder | e.g. 62.5 | ex. 62.5 |
| weight_kg_help | Mother's weight in kilograms | Poids de la mère en kilogrammes |
| systolic_bp_placeholder | e.g. 110 | ex. 110 |
| systolic_bp_help | Upper (systolic) blood pressure | Tension artérielle maximale (systolique) |
| diastolic_bp_placeholder | e.g. 70 | ex. 70 |
| diastolic_bp_help | Lower (diastolic) blood pressure | Tension artérielle minimale (diastolique) |
| fundal_height_cm_placeholder | e.g. 28 | ex. 28 |
| fundal_height_cm_help | Measured in cm from symphysis to fundus | Mesurée en cm de la symphyse au fond utérin |
| foetal_hr_placeholder | e.g. 140 | ex. 140 |
| foetal_hr_help | Fetal heart rate in beats per minute | Rythme cardiaque fœtal en battements par minute |
| presentation_help | Baby's position in the womb | Position du bébé dans l'utérus |
| urinalysis_protein_help | Protein level from the urine test | Taux de protéines à l'examen d'urine |
| urinalysis_glucose_help | Glucose level from the urine test | Taux de glucose à l'examen d'urine |
| oedema_help | Swelling of the hands, feet or face | Gonflement des mains, des pieds ou du visage |
| tt_vaccine_help | Tetanus vaccine given at this visit | Vaccin antitétanique administré à cette consultation |
| malaria_prophylaxis_help | Malaria prevention treatment given | Traitement préventif du paludisme administré |
| iron_supplements_help | Iron and folic acid supplements given | Compléments de fer et d'acide folique administrés |
| notes_placeholder | Other observations (optional) | Autres observations (facultatif) |
| notes_help | Additional findings or concerns | Constats ou préoccupations supplémentaires |
| next_visit_date_help | Suggested follow-up date; adjust if needed | Date de suivi suggérée ; à ajuster si nécessaire |

### Delivery + newborn
| key | EN | FR |
|---|---|---|
| delivery_date_help | Date the baby was born | Date de naissance du bébé |
| delivery_location_placeholder | e.g. District hospital | ex. Hôpital de district |
| delivery_location_help | Where the delivery took place | Lieu de l'accouchement |
| delivered_by_placeholder | e.g. Midwife | ex. Sage-femme |
| delivered_by_help | Who attended the delivery | Personne ayant assisté l'accouchement |
| complications_placeholder | e.g. postpartum haemorrhage | ex. hémorragie du postpartum |
| complications_help | Problems during or after the delivery | Problèmes pendant ou après l'accouchement |
| notes_help | Additional notes about the delivery | Notes supplémentaires sur l'accouchement |
| name_help | Baby's name, if already chosen | Nom du bébé, s'il est déjà choisi |
| sex_help | Sex recorded at birth | Sexe enregistré à la naissance |
| birth_weight_g_help | Birth weight in grams | Poids de naissance en grammes |
| apgar_score_help | APGAR score at 1 or 5 minutes (0–10) | Score d'APGAR à 1 ou 5 minutes (0–10) |
| crying_at_birth_help | Did the baby cry right after birth? | Le bébé a-t-il crié juste après la naissance ? |
| breastfeeding_help | Breastfeeding started within the first hour? | Allaitement commencé dans la première heure ? |
| status_help | Outcome of this birth | Issue de cette naissance |

### Postnatal
| key | EN | FR |
|---|---|---|
| visit_date_help | Date of this postnatal visit | Date de cette consultation postnatale |
| mother_status_help | Overall condition of the mother | État général de la mère |
| newborn_id_help | Choose the baby this visit is for | Choisir le bébé concerné par cette consultation |
| newborn_weight_kg_help | Current weight in kilograms | Poids actuel en kilogrammes |
| breastfeeding_status_help | How the baby is currently being fed | Mode d'alimentation actuel du bébé |
| uterus_firm_help | Is the uterus well contracted? | L'utérus est-il bien contracté ? |
| lochia_normal_help | Is the lochia within normal limits? | Les lochies sont-elles dans les limites normales ? |
| temperature_help | Mother's temperature in degrees Celsius | Température de la mère en degrés Celsius |
| haemoglobin_help | Haemoglobin level in g/dL | Taux d'hémoglobine en g/dL |
| malaria_test_help | Malaria test done at this visit | Test de paludisme effectué à cette consultation |
| hiv_test_help | HIV test done at this visit | Test VIH effectué à cette consultation |
| mental_health_help | Any mood or mental health concerns | Toute préoccupation d'humeur ou de santé mentale |
| breast_exam_help | Findings from the breast examination | Constats de l'examen des seins |
| perineal_exam_help | Findings from the perineal examination | Constats de l'examen du périnée |
| notes_help | Additional notes (optional) | Notes supplémentaires (facultatif) |

### Referral
| key | EN | FR |
|---|---|---|
| select_facility_help | Hospital or health centre to refer to | Hôpital ou centre de santé vers lequel référer |
| complication_type_help | Main reason for the referral | Raison principale de la référence |
| chw_notes_help | Details the receiving facility should know | Détails que la formation sanitaire de réception doit connaître |

### Assessment
| key | EN | FR |
|---|---|---|
| select_patient_help | Optional — link this assessment to a patient | Facultatif — associer cette évaluation à une patiente |
| enter_patient_id_help (patient_ref) | Patient ID or name for the assessment | Identifiant ou nom de la patiente pour l'évaluation |
| age_help | Patient's age in years (10–60) | Âge de la patiente en années (10–60) |
| blood_sugar_help | Random blood sugar in mmol/L | Glycémie aléatoire en mmol/L |
| body_temp_help | Body temperature in degrees Fahrenheit | Température corporelle en degrés Fahrenheit |
| heart_rate_help | Pulse in beats per minute | Pouls en battements par minute |

### Reschedule / schedule
| key | EN | FR |
|---|---|---|
| new_date_help | New date for the scheduled visit | Nouvelle date de la visite prévue |
| reason_optional_help | Why the visit is being moved (optional) | Raison du déplacement de la visite (facultatif) |

### Mobile-only gap hints
| key | EN | FR |
|---|---|---|
| assessment.selectPatientHint | Search and choose a patient | Rechercher et choisir une patiente |
| assessment.ageHint | e.g. 25 | ex. 25 |
| assessment.systolicBpHint | e.g. 120 | ex. 120 |
| assessment.diastolicBpHint | e.g. 80 | ex. 80 |
| assessment.bloodSugarHint | e.g. 7.0 | ex. 7.0 |
| assessment.bodyTempHint | e.g. 98.6 | ex. 98.6 |
| assessment.heartRateHint | e.g. 72 | ex. 72 |
| anc.presentationHint | Select presentation | Sélectionner la présentation |
| growth.nutritionalStatusHint | Select nutritional status | Sélectionner l'état nutritionnel |
| newborn.sexHint | Select sex | Sélectionner le sexe |
| schedule.reasonHint | e.g. Patient travelling | ex. Patiente en déplacement |
| mentalhealth.scoreHint | Select a score (0–3) | Sélectionner un score (0–3) |

### Mobile help keys (mirror web content; `{ns}.{field}Help`)
`patients` → fullName, dateOfBirth, phone, address, facility, bloodGroup, allergies, emergencyName, emergencyPhone.
`maternity` → patientName, patientRef, age, gravida, parity, lmp, edd, notes.
`anc` → visitNumber, date, gestationalAge, weight, systolicBp, diastolicBp, fundalHeight, fetalHeartRate, presentation, oedema, ttVaccine, malariaProphylaxis, ironSupplements, notes, nextVisit.
`delivery` → date, location, deliveredBy, complications.
`newborn` → name, sex, birthWeight, apgar, crying, breastfeeding.
`postnatal` → visitNumber, visitDate, motherStatus, newbornWeight, breastfeedingStatus, muac, physicalExam, labs, mentalHealthNotes.
`referral` → assessmentId, patientRef, facility, reason, notes, referralDate.
`growth` → childName, childRef, ageMonths, weight, height, headCircumference, muac, nutritionalStatus, recordedAt.
`schedule` → visitNumber, date, newDate, reason.
`assessment` → selectPatient, age, systolicBp, diastolicBp, bloodSugar, bodyTemp, heartRate.
`mentalhealth` → score (used on Q1/Q2).

Each EN value = web EN help text above (e.g. `anc.visitNumberHelp` = "Visit number for this pregnancy (1–8)"). FR likewise.

---

### Task 1: Web — create `FieldHelp` component
**Files:**
- Create: `frontend/src/components/FieldHelp.jsx`

- [ ] **Step 1:** Create the component

```jsx
// Hover-triggered help tooltip. Pure CSS (Tailwind group/group-hover), no deps.
export default function FieldHelp({ text }) {
  if (!text) return null;
  return (
    <span className="group relative inline-flex ml-1.5 align-middle cursor-help">
      <span className="material-symbols-outlined text-[16px] text-text-muted">info</span>
      <span className="pointer-events-none absolute left-1/2 -translate-x-1/2 bottom-full mb-2 z-50 w-max max-w-[260px] whitespace-normal rounded-lg bg-gray-900 px-3 py-2 text-xs leading-snug text-white text-left shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-150">
        {text}
      </span>
    </span>
  );
}
```

- [ ] **Step 2:** Commit `feat(web): add FieldHelp tooltip component`

### Task 2: Web — `DateField` `help` prop
**Files:**
- Modify: `frontend/src/components/DateField.jsx`

- [ ] **Step 1:** Import `FieldHelp` and add prop + render

```jsx
import FieldHelp from "./FieldHelp";
// props: add `help = null,`
// label row becomes:
<label className="block text-xs font-medium text-text-muted mb-1.5">
  {label}
  {required && <span className="text-red-500"> *</span>}
  <FieldHelp text={help} />
</label>
```

- [ ] **Step 2:** Commit `feat(web): DateField accepts help text`

### Task 3: Web — i18n keys `en.json`
**Files:**
- Modify: `frontend/src/i18n/en.json`

- [ ] **Step 1:** Append all EN placeholder/help key/value pairs from the Copy section above to the JSON (fields: full_name, date_of_birth, phone, address, facility, allergies, emergency_contact_name, emergency_contact_phone, blood_group, lmp_date, edd_date, gravida, parity, visit_date, visit_number, gestational_age, weight_kg, systolic_bp, diastolic_bp, fundal_height_cm, foetal_hr, presentation, urinalysis_protein, urinalysis_glucose, oedema, tt_vaccine, malaria_prophylaxis, iron_supplements, notes, next_visit_date, delivery_date, delivery_location, delivered_by, complications, name, sex, birth_weight_g, apgar_score, crying_at_birth, breastfeeding, status, mother_status, newborn_id, newborn_weight_kg, breastfeeding_status, uterus_firm, lochia_normal, temperature, haemoglobin, malaria_test, hiv_test, mental_health, breast_exam, perineal_exam, select_facility, complication_type, chw_notes, select_patient, patient_ref, age, blood_sugar, body_temp, heart_rate, new_date, reason_optional).

- [ ] **Step 2:** Verify valid JSON: `cd frontend && python3 -c "import json; json.load(open('src/i18n/en.json'))"` → no output

- [ ] **Step 3:** Commit `feat(web): en i18n placeholders + help text`

### Task 4: Web — i18n keys `fr.json`
**Files:**
- Modify: `frontend/src/i18n/fr.json`

- [ ] **Step 1:** Append all FR values from the Copy section (same keys as Task 3).
- [ ] **Step 2:** Verify valid JSON (same command as Task 3 for fr.json).
- [ ] **Step 3:** Commit `feat(web): fr i18n placeholders + help text`

### Task 5: Web — PatientRegisterPage wiring
**Files:**
- Modify: `frontend/src/pages/PatientRegisterPage.jsx`

- [ ] **Step 1:** Import `FieldHelp`; add `placeholder` to each `fields` entry (`full_name`, `phone`, `address`, `facility`, `allergies`, `emergency_contact_name`, `emergency_contact_phone` — date_of_birth gets none); add `help: t(...)` to each entry via a `helpKey` and render `<FieldHelp text={t(f.help)} />` inside the `<label>`; add `placeholder={f.placeholder && t(f.placeholder)}` on the `<input>`. Add `blood_group_help` FieldHelp to the blood-group label.
- [ ] **Step 2:** Verify `npx vite build` (only pre-existing chunk-size warning).
- [ ] **Step 3:** Commit `feat(web): patient register placeholders + help`

### Task 6: Web — PregnancyRegisterPage wiring
**Files:**
- Modify: `frontend/src/pages/PregnancyRegisterPage.jsx`

- [ ] **Step 1:** Pass `help={t("lmp_date_help")}` / `help={t("edd_date_help")}` to the two DateFields; add `gravida_placeholder`/`gravida_help` and `parity_placeholder`/`parity_help` to their inputs/labels.
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): pregnancy register placeholders + help`

### Task 7: Web — VisitLogPage wiring
**Files:**
- Modify: `frontend/src/pages/VisitLogPage.jsx`

- [ ] **Step 1:** Add `helpKey` to each entry in `CLINICAL_FIELDS`, `SELECT_FIELDS`, `CHECKBOX_FIELDS`; add `placeholder` for weight_kg, systolic_bp, diastolic_bp, fundal_height_cm, foetal_hr, notes; render `<FieldHelp>` in labels and `placeholder` on inputs; pass `help` to the two DateFields.
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): ANC visit log placeholders + help`

### Task 8: Web — DeliveryForm wiring
**Files:**
- Modify: `frontend/src/components/DeliveryForm.jsx`

- [ ] **Step 1:** Pass `help` to the delivery DateField; add placeholders + FieldHelp to delivery_location, delivered_by, complications, notes; add FieldHelp to each newborn field label (name, sex, birth_weight_g, apgar_score, crying_at_birth, breastfeeding, status).
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): delivery + newborn placeholders + help`

### Task 9: Web — PostnatalVisitForm wiring
**Files:**
- Modify: `frontend/src/components/PostnatalVisitForm.jsx`

- [ ] **Step 1:** Pass `help` to the visit-date DateField; add FieldHelp to every field label (mother_status, newborn_id, newborn_weight_kg, breastfeeding_status, uterus_firm, lochia_normal, temperature, BP, haemoglobin, malaria_test, hiv_test, mental_health, breast_exam, perineal_exam, notes).
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): postnatal visit placeholders + help`

### Task 10: Web — ReferralModal wiring
**Files:**
- Modify: `frontend/src/components/ReferralModal.jsx`

- [ ] **Step 1:** Add FieldHelp to select_facility, complication_type, chw_notes labels (use `chw_notes_help`).
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): referral placeholders + help`

### Task 11: Web — AssessmentPage wiring
**Files:**
- Modify: `frontend/src/pages/AssessmentPage.jsx`

- [ ] **Step 1:** Add FieldHelp to select_patient, patient_ref, age, blood_sugar, body_temp, heart_rate labels (reuse `systolic_bp_help`/`diastolic_bp_help` for the BP pair).
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): assessment placeholders + help`

### Task 12: Web — RescheduleModal + PostnatalSchedule wiring
**Files:**
- Modify: `frontend/src/components/RescheduleModal.jsx`, `frontend/src/components/PostnatalSchedule.jsx`

- [ ] **Step 1:** RescheduleModal: FieldHelp on new_date (`new_date_help`) and reason (`reason_optional_help`) labels. PostnatalSchedule: FieldHelp beside the inline date input (`new_date_help`).
- [ ] **Step 2:** Verify `npx vite build`.
- [ ] **Step 3:** Commit `feat(web): reschedule placeholders + help`

### Task 13: Mobile — `HelpIcon` widget
**Files:**
- Create: `mobile/lib/core/widgets/help_icon.dart`

- [ ] **Step 1:** Create the widget

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small info icon that shows a one-line field description when tapped.
class HelpIcon extends StatelessWidget {
  final String message;
  const HelpIcon({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      triggerMode: TooltipTriggerMode.tap,
      child: const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
    );
  }
}
```

- [ ] **Step 2:** `flutter analyze` clean (no new issues).
- [ ] **Step 3:** Commit `feat(mobile): add HelpIcon widget`

### Task 14: Mobile — `AppTextField.help` param
**Files:**
- Modify: `mobile/lib/core/widgets/app_text_field.dart`

- [ ] **Step 1:** Add `final String? help;` field + ctor param. In `build`, when `widget.help != null`, render label as `Row(mainAxisSize: MainAxisSize.min, children: [Text(widget.label!), const SizedBox(width: 4), HelpIcon(message: widget.help!)])`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): AppTextField help param`

### Task 15: Mobile — `DateField.help` param
**Files:**
- Modify: `mobile/lib/core/widgets/date_field.dart`

- [ ] **Step 1:** Add `final String? help;` ctor param; pass `help: widget.help` to the wrapped `AppTextField`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): DateField help param`

### Task 16: Mobile — i18n `app_en.dart`
**Files:**
- Modify: `mobile/lib/l10n/app_en.dart`

- [ ] **Step 1:** Add all `{ns}.{field}Help` keys (EN values from Copy section) + gap hints (assessment.selectPatientHint … mentalhealth.scoreHint).
- [ ] **Step 2:** Commit `feat(mobile): en i18n help keys`

### Task 17: Mobile — i18n `app_fr.dart`
**Files:**
- Modify: `mobile/lib/l10n/app_fr.dart`

- [ ] **Step 1:** Add identical keys with FR values.
- [ ] **Step 2:** Verify parity: `grep -oE "^  '[a-zA-Z0-9_.]+':" lib/l10n/app_en.dart | sort > /tmp/enk.txt; grep -oE "^  '[a-zA-Z0-9_.]+':" lib/l10n/app_fr.dart | sort > /tmp/frk.txt; diff /tmp/enk.txt /tmp/frk.txt` → no output.
- [ ] **Step 3:** Commit `feat(mobile): fr i18n help keys`

### Task 18: Mobile — patient + maternity forms
**Files:**
- Modify: `mobile/lib/features/patients/screens/patient_form_screen.dart`, `mobile/lib/features/maternity/screens/maternity_form_screen.dart`

- [ ] **Step 1:** Add `help: tr(ref, 'patients.<field>Help')` to each AppTextField; add `help: tr(ref, 'maternity.<field>Help')` (incl. `maternity.lmpHelp`, `maternity.eddHelp` on the DateFields).
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): patient + maternity help icons`

### Task 19: Mobile — ANC form
**Files:**
- Modify: `mobile/lib/features/anc/screens/anc_visit_form_screen.dart`

- [ ] **Step 1:** Add `help` to every AppTextField and DateField (`anc.*Help`); presentation dropdown gets `hintText: tr(ref, 'anc.presentationHint')` + `suffixIcon: HelpIcon(message: tr(ref, 'anc.presentationHelp'))`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): ANC form help icons + presentation hint`

### Task 20: Mobile — delivery form + newborn dialog
**Files:**
- Modify: `mobile/lib/features/delivery/screens/delivery_form_screen.dart`, `mobile/lib/features/delivery/screens/delivery_detail_screen.dart`

- [ ] **Step 1:** Delivery form: add `help: tr(ref, 'delivery.*Help')`. Newborn dialog: add `help` to name/birth weight/apgar AppTextFields; sex dropdown gets `hintText: tr(ref, 'newborn.sexHint')` + `suffixIcon: HelpIcon(message: tr(ref, 'newborn.sexHelp'))`; crying/breastfeeding CheckboxListTiles get `secondary: HelpIcon(...)` if the tile supports it, else leave tiles as-is (checkbox labels are self-explanatory).
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): delivery + newborn help icons`

### Task 21: Mobile — postnatal form
**Files:**
- Modify: `mobile/lib/features/delivery/screens/postnatal_visit_form_screen.dart`

- [ ] **Step 1:** Add `help: tr(ref, 'postnatal.<field>Help')` to every AppTextField and the visit-date DateField.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): postnatal help icons`

### Task 22: Mobile — referral + growth forms
**Files:**
- Modify: `mobile/lib/features/referrals/screens/referral_form_screen.dart`, `mobile/lib/features/growth/screens/growth_form_screen.dart`

- [ ] **Step 1:** Referral: add `help` everywhere (`referral.*Help`). Growth: add `help` everywhere (`growth.*Help`); nutritional-status dropdown gets `hintText: tr(ref, 'growth.nutritionalStatusHint')` + `suffixIcon: HelpIcon(message: tr(ref, 'growth.nutritionalStatusHelp'))`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): referral + growth help icons`

### Task 23: Mobile — schedule forms + reschedule dialog
**Files:**
- Modify: `mobile/lib/features/schedule/screens/schedule_form_screen.dart`, `mobile/lib/features/schedule/screens/schedule_screen.dart`

- [ ] **Step 1:** Schedule form: `schedule.visitNumberHelp`, `schedule.dateHelp`. Reschedule dialog: new-date field gets `schedule.newDateHelp` (via label row or suffix), reason field gets `hintText: tr(ref, 'schedule.reasonHint')` + `schedule.reasonHelp`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): schedule + reschedule help icons`

### Task 24: Mobile — assessment form
**Files:**
- Modify: `mobile/lib/features/assessment/screens/assessment_form_screen.dart`

- [ ] **Step 1:** Patient select dropdown: `hintText: tr(ref, 'assessment.selectPatientHint')` + `suffixIcon: HelpIcon(message: tr(ref, 'assessment.selectPatientHelp'))`. Each of the 6 `TextFormField`s: add `hintText` (`assessment.ageHint` …) and `suffixIcon: HelpIcon(message: tr(ref, 'assessment.<field>Help'))`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): assessment placeholders + help icons`

### Task 25: Mobile — mental health form
**Files:**
- Modify: `mobile/lib/features/delivery/screens/mental_health_form_screen.dart`

- [ ] **Step 1:** Q1/Q2 score dropdowns get `hintText: tr(ref, 'mentalhealth.scoreHint')` + `suffixIcon: HelpIcon(message: tr(ref, 'mentalhealth.scoreHelp'))`.
- [ ] **Step 2:** `flutter analyze` clean.
- [ ] **Step 3:** Commit `feat(mobile): mental health help icons`

### Task 26: Verify all
- [ ] **Step 1:** Web: `cd frontend && npx vite build` → succeeds (pre-existing chunk warning OK); `node --test test/` still 4/4.
- [ ] **Step 2:** Mobile: `flutter analyze` → only 3 pre-existing `profile_screen.dart` infos; `flutter test` date_calc suite still 13/13.
- [ ] **Step 3:** Commit any stragglers; push feature commit(s) as a single logical commit if needed.
