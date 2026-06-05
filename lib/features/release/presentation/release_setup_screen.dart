import 'package:flutter/material.dart';

class ReleaseSetupScreen extends StatelessWidget {
  const ReleaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      'Set final Android applicationId and signing config',
      'Set iOS bundle identifier, display name, and signing team',
      'Replace launcher icons and splash assets',
      'Add privacy policy, terms, and support URLs',
      'Configure Android/iOS photo, file, and network permissions',
      'Test Flutterwave checkout return links',
      'Build Android AAB',
      'Archive iOS build on macOS',
      'Create store screenshots and descriptions',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Release Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final item in items)
            Card(
              child: CheckboxListTile(
                value: false,
                onChanged: (_) {},
                title: Text(item),
              ),
            ),
        ],
      ),
    );
  }
}
