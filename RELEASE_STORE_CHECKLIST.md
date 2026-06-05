# Topwebsuite Mobile Release And Store Checklist

## Android

- Set final `applicationId` in `android/app/build.gradle.kts`.
- Configure app signing for release builds.
- Replace launcher icons.
- Replace splash assets.
- Confirm Internet permission is present.
- Add photo/media/file permissions needed by `image_picker` and `file_picker`.
- Build AAB with `flutter build appbundle --release`.
- Test installable APK with `flutter build apk --release`.

## iOS

- Set final bundle identifier in Xcode.
- Set display name to `Topwebsuite`.
- Configure Apple development team and signing.
- Add privacy strings for photo library and file access.
- Archive from macOS/Xcode.

## Store Content

- App name: `Topwebsuite`
- Short description: business documents, billing, CRM, ERP, and business profiles.
- Privacy policy URL.
- Terms of service URL.
- Support email.
- Screenshots for login, dashboard, documents, billing, business profile, CRM, and ERP.

## Production QA

- Login/signup/OTP.
- Password reset.
- Subscription and billing access gates.
- Flutterwave checkout and return verification.
- Invoice, receipt, quotation, and waybill create/edit/delete/download/share.
- Letterhead and letter document download.
- Business profile publish/unpublish.
- CRM CRUD.
- ERP CRUD.
- Offline draft recovery.
- Android PDF open/share.
- iOS PDF open/share.
