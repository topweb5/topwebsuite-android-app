import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_controller.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Welcome back',
              subtitle: 'Sign in to continue managing your business documents.',
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
                        label: 'Email Address',
                        hint: 'name@company.com',
                        controller: _email,
                        icon: Icons.mail_outline,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      AuthField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _password,
                        icon: Icons.lock_outline,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            auth.isLoading ? null : _submit(),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Password is required'
                            : null,
                        suffixIcon: AuthPasswordToggle(
                          visible: !_obscure,
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.go('/forgot-password'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_error.isNotEmpty) AuthErrorBanner(message: _error),
                      AuthPrimaryButton(
                        label: 'Sign In',
                        loading: auth.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                      AuthFooterLink(
                        leading: "Don't have an account? ",
                        action: 'Sign up',
                        onTap: () => context.go('/signup'),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = '');
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text.trim(), _password.text.trim());
    if (!mounted) return;
    final result = ref.read(authControllerProvider);
    if (result.hasError) {
      setState(() => _error = result.error.toString());
    }
  }
}
