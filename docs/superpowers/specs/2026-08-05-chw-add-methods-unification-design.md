# CHW Add Methods Unification Design

**Date**: 2026-08-05  
**Status**: Draft  
**Author**: AI Assistant  

## Overview

Unify CHW addition methods across mobile and web platforms. Currently:
- **Mobile** has manual CHW creation but no invite code management for supervisors
- **Web** has invite code management but no manual CHW creation UI

This design adds the missing method to each platform and provides a unified UX for accessing both methods.

## Scope

1. **Mobile (Flutter)**: 
   - Replace single "Add CHW" FAB with animated speed dial showing both methods
   - Build new invite code management screen (`/supervisor/invites`)
   
2. **Web (React)**:
   - Replace "Add CHW via Code" button with unified dropdown showing both methods
   - Add modal dialog for manual CHW creation

## Mobile Changes

### 1. CHW List Screen - Speed Dial FAB

**File**: `mobile/lib/features/supervisor/screens/chw_list_screen.dart`

**Current**: Extended FAB that navigates directly to `/supervisor/chws/new`

**New**: 
- Circular FAB with **+** icon (rose-500 background)
- On tap: + rotates 45° to ×, two mini-FABs animate upward
- Mini-FABs:
  1. **"Invite Code"** with key icon → navigates to `/supervisor/invites`
  2. **"Manual Entry"** with person_add icon → navigates to `/supervisor/chws/new`
- Scrim overlay (black 50% opacity) behind mini-FABs
- Tap outside or × to collapse

**Implementation**: Use `flutter_speed_dial` package (well-maintained, supports all needed features: animated icon, child labels, scrim overlay, spacing)

### 2. Invite Code Management Screen

**New file**: `mobile/lib/features/supervisor/screens/invite_codes_screen.dart`  
**Route**: `/supervisor/invites`

**Layout**:
- AppBar: "Invite Codes" with back arrow
- Generate section (card):
  - TextField: Note (optional, hint: "e.g., For new clinic staff")
  - Dropdown: Expiration (7 days, 14 days, 30 days)
  - ElevatedButton: "Generate Code" (rose-500)
- Code list (ListView):
  - Each card shows:
    - Code as `XXXX-XXXX` (monospace font)
    - Copy icon button (shows snackbar "Copied!")
    - Status badge: pending (amber), used (green), revoked (gray), expired (red)
    - Created date + note (if present)
    - Revoke button (only for pending codes, shows confirmation dialog)

**Repository additions** (`supervisor_repository.dart`):
```dart
class InviteCode {
  final int id;
  final String code;
  final String status;
  final String? note;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? usedBy;
}

Future<List<InviteCode>> listInviteCodes() async {
  // GET /api/v1/admin/invite-codes
}

Future<InviteCode> createInviteCode({String? note, int expiresInDays = 14}) async {
  // POST /api/v1/admin/invite-codes
}

Future<void> revokeInviteCode(int codeId) async {
  // POST /api/v1/admin/invite-codes/:id/revoke
}
```

**State management**: Riverpod providers for invite codes list, create, revoke

**Localization**: Add keys to `app_en.dart` and `app_fr.dart`:
- `supervisor.inviteCodes`
- `supervisor.generateCode`
- `supervisor.expiration`
- `supervisor.days`
- `supervisor.pending`, `supervisor.used`, `supervisor.revoked`, `supervisor.expired`
- `supervisor.revokeCode`
- `supervisor.copied`

### 3. Router Update

**File**: `mobile/lib/core/router/app_router.dart`

Add route:
```dart
GoRoute(
  path: '/supervisor/invites',
  builder: (context, state) => const InviteCodesScreen(),
),
```

## Web Changes

### 1. CHW List Page - Unified Add Button

**File**: `frontend/src/pages/CHWListPage.jsx`

**Current**: Link button "Add CHW via Code" → `/supervisor/invites`

**New**:
- Button labeled "Add CHW" with chevron-down icon (rose-500, rounded-xl)
- On click: small popover/dropdown appears below button
- Two options:
  1. **"Invite Code"** with key icon → navigates to `/supervisor/invites`
  2. **"Manual Entry"** with person_add icon → opens modal (state: `showManualModal`)

**Implementation**: Simple React state (`showDropdown`) + absolute positioned div with Tailwind styling. Check for existing dropdown component in `frontend/src/components/` first.

### 2. Manual CHW Creation Modal

**New component**: Extract to `frontend/src/components/ManualChwModal.jsx` for reusability and cleaner separation

**Modal structure**:
- Overlay: fixed inset-0 bg-black/50 z-50
- Dialog: centered, white bg, rounded-2xl, max-w-md, p-6
- Header: "Add CHW Manually" + close (×) button
- Form fields (matching mobile):
  - Full Name (required, text input)
  - Username (required, text input)
  - Password (required, password input with show/hide toggle)
  - Facility (optional, text input)
- Submit button: "Create CHW" (rose-500, full width)
- Cancel button: "Cancel" (gray, full width, below submit)

**Form state**: React useState for each field + validation (required fields)

**API call**: 
```javascript
import { createChw } from '../api/client';

const handleSubmit = async (e) => {
  e.preventDefault();
  setLoading(true);
  try {
    await createChw({
      username,
      password,
      full_name: fullName,
      facility: facility || undefined,
    });
    toast.success('CHW created successfully');
    onClose();
    refreshList(); // re-fetch CHW list
  } catch (err) {
    toast.error(err.response?.data?.detail || 'Failed to create CHW');
  } finally {
    setLoading(false);
  }
};
```

**Backend note**: The existing `POST /api/v1/admin/users` endpoint already sets `must_change_password = True`, so the CHW will be prompted to change their temp password on first login.

**Styling**: Tailwind, rose-500 accent, matching existing web app patterns

## API Endpoints (Existing)

No backend changes required. All endpoints already exist:

- `GET /api/v1/admin/invite-codes` - List supervisor's invite codes
- `POST /api/v1/admin/invite-codes` - Create new invite code
- `POST /api/v1/admin/invite-codes/:id/revoke` - Revoke pending code
- `POST /api/v1/admin/users` - Create user (manual CHW creation)

## Testing

### Mobile
1. Speed dial opens/closes correctly
2. Both mini-FABs navigate to correct screens
3. Invite code screen: generate, copy, revoke all work
4. Manual form screen: create CHW works (existing functionality)

### Web
1. Dropdown opens/closes correctly
2. "Invite Code" option navigates to `/supervisor/invites`
3. "Manual Entry" option opens modal
4. Modal form: validation, submit, success toast, list refresh
5. Error handling: duplicate username, network failure

## Files Changed

### Mobile (Flutter)
- `mobile/lib/features/supervisor/screens/chw_list_screen.dart` - Replace FAB with speed dial
- `mobile/lib/features/supervisor/screens/invite_codes_screen.dart` - **New file**
- `mobile/lib/features/supervisor/supervisor_repository.dart` - Add invite code models + methods
- `mobile/lib/core/router/app_router.dart` - Add `/supervisor/invites` route
- `mobile/lib/l10n/app_en.dart` - Add localization keys
- `mobile/lib/l10n/app_fr.dart` - Add French translations
- `mobile/pubspec.yaml` - Add `flutter_speed_dial` dependency (if used)

### Web (React)
- `frontend/src/pages/CHWListPage.jsx` - Replace button with dropdown + add modal

## Out of Scope

- Activate/deactivate CHW UI on web (API exists, no UI)
- CHW self-registration flow changes
- Admin-level CHW management changes
- Backend changes

## Success Criteria

1. Supervisors can add CHWs via both methods on both platforms
2. Mobile speed dial is smooth and intuitive
3. Web modal form matches mobile form fields and validation
4. Invite code management on mobile matches web functionality
5. All existing functionality preserved
