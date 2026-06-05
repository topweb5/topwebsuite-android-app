import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';
import 'widgets/public_auth_chrome.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _termsAccepted = false;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _message = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width <= 768;

    return PublicAuthScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: mobile ? 40 : 30,
        ),
        child: WebAuthCard(
          maxWidth: 700,
          padding: EdgeInsets.all(mobile ? 35 : 30),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SignupHeader(title: 'Create An Account'),
                  _SignupRow(
                    children: [
                      _LabeledTextField(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _name,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Full name is required'
                            : null,
                      ),
                      _LabeledTextField(
                        label: 'Email Address',
                        hint: 'Enter your email address',
                        controller: _email,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _emailValidator,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SignupRow(
                    children: [
                      _LabeledTextField(
                        label: 'Password',
                        hint: 'Create password',
                        controller: _password,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.next,
                        suffixIcon: _PasswordToggle(
                          visible: _showPassword,
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        validator: _passwordValidator,
                      ),
                      _LabeledTextField(
                        label: 'Confirm Password',
                        hint: 'Confirm password',
                        controller: _confirmPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        obscureText: !_showConfirmPassword,
                        textInputAction: TextInputAction.done,
                        suffixIcon: _PasswordToggle(
                          visible: _showConfirmPassword,
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                        ),
                        validator: _confirmPasswordValidator,
                        onFieldSubmitted: (_) => _loading ? null : _submit(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _TermsCheckbox(
                    value: _termsAccepted,
                    onChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                    showError: !_termsAccepted && _message.isNotEmpty,
                  ),
                  const SizedBox(height: 20),
                  WebPrimaryButton(
                    label: _loading ? 'Creating Account...' : 'Create Account',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(
                        color: TopwebsuiteTheme.text,
                        fontSize: 14,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: InkWell(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFF3C68E6),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
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
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.title, this.subtext});

  final String title;
  final String? subtext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TopwebsuiteTheme.text,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 8),
            Text(
              subtext!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignupRow extends StatelessWidget {
  const _SignupRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 560) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index += 1) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: 20),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: children.first),
            const SizedBox(width: 20),
            Expanded(child: children.last),
          ],
        );
      },
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WebFieldLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 14),
          decoration: webInputDecoration(hint, suffixIcon: suffixIcon),
        ),
      ],
    );
  }
}

class _PasswordToggle extends StatelessWidget {
  const _PasswordToggle({required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      color: const Color(0xFF888888),
      icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
      tooltip: visible ? 'Hide password' : 'Show password',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(value: value, onChanged: onChanged),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                const TextSpan(
                  text: 'I agree to the ',
                  children: [
                    TextSpan(
                      text: 'Terms',
                      style: TextStyle(color: Color(0xFF3C68E6)),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(color: Color(0xFF3C68E6)),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          const Text(
            'You must agree to the terms and privacy policy',
            style: TextStyle(color: Color(0xFFD93025), fontSize: 13),
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
    final mobile = MediaQuery.sizeOf(context).width <= 576;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: EdgeInsets.fromLTRB(30, mobile ? 42 : 30, 30, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(mobile ? 16 : 18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 60,
                offset: Offset(0, 25),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -16,
                child: IconButton.filled(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF222222),
                    fixedSize: const Size(38, 38),
                  ),
                  icon: const Icon(Icons.close),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SignupHeader(
                    title: 'Verify OTP',
                    subtext: 'Enter the OTP sent to your email address.',
                  ),
                  const WebFieldLabel('Email Address'),
                  TextField(
                    controller: _email,
                    readOnly: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: webInputDecoration('Enter your email address'),
                  ),
                  const SizedBox(height: 20),
                  const WebFieldLabel('OTP Code'),
                  TextField(
                    controller: _otp,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: const TextStyle(fontSize: 14),
                    decoration: webInputDecoration('Enter OTP code'),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  WebPrimaryButton(
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
                        foregroundColor: const Color(0xFF3C68E6),
                        side: const BorderSide(color: Color(0xFF3C68E6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: Text(_resending ? 'Sending...' : 'Resend OTP'),
                    ),
                  ),
                ],
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
