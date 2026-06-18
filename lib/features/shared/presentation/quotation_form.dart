import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import '../../../core/widgets/collapsible_section.dart';
import '../../auth/application/auth_controller.dart';
import 'document_preview_screen.dart';
import 'invoice_form.dart' show currenciesProvider;

// ── Line item ───────────────────────────────────────────────────────────────

class _QLineItem {
  _QLineItem({String name = '', String qty = '1', String price = '0.00'}) {
    nameCtrl = TextEditingController(text: name);
    qtyCtrl = TextEditingController(text: qty);
    priceCtrl = TextEditingController(text: price);
  }

  factory _QLineItem.fromMap(Map m) => _QLineItem(
    name: m['description']?.toString() ?? '',
    qty: m['quantity']?.toString() ?? '1',
    price: (m['rate'] ?? m['unit_price'] ?? m['price'])?.toString() ?? '0.00',
  );

  late TextEditingController nameCtrl;
  late TextEditingController qtyCtrl;
  late TextEditingController priceCtrl;

  double get amount =>
      (double.tryParse(qtyCtrl.text) ?? 1) *
      (double.tryParse(priceCtrl.text.replaceAll(',', '')) ?? 0);

  Map<String, dynamic> toPayload() => {
    'description': nameCtrl.text.trim(),
    'quantity': qtyCtrl.text.trim().isEmpty ? '1' : qtyCtrl.text.trim(),
    'rate': priceCtrl.text.trim().isEmpty ? '0' : priceCtrl.text.trim(),
  };

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

// ── Quotation Form Sheet ──────────────────────────────────────────────────────
//
// Field keys mirror the quotations resource config / backend serializer:
// discount_percent, tax_percent, valid_until, reference, brand_color, items
// (JSON list of {description, quantity, rate}). quotation_number is generated
// server-side, so it is never sent.

class QuotationFormSheet extends ConsumerStatefulWidget {
  const QuotationFormSheet({super.key, this.existing});
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
      builder: (_) => QuotationFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<QuotationFormSheet> createState() => _QuotationFormState();
}

class _QuotationFormState extends ConsumerState<QuotationFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // QUOTATION DETAILS
  DateTime _date = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  String _status = 'open';
  String _currency = 'NGN';
  final _reference = TextEditingController();

  // BRANDING
  final _brandColor = TextEditingController(text: '#0274ff');
  XFile? _logoFile;

  // BILL FROM
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyWebsite = TextEditingController();

  // CLIENT
  final _clientName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();

  // ITEMS
  final List<_QLineItem> _items = [_QLineItem()];

  // TOTAL SETTINGS
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');

  // TERMS & NOTES
  final _notes = TextEditingController(
    text: 'This quotation is valid until the date specified above.',
  );

  // SIGNATURE
  XFile? _signatureFile;

  // STATE
  bool _saving = false;
  String? _error;

  static const _statuses = [
    ('open', 'Open'),
    ('accepted', 'Accepted'),
    ('expired', 'Expired'),
  ];

  // ── Computed totals ─────────────────────────────────────────────────────────

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.amount);
  double get _discountAmt =>
      _subtotal * (double.tryParse(_discount.text) ?? 0) / 100;
  double get _taxAmt =>
      (_subtotal - _discountAmt) * (double.tryParse(_tax.text) ?? 0) / 100;
  double get _total => _subtotal - _discountAmt + _taxAmt;

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
    for (final c in [
      _discount,
      _tax,
      ..._items.expand((i) => [i.qtyCtrl, i.priceCtrl]),
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _prefillFromExisting() {
    final e = widget.existing;
    if (e == null) return;
    _companyName.text = e['company_name']?.toString() ?? '';
    _companyAddress.text = e['company_address']?.toString() ?? '';
    _companyPhone.text = e['company_phone']?.toString() ?? '';
    _companyEmail.text = e['company_email']?.toString() ?? '';
    _companyWebsite.text = e['company_website']?.toString() ?? '';
    _clientName.text = e['client_name']?.toString() ?? '';
    _clientAddress.text = e['client_address']?.toString() ?? '';
    _clientPhone.text = e['client_phone']?.toString() ?? '';
    _clientEmail.text = e['client_email']?.toString() ?? '';
    _reference.text = e['reference']?.toString() ?? '';
    _currency = e['currency']?.toString() ?? 'NGN';
    _status = e['status']?.toString() ?? 'open';
    _discount.text = e['discount_percent']?.toString() ?? '0';
    _tax.text = e['tax_percent']?.toString() ?? '0';
    _notes.text = e['notes']?.toString() ?? _notes.text;
    if ((e['brand_color']?.toString() ?? '').isNotEmpty) {
      _brandColor.text = e['brand_color'].toString();
    }
    final existingItems = e['items'];
    if (existingItems is List && existingItems.isNotEmpty) {
      for (final i in _items) {
        i.dispose();
      }
      _items
        ..clear()
        ..addAll(existingItems.whereType<Map>().map(_QLineItem.fromMap));
    }
    if (e['date'] != null) {
      _date = DateTime.tryParse(e['date'].toString()) ?? _date;
    }
    if (e['valid_until'] != null) {
      _validUntil =
          DateTime.tryParse(e['valid_until'].toString()) ?? _validUntil;
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
      _reference,
      _brandColor,
      _companyName,
      _companyAddress,
      _companyPhone,
      _companyEmail,
      _companyWebsite,
      _clientName,
      _clientAddress,
      _clientPhone,
      _clientEmail,
      _discount,
      _tax,
      _notes,
    ]) {
      c.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── Color picker ──────────────────────────────────────────────────────────

  Future<void> _showColorPicker() async {
    final current = _parseColor(_brandColor.text);
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
              setState(() => _brandColor.text = hex);
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

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isValidUntil) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidUntil ? _validUntil : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: TopwebsuiteTheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isValidUntil) {
          _validUntil = picked;
        } else {
          _date = picked;
        }
      });
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
      final fmt = DateFormat('yyyy-MM-dd');

      final fields = <String, String>{
        'company_name': _companyName.text.trim(),
        'company_address': _companyAddress.text.trim(),
        'company_phone': _companyPhone.text.trim(),
        'company_email': _companyEmail.text.trim(),
        'company_website': _companyWebsite.text.trim(),
        'client_name': _clientName.text.trim(),
        'client_address': _clientAddress.text.trim(),
        'client_phone': _clientPhone.text.trim(),
        'client_email': _clientEmail.text.trim(),
        'currency': _currency,
        'brand_color': _brandColor.text.trim().isEmpty
            ? '#0274ff'
            : _brandColor.text.trim(),
        'date': fmt.format(_date),
        'valid_until': fmt.format(_validUntil),
        'status': _status,
        'reference': _reference.text.trim(),
        'discount_percent': _discount.text.trim().isEmpty
            ? '0'
            : _discount.text.trim(),
        'tax_percent': _tax.text.trim().isEmpty ? '0' : _tax.text.trim(),
        'notes': _notes.text.trim(),
        'items': _encodeItems(),
      };

      final files = <String, String>{
        if (_logoFile != null) 'company_logo': _logoFile!.path,
        if (_signatureFile != null)
          'authorized_signature': _signatureFile!.path,
      };

      Map<String, dynamic> result;
      if (id.isEmpty) {
        result = await api.multipartPost(
          '/api/quotations/create/',
          fields: fields,
          files: files,
        );
      } else {
        result = await api.multipartPatch(
          '/api/quotations/$id/update/',
          fields: fields,
          files: files,
        );
      }

      final data = unwrapData(result);
      final savedId = data['public_id']?.toString() ?? '';
      if (mounted) {
        final rootNav = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop(true);
        if (savedId.isNotEmpty) {
          rootNav.push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DocumentPreviewScreen(
                title: data['quotation_number']?.toString() ?? 'Quotation',
                previewPath: '/api/quotations/$savedId/preview/',
                downloadPath: '/api/quotations/$savedId/download/',
                docId: savedId,
                docType: 'quotation',
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

  String _encodeItems() {
    var list = _items
        .map((i) => i.toPayload())
        .where((p) => (p['description'] as String).isNotEmpty)
        .toList();
    if (list.isEmpty) {
      list = [
        {'description': 'Unnamed item', 'quantity': '1', 'rate': '0'},
      ];
    }
    return jsonEncode(list);
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
              _QFormHeader(
                title: isEdit ? 'Edit Quotation' : 'Create Quotation',
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
                      title: 'QUOTATION DETAILS',
                      badge: 'Basic info',
                      child: _buildDetails(),
                    ),
                    CollapsibleSection(
                      title: 'BRANDING',
                      badge: 'Customize',
                      child: _buildBranding(),
                    ),
                    CollapsibleSection(
                      title: 'BILL FROM',
                      badge: 'Your business',
                      child: _buildBillFrom(),
                    ),
                    CollapsibleSection(
                      title: 'CLIENT',
                      badge: 'Client info',
                      child: _buildClient(),
                    ),
                    CollapsibleSection(
                      title: 'ITEMS',
                      badge: 'Services / products',
                      child: _buildItems(),
                    ),
                    CollapsibleSection(
                      title: 'TOTAL SETTINGS',
                      badge: 'Optional values',
                      child: _buildTotalSettings(),
                    ),
                    CollapsibleSection(
                      title: 'TERMS & NOTES',
                      badge: 'Optional',
                      child: _buildTerms(),
                    ),
                    CollapsibleSection(
                      title: 'SIGNATURE',
                      badge: 'Sign-off',
                      child: _buildSignature(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _QFormBottomBar(
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

  Widget _buildDetails() {
    final fmt = DateFormat('dd/MM/yyyy');
    final currencies = ref.watch(currenciesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Date'),
        const SizedBox(height: 6),
        _QDateField(value: fmt.format(_date), onTap: () => _pickDate(false)),
        const SizedBox(height: 12),
        _QLabel('Valid Until'),
        const SizedBox(height: 6),
        _QDateField(
          value: fmt.format(_validUntil),
          onTap: () => _pickDate(true),
        ),
        const SizedBox(height: 12),
        _QLabel('Status'),
        const SizedBox(height: 6),
        _QDropdown(
          value: _status,
          items: _statuses,
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: 12),
        _QLabel('Currency'),
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
          error: (_, __) => _QField(
            controller: TextEditingController(text: _currency),
            hint: 'NGN',
          ),
        ),
        const SizedBox(height: 12),
        _QLabel('Reference'),
        const SizedBox(height: 6),
        _QField(controller: _reference, hint: 'PO number or reference'),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Logo'),
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
        _QLabel('Brand Color'),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: _showColorPicker,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(_brandColor.text),
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
              child: _QField(
                controller: _brandColor,
                hint: '#0274ff',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBillFrom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Company Name'),
        const SizedBox(height: 6),
        _QField(
          controller: _companyName,
          hint: 'Your company name',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _QLabel('Address'),
        const SizedBox(height: 6),
        _QField(
          controller: _companyAddress,
          hint: '123 Main Street\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _QLabel('Phone'),
        const SizedBox(height: 6),
        _QField(
          controller: _companyPhone,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _QLabel('Email'),
        const SizedBox(height: 6),
        _QField(
          controller: _companyEmail,
          hint: 'company@email.com',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _QLabel('Website'),
        const SizedBox(height: 6),
        _QField(
          controller: _companyWebsite,
          hint: 'https://yourwebsite.com',
          keyboard: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Name / Company'),
        const SizedBox(height: 6),
        _QField(
          controller: _clientName,
          hint: 'Jane Smith',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _QLabel('Address'),
        const SizedBox(height: 6),
        _QField(
          controller: _clientAddress,
          hint: '456 Oak Avenue\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _QLabel('Phone'),
        const SizedBox(height: 6),
        _QField(
          controller: _clientPhone,
          hint: '+234 800 111 2222',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _QLabel('Email'),
        const SizedBox(height: 6),
        _QField(
          controller: _clientEmail,
          hint: 'client@email.com',
          keyboard: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(
              flex: 5,
              child: Text(
                'ITEM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 50,
              child: Text(
                'QTY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(width: 6),
            SizedBox(
              width: 70,
              child: Text(
                'PRICE',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TopwebsuiteTheme.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            SizedBox(width: 32),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++) ...[
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _QField(
                  controller: _items[i].nameCtrl,
                  hint: 'Item name',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                child: _QField(
                  controller: _items[i].qtyCtrl,
                  hint: '1',
                  keyboard: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: _QField(
                  controller: _items[i].priceCtrl,
                  hint: '0.00',
                  keyboard: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _items.length > 1
                    ? () {
                        setState(() {
                          _items[i].dispose();
                          _items.removeAt(i);
                        });
                      }
                    : null,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _items.length > 1
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: _items.length > 1
                        ? TopwebsuiteTheme.danger
                        : TopwebsuiteTheme.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TopwebsuiteTheme.surface,
                    border: Border.all(color: TopwebsuiteTheme.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Amount: $_currencySymbol${_items[i].amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TopwebsuiteTheme.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (i < _items.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            final item = _QLineItem();
            item.qtyCtrl.addListener(() => setState(() {}));
            item.priceCtrl.addListener(() => setState(() {}));
            setState(() => _items.add(item));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: TopwebsuiteTheme.primary),
              borderRadius: BorderRadius.circular(8),
              color: TopwebsuiteTheme.primarySoft,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: TopwebsuiteTheme.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'Add Line Item',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TopwebsuiteTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSettings() {
    String fmtAmt(double v) => '$_currencySymbol${v.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Discount (%)'),
        const SizedBox(height: 6),
        _QField(
          controller: _discount,
          hint: '0',
          keyboard: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _QLabel('Tax (%)'),
        const SizedBox(height: 6),
        _QField(
          controller: _tax,
          hint: '0',
          keyboard: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtotal',
              style: TextStyle(fontSize: 13, color: TopwebsuiteTheme.muted),
            ),
            Text(
              fmtAmt(_subtotal),
              style: const TextStyle(
                fontSize: 13,
                color: TopwebsuiteTheme.muted,
              ),
            ),
          ],
        ),
        const Divider(height: 20, color: TopwebsuiteTheme.border),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink,
              ),
            ),
            Text(
              fmtAmt(_total),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QField(
          controller: _notes,
          hint: 'Terms, conditions or notes for this quotation.',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QLabel('Authorized Signature'),
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
}

// ── Shared Quotation form widgets ─────────────────────────────────────────────

class _QFormHeader extends StatelessWidget {
  const _QFormHeader({required this.title, required this.onClose});
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

class _QFormBottomBar extends StatelessWidget {
  const _QFormBottomBar({
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
                saving ? 'Saving...' : 'Save Quotation',
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

class _QLabel extends StatelessWidget {
  const _QLabel(this.text);
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

class _QField extends StatelessWidget {
  const _QField({
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

class _QDateField extends StatelessWidget {
  const _QDateField({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TopwebsuiteTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: TopwebsuiteTheme.muted,
          ),
        ],
      ),
    ),
  );
}

class _QDropdown extends StatelessWidget {
  const _QDropdown({
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
