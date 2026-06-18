import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/file_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/widgets/collapsible_section.dart';
import '../../auth/application/auth_controller.dart';
import 'document_preview_screen.dart';

// ── Currencies provider ────────────────────────────────────────────────────────

const _currencyCacheKey = 'cached_currencies_v1';

const _fallbackCurrencies = <Map<String, dynamic>>[
  {'code': 'NGN', 'name': 'Naira', 'symbol': '₦'},
  {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
  {'code': 'GBP', 'name': 'Pound Sterling', 'symbol': '£'},
  {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
];

/// Currencies are fetched from the API only once and then persisted on-disk.
/// Subsequent loads (this session or after an app restart) are served from the
/// cache, so the network is not hit every time a form opens.
final currenciesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final store = ref.watch(localStoreProvider);

  final cached = await store.readJson(_currencyCacheKey);
  final cachedItems = cached?['items'];
  if (cachedItems is List && cachedItems.isNotEmpty) {
    return cachedItems.whereType<Map<String, dynamic>>().toList();
  }

  final api = ref.watch(apiClientProvider);
  try {
    final list = await api.getList('/api/currencies/');
    final items = list.whereType<Map<String, dynamic>>().toList();
    if (items.isNotEmpty) {
      await store.writeJson(_currencyCacheKey, {'items': items});
    }
    return items;
  } catch (_) {
    return _fallbackCurrencies;
  }
});

// ── Line item model ────────────────────────────────────────────────────────────

class _LineItem {
  _LineItem({String name = '', String qty = '1', String price = '0.00'}) {
    nameCtrl = TextEditingController(text: name);
    qtyCtrl = TextEditingController(text: qty);
    priceCtrl = TextEditingController(text: price);
  }

  factory _LineItem.fromMap(Map m) => _LineItem(
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

// ── Invoice Form Sheet ─────────────────────────────────────────────────────────

class InvoiceFormSheet extends ConsumerStatefulWidget {
  const InvoiceFormSheet({super.key, this.existing});
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
      builder: (_) => InvoiceFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<InvoiceFormSheet> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends ConsumerState<InvoiceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // INTEGRATIONS
  bool _integrationsOpen = false;

  // APPEARANCE
  final _brandColor = TextEditingController(text: '#0274ff');
  String _currency = 'NGN';

  // LOGO
  XFile? _logoFile;

  // INVOICE DETAILS
  DateTime _date = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  // BILL FROM
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyPhone = TextEditingController();
  final _companyEmail = TextEditingController();
  final _companyWebsite = TextEditingController();

  // BILL TO
  final _clientName = TextEditingController();
  final _clientAddress = TextEditingController();
  final _clientPhone = TextEditingController();
  final _clientEmail = TextEditingController();

  // ITEMS
  final List<_LineItem> _items = [_LineItem()];
  final _description = TextEditingController();

  // TOTAL SETTINGS
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');

  // PAYMENT
  final _paymentDetails = TextEditingController();
  final _authorizedName = TextEditingController();
  XFile? _signatureFile;

  // TERMS
  final _terms = TextEditingController(
    text: 'Thank you for your business! Payment due within 30 days.',
  );

  // STATE
  bool _saving = false;
  String? _error;

  // ── Computed totals ────────────────────────────────────────────────────────

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.amount);
  double get _discountAmt =>
      _subtotal * (double.tryParse(_discount.text) ?? 0) / 100;
  double get _taxAmt =>
      (_subtotal - _discountAmt) * (double.tryParse(_tax.text) ?? 0) / 100;
  double get _total => _subtotal - _discountAmt + _taxAmt;

  // ── Init ──────────────────────────────────────────────────────────────────

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
    _currency = e['currency']?.toString() ?? 'NGN';
    _discount.text = e['discount_percent']?.toString() ?? '0';
    _tax.text = e['vat_percent']?.toString() ?? '0';
    _paymentDetails.text = e['payment_details']?.toString() ?? '';
    _authorizedName.text = e['authorized_name']?.toString() ?? '';
    _terms.text = e['notes']?.toString() ?? _terms.text;
    if ((e['brand_color']?.toString() ?? '').isNotEmpty) {
      _brandColor.text = e['brand_color'].toString();
    }
    _description.text = e['description']?.toString() ?? '';
    final existingItems = e['items'];
    if (existingItems is List && existingItems.isNotEmpty) {
      _items.clear();
      for (final i in existingItems.whereType<Map>()) {
        _items.add(_LineItem.fromMap(i));
      }
    }
    if (e['date'] != null) {
      _date = DateTime.tryParse(e['date'].toString()) ?? _date;
    }
    if (e['due_date'] != null) {
      _dueDate = DateTime.tryParse(e['due_date'].toString()) ?? _dueDate;
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
      _description,
      _discount,
      _tax,
      _paymentDetails,
      _authorizedName,
      _terms,
    ]) {
      c.dispose();
    }
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  // ── Color picker (full flutter_colorpicker) ───────────────────────────────

  Future<void> _showColorPicker() async {
    Color current = _parseColor(_brandColor.text);
    Color picked = current;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Brand Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: TopwebsuiteTheme.ink,
          ),
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
            displayThumbColor: true,
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

  // ── Date picker ──────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isDue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDue ? _dueDate : _date,
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
    if (picked != null) {
      setState(() {
        if (isDue) {
          _dueDate = picked;
        } else {
          _date = picked;
        }
      });
    }
  }

  // ── Image picker ─────────────────────────────────────────────────────────

  Future<void> _pickImage(bool isLogo) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
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

  // ── Integration helpers ──────────────────────────────────────────────────

  Future<void> _useBusinessProfileDefaults() async {
    try {
      final api = ref.read(apiClientProvider);
      final profiles = await api.getList('/api/v1/business-profile/');
      if (profiles.isEmpty) return;
      final id = profiles.first['public_id']?.toString() ?? '';
      if (id.isEmpty) return;
      final defaults = await api.getMap(
        '/api/v1/business-profile/$id/document-branding-defaults/',
      );
      setState(() {
        _companyName.text =
            defaults['company_name']?.toString() ?? _companyName.text;
        _companyAddress.text =
            defaults['company_address']?.toString() ?? _companyAddress.text;
        _companyPhone.text =
            defaults['company_phone']?.toString() ?? _companyPhone.text;
        _companyEmail.text =
            defaults['company_email']?.toString() ?? _companyEmail.text;
        _companyWebsite.text =
            defaults['company_website']?.toString() ?? _companyWebsite.text;
      });
      _showSnack('Business profile defaults applied');
    } catch (e) {
      _showSnack('Could not load business profile: $e', error: true);
    }
  }

  Future<void> _addErpItem() async {
    try {
      final api = ref.read(apiClientProvider);
      final products = await api.getList('/api/v1/erp/products/');
      if (!mounted) return;
      final chosen = await _showPickerSheet(
        'Pick ERP Product',
        products.whereType<Map<String, dynamic>>().toList(),
        (p) => p['name']?.toString() ?? '',
      );
      if (chosen == null) return;
      final pid = chosen['public_id']?.toString() ?? '';
      if (pid.isEmpty) return;
      final payload = await api.getMap(
        '/api/v1/erp/helpers/document-item-payload/?product_public_id=$pid',
      );
      setState(() {
        final item = _LineItem(
          name:
              payload['description']?.toString() ??
              chosen['name']?.toString() ??
              '',
          qty: '1',
          price:
              payload['rate']?.toString() ??
              chosen['unit_price']?.toString() ??
              '0',
        );
        item.qtyCtrl.addListener(() => setState(() {}));
        item.priceCtrl.addListener(() => setState(() {}));
        _items.add(item);
      });
    } catch (e) {
      _showSnack('Could not load ERP item: $e', error: true);
    }
  }

  Future<Map<String, dynamic>?> _showPickerSheet(
    String title,
    List<Map<String, dynamic>> items,
    String Function(Map) label,
  ) async {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  ListTile(
                    title: Text(label(item)),
                    onTap: () => Navigator.pop(context, item),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit({bool andDownload = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final api = ref.read(apiClientProvider);
      // Try both public_id and id keys for edit mode
      final id =
          (widget.existing?['public_id']?.toString() ??
                  widget.existing?['id']?.toString() ??
                  '')
              .trim();
      final fmt = DateFormat('yyyy-MM-dd');

      // Build multipart fields
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
        'due_date': fmt.format(_dueDate),
        'discount_percent': _discount.text.trim().isEmpty
            ? '0'
            : _discount.text.trim(),
        'vat_percent': _tax.text.trim().isEmpty ? '0' : _tax.text.trim(),
        'payment_details': _paymentDetails.text.trim(),
        'authorized_name': _authorizedName.text.trim(),
        'notes': _terms.text.trim(),
        'description': _description.text.trim(),
        'items': _encodeItems(),
      };

      Map<String, dynamic> result;
      if (id.isEmpty) {
        result = await api.multipartPost(
          '/api/invoices/create/',
          fields: fields,
          files: {
            if (_logoFile != null) 'company_logo': _logoFile!.path,
            if (_signatureFile != null)
              'authorized_signature': _signatureFile!.path,
          },
        );
      } else {
        result = await api.multipartPatch(
          '/api/invoices/$id/partial-update/',
          fields: fields,
          files: {
            if (_logoFile != null) 'company_logo': _logoFile!.path,
            if (_signatureFile != null)
              'authorized_signature': _signatureFile!.path,
          },
        );
      }

      final savedId = result['public_id']?.toString() ?? id;

      if (andDownload && savedId.isNotEmpty) {
        await ref
            .read(fileServiceProvider)
            .openPdf(
              '/api/invoices/$savedId/download/',
              'invoice-$savedId.pdf',
            );
      }

      if (mounted) {
        final rootNav = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop(true);
        if (savedId.isNotEmpty) {
          rootNav.push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => DocumentPreviewScreen(
                title: result['invoice_number']?.toString() ?? 'Invoice',
                previewPath: '/api/invoices/$savedId/preview/',
                downloadPath: '/api/invoices/$savedId/download/',
                docId: savedId,
                docType: 'invoice',
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
              // ── Fixed header ────────────────────────────────────────────
              _FormHeader(
                title: isEdit ? 'Edit Invoice' : 'Create Invoice',
                onClose: () => Navigator.of(context).pop(false),
              ),
              // ── Scrollable body ─────────────────────────────────────────
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
                    _buildIntegrations(),
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
                      title: 'INVOICE DETAILS',
                      badge: 'Basic info',
                      child: _buildInvoiceDetails(),
                    ),
                    CollapsibleSection(
                      title: 'BILL FROM',
                      badge: 'Your business',
                      child: _buildBillFrom(),
                    ),
                    CollapsibleSection(
                      title: 'BILL TO',
                      badge: 'Client info',
                      child: _buildBillTo(),
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
                      title: 'PAYMENT',
                      badge: 'Instructions',
                      child: _buildPayment(),
                    ),
                    CollapsibleSection(
                      title: 'TERMS',
                      badge: 'Notes',
                      child: _buildTerms(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // ── Fixed bottom buttons ─────────────────────────────────────
              _FormBottomBar(
                saving: _saving,
                onCancel: () => Navigator.of(context).pop(false),
                onSaveDownload: () => _submit(andDownload: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildIntegrations() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: TopwebsuiteTheme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Collapsible header row
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _integrationsOpen
                  ? Radius.zero
                  : const Radius.circular(10),
            ),
            onTap: () => setState(() => _integrationsOpen = !_integrationsOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'INTEGRATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'OPTIONAL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: TopwebsuiteTheme.muted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _integrationsOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: TopwebsuiteTheme.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_integrationsOpen) ...[
            const Divider(height: 1, color: TopwebsuiteTheme.border),
            _integrationBtn(
              'Use Business Profile Defaults',
              Icons.storefront_outlined,
              _useBusinessProfileDefaults,
            ),
            _integrationBtn(
              'Use CRM Customer',
              Icons.groups_2_outlined,
              () async {
                try {
                  final api = ref.read(apiClientProvider);
                  final contacts = await api.getList('/api/v1/crm/contacts/');
                  if (!mounted) return;
                  final chosen = await _showPickerSheet(
                    'CRM Contacts',
                    contacts.whereType<Map<String, dynamic>>().toList(),
                    (c) =>
                        c['full_name']?.toString() ??
                        c['email']?.toString() ??
                        '',
                  );
                  if (chosen == null) return;
                  setState(() {
                    _clientName.text = chosen['full_name']?.toString() ?? '';
                    _clientPhone.text = chosen['phone']?.toString() ?? '';
                    _clientEmail.text = chosen['email']?.toString() ?? '';
                    _clientAddress.text = chosen['address']?.toString() ?? '';
                  });
                } catch (e) {
                  _showSnack('Could not load CRM contacts', error: true);
                }
              },
            ),
            _integrationBtn(
              'Add ERP Item',
              Icons.inventory_2_outlined,
              _addErpItem,
            ),
            _integrationBtn(
              'Generate From ERP Order',
              Icons.receipt_long_outlined,
              () async {
                try {
                  final api = ref.read(apiClientProvider);
                  final orders = await api.getList('/api/v1/erp/orders/');
                  if (!mounted) return;
                  final chosen = await _showPickerSheet(
                    'ERP Orders',
                    orders.whereType<Map<String, dynamic>>().toList(),
                    (o) => o['order_number']?.toString() ?? '',
                  );
                  if (chosen == null) return;
                  final oid = chosen['public_id']?.toString() ?? '';
                  if (oid.isEmpty) return;
                  final payload = await api.getMap(
                    '/api/v1/erp/helpers/orders/$oid/invoice-payload/',
                  );
                  setState(() {
                    _clientName.text =
                        payload['client_name']?.toString() ?? _clientName.text;
                    _clientAddress.text =
                        payload['client_address']?.toString() ??
                        _clientAddress.text;
                    _clientEmail.text =
                        payload['client_email']?.toString() ??
                        _clientEmail.text;
                    final items = payload['items'];
                    if (items is List) {
                      for (final i in _items) {
                        i.dispose();
                      }
                      _items
                        ..clear()
                        ..addAll(items.whereType<Map>().map(_LineItem.fromMap));
                    }
                  });
                  _showSnack('Order data applied');
                } catch (e) {
                  _showSnack('Could not load order', error: true);
                }
              },
            ),
            _integrationBtn(
              'Save Customer To CRM',
              Icons.person_add_outlined,
              () async {
                if (_clientName.text.trim().isEmpty) {
                  _showSnack('Enter client name first', error: true);
                  return;
                }
                try {
                  await ref
                      .read(apiClientProvider)
                      .postMap('/api/v1/crm/helpers/save-document-customer/', {
                        'client_name': _clientName.text,
                        'client_email': _clientEmail.text,
                        'client_phone': _clientPhone.text,
                        'source': 'invoice',
                      });
                  _showSnack('Customer saved to CRM');
                } catch (e) {
                  _showSnack('Error: $e', error: true);
                }
              },
            ),
            _integrationBtn(
              'Save Customer To ERP',
              Icons.warehouse_outlined,
              () async {
                if (_clientName.text.trim().isEmpty) {
                  _showSnack('Enter client name first', error: true);
                  return;
                }
                try {
                  await ref.read(apiClientProvider).postMap(
                    '/api/v1/integrations/documents/save-customer-to-erp/',
                    {
                      'full_name': _clientName.text,
                      'email': _clientEmail.text,
                      'phone': _clientPhone.text,
                      'source': 'invoice',
                    },
                  );
                  _showSnack('Customer saved to ERP');
                } catch (e) {
                  _showSnack('Error: $e', error: true);
                }
              },
            ),
            const Divider(height: 1, color: TopwebsuiteTheme.border),
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Text(
                'These helpers are optional. Manual invoice entry still works exactly as before.',
                style: TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _integrationBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 16, color: TopwebsuiteTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: TopwebsuiteTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearance() {
    final currencies = ref.watch(currenciesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Brand Color'),
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
              child: _Field(
                controller: _brandColor,
                hint: '#0274ff',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _FieldLabel('Currency'),
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
          error: (_, __) => _Field(
            controller: TextEditingController(text: _currency),
            hint: 'NGN',
          ),
        ),
      ],
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

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pickImage(true),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(
                color: TopwebsuiteTheme.border,
                style: BorderStyle.solid,
              ),
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

  Widget _buildInvoiceDetails() {
    final fmt = DateFormat('dd/MM/yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Date'),
        const SizedBox(height: 6),
        _DateField(value: fmt.format(_date), onTap: () => _pickDate(false)),
        const SizedBox(height: 12),
        _FieldLabel('Due Date'),
        const SizedBox(height: 6),
        _DateField(value: fmt.format(_dueDate), onTap: () => _pickDate(true)),
      ],
    );
  }

  Widget _buildBillFrom() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Company Name'),
        const SizedBox(height: 6),
        _Field(
          controller: _companyName,
          hint: 'Your company name',
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Address'),
        const SizedBox(height: 6),
        _Field(
          controller: _companyAddress,
          hint: '123 Main Street\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Phone'),
        const SizedBox(height: 6),
        _Field(
          controller: _companyPhone,
          hint: '+1 (555) 000-0000',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Email'),
        const SizedBox(height: 6),
        _Field(
          controller: _companyEmail,
          hint: 'company@email.com',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Website'),
        const SizedBox(height: 6),
        _Field(
          controller: _companyWebsite,
          hint: 'https://yourwebsite.com',
          keyboard: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildBillTo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Client Name / Company'),
        const SizedBox(height: 6),
        _Field(
          controller: _clientName,
          hint: 'Jane Smith',
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Address'),
        const SizedBox(height: 6),
        _Field(
          controller: _clientAddress,
          hint: '456 Oak Avenue\nCity, State 00000',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Phone'),
        const SizedBox(height: 6),
        _Field(
          controller: _clientPhone,
          hint: '+1 (555) 111-2222',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Email'),
        const SizedBox(height: 6),
        _Field(
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
        // Column headers
        Row(
          children: [
            const Expanded(
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
            const SizedBox(width: 6),
            const SizedBox(
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
            const SizedBox(width: 6),
            const SizedBox(
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
            const SizedBox(width: 32),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++) ...[
          Row(
            children: [
              Expanded(
                flex: 5,
                child: _Field(
                  controller: _items[i].nameCtrl,
                  hint: 'Item name',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 50,
                child: _Field(
                  controller: _items[i].qtyCtrl,
                  hint: '1',
                  keyboard: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: _Field(
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
          // Amount row
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
                    'Amount: $_currency ${_items[i].amount.toStringAsFixed(2)}',
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
        // Add Line Item button
        GestureDetector(
          onTap: () {
            final item = _LineItem();
            item.qtyCtrl.addListener(() => setState(() {}));
            item.priceCtrl.addListener(() => setState(() {}));
            setState(() => _items.add(item));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: TopwebsuiteTheme.primary,
                style: BorderStyle.solid,
              ),
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
        const SizedBox(height: 12),
        _FieldLabel('Description (optional)'),
        const SizedBox(height: 6),
        _Field(
          controller: _description,
          hint: 'Description (optional)',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTotalSettings() {
    final sym = _currency == 'NGN'
        ? '₦'
        : _currency == 'USD'
        ? '\$'
        : _currency == 'GBP'
        ? '£'
        : _currency == 'EUR'
        ? '€'
        : _currency;
    String fmtAmt(double v) => '$sym${v.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel('Discount (%)'),
        const SizedBox(height: 6),
        _Field(
          controller: _discount,
          hint: '0',
          keyboard: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _FieldLabel('Tax / VAT (%)'),
        const SizedBox(height: 6),
        _Field(
          controller: _tax,
          hint: '0',
          keyboard: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        // Subtotal row
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

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _paymentDetails,
          hint: 'Bank name, account number, payment instructions',
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _FieldLabel('Authorised name'),
        const SizedBox(height: 6),
        _Field(controller: _authorizedName, hint: 'Authorised name'),
        const SizedBox(height: 12),
        _FieldLabel('Authorised signature'),
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

  Widget _buildTerms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Field(
          controller: _terms,
          hint: 'Thank you for your business! Payment due within 30 days.',
          maxLines: 4,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Shared form widgets ────────────────────────────────────────────────────────

class _FormHeader extends StatelessWidget {
  const _FormHeader({required this.title, required this.onClose});
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

class _FormBottomBar extends StatelessWidget {
  const _FormBottomBar({
    required this.saving,
    required this.onCancel,
    required this.onSaveDownload,
  });
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSaveDownload;

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
          // Cancel
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
          // Save & Download
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: saving ? null : onSaveDownload,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded, size: 16),
              label: Text(
                saving ? 'Saving...' : 'Save & Download',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: TopwebsuiteTheme.ink,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
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
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
      decoration: InputDecoration(
        // Placeholder/example text intentionally hidden on document forms.
        hintText: hint.isEmpty ? null : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
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
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                style: const TextStyle(
                  fontSize: 13,
                  color: TopwebsuiteTheme.ink,
                ),
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
}
