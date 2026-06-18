import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/collapsible_section.dart';
import '../../auth/application/auth_controller.dart';
import 'document_preview_screen.dart';
import 'invoice_form.dart' show currenciesProvider;

// ── Waybill Form Sheet ─────────────────────────────────────────────────────────
//
// Field keys mirror apps/.../Waybill model exactly. The model has no
// `authorized_signature` field, but it is captured here per the agreed waybill
// creation spec and sent as a multipart file; the backend ignores it until the
// field is added server-side. `accent_color` and `company_logo` are real model
// fields. `waybill_number` is auto-generated server-side, so it is never sent.

class WaybillFormSheet extends ConsumerStatefulWidget {
  const WaybillFormSheet({super.key, this.existing});
  final Map<String, dynamic>? existing;

  static Future<bool?> show(
    BuildContext context, {
    Map<String, dynamic>? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WaybillFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WaybillFormSheet> createState() => _WaybillFormState();
}

class _WaybillFormState extends ConsumerState<WaybillFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // SHIPMENT DETAILS
  String _status = 'pending';
  String _currency = 'NGN';
  final _weight = TextEditingController();
  final _shipmentValue = TextEditingController(text: '0.00');
  final _shipmentDescription = TextEditingController();

  // BRANDING
  final _accentColor = TextEditingController(text: '#0274ff');
  XFile? _logoFile;

  // ISSUED BY
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyWebsite = TextEditingController();

  // SENT THROUGH (sender)
  final _senderName = TextEditingController();
  final _senderAddress = TextEditingController();
  final _senderContact = TextEditingController();

  // RECIPIENT
  final _recipientName = TextEditingController();
  final _recipientContact = TextEditingController();
  final _recipientAddress = TextEditingController();

  // APPROVAL
  XFile? _signatureFile;

  // STATE
  bool _saving = false;
  String? _error;

  static const _statuses = [
    ('pending', 'Pending'),
    ('shipped', 'Shipped'),
    ('delivered', 'Delivered'),
  ];

  double get _shipmentValueAmount =>
      double.tryParse(_shipmentValue.text.replaceAll(',', '')) ?? 0.0;

  String get _currencySymbol => switch (_currency) {
    'NGN' => '₦',
    'USD' => '\$',
    'GBP' => '£',
    'EUR' => '€',
    _ => _currency,
  };

  @override
  void initState() {
    super.initState();
    _prefillFromExisting();
    _prefillFromUser();
    _shipmentValue.addListener(() => setState(() {}));
  }

  void _prefillFromExisting() {
    final e = widget.existing;
    if (e == null) return;
    _companyName.text = e['company_name']?.toString() ?? '';
    _companyAddress.text = e['company_address']?.toString() ?? '';
    _companyPhone.text = e['company_phone']?.toString() ?? '';
    _companyEmail.text = e['company_email']?.toString() ?? '';
    _companyWebsite.text = e['company_website']?.toString() ?? '';
    _senderName.text = e['sender_name']?.toString() ?? '';
    _senderAddress.text = e['sender_address']?.toString() ?? '';
    _senderContact.text = e['sender_contact']?.toString() ?? '';
    _recipientName.text = e['recipient_name']?.toString() ?? '';
    _recipientContact.text = e['recipient_contact']?.toString() ?? '';
    _recipientAddress.text = e['recipient_address']?.toString() ?? '';
    _shipmentDescription.text = e['shipment_description']?.toString() ?? '';
    _shipmentValue.text = e['shipment_value']?.toString() ?? '0.00';
    _weight.text = e['weight']?.toString() ?? '';
    _currency = e['currency']?.toString() ?? 'NGN';
    _status = e['status']?.toString() ?? 'pending';
    if ((e['accent_color']?.toString() ?? '').isNotEmpty) {
      _accentColor.text = e['accent_color'].toString();
    }
  }

  void _prefillFromUser() {
    if (widget.existing != null) return;
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    if (_companyName.text.isEmpty) _companyName.text = user.displayName;
    if (_companyEmail.text.isEmpty) _companyEmail.text = user.email;
  }

  @override
  void dispose() {
    for (final c in [
      _weight,
      _shipmentValue,
      _shipmentDescription,
      _accentColor,
      _companyName,
      _companyAddress,
      _companyPhone,
      _companyEmail,
      _companyWebsite,
      _senderName,
      _senderAddress,
      _senderContact,
      _recipientName,
      _recipientContact,
      _recipientAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Color picker ──────────────────────────────────────────────────────────

  Future<void> _showColorPicker() async {
    final current = _parseColor(_accentColor.text);
    Color picked = current;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Brand Color',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [ColorLabelType.hex],
            pickerAreaHeightPercent: 0.7,
            hexInputBar: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: TopwebsuiteTheme.muted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final hex =
                  '#${picked.toARGB32().toRadixString(16).substring(2)}';
              setState(() => _accentColor.text = hex);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TopwebsuiteTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').padLeft(6, '0');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return TopwebsuiteTheme.primary;
    }
  }

  // ── Image picker ──────────────────────────────────────────────────────────

  Future<void> _pickImage(bool isLogo) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() {
        if (isLogo) {
          _logoFile = file;
        } else {
          _signatureFile = file;
        }
      });
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack('Please fill in all required fields', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final id =
          (widget.existing?['public_id']?.toString() ??
                  widget.existing?['id']?.toString() ??
                  '')
              .trim();

      final fields = <String, String>{
        // Issued by (company)
        'company_name': _companyName.text.trim(),
        'company_address': _companyAddress.text.trim(),
        'company_phone': _companyPhone.text.trim(),
        'company_email': _companyEmail.text.trim(),
        'company_website': _companyWebsite.text.trim(),
        // Branding
        'accent_color': _accentColor.text.trim().isEmpty
            ? '#0274ff'
            : _accentColor.text.trim(),
        'currency': _currency,
        // Sent through (sender)
        'sender_name': _senderName.text.trim(),
        'sender_address': _senderAddress.text.trim(),
        'sender_contact': _senderContact.text.trim(),
        // Recipient
        'recipient_name': _recipientName.text.trim(),
        'recipient_address': _recipientAddress.text.trim(),
        'recipient_contact': _recipientContact.text.trim(),
        // Shipment
        'shipment_description': _shipmentDescription.text.trim(),
        'shipment_value': _shipmentValue.text.trim().isEmpty
            ? '0'
            : _shipmentValue.text.trim(),
        'weight': _weight.text.trim().isEmpty ? '0' : _weight.text.trim(),
        'status': _status,
      };

      final files = <String, String>{
        if (_logoFile != null) 'company_logo': _logoFile!.path,
        if (_signatureFile != null)
          'authorized_signature': _signatureFile!.path,
      };

      Map<String, dynamic> result;
      if (id.isEmpty) {
        result = await api.multipartPost(
          '/api/waybills/create/',
          fields: fields,
          files: files,
        );
      } else {
        result = await api.multipartPatch(
          '/api/waybills/$id/update/',
          fields: fields,
          files: files,
        );
      }

      final savedId = result['public_id']?.toString() ?? '';
      if (mounted) {
        final rootNav = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop(true);
        if (savedId.isNotEmpty) {
          rootNav.push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DocumentPreviewScreen(
                title: result['waybill_number']?.toString() ?? 'Waybill',
                previewPath: '/api/waybills/$savedId/preview/',
                downloadPath: '/api/waybills/$savedId/download/',
                docId: savedId,
                docType: 'waybill',
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showSnack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    setState(() => _error = error ? msg : null);
    if (!error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: TopwebsuiteTheme.success),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _WFormHeader(
                title: isEdit ? 'Edit Waybill' : 'Create Waybill',
                onClose: () => Navigator.of(context).pop(false),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: TopwebsuiteTheme.danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: TopwebsuiteTheme.danger,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _error = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: TopwebsuiteTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    CollapsibleSection(
                      title: 'SHIPMENT DETAILS',
                      badge: 'Basic info',
                      child: _buildShipmentDetails(),
                    ),
                    CollapsibleSection(
                      title: 'BRANDING',
                      badge: 'Customize',
                      child: _buildBranding(),
                    ),
                    CollapsibleSection(
                      title: 'ISSUED BY',
                      badge: 'Your business',
                      child: _buildIssuedBy(),
                    ),
                    CollapsibleSection(
                      title: 'SENT THROUGH',
                      badge: 'Transport / sender',
                      child: _buildSentThrough(),
                    ),
                    CollapsibleSection(
                      title: 'RECIPIENT',
                      badge: 'Receiver details',
                      child: _buildRecipient(),
                    ),
                    CollapsibleSection(
                      title: 'APPROVAL',
                      badge: 'Sign-off',
                      child: _buildApproval(),
                    ),
                    _buildValueSummary(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _WFormBottomBar(
                saving: _saving,
                onCancel: () => Navigator.of(context).pop(false),
                onSave: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildShipmentDetails() {
    final currencies = ref.watch(currenciesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Status'),
        const SizedBox(height: 6),
        _WDropdown(
          value: _status,
          items: _statuses,
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: 12),
        _WLabel('Weight (kg)'),
        const SizedBox(height: 6),
        _WField(
          controller: _weight,
          hint: '0.0',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Currency'),
        const SizedBox(height: 6),
        currencies.when(
          data: (list) {
            final options = list.isEmpty
                ? [
                    {'code': 'NGN', 'name': 'Naira'},
                  ]
                : list;
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TopwebsuiteTheme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: options.any((c) => c['code'] == _currency)
                      ? _currency
                      : options.first['code']?.toString(),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 13,
                    color: TopwebsuiteTheme.ink,
                  ),
                  iconEnabledColor: TopwebsuiteTheme.muted,
                  items: options.map((c) {
                    final code = c['code']?.toString() ?? '';
                    final name = c['name']?.toString() ?? '';
                    return DropdownMenuItem(
                      value: code,
                      child: Text(
                        '$code - $name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: TopwebsuiteTheme.ink,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _currency = v ?? _currency),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => _WField(
            controller: TextEditingController(text: _currency),
            hint: 'NGN',
          ),
        ),
        const SizedBox(height: 12),
        _WLabel('Shipment Value'),
        const SizedBox(height: 6),
        _WField(
          controller: _shipmentValue,
          hint: '0.00',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _WLabel('Shipment Description'),
        const SizedBox(height: 6),
        _WField(
          controller: _shipmentDescription,
          hint: 'Describe the goods being shipped',
          maxLines: 3,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Logo'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: TopwebsuiteTheme.border),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFF8FAFB),
            ),
            child: _logoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_logoFile!.path),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 22,
                        color: TopwebsuiteTheme.muted,
                      ),
                      SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Company Logo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TopwebsuiteTheme.ink,
                            ),
                          ),
                          Text(
                            'PNG, JPG or SVG · Max 2 MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: TopwebsuiteTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _WLabel('Brand Color'),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(_accentColor.text),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: TopwebsuiteTheme.border,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.colorize_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WField(
                controller: _accentColor,
                hint: '#0274ff',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIssuedBy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Company Name'),
        const SizedBox(height: 6),
        _WField(
          controller: _companyName,
          hint: 'Your company name',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Address'),
        const SizedBox(height: 6),
        _WField(
          controller: _companyAddress,
          hint: '123 Main Street\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _WLabel('Phone'),
        const SizedBox(height: 6),
        _WField(
          controller: _companyPhone,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _WLabel('Email'),
        const SizedBox(height: 6),
        _WField(
          controller: _companyEmail,
          hint: 'company@email.com',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _WLabel('Website'),
        const SizedBox(height: 6),
        _WField(
          controller: _companyWebsite,
          hint: 'https://yourwebsite.com',
          keyboard: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildSentThrough() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Transport Company Name'),
        const SizedBox(height: 6),
        _WField(
          controller: _senderName,
          hint: 'Courier or transport company',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Address'),
        const SizedBox(height: 6),
        _WField(
          controller: _senderAddress,
          hint: 'Pickup / origin address',
          maxLines: 3,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Contact'),
        const SizedBox(height: 6),
        _WField(
          controller: _senderContact,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildRecipient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Name'),
        const SizedBox(height: 6),
        _WField(
          controller: _recipientName,
          hint: 'Recipient name',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Contact'),
        const SizedBox(height: 6),
        _WField(
          controller: _recipientContact,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _WLabel('Address'),
        const SizedBox(height: 6),
        _WField(
          controller: _recipientAddress,
          hint: 'Delivery / destination address',
          maxLines: 3,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildApproval() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WLabel('Authorized Signature'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pickImage(false),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              border: Border.all(color: TopwebsuiteTheme.border),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: TopwebsuiteTheme.border),
                  ),
                  child: const Text(
                    'Choose file',
                    style: TextStyle(fontSize: 12, color: TopwebsuiteTheme.ink),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _signatureFile == null
                        ? 'No file chosen'
                        : _signatureFile!.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TopwebsuiteTheme.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValueSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TopwebsuiteTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Shipment Value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          Text(
            '$_currencySymbol${_shipmentValueAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Waybill form widgets ───────────────────────────────────────────────

class _WFormHeader extends StatelessWidget {
  const _WFormHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TopwebsuiteTheme.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: TopwebsuiteTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WFormBottomBar extends StatelessWidget {
  const _WFormBottomBar({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TopwebsuiteTheme.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: saving ? null : onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: TopwebsuiteTheme.border),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14, color: TopwebsuiteTheme.ink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                saving ? 'Saving...' : 'Save Waybill',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TopwebsuiteTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WLabel extends StatelessWidget {
  const _WLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: TopwebsuiteTheme.ink,
    ),
  );
}

class _WField extends StatelessWidget {
  const _WField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboard;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboard,
    validator: validator,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
    decoration: InputDecoration(
      // Placeholder/example text intentionally hidden on document forms.
      hintText: hint.isEmpty ? null : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TopwebsuiteTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: TopwebsuiteTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: TopwebsuiteTheme.primary,
          width: 1.5,
        ),
      ),
    ),
  );
}

class _WDropdown extends StatelessWidget {
  const _WDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TopwebsuiteTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
          iconEnabledColor: TopwebsuiteTheme.muted,
          items: items
              .map(
                (m) => DropdownMenuItem(
                  value: m.$1,
                  child: Text(
                    m.$2,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }
}
