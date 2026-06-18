import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/api_shapes.dart';
import '../../../core/widgets/live_web_page_screen.dart';
import '../../auth/application/auth_controller.dart';
import '../../modules/data/reference_data.dart';

// ── Business Profile Form Sheet ────────────────────────────────────────────────
//
// Field keys mirror apps/directory BusinessProfileSerializer:
//   business_name (required), phone (required), category & country (int IDs),
//   working_hours ({"mon":"9-5"} map), social_links [{platform, url}],
//   service_summaries [{name, description, price_optional, is_featured}].
//
// The serializer mixes nested object arrays with file fields (logo, cover_image,
// gallery images). DRF multipart can't reliably parse nested object arrays, and
// JSON can't carry files, so the save runs in two steps:
//   1. JSON write  → scalars + working_hours + social_links + service_summaries.
//   2. Multipart write → logo / cover_image / gallery images (only if chosen).

class BusinessProfileFormSheet extends ConsumerStatefulWidget {
  const BusinessProfileFormSheet({super.key, this.existing});
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
      builder: (_) => BusinessProfileFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<BusinessProfileFormSheet> createState() =>
      _BusinessProfileFormState();
}

const _kDays = <(String, String)>[
  ('mon', 'Monday'),
  ('tue', 'Tuesday'),
  ('wed', 'Wednesday'),
  ('thu', 'Thursday'),
  ('fri', 'Friday'),
  ('sat', 'Saturday'),
  ('sun', 'Sunday'),
];

class _SocialLink {
  _SocialLink({String platform = '', String url = ''}) {
    platformCtrl = TextEditingController(text: platform);
    urlCtrl = TextEditingController(text: url);
  }
  late TextEditingController platformCtrl;
  late TextEditingController urlCtrl;
  void dispose() {
    platformCtrl.dispose();
    urlCtrl.dispose();
  }
}

class _ServiceSummary {
  _ServiceSummary({
    String name = '',
    String description = '',
    String price = '',
    this.featured = false,
  }) {
    nameCtrl = TextEditingController(text: name);
    descCtrl = TextEditingController(text: description);
    priceCtrl = TextEditingController(text: price);
  }
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController priceCtrl;
  bool featured;
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _GalleryItem {
  _GalleryItem({required this.file, String caption = ''}) {
    captionCtrl = TextEditingController(text: caption);
  }
  final XFile file;
  late TextEditingController captionCtrl;
  void dispose() => captionCtrl.dispose();
}

class _BusinessProfileFormState
    extends ConsumerState<BusinessProfileFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // BUSINESS DETAILS
  final _businessName = TextEditingController();
  int? _categoryId;
  final _subcategory = TextEditingController();
  final _description = TextEditingController();

  // CONTACT
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _website = TextEditingController();

  // LOCATION
  int? _countryId;
  final _state = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _address = TextEditingController();
  final _addressLine2 = TextEditingController();

  // BRANDING
  final _brandColor = TextEditingController(text: '#0274ff');
  XFile? _logoFile;
  XFile? _coverFile;

  // WORKING HOURS (day key -> controller)
  late final Map<String, TextEditingController> _hours = {
    for (final d in _kDays) d.$1: TextEditingController(),
  };

  // SOCIAL LINKS
  final List<_SocialLink> _social = [];

  // GALLERY
  final List<_GalleryItem> _gallery = [];

  // SERVICE SUMMARIES
  final List<_ServiceSummary> _services = [];

  // STATE
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFromExisting();
    _prefillFromUser();
  }

  void _prefillFromExisting() {
    final e = widget.existing;
    if (e == null) return;
    _businessName.text = e['business_name']?.toString() ?? '';
    _categoryId = _refId(e['category']);
    _subcategory.text = e['subcategory']?.toString() ?? '';
    _description.text = e['description']?.toString() ?? '';
    _email.text = e['email']?.toString() ?? '';
    _phone.text = e['phone']?.toString() ?? '';
    _whatsapp.text = e['whatsapp']?.toString() ?? '';
    _website.text = e['website']?.toString() ?? '';
    _countryId = _refId(e['country']);
    _state.text = e['state']?.toString() ?? '';
    _city.text = e['city']?.toString() ?? '';
    _postalCode.text = e['postal_code']?.toString() ?? '';
    _address.text = e['address']?.toString() ?? '';
    _addressLine2.text = e['address_line_2']?.toString() ?? '';
    if ((e['brand_color']?.toString() ?? '').isNotEmpty) {
      _brandColor.text = e['brand_color'].toString();
    }
    final wh = e['working_hours'];
    if (wh is Map) {
      for (final d in _kDays) {
        _hours[d.$1]!.text = wh[d.$1]?.toString() ?? '';
      }
    }
    final links = e['social_links'];
    if (links is List) {
      for (final l in links.whereType<Map>()) {
        _social.add(
          _SocialLink(
            platform: l['platform']?.toString() ?? '',
            url: l['url']?.toString() ?? '',
          ),
        );
      }
    }
    final services = e['service_summaries'];
    if (services is List) {
      for (final s in services.whereType<Map>()) {
        _services.add(
          _ServiceSummary(
            name: s['name']?.toString() ?? '',
            description: s['description']?.toString() ?? '',
            price: s['price_optional']?.toString() ?? '',
            featured: s['is_featured'] == true,
          ),
        );
      }
    }
  }

  void _prefillFromUser() {
    if (widget.existing != null) return;
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    if (_businessName.text.isEmpty) _businessName.text = user.displayName;
    if (_email.text.isEmpty) _email.text = user.email;
  }

  static int? _refId(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is Map) return _refId(raw['id'] ?? raw['public_id']);
    return int.tryParse(raw.toString());
  }

  @override
  void dispose() {
    for (final c in [
      _businessName,
      _subcategory,
      _description,
      _email,
      _phone,
      _whatsapp,
      _website,
      _state,
      _city,
      _postalCode,
      _address,
      _addressLine2,
      _brandColor,
      ..._hours.values,
    ]) {
      c.dispose();
    }
    for (final s in _social) {
      s.dispose();
    }
    for (final g in _gallery) {
      g.dispose();
    }
    for (final s in _services) {
      s.dispose();
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

  // ── Image pickers ─────────────────────────────────────────────────────────

  Future<void> _pickBranding(bool isLogo) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() {
      if (isLogo) {
        _logoFile = file;
      } else {
        _coverFile = file;
      }
    });
  }

  Future<void> _addGalleryImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    setState(() => _gallery.add(_GalleryItem(file: file)));
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fill in all required fields');
      return;
    }
    if (_categoryId == null || _countryId == null) {
      _showError('Select a category and country');
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final existingId =
          (widget.existing?['public_id']?.toString() ??
                  widget.existing?['id']?.toString() ??
                  '')
              .trim();
      final isCreate = existingId.isEmpty;

      // ── Step 1: JSON write (scalars + nested arrays) ──────────────────────
      final body = <String, dynamic>{
        'business_name': _businessName.text.trim(),
        'phone': _phone.text.trim(),
        'category': _categoryId,
        'country': _countryId,
        'brand_color': _brandColor.text.trim().isEmpty
            ? '#0274ff'
            : _brandColor.text.trim(),
        'working_hours': _workingHoursPayload(),
        'social_links': _socialPayload(),
        'service_summaries': _servicesPayload(),
      };
      _putIfNotEmpty(body, 'subcategory', _subcategory.text);
      _putIfNotEmpty(body, 'description', _description.text);
      _putIfNotEmpty(body, 'email', _email.text);
      _putIfNotEmpty(body, 'whatsapp', _whatsapp.text);
      _putIfNotEmpty(body, 'website', _website.text);
      _putIfNotEmpty(body, 'state', _state.text);
      _putIfNotEmpty(body, 'city', _city.text);
      _putIfNotEmpty(body, 'postal_code', _postalCode.text);
      _putIfNotEmpty(body, 'address', _address.text);
      _putIfNotEmpty(body, 'address_line_2', _addressLine2.text);
      if (isCreate) body['publish_status'] = 'draft';

      final String id;
      var slug = widget.existing?['slug']?.toString() ?? '';
      if (isCreate) {
        final created = unwrapData(
          await api.postMap('/api/v1/business-profile/', body),
        );
        id = created['public_id']?.toString() ?? '';
        slug = created['slug']?.toString() ?? '';
      } else {
        await api.patchMap('/api/v1/business-profile/$existingId/', body);
        id = existingId;
      }

      // ── Step 2: multipart write (files) ───────────────────────────────────
      final files = <String, String>{
        if (_logoFile != null) 'logo': _logoFile!.path,
        if (_coverFile != null) 'cover_image': _coverFile!.path,
      };
      final fileFields = <String, String>{};
      for (var i = 0; i < _gallery.length; i++) {
        files['gallery_items[$i][image]'] = _gallery[i].file.path;
        final caption = _gallery[i].captionCtrl.text.trim();
        if (caption.isNotEmpty) {
          fileFields['gallery_items[$i][caption]'] = caption;
        }
      }
      if (id.isNotEmpty && files.isNotEmpty) {
        await api.multipartPatch(
          '/api/v1/business-profile/$id/',
          fields: fileFields,
          files: files,
        );
      }

      // ── On create: auto-publish, then open the live public page ───────────
      if (isCreate) {
        var liveUrl = '';
        try {
          await api.postMap(
            '/api/v1/business-profile/$id/publish/',
            const <String, dynamic>{},
          );
          if (slug.isNotEmpty) {
            final pub = unwrapData(
              await api.getMap('/api/v1/business-profile/public/$slug/'),
            );
            liveUrl = _resolveLiveUrl(pub['public_url']?.toString() ?? '');
          }
        } catch (_) {
          // Publishing is best-effort; the profile is still saved as a draft.
        }
        if (mounted) {
          final rootNav = Navigator.of(context, rootNavigator: true);
          Navigator.of(context).pop(true);
          if (liveUrl.isNotEmpty) {
            rootNav.push(
              MaterialPageRoute(
                builder: (_) => LiveWebPageScreen(
                  url: liveUrl,
                  title: _businessName.text.trim().isEmpty
                      ? 'Live Page'
                      : _businessName.text.trim(),
                ),
              ),
            );
          }
        }
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Turns the API's `public_url` into an absolute live-page URL. When the
  /// backend has no public base URL configured it returns a relative path, so
  /// we fall back to the production directory domain.
  String _resolveLiveUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final path = raw.startsWith('/') ? raw : '/$raw';
    return 'https://topwebsuite.online$path';
  }

  void _putIfNotEmpty(Map<String, dynamic> body, String key, String value) {
    final v = value.trim();
    if (v.isNotEmpty) body[key] = v;
  }

  Map<String, String> _workingHoursPayload() {
    final out = <String, String>{};
    for (final d in _kDays) {
      final v = _hours[d.$1]!.text.trim();
      if (v.isNotEmpty) out[d.$1] = v;
    }
    return out;
  }

  List<Map<String, String>> _socialPayload() => _social
      .where(
        (s) =>
            s.platformCtrl.text.trim().isNotEmpty &&
            s.urlCtrl.text.trim().isNotEmpty,
      )
      .map(
        (s) => {
          'platform': s.platformCtrl.text.trim(),
          'url': s.urlCtrl.text.trim(),
        },
      )
      .toList();

  List<Map<String, dynamic>> _servicesPayload() => _services
      .where((s) => s.nameCtrl.text.trim().isNotEmpty)
      .map(
        (s) => <String, dynamic>{
          'name': s.nameCtrl.text.trim(),
          'description': s.descCtrl.text.trim(),
          'is_featured': s.featured,
          if (s.priceCtrl.text.trim().isNotEmpty)
            'price_optional': s.priceCtrl.text.trim(),
        },
      )
      .toList();

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
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
              _BFormHeader(
                title: isEdit
                    ? 'Edit Business Profile'
                    : 'Create Business Profile',
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
                    _buildBusinessDetails(),
                    const SizedBox(height: 18),
                    _buildContact(),
                    const SizedBox(height: 18),
                    _buildLocation(),
                    const SizedBox(height: 18),
                    _buildBranding(),
                    const SizedBox(height: 18),
                    _buildWorkingHours(),
                    const SizedBox(height: 18),
                    _buildSocialLinks(),
                    const SizedBox(height: 18),
                    _buildGallery(),
                    const SizedBox(height: 18),
                    _buildServices(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _BFormBottomBar(
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

  Widget _buildBusinessDetails() {
    final categories = ref.watch(businessCategoriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'BUSINESS DETAILS', badge: 'Identity'),
        const SizedBox(height: 12),
        _BLabel('Business Name'),
        const SizedBox(height: 6),
        _BField(
          controller: _businessName,
          hint: 'Your business name',
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _BLabel('Category'),
        const SizedBox(height: 6),
        categories.when(
          data: (list) => _BIntDropdown(
            value: _categoryId,
            items: list,
            hint: 'Select category',
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          loading: () => const _BLoadingField(),
          error: (_, __) => const Text(
            'Could not load categories',
            style: TextStyle(fontSize: 12, color: TopwebsuiteTheme.danger),
          ),
        ),
        const SizedBox(height: 12),
        _BLabel('Subcategory'),
        const SizedBox(height: 6),
        _BField(controller: _subcategory, hint: 'e.g. Software'),
        const SizedBox(height: 12),
        _BLabel('Description'),
        const SizedBox(height: 6),
        _BField(
          controller: _description,
          hint: 'What does your business do?',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'CONTACT', badge: 'How to reach you'),
        const SizedBox(height: 12),
        _BLabel('Email'),
        const SizedBox(height: 6),
        _BField(
          controller: _email,
          hint: 'business@email.com',
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _BLabel('Phone'),
        const SizedBox(height: 6),
        _BField(
          controller: _phone,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 12),
        _BLabel('WhatsApp'),
        const SizedBox(height: 6),
        _BField(
          controller: _whatsapp,
          hint: '+234 800 000 0000',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _BLabel('Website'),
        const SizedBox(height: 6),
        _BField(
          controller: _website,
          hint: 'https://yourwebsite.com',
          keyboard: TextInputType.url,
        ),
      ],
    );
  }

  Widget _buildLocation() {
    final countries = ref.watch(countriesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'LOCATION', badge: 'Where you operate'),
        const SizedBox(height: 12),
        _BLabel('Country'),
        const SizedBox(height: 6),
        countries.when(
          data: (list) => _BIntDropdown(
            value: _countryId,
            items: list,
            hint: 'Select country',
            onChanged: (v) => setState(() => _countryId = v),
          ),
          loading: () => const _BLoadingField(),
          error: (_, __) => const Text(
            'Could not load countries',
            style: TextStyle(fontSize: 12, color: TopwebsuiteTheme.danger),
          ),
        ),
        const SizedBox(height: 12),
        _BLabel('State'),
        const SizedBox(height: 6),
        _BField(controller: _state, hint: 'State / region'),
        const SizedBox(height: 12),
        _BLabel('City'),
        const SizedBox(height: 6),
        _BField(controller: _city, hint: 'City'),
        const SizedBox(height: 12),
        _BLabel('Postal Code'),
        const SizedBox(height: 6),
        _BField(controller: _postalCode, hint: 'Postal / ZIP code'),
        const SizedBox(height: 12),
        _BLabel('Address'),
        const SizedBox(height: 6),
        _BField(controller: _address, hint: 'Street address', maxLines: 2),
        const SizedBox(height: 12),
        _BLabel('Address Line 2'),
        const SizedBox(height: 6),
        _BField(controller: _addressLine2, hint: 'Suite, unit, etc.'),
      ],
    );
  }

  Widget _buildBranding() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'BRANDING', badge: 'Customize'),
        const SizedBox(height: 12),
        _BLabel('Brand Color'),
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
              child: _BField(
                controller: _brandColor,
                hint: '#0274ff',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BLabel('Logo'),
        const SizedBox(height: 6),
        _BImagePickerTile(
          file: _logoFile,
          placeholder: 'Upload Logo',
          height: 72,
          onTap: () => _pickBranding(true),
        ),
        const SizedBox(height: 12),
        _BLabel('Cover Image'),
        const SizedBox(height: 6),
        _BImagePickerTile(
          file: _coverFile,
          placeholder: 'Upload Cover Image',
          height: 110,
          onTap: () => _pickBranding(false),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'WORKING HOURS', badge: 'Optional'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              final mon = _hours['mon']!.text;
              setState(() {
                for (final d in ['tue', 'wed', 'thu', 'fri']) {
                  _hours[d]!.text = mon;
                }
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: TopwebsuiteTheme.primary,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.copy_all_rounded, size: 16),
            label: const Text(
              'Apply Monday to weekdays',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 4),
        for (final d in _kDays) ...[
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  d.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TopwebsuiteTheme.ink,
                  ),
                ),
              ),
              Expanded(
                child: _BField(controller: _hours[d.$1]!, hint: 'e.g. 9-5'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'SOCIAL LINKS', badge: 'Optional'),
        const SizedBox(height: 12),
        for (var i = 0; i < _social.length; i++) ...[
          Row(
            children: [
              SizedBox(
                width: 110,
                child: _BField(
                  controller: _social[i].platformCtrl,
                  hint: 'Platform',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BField(
                  controller: _social[i].urlCtrl,
                  hint: 'https://...',
                  keyboard: TextInputType.url,
                ),
              ),
              const SizedBox(width: 6),
              _BRemoveBtn(
                onTap: () => setState(() {
                  _social[i].dispose();
                  _social.removeAt(i);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _BAddBtn(
          label: 'Add Social Link',
          onTap: () => setState(() => _social.add(_SocialLink())),
        ),
      ],
    );
  }

  Widget _buildGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'GALLERY', badge: 'Images'),
        const SizedBox(height: 12),
        for (var i = 0; i < _gallery.length; i++) ...[
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_gallery[i].file.path),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _BField(
                  controller: _gallery[i].captionCtrl,
                  hint: 'Caption (optional)',
                ),
              ),
              const SizedBox(width: 6),
              _BRemoveBtn(
                onTap: () => setState(() {
                  _gallery[i].dispose();
                  _gallery.removeAt(i);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _BAddBtn(label: 'Add Image', onTap: _addGalleryImage),
      ],
    );
  }

  Widget _buildServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BSecHead(title: 'SERVICE SUMMARIES', badge: 'Optional'),
        const SizedBox(height: 12),
        for (var i = 0; i < _services.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TopwebsuiteTheme.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BField(
                        controller: _services[i].nameCtrl,
                        hint: 'Service name',
                      ),
                    ),
                    const SizedBox(width: 6),
                    _BRemoveBtn(
                      onTap: () => setState(() {
                        _services[i].dispose();
                        _services.removeAt(i);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _BField(
                  controller: _services[i].descCtrl,
                  hint: 'Short description',
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _BField(
                        controller: _services[i].priceCtrl,
                        hint: 'Price (optional)',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: _services[i].featured,
                          activeColor: TopwebsuiteTheme.primary,
                          onChanged: (v) => setState(
                            () => _services[i].featured = v ?? false,
                          ),
                        ),
                        const Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 12,
                            color: TopwebsuiteTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        _BAddBtn(
          label: 'Add Service',
          onTap: () => setState(() => _services.add(_ServiceSummary())),
        ),
      ],
    );
  }
}

// ── Shared Business Profile form widgets ──────────────────────────────────────

class _BFormHeader extends StatelessWidget {
  const _BFormHeader({required this.title, required this.onClose});
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
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: TopwebsuiteTheme.ink,
              ),
            ),
          ),
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

class _BFormBottomBar extends StatelessWidget {
  const _BFormBottomBar({
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
                saving ? 'Saving...' : 'Save Profile',
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

class _BSecHead extends StatelessWidget {
  const _BSecHead({required this.title, required this.badge});
  final String title;
  final String badge;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: TopwebsuiteTheme.ink,
          ),
        ),
      ),
      Text(
        badge,
        style: const TextStyle(fontSize: 11, color: TopwebsuiteTheme.muted),
      ),
    ],
  );
}

class _BLabel extends StatelessWidget {
  const _BLabel(this.text);
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

class _BField extends StatelessWidget {
  const _BField({
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
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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

class _BLoadingField extends StatelessWidget {
  const _BLoadingField();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 44,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _BIntDropdown extends StatelessWidget {
  const _BIntDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });
  final int? value;
  final List<Map<String, dynamic>> items;
  final String hint;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ids = items.map((e) => e['id']).whereType<int>().toSet();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: TopwebsuiteTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: ids.contains(value) ? value : null,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          dropdownColor: Colors.white,
          style: const TextStyle(fontSize: 13, color: TopwebsuiteTheme.ink),
          iconEnabledColor: TopwebsuiteTheme.muted,
          items: items.map((c) {
            final id = c['id'] as int?;
            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                c['name']?.toString() ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TopwebsuiteTheme.ink,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BImagePickerTile extends StatelessWidget {
  const _BImagePickerTile({
    required this.file,
    required this.placeholder,
    required this.height,
    required this.onTap,
  });
  final XFile? file;
  final String placeholder;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: TopwebsuiteTheme.border),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFF8FAFB),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(File(file!.path), fit: BoxFit.cover),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 22,
                    color: TopwebsuiteTheme.muted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    placeholder,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TopwebsuiteTheme.ink,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BAddBtn extends StatelessWidget {
  const _BAddBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: TopwebsuiteTheme.primary),
          borderRadius: BorderRadius.circular(8),
          color: TopwebsuiteTheme.primarySoft,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 16,
              color: TopwebsuiteTheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TopwebsuiteTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BRemoveBtn extends StatelessWidget {
  const _BRemoveBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 16,
          color: TopwebsuiteTheme.danger,
        ),
      ),
    );
  }
}
