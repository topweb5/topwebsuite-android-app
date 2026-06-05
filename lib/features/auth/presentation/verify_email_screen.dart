import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_controller.dart';
import '../data/auth_repository.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _otp = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the OTP sent to ${widget.email}.'),
            const SizedBox(height: 16),
            TextField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: Text(_loading ? 'Verifying...' : 'Verify'),
            ),
            TextButton(onPressed: _resend, child: const Text('Resend OTP')),
          ],
        ),
      ),
    );
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(email: widget.email, otp: _otp.text.trim());
      ref.read(authControllerProvider.notifier).setAuthenticatedUser(user);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    await ref.read(authRepositoryProvider).resendOtp(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent.')));
    }
  }
}
