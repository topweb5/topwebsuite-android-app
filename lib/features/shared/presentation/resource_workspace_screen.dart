import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/env.dart';
import '../../../app/theme.dart';
import '../../../core/services/file_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../../core/utils/api_shapes.dart';
import '../../../core/widgets/web_status_chip.dart';
import '../data/resource_repository.dart';
import '../domain/field_config.dart';
import '../domain/resource_config.dart';

final resourceListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ResourceConfig>((
      ref,
      config,
    ) {
      return ref.watch(resourceRepositoryProvider).list(config);
    });

class ResourceWorkspaceScreen extends ConsumerWidget {
  const ResourceWorkspaceScreen({super.key, required this.config});

  final ResourceConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(resourceListProvider(config));
    return Scaffold(
      appBar: AppBar(title: Text(config.title)),
      body: rows.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(resourceListProvider(config)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(config: config, count: items.length),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const _EmptyPanel()
              else
                for (final row in items)
                  _ResourceCard(config: config, row: row),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString()),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic>? row,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResourceForm(config: config, row: row),
    );
    if (saved == true) ref.invalidate(resourceListProvider(config));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.config, required this.count});

  final ResourceConfig config;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: TopwebsuiteTheme.border),
        gradient: const LinearGradient(
          colors: [Colors.white, TopwebsuiteTheme.primarySoft],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebStatusChip(
            label: 'Synced with web',
            tone: WebStatusTone.draft,
          ),
          const SizedBox(height: 14),
          Text(
            config.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$count record${count == 1 ? '' : 's'} from the same backend used by PFED.',
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 46,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No records yet',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Create the first record here or from the web app.'),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends ConsumerWidget {
  const _ResourceCard({required this.config, required this.row});

  final ResourceConfig config;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = stringValue(row, config.idKeys);
    final title = stringValue(row, config.titleKeys, fallback: id);
    final subtitle = stringValue(
      row,
      config.subtitleKeys,
      fallback: 'Tap edit to update',
    );
    final status = stringValue(row, [
      'status',
      'publish_status',
      'delivery_status',
    ], fallback: 'Ready');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: TopwebsuiteTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: TopwebsuiteTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: TopwebsuiteTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  WebStatusChip(label: status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openForm(context, ref),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  if (config.downloadPath != null && id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(fileServiceProvider)
                          .openPdf(config.downloadPath!(id), '$title.pdf'),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF'),
                    ),
                  if (config.downloadPath != null && id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => ref
                          .read(fileServiceProvider)
                          .sharePdf(config.downloadPath!(id), '$title.pdf'),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  if (config.previewPath != null && id.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final token = await ref
                            .read(secureTokenStoreProvider)
                            .readAccessToken();
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BackendPreviewScreen(
                              title: title,
                              path: config.previewPath!(id),
                              token: token,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Preview'),
                    ),
                  OutlinedButton.icon(
                    onPressed: id.isEmpty
                        ? null
                        : () async {
                            await ref
                                .read(resourceRepositoryProvider)
                                .remove(config, id);
                            ref.invalidate(resourceListProvider(config));
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResourceForm(config: config, row: row),
    );
    if (saved == true) ref.invalidate(resourceListProvider(config));
  }
}

class _ResourceForm extends ConsumerStatefulWidget {
  const _ResourceForm({required this.config, this.row});

  final ResourceConfig config;
  final Map<String, dynamic>? row;

  @override
  ConsumerState<_ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends ConsumerState<_ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  late final List<_LineItemControllers> _lineItems;
  bool _saving = false;
  String get _draftKey => 'draft_${widget.config.key}';

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final field in widget.config.fields)
        field.key: TextEditingController(
          text: widget.row?[field.key]?.toString() ?? '',
        ),
    };
    for (final controller in _controllers.values) {
      controller.addListener(_saveDraft);
    }
    _lineItems = [];
    if (widget.config.hasLineItems) {
      final items = widget.row?['items'];
      if (items is List && items.isNotEmpty) {
        for (final item in items.whereType<Map>()) {
          _lineItems.add(_LineItemControllers.fromMap(item));
        }
      } else {
        _lineItems.add(_LineItemControllers.empty());
      }
    }
    if (widget.row == null) {
      Future.microtask(_loadDraft);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .92,
      builder: (context, controller) => Material(
        color: TopwebsuiteTheme.surface,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              widget.row == null
                  ? 'Create ${widget.config.title}'
                  : 'Edit ${widget.config.title}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  for (final field in widget.config.fields) ...[
                    TextFormField(
                      controller: _controllers[field.key],
                      maxLines: field.multiline ? 4 : 1,
                      keyboardType: switch (field.keyboard) {
                        FieldKeyboard.email => TextInputType.emailAddress,
                        FieldKeyboard.phone => TextInputType.phone,
                        FieldKeyboard.number => TextInputType.number,
                        FieldKeyboard.date => TextInputType.datetime,
                        FieldKeyboard.url => TextInputType.url,
                        FieldKeyboard.text => TextInputType.text,
                      },
                      decoration: InputDecoration(labelText: field.label),
                      validator: field.required
                          ? (value) => value == null || value.trim().isEmpty
                                ? 'Required'
                                : null
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (widget.config.hasLineItems) ...[
                    const SizedBox(height: 6),
                    _LineItemsEditor(
                      items: _lineItems,
                      onChanged: () {
                        setState(() {});
                        _saveDraft();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    if (widget.config.hasLineItems) {
      final items = _lineItems
          .map((item) => item.toPayload())
          .where((item) => (item['description'] ?? '').toString().isNotEmpty)
          .toList();
      if (items.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one line item.')),
        );
        return;
      }
      payload['items'] = items;
    }
    try {
      final id = stringValue(widget.row ?? {}, widget.config.idKeys);
      if (widget.row == null || id.isEmpty) {
        await ref
            .read(resourceRepositoryProvider)
            .create(widget.config, payload);
      } else {
        await ref
            .read(resourceRepositoryProvider)
            .update(widget.config, id, payload);
      }
      await ref.read(localStoreProvider).remove(_draftKey);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadDraft() async {
    final draft = await ref.read(localStoreProvider).readJson(_draftKey);
    if (draft == null || !mounted) return;
    for (final entry in _controllers.entries) {
      final value = draft[entry.key];
      if (value != null && entry.value.text.isEmpty) {
        entry.value.text = value.toString();
      }
    }
    final draftItems = draft['items'];
    if (widget.config.hasLineItems &&
        draftItems is List &&
        draftItems.isNotEmpty) {
      for (final item in _lineItems) {
        item.dispose();
      }
      _lineItems
        ..clear()
        ..addAll(draftItems.whereType<Map>().map(_LineItemControllers.fromMap));
      setState(() {});
    }
  }

  Future<void> _saveDraft() async {
    if (widget.row != null) return;
    final draft = <String, dynamic>{
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    };
    if (widget.config.hasLineItems) {
      draft['items'] = _lineItems.map((item) => item.toPayload()).toList();
    }
    await ref.read(localStoreProvider).writeJson(_draftKey, draft);
  }
}

class _LineItemControllers {
  _LineItemControllers({
    required this.description,
    required this.quantity,
    required this.rate,
  });

  factory _LineItemControllers.empty() {
    return _LineItemControllers(
      description: TextEditingController(),
      quantity: TextEditingController(text: '1'),
      rate: TextEditingController(),
    );
  }

  factory _LineItemControllers.fromMap(Map<dynamic, dynamic> item) {
    return _LineItemControllers(
      description: TextEditingController(
        text: item['description']?.toString() ?? '',
      ),
      quantity: TextEditingController(
        text: item['quantity']?.toString() ?? '1',
      ),
      rate: TextEditingController(
        text:
            (item['rate'] ?? item['unit_price'] ?? item['price'])?.toString() ??
            '',
      ),
    );
  }

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController rate;

  Map<String, dynamic> toPayload() {
    return {
      'description': description.text.trim(),
      'quantity': quantity.text.trim().isEmpty ? '1' : quantity.text.trim(),
      'rate': rate.text.trim().isEmpty ? '0' : rate.text.trim(),
    };
  }

  void dispose() {
    description.dispose();
    quantity.dispose();
    rate.dispose();
  }
}

class _LineItemsEditor extends StatefulWidget {
  const _LineItemsEditor({required this.items, required this.onChanged});

  final List<_LineItemControllers> items;
  final VoidCallback onChanged;

  @override
  State<_LineItemsEditor> createState() => _LineItemsEditorState();
}

class _LineItemsEditorState extends State<_LineItemsEditor> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Line items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add item',
                  onPressed: () {
                    setState(
                      () => widget.items.add(_LineItemControllers.empty()),
                    );
                    widget.onChanged();
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < widget.items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    TextFormField(
                      controller: widget.items[index].description,
                      onChanged: (_) => widget.onChanged(),
                      decoration: InputDecoration(
                        labelText: 'Item ${index + 1} description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: widget.items[index].quantity,
                            onChanged: (_) => widget.onChanged(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Qty'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: widget.items[index].rate,
                            onChanged: (_) => widget.onChanged(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rate',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove item',
                          onPressed: widget.items.length == 1
                              ? null
                              : () {
                                  final removed = widget.items.removeAt(index);
                                  removed.dispose();
                                  setState(() {});
                                  widget.onChanged();
                                },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BackendPreviewScreen extends StatefulWidget {
  const BackendPreviewScreen({
    super.key,
    required this.title,
    required this.path,
    required this.token,
  });

  final String title;
  final String path;
  final String? token;

  @override
  State<BackendPreviewScreen> createState() => _BackendPreviewScreenState();
}

class _BackendPreviewScreenState extends State<BackendPreviewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final headers = <String, String>{};
    if (widget.token != null && widget.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(AppEnv.resolve(widget.path), headers: headers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: WebViewWidget(controller: _controller),
    );
  }
}
