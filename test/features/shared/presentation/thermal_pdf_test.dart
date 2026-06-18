import 'package:flutter_test/flutter_test.dart';
import 'package:topwebsuite_mobile/features/shared/presentation/thermal_pdf.dart';

void main() {
  // Sample payload covering the fields each document type reads.
  Map<String, dynamic> sample() => {
    'company_name': 'Acme Logistics Ltd',
    'company_address': '12 Allen Avenue, Ikeja',
    'company_phone': '+234 800 000 0000',
    'company_email': 'hello@acme.com',
    'currency': 'NGN',
    'invoice_number': 'INV-2026-0001',
    'receipt_number': 'RC-2026-0001',
    'waybill_number': 'WB-2026-ABC123',
    'quotation_number': 'QT-2026-0001',
    'date': '2026-06-15',
    'client_name': 'Jane Smith',
    'client_address': '4 Marina Road',
    'received_from': 'Jane Smith',
    'being_payment_for': 'Website balance',
    'payment_method': 'transfer',
    'amount': '150000',
    'sender_name': 'Acme Couriers',
    'sender_address': 'Depot 1',
    'sender_contact': '+234 801',
    'recipient_name': 'Bob Jones',
    'recipient_address': '9 Lekki Phase 1',
    'recipient_contact': '+234 802',
    'shipment_description': '2 cartons of books',
    'weight': '4.5',
    'shipment_value': '50000',
    'status': 'shipped',
    'valid_until': '2026-07-15',
    'reference': 'PO-99',
    'items': [
      {'description': 'Design service', 'quantity': '2', 'rate': '25000'},
      {'description': 'Hosting', 'quantity': '1', 'rate': '12000'},
    ],
    'discount_percent': '10',
    'vat_percent': '7.5',
    'tax_percent': '5',
    'notes': 'Thank you.',
  };

  for (final type in const ['invoice', 'receipt', 'waybill', 'quotation']) {
    test('thermal PDF builds for $type', () async {
      final bytes = await buildThermalReceiptPdf(type, sample());
      expect(bytes, isNotEmpty, reason: '$type produced no bytes');
      // Valid PDF files start with the "%PDF" magic header.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  }
}
