# Profile Language Switching — Design

Date: 2026-08-03
App: Flutter app at `mobile/` (MamaSafe)

## Goal

Add a page under **Profile** that lets a user switch the app language (English / French),
apply it immediately, and persist it across launches.

## Current state

- `lib/l10n/localization_provider.dart` holds a mutable `LocalizationService` exposed via a
  plain `Provider`. It is **not reactive**: calling `setLocale()` mutates the service but
  nothing notifies Riverpod, so the UI never rebuilds.
- `lib/l10n/tr.dart` uses `ref.read`, so translated widgets do not subscribe to locale changes.
- Most screens render hardcoded English strings; ~80 labels use `tr(ref, key)`.
- The Profile screen (`features/profile/screens/profile_screen.dart`) has a Settings card that is
  a natural home for a Language entry.
- Codebase convention is `StateNotifier` + `StateNotifierProvider`.

## Approach (approved: Approach 1 — StateNotifier refactor)

1. **`localization_provider.dart`** — Replace `LocalizationService` with
   `LocalizationNotifier extends StateNotifier<AppLocale>` (en/fr) exposed via
   `StateNotifierProvider<LocalizationNotifier, AppLocale>`.
   - `loadLocale()`: read `SharedPreferences` key `'locale'`; if unset, fall back to device
     locale (`PlatformDispatcher.instance.locale.languageCode == 'fr'`).
   - `setLocale(locale)`: update state and persist to SharedPreferences.
   - Remove `currentLocaleProvider` (superseded).

2. **`tr.dart`** — Use `ref.watch` instead of `ref.read` so translated widgets rebuild on change.
   Signature unchanged; ~80 existing call sites are unaffected.

3. **`app.dart`** — `_init()` loads locale through the notifier (same `_ready` gate);
   `MaterialApp` watches `localeProvider` for `locale`.

4. **New screen `features/profile/screens/language_screen.dart`** — `ConsumerWidget`, AppBar
   titled `language.title`, an `AppCard` listing the supported languages (English, Français)
   with a trailing check on the current selection. Tapping calls `setLocale()` — applies
   immediately and persists.

5. **`profile_screen.dart`** — Add a Language tile to the Settings card (current language +
   chevron) that navigates to `/profile/language`. Migrate all hardcoded strings on this
   screen (account info, settings tiles, supervisor tab, stat cards, About dialog) to
   `tr(ref, ...)`.

6. **`app_router.dart`** — Add `GoRoute(path: 'language')` under the `/profile` branch.
   Localize bottom-nav labels in `MainShell` using existing `nav.*` keys.

7. **l10n strings** — Add en/fr keys for `language.*` and `profile.*` labels
   (~25 per file, fully translated).

## Out of scope

- Localizing the ~20 other screens (separate pass).
- Adding languages beyond en/fr.
- `flutter_localizations` for Material widgets (date pickers, etc.).

## Tests

- `test/l10n/localization_provider_test.dart` — default en; `setLocale` persists + updates
  state; `loadLocale` restores saved value / falls back to device.
- `test/features/profile/language_screen_test.dart` — renders both languages, marks current
  selection, tapping French switches locale and persists (using
  `SharedPreferences.setMockInitialValues`).

## Verification

- `flutter analyze` clean.
- `flutter test` green.
