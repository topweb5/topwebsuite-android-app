# Topwebsuite Mobile Implementation Audit

## Source Of Truth

- Backend: `C:\Users\user\Desktop\topwebsuite`
- Web/PFED: `C:\Users\user\Desktop\topwebsuite PFED`

The old/free mobile app is intentionally excluded.

## Backend Base URLs

- Production: `https://web-production-4266f.up.railway.app`
- Local: `http://127.0.0.1:8000`

## PFED Behavior Confirmed

PFED stores:

- `access_token`
- `refresh_token`
- `user`
- cached billing/subscription context in app shell flows

Mobile equivalent:

- Store access/refresh tokens in secure storage.
- Store non-sensitive cache/drafts in shared preferences first, then migrate to a database when offline sync grows.

## Phase 0 Endpoint Groups

### Auth

- `POST /api/auth/signup`
- `POST /api/auth/verify-email-otp`
- `POST /api/auth/resend-email-otp`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `GET /api/auth/me/`
- `POST /api/auth/logout`
- `GET /api/auth/usage/`
- `POST /api/auth/forgot-password/`
- `POST /api/auth/reset-password/`
- `POST /api/auth/change-password/`

### Account

- `GET/PATCH /api/account/profile/`
- `POST /api/account/email-change/request/`
- `POST /api/account/email-change/verify/`
- `GET/PATCH /api/account/settings/`
- `GET/PATCH /api/account/document-settings/`
- `GET/PATCH /api/account/branding/`
- `GET/PATCH /api/account/notification-settings/`

### Billing

- `GET /api/billing/context/`
- `GET /api/billing/plans/`
- `GET /api/billing/subscription/`
- `POST /api/billing/checkout/`
- `GET /api/billing/verify-payment/`
- `POST /api/billing/cancel/`
- `GET /api/billing/invoices/`
- `GET /api/billing/invoices/<id>/download/`

### Documents

- `GET /api/currencies/`
- invoices, quotations, receipts, waybills CRUD
- backend HTML preview endpoints
- backend PDF download/generate endpoints
- letterhead and letter document endpoints

### Business Profile

- `/api/v1/business-profile/`
- publish/unpublish/verification
- public detail/directory/categories
- document branding defaults

### CRM, ERP, Integrations

- `/api/v1/crm/*`
- `/api/v1/erp/*`
- `/api/v1/integrations/*`

## Initial Mobile Implementation Decision

Build native Flutter screens for data entry and management. Use WebView only for:

- backend HTML document previews
- Flutterwave checkout flow
- public profile preview if native parity would delay launch

Use backend PDF endpoints for document exports so web and mobile output remain identical.
