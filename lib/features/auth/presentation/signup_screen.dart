import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../modules/data/reference_data.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _country = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _countryCode;
  bool _termsAccepted = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _message = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _country.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Create your account',
              subtitle:
                  'Start generating professional invoices, receipts and more.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 32),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _name,
                        icon: Icons.person_outline,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        controller: _email,
                        icon: Icons.mail_outline,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _emailValidator,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Country',
                        hint: 'Select your country',
                        controller: _country,
                        icon: Icons.public_outlined,
                        readOnly: true,
                        onTap: _pickCountry,
                        validator: (_) => _countryCode == null
                            ? 'Please select your country'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Password',
                        hint: 'Create a password',
                        controller: _password,
                        icon: Icons.lock_outline,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: AuthPasswordToggle(
                          visible: _showPassword,
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        validator: _passwordValidator,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        controller: _confirmPassword,
                        icon: Icons.lock_outline,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: !_showConfirmPassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: AuthPasswordToggle(
                          visible: _showConfirmPassword,
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                        validator: _confirmPasswordValidator,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                      ),
                      const SizedBox(height: 18),
                      _TermsCheckbox(
                        value: _termsAccepted,
                        onChanged: (value) =>
                            setState(() => _termsAccepted = value ?? false),
                        showError: !_termsAccepted && _message.isNotEmpty,
                      ),
                      const SizedBox(height: 22),
                      if (_message.isNotEmpty)
                        AuthErrorBanner(message: _message),
                      AuthPrimaryButton(
                        label: _loading
                            ? 'Creating Account...'
                            : 'Create Account',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                      AuthFooterLink(
                        leading: 'Already have an account? ',
                        action: 'Login',
                        onTap: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email address is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _message = '');

    final validForm = _formKey.currentState!.validate();
    if (!validForm || !_termsAccepted) {
      setState(() {
        _message = !_termsAccepted
            ? 'You must agree to the terms and privacy policy'
            : '';
      });
      return;
    }

    setState(() => _loading = true);
    final authRepository = ref.read(authRepositoryProvider);
    try {
      await authRepository.signup(
        email: _email.text.trim(),
        fullName: _name.text.trim(),
        password: _password.text.trim(),
        country: _countryCode,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _OtpDialog(email: _email.text.trim()),
      );
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCountry() async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryPickerSheet(),
    );
    if (selected != null) {
      setState(() {
        _countryCode = selected['code']?.toString();
        _country.text = selected['name']?.toString() ?? '';
      });
    }
  }
}

class _CountryPickerSheet extends ConsumerStatefulWidget {
  const _CountryPickerSheet();

  @override
  ConsumerState<_CountryPickerSheet> createState() =>
      _CountryPickerSheetState();
}

class _CountryPickerSheetState extends ConsumerState<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TopwebsuiteTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select your country',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TopwebsuiteTheme.ink,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: TopwebsuiteTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TopwebsuiteTheme.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TopwebsuiteTheme.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TopwebsuiteTheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: countries.when(
                data: (list) {
                  final filtered = list
                      .where(
                        (c) => (c['name']?.toString() ?? '')
                            .toLowerCase()
                            .contains(_query),
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No countries found',
                        style: TextStyle(color: TopwebsuiteTheme.muted),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return ListTile(
                        title: Text(
                          c['name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: TopwebsuiteTheme.ink,
                          ),
                        ),
                        trailing: Text(
                          c['code']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TopwebsuiteTheme.muted,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: TopwebsuiteTheme.primary,
                  ),
                ),
                error: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load countries. Check your connection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TopwebsuiteTheme.muted),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.showError,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: TopwebsuiteTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(
                        color: TopwebsuiteTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: TopwebsuiteTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 13.5, color: TopwebsuiteTheme.muted),
              ),
            ),
          ],
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          const Text(
            'You must agree to the terms and privacy policy',
            style: TextStyle(color: TopwebsuiteTheme.danger, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

class _OtpDialog extends ConsumerStatefulWidget {
  const _OtpDialog({required this.email});

  final String email;

  @override
  ConsumerState<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends ConsumerState<_OtpDialog> {
  late final TextEditingController _email;
  final _otp = TextEditingController();
  bool _verifying = false;
  bool _resending = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(22),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: TopwebsuiteTheme.ink,
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: TopwebsuiteTheme.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the OTP sent to your email address.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: TopwebsuiteTheme.muted,
                ),
              ),
              const SizedBox(height: 24),
              AuthField(
                label: 'Email Address',
                hint: 'Enter your email address',
                controller: _email,
                icon: Icons.mail_outline,
                readOnly: true,
              ),
              const SizedBox(height: 18),
              AuthField(
                label: 'OTP Code',
                hint: 'Enter OTP code',
                controller: _otp,
                icon: Icons.password_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TopwebsuiteTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              AuthPrimaryButton(
                label: _verifying ? 'Verifying...' : 'Verify OTP',
                loading: _verifying,
                onPressed: _verify,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _resending ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TopwebsuiteTheme.primary,
                    side: const BorderSide(color: TopwebsuiteTheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(_resending ? 'Sending...' : 'Resend OTP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    if (_otp.text.trim().isEmpty) {
      setState(() => _message = 'OTP code is required');
      return;
    }
    setState(() {
      _verifying = true;
      _message = '';
    });
    final authRepository = ref.read(authRepositoryProvider);
    final authController = ref.read(authControllerProvider.notifier);
    try {
      final user = await authRepository.verifyEmailOtp(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
      );
      if (!mounted) return;
      authController.setAuthenticatedUser(user);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = '';
    });
    final authRepository = ref.read(authRepositoryProvider);
    try {
      await authRepository.resendOtp(_email.text.trim());
      if (mounted) {
        setState(() => _message = 'OTP resent successfully.');
      }
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }
}
