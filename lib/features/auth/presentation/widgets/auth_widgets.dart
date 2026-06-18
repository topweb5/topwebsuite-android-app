import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';

/// Shared premium building blocks for the public auth screens (login / signup).
/// Keeps a single consistent visual language across the auth flow.

const double _fieldRadius = 14;
const Color _hintColor = Color(0xFF94A3B8);
const Color _fieldFill = Color(0xFFF8FAFD);

/// Curved brand-gradient header with a floating logo badge, title + subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(28, topInset + 36, 28, 40),
      decoration: const BoxDecoration(
        gradient: TopwebsuiteTheme.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LogoBadge(),
          const SizedBox(height: 22),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/topwebsuite-favicon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Labeled, premium text field used across the auth forms.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: TopwebsuiteTheme.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 20, color: TopwebsuiteTheme.muted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: _border(TopwebsuiteTheme.border),
            enabledBorder: _border(TopwebsuiteTheme.border),
            focusedBorder: _border(TopwebsuiteTheme.primary, width: 1.6),
            errorBorder: _border(TopwebsuiteTheme.danger),
            focusedErrorBorder: _border(TopwebsuiteTheme.danger, width: 1.6),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(_fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Toggle button for password visibility.
class AuthPasswordToggle extends StatelessWidget {
  const AuthPasswordToggle({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      color: TopwebsuiteTheme.muted,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      tooltip: visible ? 'Hide password' : 'Show password',
    );
  }
}

/// Full-width gradient primary button with a loading state.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
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
    final enabled = !loading && onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: TopwebsuiteTheme.brandGradient,
          borderRadius: BorderRadius.circular(_fieldRadius),
          boxShadow: [
            BoxShadow(
              color: TopwebsuiteTheme.primary.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_fieldRadius),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 54,
              child: Center(
                child: loading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error banner shown above the submit button.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: TopwebsuiteTheme.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TopwebsuiteTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Don't have an account? Sign up" style footer link.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.leading,
    required this.action,
    required this.onTap,
  });

  final String leading;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leading,
          style: const TextStyle(fontSize: 13.5, color: TopwebsuiteTheme.muted),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
