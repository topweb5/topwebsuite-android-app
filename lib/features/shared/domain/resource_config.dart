import 'field_config.dart';

class ResourceConfig {
  const ResourceConfig({
    required this.key,
    required this.title,
    required this.listPath,
    required this.createPath,
    required this.detailPath,
    required this.updatePath,
    required this.deletePath,
    required this.fields,
    this.previewPath,
    this.downloadPath,
    this.hasLineItems = false,
    this.idKeys = const ['public_id', 'id'],
    this.titleKeys = const [
      'name',
      'title',
      'invoice_number',
      'receipt_number',
      'quotation_number',
      'waybill_number',
      'business_name',
      'full_name',
    ],
    this.subtitleKeys = const [
      'client_name',
      'email',
      'company_name',
      'description',
      'status',
    ],
  });

  final String key;
  final String title;
  final String listPath;
  final String createPath;
  final String Function(String id) detailPath;
  final String Function(String id) updatePath;
  final String Function(String id) deletePath;
  final String Function(String id)? previewPath;
  final String Function(String id)? downloadPath;
  final bool hasLineItems;
  final List<FieldConfig> fields;
  final List<String> idKeys;
  final List<String> titleKeys;
  final List<String> subtitleKeys;
}
