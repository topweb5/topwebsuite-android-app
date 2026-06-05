import '../shared/domain/field_config.dart';
import '../shared/domain/resource_config.dart';

String _detail(String base, String id) => '$base/$id/';
String _update(String base, String id) => '$base/$id/update/';
String _delete(String base, String id) => '$base/$id/delete/';
String _plainDetail(String base, String id) => '$base/$id/';

const _businessFields = [
  FieldConfig('business_name', 'Business name', required: true),
  FieldConfig('tagline', 'Tagline'),
  FieldConfig('description', 'Description', multiline: true),
  FieldConfig('subcategory', 'Subcategory'),
  FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
  FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
  FieldConfig('whatsapp', 'WhatsApp', keyboard: FieldKeyboard.phone),
  FieldConfig('website', 'Website', keyboard: FieldKeyboard.url),
  FieldConfig('state', 'State'),
  FieldConfig('city', 'City'),
  FieldConfig('address', 'Address', multiline: true),
];

final documentConfigs = <ResourceConfig>[
  ResourceConfig(
    key: 'invoices',
    title: 'Invoices',
    listPath: '/api/invoices/',
    createPath: '/api/invoices/create/',
    detailPath: (id) => _detail('/api/invoices', id),
    updatePath: (id) => '/api/invoices/$id/partial-update/',
    deletePath: (id) => _delete('/api/invoices', id),
    previewPath: (id) => '/api/invoices/$id/preview/',
    downloadPath: (id) => '/api/invoices/$id/download/',
    hasLineItems: true,
    titleKeys: const ['invoice_number', 'client_name', 'company_name'],
    fields: const [
      FieldConfig('company_name', 'Company name', required: true),
      FieldConfig('company_address', 'Company address', multiline: true),
      FieldConfig(
        'company_phone',
        'Company phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'company_email',
        'Company email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig(
        'company_website',
        'Company website',
        keyboard: FieldKeyboard.url,
      ),
      FieldConfig('client_name', 'Client name', required: true),
      FieldConfig('client_address', 'Client address', multiline: true),
      FieldConfig(
        'client_phone',
        'Client phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'client_email',
        'Client email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig('invoice_number', 'Invoice number'),
      FieldConfig('issued_date', 'Issue date', keyboard: FieldKeyboard.date),
      FieldConfig('due_date', 'Due date', keyboard: FieldKeyboard.date),
      FieldConfig('currency', 'Currency'),
      FieldConfig(
        'discount_percent',
        'Discount percent',
        keyboard: FieldKeyboard.number,
      ),
      FieldConfig(
        'vat_percent',
        'Tax/VAT percent',
        keyboard: FieldKeyboard.number,
      ),
      FieldConfig('payment_details', 'Payment details', multiline: true),
      FieldConfig('notes', 'Notes', multiline: true),
    ],
  ),
  ResourceConfig(
    key: 'receipts',
    title: 'Receipts',
    listPath: '/api/receipts/',
    createPath: '/api/receipts/create/',
    detailPath: (id) => _detail('/api/receipts', id),
    updatePath: (id) => _update('/api/receipts', id),
    deletePath: (id) => _delete('/api/receipts', id),
    previewPath: (id) => '/api/receipts/$id/preview/',
    downloadPath: (id) => '/api/receipts/$id/download/',
    titleKeys: const ['receipt_number', 'received_from'],
    fields: const [
      FieldConfig('company_name', 'Company name', required: true),
      FieldConfig('company_address', 'Company address', multiline: true),
      FieldConfig(
        'company_phone',
        'Company phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'company_email',
        'Company email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig('receipt_number', 'Receipt number'),
      FieldConfig('date', 'Date', keyboard: FieldKeyboard.date),
      FieldConfig('received_from', 'Received from', required: true),
      FieldConfig(
        'amount',
        'Amount',
        keyboard: FieldKeyboard.number,
        required: true,
      ),
      FieldConfig('balance', 'Balance', keyboard: FieldKeyboard.number),
      FieldConfig('payment_method', 'Payment method'),
      FieldConfig('being_payment_for', 'Purpose', multiline: true),
      FieldConfig('notes', 'Notes', multiline: true),
      FieldConfig('authorized_name', 'Authorized name'),
    ],
  ),
  ResourceConfig(
    key: 'quotations',
    title: 'Quotations',
    listPath: '/api/quotations/',
    createPath: '/api/quotations/create/',
    detailPath: (id) => _detail('/api/quotations', id),
    updatePath: (id) => _update('/api/quotations', id),
    deletePath: (id) => _delete('/api/quotations', id),
    previewPath: (id) => '/api/quotations/$id/preview/',
    downloadPath: (id) => '/api/quotations/$id/download/',
    hasLineItems: true,
    titleKeys: const ['quotation_number', 'client_name'],
    fields: const [
      FieldConfig('company_name', 'Company name', required: true),
      FieldConfig('company_address', 'Company address', multiline: true),
      FieldConfig(
        'company_phone',
        'Company phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'company_email',
        'Company email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig('client_name', 'Client name', required: true),
      FieldConfig('client_address', 'Client address', multiline: true),
      FieldConfig(
        'client_phone',
        'Client phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'client_email',
        'Client email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig('quotation_number', 'Quotation number'),
      FieldConfig('date', 'Issue date', keyboard: FieldKeyboard.date),
      FieldConfig('valid_until', 'Valid until', keyboard: FieldKeyboard.date),
      FieldConfig('reference', 'Reference'),
      FieldConfig('currency', 'Currency'),
      FieldConfig(
        'discount_percent',
        'Discount percent',
        keyboard: FieldKeyboard.number,
      ),
      FieldConfig('tax_percent', 'Tax percent', keyboard: FieldKeyboard.number),
      FieldConfig('notes', 'Notes', multiline: true),
    ],
  ),
  ResourceConfig(
    key: 'waybills',
    title: 'Waybills',
    listPath: '/api/waybills/',
    createPath: '/api/waybills/create/',
    detailPath: (id) => _detail('/api/waybills', id),
    updatePath: (id) => _update('/api/waybills', id),
    deletePath: (id) => _delete('/api/waybills', id),
    previewPath: (id) => '/api/waybills/$id/preview/',
    downloadPath: (id) => '/api/waybills/$id/download/',
    titleKeys: const ['waybill_number', 'receiver_name', 'recipient_name'],
    fields: const [
      FieldConfig('company_name', 'Company name', required: true),
      FieldConfig('company_address', 'Company address', multiline: true),
      FieldConfig(
        'company_phone',
        'Company phone',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig(
        'company_email',
        'Company email',
        keyboard: FieldKeyboard.email,
      ),
      FieldConfig('waybill_number', 'Waybill number'),
      FieldConfig('date', 'Date', keyboard: FieldKeyboard.date),
      FieldConfig('sender_name', 'Sender name'),
      FieldConfig('sender_address', 'Sender address', multiline: true),
      FieldConfig('currency', 'Currency'),
      FieldConfig(
        'sender_contact',
        'Sender contact',
        keyboard: FieldKeyboard.phone,
      ),
      FieldConfig('recipient_name', 'Recipient name', required: true),
      FieldConfig(
        'recipient_address',
        'Recipient address',
        multiline: true,
        required: true,
      ),
      FieldConfig(
        'recipient_contact',
        'Recipient contact',
        keyboard: FieldKeyboard.phone,
        required: true,
      ),
      FieldConfig(
        'shipment_description',
        'Shipment description',
        multiline: true,
        required: true,
      ),
      FieldConfig(
        'shipment_value',
        'Shipment value',
        keyboard: FieldKeyboard.number,
        required: true,
      ),
      FieldConfig(
        'weight',
        'Weight kg',
        keyboard: FieldKeyboard.number,
        required: true,
      ),
      FieldConfig('status', 'Status'),
    ],
  ),
];

final letterConfigs = <ResourceConfig>[
  ResourceConfig(
    key: 'letterhead',
    title: 'Letterhead Assets',
    listPath: '/api/letterhead/',
    createPath: '/api/letterhead/create/',
    detailPath: (id) => _plainDetail('/api/letterhead', id),
    updatePath: (id) => _update('/api/letterhead', id),
    deletePath: (id) => _delete('/api/letterhead', id),
    fields: const [
      FieldConfig('title', 'Title', required: true),
      FieldConfig('page_size', 'Page size'),
      FieldConfig('margin_top', 'Top margin', keyboard: FieldKeyboard.number),
      FieldConfig(
        'margin_right',
        'Right margin',
        keyboard: FieldKeyboard.number,
      ),
      FieldConfig(
        'margin_bottom',
        'Bottom margin',
        keyboard: FieldKeyboard.number,
      ),
      FieldConfig('margin_left', 'Left margin', keyboard: FieldKeyboard.number),
    ],
  ),
  ResourceConfig(
    key: 'letters',
    title: 'Letters',
    listPath: '/api/letters/',
    createPath: '/api/letters/create/',
    detailPath: (id) => _detail('/api/letters', id),
    updatePath: (id) => _update('/api/letters', id),
    deletePath: (id) => _delete('/api/letters', id),
    previewPath: (id) => '/api/letters/$id/preview/',
    downloadPath: (id) => '/api/letters/$id/download/',
    fields: const [
      FieldConfig('title', 'Title', required: true),
      FieldConfig('content_html', 'Letter content HTML', multiline: true),
      FieldConfig('plain_text', 'Plain text', multiline: true),
      FieldConfig('page_size', 'Page size'),
      FieldConfig('orientation', 'Orientation'),
      FieldConfig('status', 'Status'),
    ],
  ),
];

final businessProfileConfig = ResourceConfig(
  key: 'business-profile',
  title: 'Business Profiles',
  listPath: '/api/v1/business-profile/',
  createPath: '/api/v1/business-profile/',
  detailPath: (id) => _plainDetail('/api/v1/business-profile', id),
  updatePath: (id) => _plainDetail('/api/v1/business-profile', id),
  deletePath: (id) => _plainDetail('/api/v1/business-profile', id),
  titleKeys: const ['business_name'],
  subtitleKeys: const ['tagline', 'city', 'email'],
  fields: _businessFields,
);

final crmConfigs = <ResourceConfig>[
  _crm('leads', 'Leads', [
    const FieldConfig('full_name', 'Full name', required: true),
    const FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    const FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    const FieldConfig('company_name', 'Company name'),
    const FieldConfig('source', 'Source'),
    const FieldConfig('status', 'Status'),
    const FieldConfig('stage', 'Stage'),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _crm('contacts', 'Contacts', [
    const FieldConfig('full_name', 'Full name', required: true),
    const FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    const FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    const FieldConfig('company_name', 'Company name'),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _crm('companies', 'Companies', [
    const FieldConfig('name', 'Company name', required: true),
    const FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    const FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    const FieldConfig('website', 'Website', keyboard: FieldKeyboard.url),
    const FieldConfig('address', 'Address', multiline: true),
  ]),
  _crm('opportunities', 'Opportunities', [
    const FieldConfig('title', 'Title', required: true),
    const FieldConfig('value', 'Value', keyboard: FieldKeyboard.number),
    const FieldConfig('stage', 'Stage'),
    const FieldConfig('status', 'Status'),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _crm('activities', 'Activities', [
    const FieldConfig('title', 'Title', required: true),
    const FieldConfig('activity_type', 'Activity type'),
    const FieldConfig('due_date', 'Due date', keyboard: FieldKeyboard.date),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
];

ResourceConfig _crm(String key, String title, List<FieldConfig> fields) {
  return ResourceConfig(
    key: key,
    title: title,
    listPath: '/api/v1/crm/$key/',
    createPath: '/api/v1/crm/$key/',
    detailPath: (id) => _plainDetail('/api/v1/crm/$key', id),
    updatePath: (id) => _plainDetail('/api/v1/crm/$key', id),
    deletePath: (id) => _plainDetail('/api/v1/crm/$key', id),
    fields: fields,
  );
}

final erpConfigs = <ResourceConfig>[
  _erp('products', 'Products', [
    const FieldConfig('name', 'Name', required: true),
    const FieldConfig('sku', 'SKU'),
    const FieldConfig('description', 'Description', multiline: true),
    const FieldConfig('category', 'Category'),
    const FieldConfig(
      'unit_price',
      'Unit price',
      keyboard: FieldKeyboard.number,
    ),
    const FieldConfig(
      'stock_quantity',
      'Stock quantity',
      keyboard: FieldKeyboard.number,
    ),
    const FieldConfig(
      'reorder_level',
      'Reorder level',
      keyboard: FieldKeyboard.number,
    ),
  ]),
  _erp('services', 'Services', [
    const FieldConfig('name', 'Name', required: true),
    const FieldConfig('description', 'Description', multiline: true),
    const FieldConfig(
      'unit_price',
      'Unit price',
      keyboard: FieldKeyboard.number,
    ),
  ]),
  _erp('customers', 'Customers', [
    const FieldConfig('full_name', 'Full name', required: true),
    const FieldConfig('company_name', 'Company name'),
    const FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    const FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    const FieldConfig('address', 'Address', multiline: true),
    const FieldConfig('city', 'City'),
    const FieldConfig('state', 'State'),
    const FieldConfig('country', 'Country'),
  ]),
  _erp('orders', 'Orders', [
    const FieldConfig('order_number', 'Order number', required: true),
    const FieldConfig('status', 'Status'),
    const FieldConfig('tax', 'Tax', keyboard: FieldKeyboard.number),
    const FieldConfig('discount', 'Discount', keyboard: FieldKeyboard.number),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _erp('procurements', 'Procurements', [
    const FieldConfig('title', 'Title', required: true),
    const FieldConfig('status', 'Status'),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _erp('deliveries', 'Deliveries', [
    const FieldConfig('tracking_number', 'Tracking number'),
    const FieldConfig('delivery_status', 'Delivery status'),
    const FieldConfig(
      'dispatch_date',
      'Dispatch date',
      keyboard: FieldKeyboard.date,
    ),
    const FieldConfig(
      'delivery_date',
      'Delivery date',
      keyboard: FieldKeyboard.date,
    ),
    const FieldConfig(
      'delivery_address',
      'Delivery address',
      multiline: true,
      required: true,
    ),
    const FieldConfig('notes', 'Notes', multiline: true),
  ]),
];

ResourceConfig _erp(String key, String title, List<FieldConfig> fields) {
  return ResourceConfig(
    key: key,
    title: title,
    listPath: '/api/v1/erp/$key/',
    createPath: '/api/v1/erp/$key/',
    detailPath: (id) => _plainDetail('/api/v1/erp/$key', id),
    updatePath: (id) => _plainDetail('/api/v1/erp/$key', id),
    deletePath: (id) => _plainDetail('/api/v1/erp/$key', id),
    fields: fields,
  );
}
