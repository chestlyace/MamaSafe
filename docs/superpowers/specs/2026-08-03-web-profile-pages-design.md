# Web Profile Pages — Design

Date: 2026-08-03
App: Web platform at `frontend/` (Vite + React) + `backend/` (FastAPI)

## Goal

Give every web user (CHW, supervisor, admin) a **Profile page** where they can view their
account information, edit the fields their role is allowed to edit, and change their password.

## Current state

- No profile page exists in the web app.
- No `GET /users/me` or self-update/password-change endpoints exist.
- `User` model (`backend/app/database.py`) already has: `id`, `username`, `hashed_password`,
  `role` (`chw | supervisor | admin`), `is_active`, `full_name`, `facility`, `district`,
  `region`, `whatsapp_number`, `last_active`, `created_at`, `must_change_password`.
- `get_current_user` dependency + `verify_password`/`hash_password` helpers exist in
  `backend/app/routers/auth.py`.
- Routers are registered in `backend/app/main.py` via `app.include_router(...)`.
- Frontend pages live under `frontend/src/pages/`, wrapped by `Layout` + `NavBar`; i18n keys
  live in `frontend/src/i18n/en.json` + `fr.json`.
- Supervisor/admin CRUD (`/api/v1/admin/users`, schemas in `schemas_admin.py`) is a separate,
  supervisor-scoped concern — the self-service profile is kept apart from it.

## Approach (approved: Approach A — dedicated `/api/v1/users` router)

### Backend

New file `backend/app/routers/users.py` (prefix `/api/v1/users`, tag `users`), registered in
`main.py`. All endpoints use `get_current_user` and the password helpers from `auth.py`.

- `GET /me` → `UserProfileOut`
  Returns `id`, `username`, `full_name`, `role`, `facility`, `district`, `region`,
  `whatsapp_number`, `is_active`, `last_active`, `created_at`.
- `PATCH /me` → body `UserProfileUpdate`, returns updated `UserProfileOut`
  Body fields (all `Optional[str] = None`): `full_name`, `whatsapp_number`, `facility`,
  `district`, `region`.
  - Applies only fields actually sent (`exclude_unset`).
  - Role-based allow-list; a disallowed field present in the request → `403` with detail
    naming the field:
    - all roles: `full_name`, `whatsapp_number`
    - CHW: + `facility`
    - supervisor: + `district`, `region`
    - admin: nothing extra
- `POST /me/password` → body `PasswordChange`, returns `{"message": "..."}`
  Body: `current_password: str`, `new_password: str` (min_length 8).
  - Wrong current password → `400 "Current password is incorrect"`.
  - On success: hash + save new password, clear `must_change_password`.

New schemas `UserProfileOut`, `UserProfileUpdate`, `PasswordChange` in `backend/app/schemas.py`
(kept separate from the supervisor-scoped `UserUpdate` in `schemas_admin.py`).

### Frontend

- `frontend/src/api/client.js`: add `getMe()`, `updateMe(data)`, `changePassword(currentPassword, newPassword)`.
- New `frontend/src/pages/ProfilePage.jsx`:
  - Fetches `getMe()` on mount (existing fetch-on-mount pattern; no `setState` in effect bodies).
  - **Header**: avatar initial, full name, username, role badge, member-since date.
  - **Profile form** (editable per role):
    - Everyone: `full_name`, `whatsapp_number`.
    - CHW: `facility` editable; read-only text for others.
    - Supervisor: `district`, `region` editable; read-only for others.
    - Save → `updateMe` → success banner + refreshed values; `403` shown as inline error.
  - **Change password section**: current password, new password (min 8, client-validated),
    confirm match. Submit → `changePassword` → success banner + cleared fields; wrong current
    password shown inline.
- Route: `<Route path="/profile" element={<ProfilePage />} />` added to the main
  `ProtectedRoute` Layout (accessible to CHW, supervisor, and admin).
- `frontend/src/components/NavBar.jsx`: add a Profile link (`person` icon, `t('profile')`) to
  `navLinks` for all roles (desktop + mobile drawer).
- i18n: new keys (e.g. `profile`, `current_password`, `new_password`, `confirm_password`,
  `save`, `password_updated`, `profile_updated`, field labels) added to both `en.json` and
  `fr.json`.

## Out of scope

- Enforcing `must_change_password` on first login (user chose optional-only password change).
- Editing `username` or `role` (immutable, system-managed).
- Changing another user's profile (admin/supervisor CRUD already exists via `/api/v1/admin/users`).

## Error handling

- `PATCH /me` disallowed field → `403` with field name; inline error in the form.
- `POST /me/password`: wrong current password → `400`; new password < 8 chars → `422` (schema
  `min_length`), plus client-side pre-validation; password fields cleared on success.
- `401` → existing axios interceptor redirects to `/login`.

## Verification

- Backend import check (`python -c "from app.routers import users; from app.schemas import UserProfileOut"`).
- `npx eslint` on changed files; `npm run build` passes.
- Curl smoke tests: `GET /me` for each role; `PATCH /me` allowed + disallowed fields per role;
  password change happy path, wrong current password, login still works with the new password.
- Manual browser walkthrough of the profile page for a CHW, a supervisor, and an admin.
