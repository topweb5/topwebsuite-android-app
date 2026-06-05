# Topwebsuite Mobile App Development Phase Map

## Development Rule

Use only:

- Backend: `C:\Users\user\Desktop\topwebsuite`
- Web frontend/PFED: `C:\Users\user\Desktop\topwebsuite PFED`

Do not use `topwebsuite free mobile app` as a reference.

## Phase Status Legend

- `Not started`: no implementation work yet
- `In progress`: actively being built
- `Blocked`: needs a decision, credential, backend fix, or external setup
- `Ready for QA`: implementation complete and awaiting verification
- `Done`: verified against backend and web behavior

## Phase 0: Source Audit and Flutter Scaffold

Status: `Ready for QA`

Goal: create the clean Flutter project and lock the source-of-truth contracts.

Tasks:

- Audit backend API guide and URL files.
- Audit PFED web flows for auth, dashboard, billing, documents, business profile, CRM, ERP, and integrations.
- Scaffold fresh Flutter app in this workspace.
- Add app name, package/bundle IDs, app icon placeholders, environment config, and folder structure.
- Add base dependencies.
- Add lint rules and CI-ready scripts.

Deliverables:

- Fresh Flutter project. Completed.
- `lib/app`, `lib/core`, and `lib/features` structure. Completed.
- API endpoint inventory. Completed in `IMPLEMENTATION_AUDIT.md`.
- Web parity checklist. Started in `IMPLEMENTATION_AUDIT.md`.

Acceptance:

- `flutter pub get` passes. Verified.
- `flutter analyze` passes. Verified.
- App launches to a branded splash screen. Implemented, device run still pending.
- Backend and PFED parity documents exist. Verified.

## Phase 1: Core App Foundation

Status: `Ready for QA`

Goal: build the infrastructure every feature will use.

Tasks:

- App theme matching Topwebsuite PFED visual language.
- `go_router` navigation shell.
- `Dio` API client.
- Request/response logging in debug mode.
- Multipart upload helper.
- File download helper.
- Error parser matching backend response shapes.
- Secure token storage.
- Local storage for cache and drafts.
- Shared form, list, loading, empty, error, confirmation, toast, and bottom-sheet widgets. Started with native PFED-style module workspaces and reusable status chips.

Deliverables:

- Stable app shell. Started.
- Core API layer. Started with `Dio`, auth interceptor, refresh retry, error parser, and download helper.
- Core storage layer. Started with secure token storage and shared preferences JSON storage.
- Reusable UI component set. Started with logo and async state widgets.

Acceptance:

- App handles loading, empty, error, and offline states.
- API client can call public backend endpoints.
- Shared components are used in starter screens.

## Phase 2: Authentication and Session Management

Status: `Ready for QA`

Goal: mobile login/signup must work with the same backend account as web.

Tasks:

- Login. Implemented.
- Signup. Implemented.
- Email OTP verification. Implemented.
- Resend OTP. Implemented.
- Forgot password. Implemented.
- Reset password. Implemented.
- Auth route guards. Implemented.
- Token refresh. Implemented in API client.
- Logout. Implemented.
- Session expiry handling. Started.

Primary endpoints:

- `/api/auth/signup`
- `/api/auth/verify-email-otp`
- `/api/auth/resend-email-otp`
- `/api/auth/login`
- `/api/auth/refresh`
- `/api/auth/me/`
- `/api/auth/logout`
- `/api/auth/forgot-password/`
- `/api/auth/reset-password/`

Acceptance:

- Same user can log in on web and mobile.
- Expired access token refreshes using refresh token.
- Invalid session returns user to login.

## Phase 3: Dashboard, Account, Settings, and Branding

Status: `In progress`

Goal: authenticated users can manage the same profile and settings as web.

Tasks:

- Dashboard summary. Started with subscription and usage summary.
- Profile screen and avatar upload.
- Email change request/verify.
- Change password.
- Account settings. Read-only parity screen implemented.
- Document settings. Read-only parity screen implemented.
- Branding settings. Read-only parity screen implemented.
- Notification settings. Read-only parity screen implemented.
- Currency list integration.

Primary endpoints:

- `/api/auth/me/`
- `/api/auth/usage/`
- `/api/account/profile/`
- `/api/account/email-change/request/`
- `/api/account/email-change/verify/`
- `/api/account/settings/`
- `/api/account/document-settings/`
- `/api/account/branding/`
- `/api/account/notification-settings/`
- `/api/currencies/`

Acceptance:

- Profile and settings changes appear on web.
- Web changes appear on mobile after refresh.
- Branding defaults can prefill document forms.

## Phase 4: Billing and Module Access

Status: `In progress`

Goal: mobile respects the same Free, Basic, and Premium access as the backend/web.

Tasks:

- Billing context. Implemented.
- Plans screen. Implemented.
- Subscription status. Implemented.
- Usage display. Implemented.
- Module gate service.
- Flutterwave checkout handoff. Implemented with WebView.
- Payment verification.
- Billing invoice list. Implemented.
- Billing invoice PDF download/share. PDF open implemented.
- Cancel subscription.

Primary endpoints:

- `/api/billing/context/`
- `/api/billing/plans/`
- `/api/billing/subscription/`
- `/api/billing/checkout/`
- `/api/billing/verify-payment/`
- `/api/billing/cancel/`
- `/api/billing/invoices/`
- `/api/billing/invoices/<id>/download/`

Acceptance:

- Free users see business profile access only.
- Basic users see documents and business profile.
- Premium users see documents, business profile, CRM, and ERP.
- Backend 403 states are handled cleanly.

## Phase 5: Document Engine and Invoice Module

Status: `In progress`

Goal: build the shared document foundation and complete invoices first.

Tasks:

- Shared document list widgets. Implemented.
- Shared document form sections. Implemented as generic field-driven forms.
- Shared item row editor.
- Shared totals calculator matching PFED field behavior.
- Shared backend preview WebView. Queued.
- Shared PDF download/share/open. PDF open/share implemented for download endpoints.
- Invoice list/create/detail/edit/delete. Implemented through shared resource workspace.
- Invoice logo/signature upload.
- Invoice business profile/CRM/ERP helper hooks.

Primary endpoints:

- `/api/invoices/`
- `/api/invoices/create/`
- `/api/invoices/<public_id>/`
- `/api/invoices/<public_id>/partial-update/`
- `/api/invoices/<public_id>/delete/`
- `/api/invoices/<public_id>/preview/`
- `/api/invoices/<public_id>/download/`
- `/api/invoices/<public_id>/generate-pdf/`

Acceptance:

- Mobile-created invoices appear on web.
- Web-created invoices appear on mobile.
- Preview and PDF match backend rendering.

## Phase 6: Receipt, Quotation, and Waybill Modules

Status: `In progress`

Goal: complete the remaining core document modules with parity.

Tasks:

- Receipt list/create/detail/edit/delete/download. Implemented through shared resource workspace.
- Quotation list/create/detail/edit/delete/download. Implemented through shared resource workspace.
- Waybill list/create/detail/edit/delete/download. Implemented through shared resource workspace.
- File uploads where supported.
- Local drafts for all three.
- Shared search/filter/sort.
- Integration helper hooks.

Primary endpoints:

- `/api/receipts/`
- `/api/receipts/create/`
- `/api/receipts/<public_id>/`
- `/api/receipts/<public_id>/update/`
- `/api/receipts/<public_id>/delete/`
- `/api/receipts/<public_id>/preview/`
- `/api/receipts/<public_id>/download/`
- `/api/quotations/`
- `/api/quotations/create/`
- `/api/quotations/<public_id>/`
- `/api/quotations/<public_id>/update/`
- `/api/quotations/<public_id>/delete/`
- `/api/quotations/<public_id>/preview/`
- `/api/quotations/<public_id>/download/`
- `/api/waybills/`
- `/api/waybills/create/`
- `/api/waybills/<public_id>/`
- `/api/waybills/<public_id>/update/`
- `/api/waybills/<public_id>/delete/`
- `/api/waybills/<public_id>/preview/`
- `/api/waybills/<public_id>/download/`

Acceptance:

- All four core document types share records with web.
- All PDF downloads open and share natively.
- Required field validation matches backend expectations.

## Phase 7: Letterhead and Letter Writer

Status: `In progress`

Goal: complete document parity beyond invoices, receipts, quotations, and waybills.

Tasks:

- Letterhead asset CRUD. Implemented through shared resource workspace.
- Letterhead image/PDF upload.
- Template list.
- Letter document CRUD. Implemented through shared resource workspace.
- Letter duplicate.
- Mobile-friendly editor.
- Preview and PDF download/share.

Primary endpoints:

- `/api/letterhead/create/`
- `/api/letterhead/`
- `/api/letterhead/<public_id>/update/`
- `/api/letterhead/<public_id>/delete/`
- `/api/letterhead/templates/`
- `/api/letters/`
- `/api/letters/create/`
- `/api/letters/<public_id>/`
- `/api/letters/<public_id>/update/`
- `/api/letters/<public_id>/delete/`
- `/api/letters/<public_id>/duplicate/`
- `/api/letters/<public_id>/preview/`
- `/api/letters/<public_id>/download/`
- `/api/letters/<public_id>/generate-pdf/`

Acceptance:

- Mobile and web letter records are shared.
- Uploaded letterhead assets render in preview/PDF.

## Phase 8: Business Profile and Directory

Status: `In progress`

Goal: support the free business profile module on mobile.

Tasks:

- Business profile CRUD. Implemented through shared resource workspace.
- Country/category selectors.
- Publish/unpublish.
- Verification submission.
- Public profile view.
- Directory search.
- Document branding defaults.
- Logo, cover, and media upload support where backend supports it.

Primary endpoints:

- `/api/directory/countries/`
- `/api/v1/business-profile/`
- `/api/v1/business-profile/<public_id>/`
- `/api/v1/business-profile/<public_id>/publish/`
- `/api/v1/business-profile/<public_id>/unpublish/`
- `/api/v1/business-profile/<public_id>/submit-verification/`
- `/api/v1/business-profile/<public_id>/document-branding-defaults/`
- `/api/v1/business-profile/public/<slug>/`
- `/api/v1/business-profile/directory/`
- `/api/v1/business-profile/categories/`

Acceptance:

- Business profile changes sync with web.
- Published profile can be opened from public API.
- Document defaults can be applied to invoice/quotation forms.

## Phase 9: CRM

Status: `In progress`

Goal: Premium CRM users can manage sales data on mobile.

Tasks:

- Leads CRUD. Implemented through shared resource workspace.
- Contacts CRUD. Implemented through shared resource workspace.
- Companies CRUD. Implemented through shared resource workspace.
- Opportunities CRUD. Implemented through shared resource workspace.
- Activities CRUD. Implemented through shared resource workspace.
- CRM-to-document prefill.
- Save document customer to CRM.

Primary endpoints:

- `/api/v1/crm/leads/`
- `/api/v1/crm/contacts/`
- `/api/v1/crm/companies/`
- `/api/v1/crm/opportunities/`
- `/api/v1/crm/activities/`
- `/api/v1/crm/helpers/quotation-payload/`
- `/api/v1/crm/helpers/save-document-customer/`

Acceptance:

- CRM is blocked for non-Premium users.
- CRM records sync between mobile and web.
- CRM helper payloads can prefill documents.

## Phase 10: ERP

Status: `In progress`

Goal: Premium ERP users can manage operations data on mobile.

Tasks:

- Products CRUD. Implemented through shared resource workspace.
- Services CRUD. Implemented through shared resource workspace.
- Customers CRUD. Implemented through shared resource workspace.
- Orders CRUD. Implemented through shared resource workspace.
- Procurements CRUD. Implemented through shared resource workspace.
- Deliveries CRUD. Implemented through shared resource workspace.
- ERP item-to-document helper.
- Order-to-invoice helper.
- Delivery-to-waybill helper.
- Save customer to ERP integration.

Primary endpoints:

- `/api/v1/erp/products/`
- `/api/v1/erp/services/`
- `/api/v1/erp/customers/`
- `/api/v1/erp/orders/`
- `/api/v1/erp/procurements/`
- `/api/v1/erp/deliveries/`
- `/api/v1/erp/helpers/document-item-payload/`
- `/api/v1/erp/helpers/orders/<public_id>/invoice-payload/`
- `/api/v1/erp/helpers/deliveries/<public_id>/waybill-payload/`
- `/api/v1/integrations/documents/save-customer-to-erp/`

Acceptance:

- ERP is blocked for non-Premium users.
- ERP records sync between mobile and web.
- ERP helper payloads can prefill documents.

## Phase 11: Offline Drafts, Sync Polish, and Mobile UX Hardening

Status: `In progress`

Goal: make the app reliable in real mobile conditions.

Tasks:

- Offline draft autosave for long forms. Core LocalStore is in place; per-editor queues are next.
- Draft recovery.
- Conflict-safe editing when server data changed.
- Pull-to-refresh.
- Cached list states.
- Global search.
- Recent documents.
- Quick create menu.
- Deep links for billing returns.
- Native file share/open/download polish.

Acceptance:

- Users can start a draft offline and save when online.
- Users can recover interrupted document edits.
- Downloaded PDFs have correct filenames and can be shared.

## Phase 12: QA, Release Builds, and Launch

Status: `In progress`

Goal: prepare for app store submission and production launch.

Tasks:

- Unit tests for API clients and mappers.
- Widget tests for key forms and gates.
- Integration tests for auth, billing, and documents.
- Android release config. Checklist screen added.
- iOS release config. Checklist screen added.
- App icon.
- Splash assets.
- Privacy policy and terms links.
- Runtime permissions.
- Production environment build.
- Store screenshots and metadata.

Acceptance:

- `flutter analyze` passes.
- `flutter test` passes.
- Android AAB builds successfully.
- iOS archive builds successfully on macOS.
- Critical web workflows pass on mobile.

## First Development Sprint

Start with Phase 0 and Phase 1.

Sprint deliverables:

- Fresh Flutter scaffold.
- Source audit notes from backend and PFED.
- App shell with Topwebsuite theme.
- API client.
- Secure/local storage.
- Router and splash/login placeholders.
- Reusable UI foundation.

Sprint exit criteria:

- App runs on Android emulator or device.
- Public backend health/API calls work.
- Codebase structure is ready for auth implementation.
