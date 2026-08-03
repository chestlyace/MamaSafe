# Mobile Auth Web Parity — Design

Date: 2026-08-03
Status: Approved
Scope: `mobile/` Flutter app only. No backend changes required.

## Goal

Rebuild the mobile login screen to be a faithful port of the web login, add
registration links on it, and add registration pages for supervisors and CHWs.
Mirror the web (frontend/) behavior and visuals: branding, language toggle,
show-password toggle, error banner, "No account?" box, inline signup success
states, and role-based landing after login. Mobile is used by supervisors and
CHWs only; admins are directed to the web app via an in-app browser.

## Reference (web)

- `frontend/src/pages/LoginPage.jsx` — logo + tagline, LanguageToggle top-right,
  white card (username/password with show-password toggle, error banner, login
  button), "No account?" box with links to `/signup` and `/chw-signup`, YIBS
  footer. Role redirect after login: admin → `/admin`, supervisor →
  `/supervisor`, else → `/assess`.
- `frontend/src/pages/SignupPage.jsx` (supervisor) — full_name, username,
  password, district, region, whatsapp_number → `POST /api/v1/auth/supervisor-signup`.
- `frontend/src/pages/ChwSignupPage.jsx` — invite_code (XXXX-XXXX, centered,
  mono, uppercase), full_name, username, password, facility, whatsapp_number →
  `POST /api/v1/auth/chw-signup`.
- Both signup pages: inline success card with "Go to login" button; error
  banner; back-to-login link; max-width 440px card layout.

## Backend (unchanged)

- `POST /api/v1/auth/supervisor-signup` body `{full_name, username, password,
  district, region?, whatsapp_number?}` → 400 `detail` on duplicate username.
- `POST /api/v1/auth/chw-signup` body `{full_name, username, password,
  facility?, whatsapp_number?, invite_code}` → validates invite code (exists,
  status `pending`, not expired); marks it `used`; 400 `detail` otherwise.
- Neither signup auto-authenticates; both return `{message}` only.

## Section 1 — Screens & navigation

Routes (`mobile/lib/core/router/app_router.dart`):

- `/login` — rebuilt `LoginScreen`.
- `/signup` — supervisor registration `SupervisorSignupScreen`.
- `/chw-signup` — CHW registration `ChwSignupScreen`.
- `/login/forgot-password` — unchanged.
- `/admin-browser` — in-app browser screen, gated to role `admin`.

New screen files under `mobile/lib/features/auth/screens/`:
`supervisor_signup_screen.dart`, `chw_signup_screen.dart`; `login_screen.dart`
rebuilt in place.

Shared auth widgets (`mobile/lib/features/auth/widgets/`):

- `auth_brand.dart` — logo image + "MamaSafe" + tagline header.
- `auth_language_toggle.dart` — small EN/FR chip (top-right), backed by the
  existing `localeProvider`.
- `auth_error_banner.dart` — web-style red error box.

Branding: copy `frontend/src/assets/logo.svg` to `mobile/assets/images/logo.svg`
and register it in the Flutter asset bundle. Tagline uses existing key
`auth.supportingHealthyPregnancies`.

Post-login landing (redirect logic): supervisor → `/supervisor`, chw → `/home`,
admin → in-app browser flow (Section 3). Forgot-password route stays accessible
pre-auth.

## Section 2 — Auth repository & API integration

New methods on `AuthRepository` (`mobile/lib/features/auth/auth_repository.dart`):

- `Future<void> supervisorSignup({required String fullName, required String
  username, required String password, required String district, String? region,
  String? whatsappNumber})` → `POST /api/v1/auth/supervisor-signup`.
- `Future<void> chwSignup({required String fullName, required String username,
  required String password, String? facility, String? whatsappNumber, required
  String inviteCode})` → `POST /api/v1/auth/chw-signup`.
- `login(...)` extended so the returned `User` (role included via
  `User.fromJson`) drives the post-login redirect.

Login keeps the form-urlencoded `POST /api/v1/auth/login`; JWT stored in secure
storage. Signups do not change auth state (no token, no auto-login); success
surfaces via the inline success card → "Go to login".

Networking reuses `dioProvider`/`api_client.dart`. Errors use the existing
`DioException` → `data['detail']` extraction pattern; fallback to a generic
translated error message.

## Section 3 — Admin in-app browser flow

- Add `webview_flutter` to `mobile/pubspec.yaml`.
- Add configurable `WEB_APP_URL` via `mobile/.env` (dotenv already used by
  `api_client.dart`); default `http://localhost:5173`.
- On successful admin login: store JWT as usual, then navigate to
  `AdminWebViewScreen` which opens `WEB_APP_URL` in a `WebView` with a native
  top bar (app name + close button).
- Closing the webview logs the admin out of mobile (`logout()`) and returns to
  `/login`, so no admin session lingers.
- Route gated to role `admin`.
- Missing/invalid `WEB_APP_URL`: show the error notice and abort the redirect.

## Section 4 — Validation, error handling, l10n, testing

Validation reuses `mobile/lib/core/validators/validators.dart` with `ref: ref`:

- Login: unchanged (username required; password ≥ 6).
- Supervisor: full_name, username, password (≥ 6), district required; region,
  whatsapp optional.
- CHW: invite_code required (uppercase, `XXXX-XXXX` hint), full_name, username,
  password required; facility, whatsapp optional.

Error handling: API `detail` shown in `AuthErrorBanner`; network failures fall
back to a translated generic message.

l10n: new `auth.*` / `signup.*` keys added to both `app_en.dart` and `app_fr.dart`
(login additions, signup fields, success states, go-to-login, back-to-login,
web-only admin notice). EN/FR parity re-verified with the existing script.

Testing:

- Widget tests: login shows signup links + language toggle; signup screens
  validate required fields and render the success state on a mocked repository;
  admin login triggers the webview flow.
- Repository unit tests: `supervisorSignup`/`chwSignup` POST correct payloads and
  surface `detail` errors (mocked Dio).
- Router tests: supervisor → `/supervisor`, chw → `/home`.
- Gate: `flutter analyze lib test` clean; `flutter test` shows no new failures
  beyond the pre-existing drift/sqlite ones.

## Out of scope

- No backend changes.
- No admin pages in the mobile app.
- No auto-login after signup.
