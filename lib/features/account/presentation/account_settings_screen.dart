import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';

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
      'Profile': unwrapData(results[0]),
      'Preferences': unwrapData(results[1]),
      'Documents': unwrapData(results[2]),
      'Branding': unwrapData(results[3]),
      'Notifications': unwrapData(results[4]),
    };
  },
);

class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(accountBundleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account and Settings')),
      body: bundle.when(
        data: (groups) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(accountBundleProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in groups.entries)
                _SettingsSection(title: entry.key, values: entry.value),
            ],
          ),
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final entry in values.entries.take(14))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key.replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${entry.value ?? ''}',
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: () => _openEditor(context, title, values),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    String title,
    Map<String, dynamic> values,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _SettingsEditor(title: title, values: values),
    );
  }
}

class _SettingsEditor extends ConsumerStatefulWidget {
  const _SettingsEditor({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;

  @override
  ConsumerState<_SettingsEditor> createState() => _SettingsEditorState();
}

class _SettingsEditorState extends ConsumerState<_SettingsEditor> {
  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;

  static const editableFields = {
    'Profile': ['full_name', 'phone', 'country', 'timezone', 'role_title'],
    'Preferences': [
      'default_currency',
      'date_format',
      'timezone',
      'number_format',
      'default_language',
      'billing_country',
      'billing_currency',
    ],
    'Documents': [
      'invoice_prefix',
      'quotation_prefix',
      'receipt_prefix',
      'waybill_prefix',
      'pdf_paper_size',
      'default_payment_details',
      'default_invoice_note',
      'default_receipt_note',
      'default_payment_method',
      'default_terms_and_conditions',
    ],
    'Branding': ['brand_color', 'footer_note', 'signature_text'],
    'Notifications': [
      'invoice_viewed_email',
      'payment_received_email',
      'subscription_renewal_email',
      'usage_limit_email',
      'product_updates_email',
    ],
  };

  static const endpoints = {
    'Profile': '/api/account/profile/',
    'Preferences': '/api/account/settings/',
    'Documents': '/api/account/document-settings/',
    'Branding': '/api/account/branding/',
    'Notifications': '/api/account/notification-settings/',
  };

  @override
  void initState() {
    super.initState();
    final fields = editableFields[widget.title] ?? const <String>[];
    _controllers = {
      for (final field in fields)
        field: TextEditingController(
          text: widget.values[field]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      builder: (context, scrollController) => Material(
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Edit ${widget.title}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final entry in _controllers.entries) ...[
              TextField(
                controller: entry.value,
                minLines: _isLongField(entry.key) ? 3 : 1,
                maxLines: _isLongField(entry.key) ? 5 : 1,
                decoration: InputDecoration(
                  labelText: entry.key.replaceAll('_', ' '),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isLongField(String key) {
    return key.contains('note') ||
        key.contains('terms') ||
        key.contains('details') ||
        key == 'footer_note';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final endpoint = endpoints[widget.title]!;
    final payload = <String, dynamic>{};
    for (final entry in _controllers.entries) {
      final original = widget.values[entry.key];
      final text = entry.value.text.trim();
      if (original is bool) {
        payload[entry.key] = text.toLowerCase() == 'true' || text == '1';
      } else {
        payload[entry.key] = text;
      }
    }

    try {
      await ref.read(apiClientProvider).patchMap(endpoint, payload);
      ref.invalidate(accountBundleProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
