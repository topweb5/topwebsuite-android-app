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
      FieldConfig(
        'status',
        'Status',
        choices: [
          FieldChoice('open', 'Open'),
          FieldChoice('accepted', 'Accepted'),
          FieldChoice('expired', 'Expired'),
        ],
      ),
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
    titleKeys: const ['waybill_number', 'recipient_name'],
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
      FieldConfig('waybill_number', 'Waybill number'),
      FieldConfig('currency', 'Currency'),
      FieldConfig('sender_name', 'Sender name', required: true),
      FieldConfig(
        'sender_address',
        'Sender address',
        multiline: true,
        required: true,
      ),
      FieldConfig(
        'sender_contact',
        'Sender contact',
        keyboard: FieldKeyboard.phone,
        required: true,
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
      FieldConfig(
        'status',
        'Status',
        choices: [
          FieldChoice('pending', 'Pending'),
          FieldChoice('shipped', 'Shipped'),
          FieldChoice('delivered', 'Delivered'),
        ],
      ),
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
      FieldConfig(
        'status',
        'Status',
        choices: [FieldChoice('draft', 'Draft'), FieldChoice('final', 'Final')],
      ),
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

// ── CRM ── field keys mirror apps/crm/models.py exactly ──────────────────────

final crmConfigs = <ResourceConfig>[
  _crm('leads', 'Leads', const [
    FieldConfig('full_name', 'Full name', required: true),
    FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    FieldConfig('company_name', 'Company name'),
    FieldConfig(
      'source',
      'Source',
      choices: [
        FieldChoice('manual', 'Manual'),
        FieldChoice('directory_enquiry', 'Directory Enquiry'),
        FieldChoice('quote_request', 'Quote Request'),
        FieldChoice('imported', 'Imported'),
      ],
    ),
    FieldConfig(
      'status',
      'Status',
      choices: [
        FieldChoice('new', 'New'),
        FieldChoice('contacted', 'Contacted'),
        FieldChoice('qualified', 'Qualified'),
        FieldChoice('won', 'Won'),
        FieldChoice('lost', 'Lost'),
      ],
    ),
    FieldConfig(
      'stage',
      'Stage',
      choices: [
        FieldChoice('prospect', 'Prospect'),
        FieldChoice('negotiation', 'Negotiation'),
        FieldChoice('proposal', 'Proposal'),
        FieldChoice('closed', 'Closed'),
      ],
    ),
    FieldConfig('notes', 'Notes', multiline: true),
  ]),
  _crm('contacts', 'Contacts', const [
    FieldConfig('full_name', 'Full name', required: true),
    FieldConfig('email', 'Email', keyboard: FieldKeyboard.email),
    FieldConfig('phone', 'Phone', keyboard: FieldKeyboard.phone),
    FieldConfig('address_optional', 'Address', multiline: true),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _crm('companies', 'Companies', const [
    FieldConfig('name', 'Company name', required: true),
    FieldConfig('email_optional', 'Email', keyboard: FieldKeyboard.email),
    FieldConfig('phone_optional', 'Phone', keyboard: FieldKeyboard.phone),
    FieldConfig('website_optional', 'Website', keyboard: FieldKeyboard.url),
    FieldConfig('industry_optional', 'Industry'),
    FieldConfig('address_optional', 'Address', multiline: true),
    FieldConfig('city_optional', 'City'),
    FieldConfig('state_optional', 'State'),
    FieldConfig('country_optional', 'Country'),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _crm('opportunities', 'Opportunities', const [
    FieldConfig('title', 'Title', required: true),
    FieldConfig('value_optional', 'Value', keyboard: FieldKeyboard.number),
    FieldConfig(
      'stage',
      'Stage',
      choices: [
        FieldChoice('lead', 'Lead'),
        FieldChoice('discovery', 'Discovery'),
        FieldChoice('proposal', 'Proposal'),
        FieldChoice('negotiation', 'Negotiation'),
        FieldChoice('won', 'Won'),
        FieldChoice('lost', 'Lost'),
      ],
    ),
    FieldConfig(
      'probability_optional',
      'Probability %',
      keyboard: FieldKeyboard.number,
    ),
    FieldConfig(
      'expected_close_date_optional',
      'Expected close date',
      keyboard: FieldKeyboard.date,
    ),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _crm('activities', 'Activities', const [
    FieldConfig('subject', 'Subject', required: true),
    FieldConfig(
      'activity_type',
      'Activity type',
      required: true,
      choices: [
        FieldChoice('call', 'Call'),
        FieldChoice('email', 'Email'),
        FieldChoice('meeting', 'Meeting'),
        FieldChoice('task', 'Task'),
        FieldChoice('note', 'Note'),
      ],
    ),
    FieldConfig('due_date_optional', 'Due date', keyboard: FieldKeyboard.date),
    FieldConfig('note_optional', 'Note', multiline: true),
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

// ── ERP ── field keys mirror apps/erp/models.py exactly ──────────────────────

final erpConfigs = <ResourceConfig>[
  _erp('products', 'Products', const [
    FieldConfig('name', 'Name', required: true),
    FieldConfig('sku', 'SKU', required: true),
    FieldConfig('description_optional', 'Description', multiline: true),
    FieldConfig('category_optional', 'Category'),
    FieldConfig(
      'unit_price',
      'Unit price',
      keyboard: FieldKeyboard.number,
      required: true,
    ),
    FieldConfig(
      'stock_quantity',
      'Stock quantity',
      keyboard: FieldKeyboard.number,
    ),
    FieldConfig(
      'reorder_level_optional',
      'Reorder level',
      keyboard: FieldKeyboard.number,
    ),
  ]),
  _erp('services', 'Services', const [
    FieldConfig('name', 'Name', required: true),
    FieldConfig('description_optional', 'Description', multiline: true),
    FieldConfig(
      'unit_price',
      'Unit price',
      keyboard: FieldKeyboard.number,
      required: true,
    ),
  ]),
  _erp('customers', 'Customers', const [
    FieldConfig('full_name', 'Full name', required: true),
    FieldConfig('company_name_optional', 'Company name'),
    FieldConfig('email_optional', 'Email', keyboard: FieldKeyboard.email),
    FieldConfig('phone_optional', 'Phone', keyboard: FieldKeyboard.phone),
    FieldConfig('address_optional', 'Address', multiline: true),
    FieldConfig('city_optional', 'City'),
    FieldConfig('state_optional', 'State'),
    FieldConfig('country_optional', 'Country'),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _erp('orders', 'Orders', const [
    FieldConfig('order_number', 'Order number', required: true),
    FieldConfig(
      'status',
      'Status',
      choices: [
        FieldChoice('draft', 'Draft'),
        FieldChoice('confirmed', 'Confirmed'),
        FieldChoice('fulfilled', 'Fulfilled'),
        FieldChoice('cancelled', 'Cancelled'),
      ],
    ),
    FieldConfig('tax_optional', 'Tax', keyboard: FieldKeyboard.number),
    FieldConfig(
      'discount_optional',
      'Discount',
      keyboard: FieldKeyboard.number,
    ),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _erp('procurements', 'Procurements', const [
    FieldConfig('supplier_name', 'Supplier name', required: true),
    FieldConfig('reference_optional', 'Reference'),
    FieldConfig(
      'status',
      'Status',
      choices: [
        FieldChoice('pending', 'Pending'),
        FieldChoice('ordered', 'Ordered'),
        FieldChoice('received', 'Received'),
      ],
    ),
    FieldConfig('total_optional', 'Total', keyboard: FieldKeyboard.number),
    FieldConfig('notes_optional', 'Notes', multiline: true),
  ]),
  _erp('deliveries', 'Deliveries', const [
    FieldConfig('tracking_number_optional', 'Tracking number'),
    FieldConfig(
      'delivery_status',
      'Delivery status',
      choices: [
        FieldChoice('pending', 'Pending'),
        FieldChoice('dispatched', 'Dispatched'),
        FieldChoice('delivered', 'Delivered'),
      ],
    ),
    FieldConfig(
      'dispatch_date_optional',
      'Dispatch date',
      keyboard: FieldKeyboard.date,
    ),
    FieldConfig(
      'delivery_date_optional',
      'Delivery date',
      keyboard: FieldKeyboard.date,
    ),
    FieldConfig(
      'delivery_address',
      'Delivery address',
      multiline: true,
      required: true,
    ),
    FieldConfig('notes_optional', 'Notes', multiline: true),
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
