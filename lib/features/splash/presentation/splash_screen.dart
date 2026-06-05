import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Force status bar icons to light (white) on the blue background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return const Scaffold(
      backgroundColor: Color(0xFF024EE0),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White rounded-square logo card
            _LogoCard(),
            SizedBox(height: 32),
            // App name
            Text(
              'Topwebsuite',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 48),
            // Loading indicator
            _SplashSpinner(),
          ],
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Image.asset(
        'assets/images/topwebsuite-favicon.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SplashSpinner extends StatelessWidget {
  const _SplashSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          Color(0xFFB3D4FF),
        ),
      ),
    );
  }
}
