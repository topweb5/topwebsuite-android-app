# Topwebsuite Flutter Mobile App Launch Roadmap

## Current Workspace Check

The folder `C:\Users\user\Desktop\Topwebsuite Mobile App` is the new mobile app workspace.

Use only these two source projects as references:

- Backend: `C:\Users\user\Desktop\topwebsuite`
- Web frontend: `C:\Users\user\Desktop\topwebsuite PFED`

Do not use or reference `topwebsuite free mobile app`. The Flutter app should be planned and built fresh from the backend API, backend guide, and the working PFED web frontend flows.

## Product Goal

Build a production-ready Flutter mobile app for Topwebsuite that shares the same backend, authentication, subscription access, document data, billing status, and module permissions as the web app.

The mobile app must not be a demo or isolated offline generator. It should be a real mobile client for the existing Topwebsuite SaaS platform, with offline draft support where practical.

## Required Feature Parity

### Public and Account Access

- Splash screen
- Login
- Signup
- Email OTP verification
- Resend OTP
- Forgot password
- Reset password
- JWT access/refresh token handling
- Auto refresh expired access token
- Logout
- Authenticated dashboard
- Profile management
- Email change request and verification
- Change password
- Account settings
- Document settings
- Branding settings
- Notification settings

### Billing and Access Control

- Billing context
- Plan list
- Current subscription
- Usage limit and usage used
- Module access gates from backend `module_access`
- Flutterwave checkout handoff
- Payment verification return flow
- Billing invoice history
- Billing invoice PDF download
- Cancel subscription flow

Module access must match backend behavior:

- Free: business profile access
- Basic: documents and business profile access
- Premium: documents, business profile, CRM, and ERP access

### Documents

Documents must use the backend CRUD and PDF endpoints so records are shared with web.

- Invoices
- Quotations
- Receipts
- Waybills
- Letterhead assets
- Letter documents
- Currency list
- Preview HTML from backend
- PDF download from backend
- Native share/download/print behavior
- Create, list, detail, edit, duplicate where supported, and delete
- File upload support for logos and signatures
- Local draft/autosave before backend save

### Business Profile and Directory

- Business profile list/create/detail/update/delete
- Publish/unpublish
- Submit verification
- Public profile preview
- Directory search
- Categories
- Countries
- Business profile document branding defaults
- Upload logo, cover image, gallery, and media where backend supports it

### CRM

Premium-gated mobile screens for:

- Leads
- Contacts
- Companies
- Opportunities
- Activities
- Quotation/customer helper payloads
- Save document customer to CRM

### ERP

Premium-gated mobile screens for:

- Products
- Services
- Customers
- Orders
- Procurements
- Deliveries
- Product/service document item helpers
- Order to invoice helper
- Delivery to waybill helper
- Save document customer to ERP

### Integrations

- Business profile defaults to document forms
- CRM customer prefill for invoice/quotation
- ERP item prefill for invoice/quotation
- ERP order payload to invoice
- ERP delivery payload to waybill
- Save document customer to ERP

## Flutter Architecture

Use a feature-based architecture:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
    env.dart
  core/
    api/
    auth/
    storage/
    errors/
    widgets/
    utils/
  features/
    auth/
    dashboard/
    billing/
    account/
    documents/
      invoices/
      quotations/
      receipts/
      waybills/
      letters/
      letterheads/
    business_profile/
    crm/
    erp/
    integrations/
    settings/
```

Recommended packages:

- `flutter_riverpod` for state management
- `go_router` for navigation and auth guards
- `dio` for API calls, multipart upload, auth interceptors, and file download
- `flutter_secure_storage` for tokens
- `hive` or `isar` for local drafts and cached lists
- `path_provider` for file paths
- `open_filex` for opening PDFs
- `share_plus` for native sharing
- `printing` only for locally rendered PDFs if needed
- `webview_flutter` for backend HTML previews and Flutterwave checkout
- `image_picker` for logo/signature/media upload
- `file_picker` for letterhead PDF/image upload
- `intl` for dates, currency, and number formatting
- `uuid` for local draft IDs

## Implementation Phases

### Phase 0: Project Intake and Workspace Setup

Outcome: confirmed backend/web references and a clean Flutter app shell.

Tasks:

- Confirm backend source path: `C:\Users\user\Desktop\topwebsuite`.
- Confirm web source path: `C:\Users\user\Desktop\topwebsuite PFED`.
- Scaffold a fresh Flutter project inside `C:\Users\user\Desktop\Topwebsuite Mobile App`.
- Run backend tests.
- Audit PFED web JavaScript and pages for working user flows, field names, payloads, filters, and preview/download behavior.
- Audit `BACKEND_API_GUIDE.md` and backend URL files for canonical endpoints.
- Create app environment config for production and local backend base URLs.
- Set Android package name and iOS bundle identifier.

Acceptance:

- `flutter pub get` passes.
- `flutter analyze` passes on the base app.
- App launches to splash/login.
- Backend API guide and Swagger schema are available.

### Phase 1: Core Mobile Foundation

Outcome: secure, production-grade mobile foundation.

Tasks:

- Implement design system matching Topwebsuite web branding.
- Implement `Dio` API client with JSON, multipart, blob download, and error parsing.
- Implement secure token storage.
- Implement token refresh.
- Implement auth route guards.
- Implement common loading, empty, error, form, list, action sheet, confirmation, and toast widgets.
- Implement local cache/draft storage.
- Add app-wide telemetry/logging hooks for production debugging.

Acceptance:

- API errors show useful messages.
- Expired sessions refresh automatically or return user to login.
- Authenticated routes cannot be opened without token.
- App handles offline state gracefully.

### Phase 2: Authentication and Account

Outcome: mobile users can manage the same account as web.

Tasks:

- Login.
- Signup.
- Verify email OTP.
- Resend OTP.
- Forgot/reset password.
- Logout.
- Profile screen.
- Avatar upload.
- Email change request/verify.
- Change password.
- Account settings.
- Document settings.
- Branding settings.
- Notification settings.

Backend endpoints:

- `/api/auth/signup`
- `/api/auth/verify-email-otp`
- `/api/auth/resend-email-otp`
- `/api/auth/login`
- `/api/auth/refresh`
- `/api/auth/me/`
- `/api/auth/logout`
- `/api/auth/forgot-password/`
- `/api/auth/reset-password/`
- `/api/auth/change-password/`
- `/api/account/profile/`
- `/api/account/email-change/request/`
- `/api/account/email-change/verify/`
- `/api/account/settings/`
- `/api/account/document-settings/`
- `/api/account/branding/`
- `/api/account/notification-settings/`

Acceptance:

- Same credentials work on web and mobile.
- Profile edits appear on web after refresh.
- Branding/document defaults can be used by document forms.

### Phase 3: Dashboard, Billing, and Module Gates

Outcome: mobile app respects the same subscription access as web.

Tasks:

- Build dashboard summary for usage, plan, documents, business profile, CRM, and ERP.
- Load subscription and billing context.
- Display localized plan prices.
- Implement plan upgrade flow using Flutterwave checkout in secure WebView or external browser.
- Handle success/cancel return and verify payment.
- Show billing invoice history and PDF download.
- Gate documents, CRM, and ERP screens using `module_access`.

Backend endpoints:

- `/api/auth/usage/`
- `/api/billing/context/`
- `/api/billing/plans/`
- `/api/billing/subscription/`
- `/api/billing/checkout/`
- `/api/billing/verify-payment/`
- `/api/billing/cancel/`
- `/api/billing/invoices/`
- `/api/billing/invoices/<id>/download/`

Acceptance:

- Free, Basic, and Premium users see correct modules.
- Paid checkout activates the plan after verification.
- Backend remains the authority for access.

### Phase 4: Documents MVP With Backend PDF Parity

Outcome: core document modules work end to end and records are shared with web.

Build in this order:

1. Invoice
2. Receipt
3. Quotation
4. Waybill

Tasks per module:

- List screen with search/filter/sort.
- Create/edit form.
- Local draft autosave.
- Multipart upload for logo/signature where supported.
- Backend save/update/delete.
- Backend preview in WebView using preview HTML endpoint.
- Backend PDF download.
- Native share/open file.
- Integration buttons where available.

Backend endpoints:

- `/api/currencies/`
- `/api/invoices/`
- `/api/invoices/create/`
- `/api/invoices/<public_id>/`
- `/api/invoices/<public_id>/partial-update/`
- `/api/invoices/<public_id>/delete/`
- `/api/invoices/<public_id>/preview/`
- `/api/invoices/<public_id>/download/`
- `/api/invoices/<public_id>/generate-pdf/`
- `/api/quotations/`
- `/api/quotations/create/`
- `/api/quotations/<public_id>/`
- `/api/quotations/<public_id>/update/`
- `/api/quotations/<public_id>/delete/`
- `/api/quotations/<public_id>/preview/`
- `/api/quotations/<public_id>/download/`
- `/api/receipts/`
- `/api/receipts/create/`
- `/api/receipts/<public_id>/`
- `/api/receipts/<public_id>/update/`
- `/api/receipts/<public_id>/delete/`
- `/api/receipts/<public_id>/preview/`
- `/api/receipts/<public_id>/download/`
- `/api/waybills/`
- `/api/waybills/create/`
- `/api/waybills/<public_id>/`
- `/api/waybills/<public_id>/update/`
- `/api/waybills/<public_id>/delete/`
- `/api/waybills/<public_id>/preview/`
- `/api/waybills/<public_id>/download/`

Acceptance:

- A document created on mobile appears on web.
- A document created on web appears on mobile.
- PDF output matches backend/web rendering.
- Logo/signature uploads render in preview and PDF.

### Phase 5: Letterhead and Letter Writer

Outcome: mobile reaches full document parity beyond the four generators.

Tasks:

- Letterhead asset list/create/edit/delete.
- Upload image/PDF letterhead.
- Template list.
- Letter document list/create/edit/delete/duplicate.
- Rich text editing approach for mobile.
- HTML preview in WebView.
- PDF download/share.

Backend endpoints:

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

- Existing web letter documents are editable or at least viewable on mobile.
- Mobile-created letters preview/download correctly on web.

### Phase 6: Business Profile and Directory

Outcome: mobile supports the free business profile module and public directory.

Tasks:

- Business profile CRUD.
- Country/category selectors.
- Logo/cover/gallery upload.
- Publish/unpublish.
- Submit verification.
- Document branding defaults.
- Public profile preview.
- Directory search.

Backend endpoints:

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

- Business profile data is identical between web and mobile.
- Published profiles resolve through public API.

### Phase 7: CRM

Outcome: Premium users can manage CRM from mobile.

Tasks:

- Leads CRUD.
- Contacts CRUD.
- Companies CRUD.
- Opportunities CRUD.
- Activities CRUD.
- CRM-to-document prefill.
- Save document customer to CRM.

Backend endpoints:

- `/api/v1/crm/leads/`
- `/api/v1/crm/contacts/`
- `/api/v1/crm/companies/`
- `/api/v1/crm/opportunities/`
- `/api/v1/crm/activities/`
- `/api/v1/crm/helpers/quotation-payload/`
- `/api/v1/crm/helpers/save-document-customer/`

Acceptance:

- CRM access is blocked for non-Premium users.
- CRM records sync with web.
- CRM helpers can prefill mobile document forms.

### Phase 8: ERP

Outcome: Premium users can manage ERP from mobile.

Tasks:

- Products CRUD.
- Services CRUD.
- Customers CRUD.
- Orders CRUD.
- Procurements CRUD.
- Deliveries CRUD.
- ERP item-to-document helper.
- Order-to-invoice helper.
- Delivery-to-waybill helper.

Backend endpoints:

- `/api/v1/erp/products/`
- `/api/v1/erp/services/`
- `/api/v1/erp/customers/`
- `/api/v1/erp/orders/`
- `/api/v1/erp/procurements/`
- `/api/v1/erp/deliveries/`
- `/api/v1/erp/helpers/document-item-payload/`
- `/api/v1/erp/helpers/orders/<public_id>/invoice-payload/`
- `/api/v1/erp/helpers/deliveries/<public_id>/waybill-payload/`

Acceptance:

- ERP access is blocked for non-Premium users.
- ERP records sync with web.
- ERP helpers can prefill document forms.

### Phase 9: Integration Polish and Offline Drafts

Outcome: the app feels cohesive and reliable in real mobile use.

Tasks:

- Offline draft queue for document forms.
- Conflict-safe edit behavior.
- Pull-to-refresh and cached list states.
- Recent documents.
- Global search.
- Quick create menu.
- Duplicate document flows where backend supports duplication.
- Robust file download naming.
- Native share to WhatsApp/email.
- Deep link handling for billing returns and public profile links.

Acceptance:

- A user can start a document offline, return online, and save it.
- Downloaded PDFs open locally and share correctly.
- Mobile flows are faster than forcing users through desktop-style pages.

### Phase 10: QA, Hardening, and Store Readiness

Outcome: launch-ready Android and iOS app.

Tasks:

- Unit tests for API clients, mappers, validators, and calculations.
- Widget tests for forms and access gates.
- Integration tests for auth, documents, billing, and module access.
- Test against production backend and local backend.
- Test real Flutterwave sandbox/live payment return.
- Test file upload sizes and invalid file formats.
- Test Android PDF download/open/share.
- Test iOS PDF download/open/share.
- Add app icon and splash assets.
- Add privacy policy and terms links.
- Configure Android permissions.
- Configure iOS permissions.
- Build release APK/AAB.
- Build iOS archive.

Acceptance:

- `flutter analyze` passes.
- `flutter test` passes.
- Android release build succeeds.
- iOS release build succeeds on macOS.
- All critical web workflows have mobile equivalents.

## Recommended Build Strategy

Do not build this as a WebView wrapper. Use native Flutter screens for forms, dashboards, lists, settings, CRM, ERP, and business profile. Use WebView only for:

- Backend HTML document previews
- Flutterwave checkout, if external browser is not preferred
- Public profile preview where native rendering would delay launch

Use backend-generated PDFs for the authenticated SaaS documents. This ensures mobile and web exports stay identical.

## Launch Definition of Done

The app is launch-ready only when:

- It uses the same production backend as web.
- Auth and billing access match web.
- Subscription module gates match backend `module_access`.
- Mobile-created data appears on web.
- Web-created data appears on mobile.
- Document previews and PDFs are generated by the backend or match backend output.
- Uploads work for avatar, logos, signatures, letterheads, and business media.
- Offline drafts are available for long forms.
- Release builds are tested on real Android and iOS devices.
- Store metadata, app icons, privacy links, and permissions are complete.

## Immediate Next Steps

1. Use `C:\Users\user\Desktop\topwebsuite` as the backend source of truth.
2. Use `C:\Users\user\Desktop\topwebsuite PFED` as the web/frontend behavior source of truth.
3. Start with Phase 0 and Phase 1, then ship auth/account/billing before document modules.
4. Build document modules using backend APIs first, not local-only PDF logic.
5. Add CRM, ERP, and full business profile after document parity is stable.
