import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/collapsible_section.dart';
import '../../auth/application/auth_controller.dart';
import 'document_preview_screen.dart';
import 'invoice_form.dart' show currenciesProvider;

// ── Receipt Form Sheet ─────────────────────────────────────────────────────────

class ReceiptFormSheet extends ConsumerStatefulWidget {
  const ReceiptFormSheet({super.key, this.existing});
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
      builder: (_) => ReceiptFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<ReceiptFormSheet> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends ConsumerState<ReceiptFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // APPEARANCE
  final _brandColor = TextEditingController(text: '#0274ff');
  String _currency = 'NGN';

  // LOGO
  XFile? _logoFile;

  // RECEIPT DETAILS
  DateTime _date = DateTime.now();
  String _paymentMethod = 'cash';

  // ISSUED BY
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyWebsite = TextEditingController();

  // RECEIVED FROM
  final _receivedFrom = TextEditingController();
  final _payerAddress = TextEditingController();
  final _payerPhone = TextEditingController();
  final _payerEmail = TextEditingController();
  final _beingPaymentFor = TextEditingController();
  final _amount = TextEditingController(text: '0.00');
  final _chequeNumber = TextEditingController();

  // APPROVAL
  final _authorizedName = TextEditingController();
  XFile? _signatureFile;

  // NOTES
  final _notes = TextEditingController(text: 'Payment received with thanks.');

  // STATE
  bool _saving = false;
  String? _error;

  static const _paymentMethods = [
    ('cash', 'Cash'),
    ('cheque', 'Cheque'),
    ('transfer', 'Transfer'),
    ('other', 'Other'),
  ];

  double get _amountValue =>
      double.tryParse(_amount.text.replaceAll(',', '')) ?? 0.0;

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
    _amount.addListener(() => setState(() {}));
  }

  void _prefillFromExisting() {
    final e = widget.existing;
    if (e == null) return;
    _companyName.text = e['company_name']?.toString() ?? '';
    _companyAddress.text = e['company_address']?.toString() ?? '';
    _companyPhone.text = e['company_phone']?.toString() ?? '';
    _companyEmail.text = e['company_email']?.toString() ?? '';
    _companyWebsite.text = e['company_website']?.toString() ?? '';
    _receivedFrom.text = e['received_from']?.toString() ?? '';
    _payerAddress.text = e['payer_address']?.toString() ?? '';
    _payerPhone.text = e['payer_phone']?.toString() ?? '';
    _payerEmail.text = e['payer_email']?.toString() ?? '';
    _beingPaymentFor.text = e['being_payment_for']?.toString() ?? '';
    _amount.text = e['amount']?.toString() ?? '0.00';
    _currency = e['currency']?.toString() ?? 'NGN';
    _paymentMethod = e['payment_method']?.toString() ?? 'cash';
    _chequeNumber.text = e['cheque_number']?.toString() ?? '';
    _authorizedName.text = e['authorized_name']?.toString() ?? '';
    _notes.text = e['notes']?.toString() ?? _notes.text;
    if ((e['brand_color']?.toString() ?? '').isNotEmpty) {
      _brandColor.text = e['brand_color'].toString();
    }
    if (e['date'] != null) {
      _date = DateTime.tryParse(e['date'].toString()) ?? _date;
    }
  }

  void _prefillFromUser() {
    if (widget.existing != null) return;
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    if (_companyName.text.isEmpty) _companyName.text = user.displayName;
    if (_companyEmail.text.isEmpty) _companyEmail.text = user.email;
    if (_authorizedName.text.isEmpty) _authorizedName.text = user.displayName;
  }

  @override
  void dispose() {
    for (final c in [
      _brandColor,
      _companyName,
      _companyAddress,
      _companyPhone,
      _companyEmail,
      _companyWebsite,
      _receivedFrom,
      _payerAddress,
      _payerPhone,
      _payerEmail,
      _beingPaymentFor,
      _amount,
      _chequeNumber,
      _authorizedName,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Color picker ──────────────────────────────────────────────────────────

  Future<void> _showColorPicker() async {
    Color current = _parseColor(_brandColor.text);
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: TopwebsuiteTheme.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
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
        'brand_color': _brandColor.text.trim().isEmpty
            ? '#0274ff'
            : _brandColor.text.trim(),
        'received_from': _receivedFrom.text.trim(),
        'payer_address': _payerAddress.text.trim(),
        'payer_phone': _payerPhone.text.trim(),
        'payer_email': _payerEmail.text.trim(),
        'being_payment_for': _beingPaymentFor.text.trim(),
        'amount': _amount.text.trim().isEmpty ? '0' : _amount.text.trim(),
        'currency': _currency,
        'date': fmt.format(_date),
        'payment_method': _paymentMethod,
        'cheque_number': _chequeNumber.text.trim(),
        'authorized_name': _authorizedName.text.trim(),
        'notes': _notes.text.trim(),
      };

      Map<String, dynamic> result;
      if (id.isEmpty) {
        result = await api.multipartPost(
          '/api/receipts/create/',
          fields: fields,
          files: {
            if (_logoFile != null) 'company_logo': _logoFile!.path,
            if (_signatureFile != null)
              'authorized_signature': _signatureFile!.path,
          },
        );
      } else {
        result = await api.multipartPatch(
          '/api/receipts/$id/partial-update/',
          fields: fields,
          files: {
            if (_logoFile != null) 'company_logo': _logoFile!.path,
            if (_signatureFile != null)
              'authorized_signature': _signatureFile!.path,
          },
        );
      }

      final savedId = result['public_id']?.toString() ?? '';
      if (mounted) {
        // Capture root navigator before popping the modal
        final rootNav = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop(true);
        if (savedId.isNotEmpty) {
          rootNav.push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DocumentPreviewScreen(
                title: result['receipt_number']?.toString() ?? 'Receipt',
                previewPath: '/api/receipts/$savedId/preview/',
                downloadPath: '/api/receipts/$savedId/download/',
                docId: savedId,
                docType: 'receipt',
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

  // ── Amount in words ───────────────────────────────────────────────────────

  String get _amountInWords {
    if (_amountValue <= 0) return '';
    return _numToWords(_amountValue, _currency);
  }

  static String _numToWords(double amount, String curr) {
    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String convert(int n) {
      if (n == 0) return '';
      if (n < 20) return ones[n];
      if (n < 100) {
        return '${tens[n ~/ 10]}${n % 10 != 0 ? ' ${ones[n % 10]}' : ''}';
      }
      if (n < 1000) {
        return '${ones[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      }
      if (n < 1000000) {
        return '${convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      }
      if (n < 1000000000) {
        return '${convert(n ~/ 1000000)} Million${n % 1000000 != 0 ? ' ${convert(n % 1000000)}' : ''}';
      }
      return '${convert(n ~/ 1000000000)} Billion${n % 1000000000 != 0 ? ' ${convert(n % 1000000000)}' : ''}';
    }

    final intPart = amount.floor();
    final decPart = ((amount - intPart) * 100).round();
    final mainName = curr == 'NGN'
        ? 'Naira'
        : curr == 'USD'
        ? 'Dollars'
        : curr == 'GBP'
        ? 'Pounds'
        : curr == 'EUR'
        ? 'Euro'
        : curr;
    final subName = curr == 'NGN' ? 'Kobo' : 'Cents';
    final main = convert(intPart);
    if (decPart > 0) {
      return '$main $mainName and ${convert(decPart)} $subName Only';
    }
    return '$main $mainName Only';
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
              _RFormHeader(
                title: isEdit ? 'Edit Receipt' : 'Create Receipt',
                onClose: () => Navigator.of(context).pop(false),
              ),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // ── Error banner ─────────────────────────────────────
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
                      title: 'APPEARANCE',
                      badge: 'Customize',
                      child: _buildAppearance(),
                    ),
                    CollapsibleSection(
                      title: 'LOGO',
                      badge: 'Branding',
                      child: _buildLogo(),
                    ),
                    CollapsibleSection(
                      title: 'RECEIPT DETAILS',
                      badge: 'Basic info',
                      child: _buildReceiptDetails(),
                    ),
                    CollapsibleSection(
                      title: 'ISSUED BY',
                      badge: 'Your business',
                      child: _buildIssuedBy(),
                    ),
                    CollapsibleSection(
                      title: 'RECEIVED FROM',
                      badge: 'Payer details',
                      child: _buildReceivedFrom(),
                    ),
                    CollapsibleSection(
                      title: 'APPROVAL',
                      badge: 'Sign-off',
                      child: _buildApproval(),
                    ),
                    CollapsibleSection(
                      title: 'NOTES',
                      badge: 'Optional',
                      child: _buildNotes(),
                    ),
                    const SizedBox(height: 16),
                    // Receipt amount summary
                    _buildAmountSummary(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _RFormBottomBar(
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

  Widget _buildAppearance() {
    final currencies = ref.watch(currenciesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RLabel('Brand Color'),
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
              child: _RField(
                controller: _brandColor,
                hint: '#0274ff',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RLabel('Currency'),
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
          error: (_, __) => _RField(
            controller: TextEditingController(text: _currency),
            hint: 'NGN',
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildReceiptDetails() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RLabel('Date'),
        const SizedBox(height: 6),
        _RDateField(value: fmt.format(_date), onTap: _pickDate),
        const SizedBox(height: 12),
        _RLabel('Payment Method'),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: TopwebsuiteTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _paymentMethod,
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
              iconEnabledColor: TopwebsuiteTheme.muted,
              items: _paymentMethods
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
              onChanged: (v) =>
                  setState(() => _paymentMethod = v ?? _paymentMethod),
            ),
          ),
        ),
        if (_paymentMethod == 'cheque') ...[
          const SizedBox(height: 12),
          const Text(
            'Cheque number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: TopwebsuiteTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _chequeNumber,
            style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
            decoration: InputDecoration(
              hintText: 'Enter cheque number',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
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
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIssuedBy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RLabel('Company Name'),
        const SizedBox(height: 6),
        _RField(
          controller: _companyName,
          hint: 'Your company name',
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _RLabel('Address'),
        const SizedBox(height: 6),
        _RField(
          controller: _companyAddress,
          hint: '123 Main Street\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _RLabel('Phone'),
        const SizedBox(height: 6),
        _RField(
          controller: _companyPhone,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _RLabel('Email'),
        const SizedBox(height: 6),
        _RField(
          controller: _companyEmail,
          hint: 'company@email.com',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _RLabel('Website'),
        const SizedBox(height: 6),
        _RField(
          controller: _companyWebsite,
          hint: 'https://yourwebsite.com',
          keyboard: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildReceivedFrom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RLabel('Name / Company'),
        const SizedBox(height: 6),
        _RField(
          controller: _receivedFrom,
          hint: 'Jane Smith',
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _RLabel('Payment For'),
        const SizedBox(height: 6),
        _RField(
          controller: _beingPaymentFor,
          hint: 'Website design project balance',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _RLabel('Amount'),
        const SizedBox(height: 6),
        _RField(
          controller: _amount,
          hint: '0.00',
          keyboard: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _RLabel('Amount In Words'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFB),
            border: Border.all(color: TopwebsuiteTheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _amountInWords.isNotEmpty
                ? _amountInWords
                : 'Automatically written when amount is entered',
            style: TextStyle(
              fontSize: 13,
              color: _amountInWords.isNotEmpty
                  ? TopwebsuiteTheme.ink
                  : TopwebsuiteTheme.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApproval() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RLabel('Authorized Name'),
        const SizedBox(height: 6),
        _RField(controller: _authorizedName, hint: 'Authorized name'),
        const SizedBox(height: 12),
        _RLabel('Authorized Signature'),
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

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RField(
          controller: _notes,
          hint: 'Payment received with thanks.',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildAmountSummary() {
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
            'Receipt Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: TopwebsuiteTheme.ink,
            ),
          ),
          Text(
            '$_currencySymbol${_amountValue.toStringAsFixed(2)}',
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

// ── Shared Receipt form widgets ───────────────────────────────────────────────

class _RFormHeader extends StatelessWidget {
  const _RFormHeader({required this.title, required this.onClose});
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

class _RFormBottomBar extends StatelessWidget {
  const _RFormBottomBar({
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
                saving ? 'Saving...' : 'Save Receipt',
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

class _RLabel extends StatelessWidget {
  const _RLabel(this.text);
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

class _RField extends StatelessWidget {
  const _RField({
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

class _RDateField extends StatelessWidget {
  const _RDateField({required this.value, required this.onTap});
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
