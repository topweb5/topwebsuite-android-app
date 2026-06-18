import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import 'thermal_pdf.dart';

final printServiceProvider = Provider<PrintService>(
  (ref) => PrintService(ref.read(apiClientProvider)),
);

class PrintService {
  PrintService(this._api);

  final ApiClient _api;

  /// Prints the backend-rendered A4 PDF as-is via the system print dialog.
  Future<void> printStandard(String downloadPath, String name) async {
    final res = await _api.download(downloadPath);
    final bytes = Uint8List.fromList(res.data ?? const <int>[]);
    await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
  }

  /// Fetches the document data and prints a custom 80mm black-and-white
  /// thermal layout (the backend template is not used for this mode).
  Future<void> printThermal({
    required String docType,
    required String docId,
  }) async {
    final detail = unwrapData(await _api.getMap(_detailPath(docType, docId)));
    final bytes = await buildThermalReceiptPdf(docType, detail);
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '$docType-$docId-thermal',
    );
  }

  String _detailPath(String docType, String id) => switch (docType) {
    'invoice' => '/api/invoices/$id/',
    'receipt' => '/api/receipts/$id/',
    'waybill' => '/api/waybills/$id/',
    'quotation' => '/api/quotations/$id/',
    _ => '/api/$docType/$id/',
  };
}
