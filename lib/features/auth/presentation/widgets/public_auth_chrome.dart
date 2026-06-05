import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/app_logo.dart';

const _pfedBlue = Color(0xFF3C68E6);
const _pfedHeaderBlue = Color(0xFF2F68E6);
const _pfedBody = Color(0xFFF7F9FC);
const _pfedLine = Color(0xFFE9EDF7);
const _pfedMuted = Color(0xFF5B6475);

class PublicAuthScaffold extends StatelessWidget {
  const PublicAuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth <= 768) return const SizedBox.shrink();
                return const _TopAlertBar();
              },
            ),
            const _PublicHeader(),
            Expanded(
              child: ColoredBox(
                color: _pfedBody,
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebAuthCard extends StatelessWidget {
  const WebAuthCard({
    super.key,
    required this.maxWidth,
    required this.child,
    this.padding,
  });

  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding ?? const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 40,
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class WebFieldLabel extends StatelessWidget {
  const WebFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: TopwebsuiteTheme.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class WebPrimaryButton extends StatelessWidget {
  const WebPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pfedBlue,
          disabledBackgroundColor: _pfedBlue.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

InputDecoration webInputDecoration(String hint, {Widget? suffixIcon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _pfedBlue),
    ),
  );
}

class _TopAlertBar extends StatelessWidget {
  const _TopAlertBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0274D8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Generate professional ',
                      children: [
                        TextSpan(
                          text: 'invoice',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'receipt',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ', '),
                        TextSpan(
                          text: 'waybill',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ', and '),
                        TextSpan(
                          text: 'write a letter online',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Start Now',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  const _PublicHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth > 1024;
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, desktop ? 26 : 16, 18, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: SizedBox(
                      height: desktop ? 74 : 68,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => context.go('/login'),
                            borderRadius: BorderRadius.circular(8),
                            child: const AppLogo(compact: true),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Topwebsuite',
                            style: TextStyle(
                              color: _pfedHeaderBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (desktop) ...[
                            const Expanded(child: _DesktopNav()),
                            _HeaderTextButton(
                              label: 'Create Account',
                              onPressed: () => context.go('/signup'),
                            ),
                            const SizedBox(width: 18),
                            Container(
                              width: 1,
                              height: 34,
                              color: const Color(0xFFCFD5DF),
                            ),
                            const SizedBox(width: 18),
                            _HeaderTextButton(
                              label: 'Login',
                              onPressed: () => context.go('/login'),
                            ),
                            const SizedBox(width: 18),
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => context.go('/signup'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pfedHeaderBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Start Free'),
                              ),
                            ),
                          ] else ...[
                            const Spacer(),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.menu),
                              onSelected: (value) => context.go(value),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: '/documents',
                                  child: Text('Create New Document'),
                                ),
                                PopupMenuItem(
                                  value: '/billing',
                                  child: Text('Pricing'),
                                ),
                                PopupMenuItem(
                                  value: '/signup',
                                  child: Text('Create Account'),
                                ),
                                PopupMenuItem(
                                  value: '/login',
                                  child: Text('Login'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    height: 1,
                    color: _pfedLine,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopNav extends StatelessWidget {
  const _DesktopNav();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavLabel('Create New'),
        SizedBox(width: 30),
        _NavLabel('Solutions'),
        SizedBox(width: 30),
        _NavLabel('Resources'),
        SizedBox(width: 30),
        _NavLabel('Pricing'),
      ],
    );
  }
}

class _NavLabel extends StatelessWidget {
  const _NavLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _pfedMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _HeaderTextButton extends StatelessWidget {
  const _HeaderTextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF111111),
        padding: EdgeInsets.zero,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
