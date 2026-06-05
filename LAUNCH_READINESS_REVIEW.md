# Topwebsuite Mobile Launch Readiness Review

## Review Date

May 5, 2026

## Verdict

The mobile app is **not yet ready for launch**.

The codebase now has a broad backend-connected Flutter app surface, and the current code passes static analysis and tests. However, it cannot honestly be confirmed as "exactly the same as web" or "everything works perfectly" until authenticated end-to-end testing, device UI verification, release packaging, and module-specific parity testing are complete.

## Confirmed

- The mobile app uses the same production backend base URL as PFED: `https://web-production-4266f.up.railway.app`.
- Login/signup/OTP/password-reset code uses the same auth endpoints as the web frontend.
- A web-created account should be able to log in on mobile because both clients call the same backend auth endpoints.
- A mobile-created account should be able to log in on web because mobile signup creates the user through the same backend signup and OTP verification endpoints.
- Public production backend smoke checks passed:
  - `GET /api/billing/context/` returned `200`.
  - `GET /api/currencies/` returned `200`.
- Flutter verification passed:
  - `flutter pub get`
  - `dart format lib test`
  - `flutter analyze`
  - `flutter test`

## Improved During This Review

- Added invoice/quotation line-item support so create/update payloads can include backend-required `items`.
- Added backend HTML preview WebView support for configured document preview endpoints.
- Corrected waybill field names to match the backend model (`recipient_*`, `shipment_description`, `shipment_value`, `sender_contact`, `recipient_contact`).
- Replaced the account "edit queued" button with real PATCH edit forms for:
  - profile
  - account preferences
  - document settings
  - branding
  - notification settings
- Added local autosave for new records in the shared module editors.
- Removed explicit placeholder/queued text from Flutter UI code.

## Cannot Yet Confirm

### Exact Web UI Match

The Flutter UI uses PFED colors, spacing, card style, status chips, and module layout patterns, but it has not been visually verified against the web with screenshots across mobile viewport sizes. Native Flutter also cannot be literally identical to DOM/CSS without a detailed design-spec pass.

Current status: **PFED-inspired, not proven pixel-identical**.

### Authenticated Web/Mobile Login

The code uses the same endpoints, but no real user credentials were provided for a live login test.

Current status: **contract-compatible, not live credential-tested**.

### Full Document Parity

Invoices and quotations now support line items, but full PFED parity still needs:

- logo upload
- signature upload
- exact live preview behavior
- exact totals UX
- business defaults helper
- CRM customer prefill
- ERP item/order/delivery prefill
- status/filter/sort parity
- native validation matching PFED and backend serializers

Current status: **functional scaffold improved, not full web parity**.

### Business Profile Parity

The shared CRUD screen is wired, but full parity still needs:

- country/category pickers
- logo/cover/gallery uploads
- publish/unpublish buttons
- verification submission button
- public preview
- directory search UI

Current status: **basic backend workspace, not full web parity**.

### CRM/ERP Parity

Shared CRUD workspaces exist, but full parity still needs:

- module-specific dashboards
- filters
- relationship selectors
- helper actions
- document prefill flows
- access-gate UX polish

Current status: **basic backend workspaces, not full web parity**.

### Billing Launch Readiness

Billing screen can load plans/subscription/invoices and open checkout WebView, but full launch readiness still needs:

- deep link or return URL handling
- mobile verification of payment returns
- cancel subscription confirmation flow
- billing invoice share/download polish

Current status: **partially functional, not fully launch-tested**.

### Release Readiness

`flutter build apk --debug` previously timed out locally. Android/iOS signing, app icons, splash assets, store metadata, and release builds are not complete.

Current status: **not release-packaged**.

## Launch Blockers

- No real authenticated end-to-end test credentials have been used.
- Android APK/AAB build has not completed successfully.
- iOS archive cannot be verified from this Windows workspace.
- UI has not been screenshot-compared against PFED.
- File upload flows are not implemented deeply enough for launch.
- Full document editors are still generic and need PFED-specific UX.
- Business profile, CRM, and ERP need module-specific polish beyond shared CRUD.
- Automated integration tests for auth, billing, and documents are not yet present.

## Recommended Next Fix Order

1. Complete document editors to exact PFED behavior, starting with invoices.
2. Add logo/signature/file upload support.
3. Add business defaults, CRM helper, and ERP helper flows.
4. Add full billing return verification/deep link handling.
5. Add business profile publish/verification/media flows.
6. Add CRM and ERP module-specific screens.
7. Run real login tests using web-created and mobile-created accounts.
8. Fix Android build timeout and produce APK/AAB.
9. Verify UI with screenshots against PFED mobile pages.

