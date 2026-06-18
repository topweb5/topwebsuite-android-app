import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import '../../auth/application/auth_controller.dart';

// ── Data ───────────────────────────────────────────────────────────────────────

final accountBundleProvider = FutureProvider<Map<String, Map<String, dynamic>>>(
  (ref) async {
    final api = ref.watch(apiClientProvider);
    final results = await Future.wait([
      api.getMap('/api/account/profile/'),
      api.getMap('/api/account/settings/'),
      api.getMap('/api/account/document-settings/'),
      api.getMap('/api/account/branding/'),
      api.getMap('/api/account/notification-settings/'),
    ]);
    return {
      'profile': unwrapData(results[0]),
      'settings': unwrapData(results[1]),
      'documents': unwrapData(results[2]),
      'branding': unwrapData(results[3]),
      'notifications': unwrapData(results[4]),
    };
  },
);

// ── Screen ───────────────────────────────────────────────────────────────────

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(accountBundleProvider);
    return Scaffold(
      backgroundColor: TopwebsuiteTheme.surface,
      body: bundle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(accountBundleProvider),
        ),
        data: (groups) => RefreshIndicator(
          color: TopwebsuiteTheme.primary,
          onRefresh: () async => ref.invalidate(accountBundleProvider),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _ProfileHero(profile: groups['profile']!),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                child: Column(
                  children: [
                    _ProfileSection(initial: groups['profile']!),
                    const SizedBox(height: 14),
                    const _SecuritySection(),
                    const SizedBox(height: 14),
                    _PreferencesSection(initial: groups['settings']!),
                    const SizedBox(height: 14),
                    _DocumentsSection(initial: groups['documents']!),
                    const SizedBox(height: 14),
                    _BrandingSection(initial: groups['branding']!),
                    const SizedBox(height: 14),
                    _NotificationsSection(initial: groups['notifications']!),
                    const SizedBox(height: 18),
                    _LogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero (avatar + identity) ────────────────────────────────────────────────────

class _ProfileHero extends ConsumerStatefulWidget {
  const _ProfileHero({required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<_ProfileHero> createState() => _ProfileHeroState();
}

class _ProfileHeroState extends ConsumerState<_ProfileHero> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final name = _s(widget.profile, 'full_name');
    final email = _s(widget.profile, 'email');
    final avatar = _s(widget.profile, 'avatar');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: TopwebsuiteTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Account & Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              _Avatar(name: name, url: avatar, size: 84),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _uploading ? null : _pickAvatar,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: TopwebsuiteTheme.primary,
                        width: 2,
                      ),
                    ),
                    child: _uploading
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: TopwebsuiteTheme.primary,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'Your account' : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (email.isNotEmpty)
            Text(
              email,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiClientProvider)
          .multipartPatch(
            '/api/account/profile/',
            fields: const {},
            files: {'avatar': picked.path},
          );
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

// ── Profile section ──────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  late final _full = TextEditingController(
    text: _s(widget.initial, 'full_name'),
  );
  late final _phone = TextEditingController(text: _s(widget.initial, 'phone'));
  late final _country = TextEditingController(
    text: _s(widget.initial, 'country'),
  );
  late final _tz = TextEditingController(text: _s(widget.initial, 'timezone'));
  late final _role = TextEditingController(
    text: _s(widget.initial, 'role_title'),
  );
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_full, _phone, _country, _tz, _role]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Profile',
      subtitle: 'Your personal and business identity',
      children: [
        _AccField(label: 'Full name', controller: _full),
        _AccField(
          label: 'Phone',
          controller: _phone,
          keyboard: TextInputType.phone,
        ),
        _AccField(label: 'Country', controller: _country),
        _AccField(
          label: 'Timezone',
          controller: _tz,
          hint: 'e.g. Africa/Lagos',
        ),
        _AccField(label: 'Role title', controller: _role, hint: 'e.g. Owner'),
        _ReadOnlyField(label: 'Email', value: _s(widget.initial, 'email')),
        _SaveBtn(saving: _saving, onTap: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiClientProvider).patchMap('/api/account/profile/', {
        'full_name': _full.text.trim(),
        'phone': _phone.text.trim(),
        'country': _country.text.trim(),
        'timezone': _tz.text.trim(),
        'role_title': _role.text.trim(),
      });
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Security section ────────────────────────────────────────────────────────

class _SecuritySection extends StatelessWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.shield_outlined,
      title: 'Security',
      subtitle: 'Password and sign-in email',
      children: [
        _ActionRow(
          icon: Icons.lock_outline_rounded,
          label: 'Change password',
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const _ChangePasswordDialog(),
          ),
        ),
        _ActionRow(
          icon: Icons.alternate_email_rounded,
          label: 'Change email address',
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const _ChangeEmailDialog(),
          ),
        ),
      ],
    );
  }
}

// ── Preferences section ───────────────────────────────────────────────────────

class _PreferencesSection extends ConsumerStatefulWidget {
  const _PreferencesSection({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_PreferencesSection> createState() =>
      _PreferencesSectionState();
}

class _PreferencesSectionState extends ConsumerState<_PreferencesSection> {
  late String _currency = _s(widget.initial, 'default_currency', 'NGN');
  late String _dateFormat = _s(widget.initial, 'date_format', 'DD/MM/YYYY');
  late String _numberFormat = _s(widget.initial, 'number_format', '1,234.56');
  late String _language = _s(widget.initial, 'default_language', 'en');
  late String _billingCurrency = _s(widget.initial, 'billing_currency');
  late final _tz = TextEditingController(text: _s(widget.initial, 'timezone'));
  late final _billingCountry = TextEditingController(
    text: _s(widget.initial, 'billing_country'),
  );
  bool _saving = false;

  static const _currencies = [
    'NGN',
    'USD',
    'GBP',
    'EUR',
    'GHS',
    'KES',
    'ZAR',
    'CAD',
    'AUD',
    'INR',
  ];

  @override
  void dispose() {
    _tz.dispose();
    _billingCountry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Preferences',
      subtitle: 'Defaults for currency, dates and billing',
      children: [
        _AccDropdown(
          label: 'Default currency',
          value: _currency,
          options: _ensure(_currencies, _currency),
          onChanged: (v) => setState(() => _currency = v),
        ),
        _AccDropdown(
          label: 'Date format',
          value: _dateFormat,
          options: const ['DD/MM/YYYY', 'YYYY-MM-DD', 'MM/DD/YYYY'],
          onChanged: (v) => setState(() => _dateFormat = v),
        ),
        _AccDropdown(
          label: 'Number format',
          value: _numberFormat,
          options: const ['1,234.56', '1.234,56'],
          onChanged: (v) => setState(() => _numberFormat = v),
        ),
        _AccDropdown(
          label: 'Language',
          value: _language,
          options: const ['en'],
          onChanged: (v) => setState(() => _language = v),
        ),
        _AccField(
          label: 'Timezone',
          controller: _tz,
          hint: 'e.g. Africa/Lagos',
        ),
        _AccField(label: 'Billing country', controller: _billingCountry),
        _AccDropdown(
          label: 'Billing currency',
          value: _billingCurrency.isEmpty ? '(automatic)' : _billingCurrency,
          options: const ['(automatic)', 'NGN', 'USD', 'GBP', 'EUR'],
          onChanged: (v) =>
              setState(() => _billingCurrency = v == '(automatic)' ? '' : v),
        ),
        _SaveBtn(saving: _saving, onTap: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final body = <String, dynamic>{
        'default_currency': _currency,
        'date_format': _dateFormat,
        'number_format': _numberFormat,
        'default_language': _language,
        'timezone': _tz.text.trim(),
        'billing_country': _billingCountry.text.trim(),
      };
      if (_billingCurrency.isEmpty) {
        body['billing_currency_reset'] = true;
      } else {
        body['billing_currency'] = _billingCurrency;
      }
      await ref
          .read(apiClientProvider)
          .patchMap('/api/account/settings/', body);
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Preferences saved.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Documents section ──────────────────────────────────────────────────────────

class _DocumentsSection extends ConsumerStatefulWidget {
  const _DocumentsSection({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<_DocumentsSection> {
  late final _invoicePrefix = TextEditingController(
    text: _s(widget.initial, 'invoice_prefix'),
  );
  late final _quotationPrefix = TextEditingController(
    text: _s(widget.initial, 'quotation_prefix'),
  );
  late final _receiptPrefix = TextEditingController(
    text: _s(widget.initial, 'receipt_prefix'),
  );
  late final _waybillPrefix = TextEditingController(
    text: _s(widget.initial, 'waybill_prefix'),
  );
  late final _paymentMethod = TextEditingController(
    text: _s(widget.initial, 'default_payment_method'),
  );
  late final _paymentDetails = TextEditingController(
    text: _s(widget.initial, 'default_payment_details'),
  );
  late final _invoiceNote = TextEditingController(
    text: _s(widget.initial, 'default_invoice_note'),
  );
  late final _receiptNote = TextEditingController(
    text: _s(widget.initial, 'default_receipt_note'),
  );
  late final _terms = TextEditingController(
    text: _s(widget.initial, 'default_terms_and_conditions'),
  );
  late String _paper = _s(widget.initial, 'pdf_paper_size', 'A4');
  String? _signaturePath;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _invoicePrefix,
      _quotationPrefix,
      _receiptPrefix,
      _waybillPrefix,
      _paymentMethod,
      _paymentDetails,
      _invoiceNote,
      _receiptNote,
      _terms,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Document defaults',
      subtitle: 'Numbering, notes and signature',
      children: [
        Row(
          children: [
            Expanded(
              child: _AccField(label: 'Invoice #', controller: _invoicePrefix),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccField(
                label: 'Quotation #',
                controller: _quotationPrefix,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _AccField(label: 'Receipt #', controller: _receiptPrefix),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _AccField(label: 'Waybill #', controller: _waybillPrefix),
            ),
          ],
        ),
        _AccDropdown(
          label: 'PDF paper size',
          value: _paper,
          options: const ['A4', 'Letter'],
          onChanged: (v) => setState(() => _paper = v),
        ),
        _AccField(label: 'Default payment method', controller: _paymentMethod),
        _AccField(
          label: 'Default payment details',
          controller: _paymentDetails,
          multiline: true,
        ),
        _AccField(
          label: 'Default invoice note',
          controller: _invoiceNote,
          multiline: true,
        ),
        _AccField(
          label: 'Default receipt note',
          controller: _receiptNote,
          multiline: true,
        ),
        _AccField(
          label: 'Default terms & conditions',
          controller: _terms,
          multiline: true,
        ),
        _ImagePickRow(
          label: 'Default signature image',
          existingUrl: _s(widget.initial, 'default_signature_image'),
          pickedPath: _signaturePath,
          onPick: (p) => setState(() => _signaturePath = p),
        ),
        _SaveBtn(saving: _saving, onTap: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final fields = {
      'invoice_prefix': _invoicePrefix.text.trim(),
      'quotation_prefix': _quotationPrefix.text.trim(),
      'receipt_prefix': _receiptPrefix.text.trim(),
      'waybill_prefix': _waybillPrefix.text.trim(),
      'pdf_paper_size': _paper,
      'default_payment_method': _paymentMethod.text.trim(),
      'default_payment_details': _paymentDetails.text.trim(),
      'default_invoice_note': _invoiceNote.text.trim(),
      'default_receipt_note': _receiptNote.text.trim(),
      'default_terms_and_conditions': _terms.text.trim(),
    };
    try {
      final api = ref.read(apiClientProvider);
      if (_signaturePath != null) {
        await api.multipartPatch(
          '/api/account/document-settings/',
          fields: fields,
          files: {'default_signature_image': _signaturePath!},
        );
      } else {
        await api.patchMap('/api/account/document-settings/', fields);
      }
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Document defaults saved.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Branding section ──────────────────────────────────────────────────────────

class _BrandingSection extends ConsumerStatefulWidget {
  const _BrandingSection({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends ConsumerState<_BrandingSection> {
  late String _brandColor = _s(widget.initial, 'brand_color', '#0274ff');
  late final _footer = TextEditingController(
    text: _s(widget.initial, 'footer_note'),
  );
  late final _signText = TextEditingController(
    text: _s(widget.initial, 'signature_text'),
  );
  String? _logoPath;
  String? _signaturePath;
  bool _saving = false;

  @override
  void dispose() {
    _footer.dispose();
    _signText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.palette_outlined,
      title: 'Branding',
      subtitle: 'Logo, brand color and signature',
      children: [
        _ColorRow(
          hex: _brandColor,
          onPick: (hex) => setState(() => _brandColor = hex),
        ),
        _ImagePickRow(
          label: 'Business logo',
          existingUrl: _s(widget.initial, 'business_logo'),
          pickedPath: _logoPath,
          onPick: (p) => setState(() => _logoPath = p),
        ),
        _AccField(label: 'Footer note', controller: _footer, multiline: true),
        _AccField(label: 'Signature text', controller: _signText),
        _ImagePickRow(
          label: 'Signature image',
          existingUrl: _s(widget.initial, 'signature_image'),
          pickedPath: _signaturePath,
          onPick: (p) => setState(() => _signaturePath = p),
        ),
        _SaveBtn(saving: _saving, onTap: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final fields = {
      'brand_color': _brandColor,
      'footer_note': _footer.text.trim(),
      'signature_text': _signText.text.trim(),
    };
    final files = <String, String>{
      if (_logoPath != null) 'business_logo': _logoPath!,
      if (_signaturePath != null) 'signature_image': _signaturePath!,
    };
    try {
      final api = ref.read(apiClientProvider);
      if (files.isNotEmpty) {
        await api.multipartPatch(
          '/api/account/branding/',
          fields: fields,
          files: files,
        );
      } else {
        await api.patchMap('/api/account/branding/', fields);
      }
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(const SnackBar(content: Text('Branding saved.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Notifications section ───────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection({required this.initial});
  final Map<String, dynamic> initial;

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  late final Map<String, bool> _values = {
    for (final k in _labels.keys) k: widget.initial[k] == true,
  };
  bool _saving = false;

  static const _labels = {
    'invoice_viewed_email': 'Invoice viewed',
    'payment_received_email': 'Payment received',
    'subscription_renewal_email': 'Subscription renewal',
    'usage_limit_email': 'Usage limit alerts',
    'product_updates_email': 'Product updates',
  };

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.notifications_none_rounded,
      title: 'Email notifications',
      subtitle: 'Choose what we email you about',
      children: [
        for (final entry in _labels.entries)
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeThumbColor: TopwebsuiteTheme.primary,
            title: Text(
              entry.value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            value: _values[entry.key] ?? false,
            onChanged: (v) => setState(() => _values[entry.key] = v),
          ),
        _SaveBtn(saving: _saving, onTap: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiClientProvider)
          .patchMap('/api/account/notification-settings/', _values);
      ref.invalidate(accountBundleProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Notification settings saved.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Change password dialog ───────────────────────────────────────────────────

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Change password',
      children: [
        _AccField(
          label: 'Current password',
          controller: _current,
          obscure: true,
        ),
        _AccField(label: 'New password', controller: _next, obscure: true),
        if (_error.isNotEmpty) _ErrorText(_error),
        _SaveBtn(saving: _busy, label: 'Update password', onTap: _submit),
      ],
    );
  }

  Future<void> _submit() async {
    if (_current.text.isEmpty || _next.text.length < 6) {
      setState(() => _error = 'Enter current password and a 6+ char new one.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiClientProvider).postMap('/api/auth/change-password/', {
        'current_password': _current.text,
        'new_password': _next.text,
      });
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ── Change email dialog (request + verify) ────────────────────────────────────

class _ChangeEmailDialog extends ConsumerStatefulWidget {
  const _ChangeEmailDialog();

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'Change email',
      children: [
        _AccField(
          label: 'New email address',
          controller: _email,
          keyboard: TextInputType.emailAddress,
        ),
        if (_otpSent)
          _AccField(
            label: 'OTP sent to new email',
            controller: _otp,
            keyboard: TextInputType.number,
          ),
        if (_error.isNotEmpty) _ErrorText(_error),
        _SaveBtn(
          saving: _busy,
          label: _otpSent ? 'Verify & update' : 'Send OTP',
          onTap: _otpSent ? _verify : _request,
        ),
      ],
    );
  }

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await ref.read(apiClientProvider).postMap(
        '/api/account/email-change/request/',
        {'new_email': _email.text.trim()},
      );
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiClientProvider).postMap(
        '/api/account/email-change/verify/',
        {'new_email': _email.text.trim(), 'otp': _otp.text.trim()},
      );
      ref.invalidate(accountBundleProvider);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Email updated.')));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ── Logout ───────────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: TopwebsuiteTheme.danger,
          side: BorderSide(
            color: TopwebsuiteTheme.danger.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Shared building blocks ─────────────────────────────────────────────────────

String _s(Map<String, dynamic> m, String key, [String fallback = '']) {
  final v = m[key];
  return (v == null || v.toString() == 'null') ? fallback : v.toString();
}

List<String> _ensure(List<String> options, String value) =>
    (value.isEmpty || options.contains(value)) ? options : [value, ...options];

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TopwebsuiteTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06014EE0),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TopwebsuiteTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: TopwebsuiteTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TopwebsuiteTheme.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TopwebsuiteTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _AccField extends StatelessWidget {
  const _AccField({
    required this.label,
    required this.controller,
    this.keyboard,
    this.multiline = false,
    this.obscure = false,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final bool multiline;
  final bool obscure;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        maxLines: multiline ? 3 : 1,
        style: const TextStyle(fontSize: 14, color: TopwebsuiteTheme.ink),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: TopwebsuiteTheme.muted,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: _border(TopwebsuiteTheme.border),
          enabledBorder: _border(TopwebsuiteTheme.border),
          focusedBorder: _border(TopwebsuiteTheme.primary, 1.5),
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color c, [double w = 1.2]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: TopwebsuiteTheme.muted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TopwebsuiteTheme.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccDropdown extends StatelessWidget {
  const _AccDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: TopwebsuiteTheme.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: TopwebsuiteTheme.muted,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: _AccField._border(TopwebsuiteTheme.border),
          enabledBorder: _AccField._border(TopwebsuiteTheme.border),
          focusedBorder: _AccField._border(TopwebsuiteTheme.primary, 1.5),
        ),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ImagePickRow extends StatelessWidget {
  const _ImagePickRow({
    required this.label,
    required this.existingUrl,
    required this.pickedPath,
    required this.onPick,
  });

  final String label;
  final String existingUrl;
  final String? pickedPath;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final hasPicked = pickedPath != null;
    final hasExisting = existingUrl.isNotEmpty;
    final caption = hasPicked
        ? 'New image selected'
        : (hasExisting
              ? 'Image set — tap to replace'
              : 'Tap to upload (JPG/PNG)');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
          if (picked != null) onPick(picked.path);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasPicked
                  ? TopwebsuiteTheme.primary
                  : TopwebsuiteTheme.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasPicked ? Icons.check_circle_rounded : Icons.image_outlined,
                size: 20,
                color: hasPicked
                    ? TopwebsuiteTheme.success
                    : TopwebsuiteTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TopwebsuiteTheme.ink,
                      ),
                    ),
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 11,
                        color: TopwebsuiteTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.hex, required this.onPick});
  final String hex;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hexToColor(hex),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TopwebsuiteTheme.border),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Brand color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TopwebsuiteTheme.ink,
                  ),
                ),
                Text(
                  hex,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TopwebsuiteTheme.muted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _openPicker(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: TopwebsuiteTheme.primary,
              side: const BorderSide(color: TopwebsuiteTheme.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Pick'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    var selected = _hexToColor(hex);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brand color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select'),
          ),
        ],
      ),
    );
    if (confirmed == true) onPick(_colorToHex(selected));
  }
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({
    required this.saving,
    required this.onTap,
    this.label = 'Save',
  });
  final bool saving;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: saving ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: TopwebsuiteTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(label),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: TopwebsuiteTheme.primary),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TopwebsuiteTheme.ink,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: TopwebsuiteTheme.muted,
      ),
      onTap: onTap,
    );
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        style: const TextStyle(
          color: TopwebsuiteTheme.danger,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.url, required this.size});
  final String name;
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'U'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: url.isEmpty
            ? null
            : DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url.isNotEmpty
          ? null
          : Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.primary,
              ),
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: TopwebsuiteTheme.muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TopwebsuiteTheme.muted),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Color _hexToColor(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return TopwebsuiteTheme.primary;
  return Color(int.tryParse(h, radix: 16) ?? 0xFF014EE0);
}

String _colorToHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
