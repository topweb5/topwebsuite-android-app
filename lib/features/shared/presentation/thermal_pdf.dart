import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a self-contained 80mm black-and-white thermal receipt PDF for a
/// document. The backend HTML/PDF template is intentionally ignored — this is a
/// compact layout designed to fit thermal roll paper.
///
/// Supported [docType]: invoice, receipt, waybill, quotation.
Future<Uint8List> buildThermalReceiptPdf(
  String docType,
  Map<String, dynamic> d,
) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80.copyWith(
        marginLeft: 4 * PdfPageFormat.mm,
        marginRight: 4 * PdfPageFormat.mm,
        marginTop: 6 * PdfPageFormat.mm,
        marginBottom: 8 * PdfPageFormat.mm,
      ),
      theme: pw.ThemeData.withFont(
        base: pw.Font.courier(),
        bold: pw.Font.courierBold(),
      ),
      build: (context) => _content(docType, d),
    ),
  );
  return doc.save();
}

// ── Field helpers ─────────────────────────────────────────────────────────────

String _s(Map<String, dynamic> d, String key) =>
    (d[key] ?? '').toString().trim();

String _first(Map<String, dynamic> d, List<String> keys) {
  for (final k in keys) {
    final v = _s(d, k);
    if (v.isNotEmpty) return v;
  }
  return '';
}

num _n(Object? v) =>
    num.tryParse((v ?? '').toString().replaceAll(',', '').trim()) ?? 0;

String _money(num v, String code) =>
    '$code ${NumberFormat('#,##0.00').format(v)}';

String _date(Map<String, dynamic> d) {
  final raw = _first(d, ['date', 'issued_date', 'created_at']);
  if (raw.isEmpty) return '';
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) return DateFormat('dd MMM yyyy').format(parsed);
  return raw.length >= 10 ? raw.substring(0, 10) : raw;
}

List<Map<String, dynamic>> _items(Map<String, dynamic> d) =>
    (d['items'] as List?)
        ?.whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList() ??
    const [];

num _itemAmount(Map<String, dynamic> it) {
  final explicit = _n(it['amount']);
  if (explicit > 0) return explicit;
  final rate = _n(it['rate'] ?? it['unit_price'] ?? it['price']);
  final qty = _n(it['quantity'] ?? it['qty']);
  return rate * (qty == 0 ? 1 : qty);
}

// ── Style helpers ─────────────────────────────────────────────────────────────

pw.TextStyle _style(double size, {bool bold = false}) => pw.TextStyle(
  fontSize: size,
  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  color: PdfColors.black,
);

pw.Widget _divider() => pw.Container(
  height: 0.6,
  color: PdfColors.black,
  margin: const pw.EdgeInsets.symmetric(vertical: 5),
);

pw.Widget _centerText(String text, {double size = 8, bool bold = false}) =>
    pw.Center(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: _style(size, bold: bold),
      ),
    );

pw.Widget _row(
  String left,
  String right, {
  bool bold = false,
  double size = 8,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Text(left, style: _style(size, bold: bold)),
        ),
        pw.Expanded(
          flex: 5,
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: _style(size, bold: bold),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _labelBlock(String label, String value) {
  if (value.isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: _style(7, bold: true)),
        pw.Text(value, style: _style(8)),
      ],
    ),
  );
}

// ── Content ───────────────────────────────────────────────────────────────────

pw.Widget _content(String docType, Map<String, dynamic> d) {
  final children = <pw.Widget>[];

  // Header — company identity
  final company = _first(d, ['company_name', 'business_name']);
  if (company.isNotEmpty) {
    children.add(_centerText(company, size: 11, bold: true));
  }
  final addr = _s(d, 'company_address');
  if (addr.isNotEmpty) children.add(_centerText(addr, size: 7));
  final contact = [
    _s(d, 'company_phone'),
    _s(d, 'company_email'),
  ].where((e) => e.isNotEmpty).join('  ');
  if (contact.isNotEmpty) children.add(_centerText(contact, size: 7));
  final web = _s(d, 'company_website');
  if (web.isNotEmpty) children.add(_centerText(web, size: 7));

  children.add(_divider());

  // Document title + number + date
  final meta = _docMeta(docType, d);
  children.add(_centerText(meta.$1, size: 10, bold: true));
  if (meta.$2.isNotEmpty) {
    children.add(pw.SizedBox(height: 3));
    children.add(_row('No.', meta.$2, bold: true));
  }
  final date = _date(d);
  if (date.isNotEmpty) children.add(_row('Date', date));

  children.add(_divider());

  // Per-type body
  switch (docType) {
    case 'invoice':
    case 'quotation':
      children.addAll(_documentBody(docType, d));
    case 'receipt':
      children.addAll(_receiptBody(d));
    case 'waybill':
      children.addAll(_waybillBody(d));
    default:
      children.addAll(_documentBody(docType, d));
  }

  children.add(_divider());
  children.add(pw.SizedBox(height: 4));
  children.add(_centerText('Thank you for your business', size: 7));

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: children,
  );
}

(String, String) _docMeta(String docType, Map<String, dynamic> d) {
  switch (docType) {
    case 'invoice':
      return ('INVOICE', _s(d, 'invoice_number'));
    case 'receipt':
      return ('RECEIPT', _s(d, 'receipt_number'));
    case 'waybill':
      return ('WAYBILL', _s(d, 'waybill_number'));
    case 'quotation':
      return ('QUOTATION', _s(d, 'quotation_number'));
    default:
      return (docType.toUpperCase(), '');
  }
}

// Invoice + Quotation share line-items + totals.
List<pw.Widget> _documentBody(String docType, Map<String, dynamic> d) {
  final code = _s(d, 'currency').isEmpty ? 'NGN' : _s(d, 'currency');
  final out = <pw.Widget>[];

  // Party
  final clientName = _first(d, ['client_name', 'received_from']);
  out.add(_labelBlock('BILL TO', clientName));
  final clientAddr = _s(d, 'client_address');
  if (clientAddr.isNotEmpty) out.add(pw.Text(clientAddr, style: _style(7)));
  final clientPhone = _s(d, 'client_phone');
  if (clientPhone.isNotEmpty) out.add(pw.Text(clientPhone, style: _style(7)));

  if (docType == 'quotation') {
    final valid = _s(d, 'valid_until');
    if (valid.isNotEmpty) out.add(_row('Valid until', valid));
    final ref = _s(d, 'reference');
    if (ref.isNotEmpty) out.add(_row('Reference', ref));
  }

  out.add(_divider());

  // Items
  final items = _items(d);
  num subtotal = 0;
  for (final it in items) {
    final desc = (it['description'] ?? it['name'] ?? 'Item').toString().trim();
    final qty = _n(it['quantity'] ?? it['qty']);
    final rate = _n(it['rate'] ?? it['unit_price'] ?? it['price']);
    final amount = _itemAmount(it);
    subtotal += amount;
    out.add(pw.Text(desc.isEmpty ? 'Item' : desc, style: _style(8)));
    out.add(
      _row(
        '${qty == 0 ? 1 : NumberFormat('#,##0.##').format(qty)} x ${NumberFormat('#,##0.00').format(rate)}',
        _money(amount, code),
        size: 7,
      ),
    );
  }
  if (items.isNotEmpty) out.add(_divider());

  // Totals
  final discPct = _n(d['discount_percent']);
  final taxPct = _n(d['vat_percent'] ?? d['tax_percent']);
  final discountAmt = subtotal * discPct / 100;
  final taxable = subtotal - discountAmt;
  final taxAmt = taxable * taxPct / 100;
  final total = _n(d['total']) > 0 ? _n(d['total']) : taxable + taxAmt;

  out.add(_row('Subtotal', _money(subtotal, code)));
  if (discPct > 0) {
    out.add(_row('Discount ($discPct%)', '-${_money(discountAmt, code)}'));
  }
  if (taxPct > 0) out.add(_row('Tax ($taxPct%)', _money(taxAmt, code)));
  out.add(pw.SizedBox(height: 2));
  out.add(_row('TOTAL', _money(total, code), bold: true, size: 9));

  final payment = _s(d, 'payment_details');
  if (payment.isNotEmpty) {
    out.add(_divider());
    out.add(_labelBlock('PAYMENT', payment));
  }
  final notes = _s(d, 'notes');
  if (notes.isNotEmpty) {
    out.add(pw.SizedBox(height: 4));
    out.add(pw.Text(notes, style: _style(7)));
  }
  return out;
}

List<pw.Widget> _receiptBody(Map<String, dynamic> d) {
  final code = _s(d, 'currency').isEmpty ? 'NGN' : _s(d, 'currency');
  final out = <pw.Widget>[];

  out.add(_labelBlock('RECEIVED FROM', _s(d, 'received_from')));
  final purpose = _first(d, ['being_payment_for', 'purpose']);
  if (purpose.isNotEmpty) out.add(_labelBlock('FOR', purpose));

  out.add(_divider());
  out.add(_row('AMOUNT', _money(_n(d['amount']), code), bold: true, size: 10));
  final balance = _s(d, 'balance');
  if (balance.isNotEmpty) out.add(_row('Balance', _money(_n(balance), code)));
  final method = _first(d, ['payment_method', 'method']);
  if (method.isNotEmpty) out.add(_row('Method', method));

  final authorized = _s(d, 'authorized_name');
  if (authorized.isNotEmpty) {
    out.add(_divider());
    out.add(_labelBlock('AUTHORIZED BY', authorized));
  }
  final notes = _s(d, 'notes');
  if (notes.isNotEmpty) {
    out.add(pw.SizedBox(height: 4));
    out.add(pw.Text(notes, style: _style(7)));
  }
  return out;
}

List<pw.Widget> _waybillBody(Map<String, dynamic> d) {
  final code = _s(d, 'currency').isEmpty ? 'NGN' : _s(d, 'currency');
  final out = <pw.Widget>[];

  final status = _s(d, 'status');
  if (status.isNotEmpty) {
    out.add(_row('Status', status.toUpperCase(), bold: true));
  }

  out.add(_divider());
  out.add(_labelBlock('SENT THROUGH', _s(d, 'sender_name')));
  final sAddr = _s(d, 'sender_address');
  if (sAddr.isNotEmpty) out.add(pw.Text(sAddr, style: _style(7)));
  final sContact = _s(d, 'sender_contact');
  if (sContact.isNotEmpty) out.add(pw.Text(sContact, style: _style(7)));

  out.add(_divider());
  out.add(_labelBlock('RECIPIENT', _s(d, 'recipient_name')));
  final rAddr = _s(d, 'recipient_address');
  if (rAddr.isNotEmpty) out.add(pw.Text(rAddr, style: _style(7)));
  final rContact = _s(d, 'recipient_contact');
  if (rContact.isNotEmpty) out.add(pw.Text(rContact, style: _style(7)));

  out.add(_divider());
  out.add(_labelBlock('SHIPMENT', _s(d, 'shipment_description')));
  final weight = _s(d, 'weight');
  if (weight.isNotEmpty) out.add(_row('Weight', '$weight kg'));
  final value = _s(d, 'shipment_value');
  if (value.isNotEmpty) out.add(_row('Value', _money(_n(value), code)));
  return out;
}
