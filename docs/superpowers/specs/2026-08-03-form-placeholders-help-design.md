# Form Placeholders + Field Help Descriptions — Design

Date: 2026-08-03

## Goal

Give every clinical form field a **placeholder** (where missing today) and a
**brief description** of what to input, exposed as:
- Web: a small info icon beside each label; hovering the icon shows a CSS
  tooltip with the description.
- Mobile: a small info icon beside each label; tapping it shows a Flutter
  `Tooltip` bubble with the description.

Scope (agreed): **clinical forms only** — patient, pregnancy/maternity, ANC
visit, delivery + newborn, postnatal, referral, growth (mobile), schedule +
reschedule, assessment. Auth/login, profile, password change, CHW creation,
facility and supervisor/admin screens are **out of scope**.

## Current State

- Web: ~1/3 of clinical fields already have placeholders (`*_placeholder` i18n
  keys); no `helper`/`title`/tooltip affordance exists on any input. Forms use
  plain `<label>` + `<input>/<select>/<textarea>` with Tailwind, plus the shared
  `DateField.jsx` (no `placeholder`/`help` props). i18n is flat
  (`en.json`/`fr.json`).
- Mobile: ~54 fields already have `hintText` via `*Hint` i18n keys. `AppTextField`
  supports `hint` + `suffix` but no help/helper. `DateField` wraps `AppTextField`
  (label row is the field label). No `Tooltip`, no `Icons.info*` on any input.
  Gaps (no hint): assessment form (6 raw `TextFormField`s + patient select),
  ANC presentation dropdown, growth nutritional-status dropdown, newborn sex
  dropdown, reschedule reason.

## Web Design

1. **New `frontend/src/components/FieldHelp.jsx`** — renders a Material "info"
   icon + a pure-CSS tooltip using Tailwind `group`/`group-hover` (dark bubble,
   appears above the icon, max-width ~260px, `pointer-events-none`). Props:
   `text` (string). No new dependencies.
2. **`DateField.jsx`** gains an optional `help` prop → renders `FieldHelp`
   beside its label.
3. Each clinical form renders `<FieldHelp text={t('{field}_help')} />` inside
   its `<label>` and adds `placeholder={t('{field}_placeholder')}` (i18n key)
   to text/number/textarea inputs. Date inputs get no placeholder (browser
   shows `mm/dd/yyyy`); selects keep their empty "—"/"Select…" option.
4. New flat i18n keys in `en.json` + `fr.json`:
   - `{field}_help` for every clinical field.
   - `{field}_placeholder` for every field missing one (reuse existing
     `*_placeholder` keys where present).

## Mobile Design

1. **New `mobile/lib/core/widgets/help_icon.dart`** — `HelpIcon({required String
   message})`: `Tooltip(triggerMode: TooltipTriggerMode.tap, message: message,
   child: Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary))`.
2. **`AppTextField`** gains optional `help` (String?) → when set, the label row
   becomes `Row([Text(label), SizedBox(4), HelpIcon(message: help)])`.
3. **`DateField`** gains optional `help` (String?) → passed through to the
   wrapped `AppTextField`.
4. Raw `TextFormField`s (assessment ×6): add `hintText` + `suffixIcon:
   HelpIcon(...)` to their `InputDecoration`.
5. Raw `DropdownButtonFormField`s (ANC presentation, growth status, newborn
   sex, reschedule reason): add `hintText`; verify `suffixIcon` renders beside
   the dropdown arrow (fallback: wrap the dropdown with a label row above if the
   arrow conflicts).
6. New i18n keys `{ns}.{field}Help` in `app_en.dart` + `app_fr.dart`; existing
   `*Hint` keys reused as placeholders.

## Content

Each field gets a one-line description of expected input (e.g. phone: "Include
country code if known"; fundal height: "Measured in cm from the symphysis to the
fundus"). Written in EN and FR, kept in lockstep (flat maps, keys mirrored).

## Testing

- Web: `npx vite build` (existing chunk-size warning only); manual hover spot-check.
- Mobile: `flutter analyze` (no new issues); existing tests still pass;
  `flutter test test/core/widgets/...` for any new widget tests.

## Files

- Web new: `frontend/src/components/FieldHelp.jsx`.
- Web edited: `DateField.jsx`, `PatientRegisterPage.jsx`, `PregnancyRegisterPage.jsx`,
  `VisitLogPage.jsx`, `DeliveryForm.jsx`, `PostnatalVisitForm.jsx`, `ReferralModal.jsx`,
  `AssessmentPage.jsx`, `RescheduleModal.jsx`, `PostnatalSchedule.jsx`, `en.json`, `fr.json`.
- Mobile new: `mobile/lib/core/widgets/help_icon.dart`.
- Mobile edited: `app_text_field.dart`, `date_field.dart`, `assessment_form_screen.dart`,
  `anc_visit_form_screen.dart`, `delivery_form_screen.dart`, `delivery_detail_screen.dart`,
  `postnatal_visit_form_screen.dart`, `referral_form_screen.dart`, `growth_form_screen.dart`,
  `schedule_form_screen.dart`, `schedule_screen.dart`, `maternity_form_screen.dart`,
  `patient_form_screen.dart`, `app_en.dart`, `app_fr.dart`.
