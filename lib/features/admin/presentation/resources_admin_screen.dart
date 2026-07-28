import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/file_storage.dart';
import '../../audit_log/application/audit_providers.dart';
import '../../resources/application/resource_providers.dart';
import '../../resources/domain/resource.dart';
import '../../resources/presentation/resources_screen.dart';
import 'admin_header.dart';

class ResourcesAdminScreen extends ConsumerWidget {
  const ResourcesAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openForm({Resource? existing}) async {
      final result = await showDialog<Resource>(
        context: context,
        builder: (_) => _ResourceForm(existing: existing),
      );
      if (result == null) return;
      await ref.read(resourceControllerProvider).save(result, replacing: existing);
    }

    return AdminListScaffold<Resource>(
      title: 'Resources',
      subtitle: 'Upload a file or paste a link. Mark anything internal as members-only.',
      value: ref.watch(allResourcesProvider),
      errorContext: 'resources',
      emptyMessage: 'No resources yet. Add the first one.',
      newLabel: 'New Resource',
      maxWidth: 860,
      onNew: openForm,
      itemBuilder: (resource) => AdminListTile(
        title: resource.title,
        subtitle: [
          if (resource.category.isNotEmpty) resource.category,
          resource.isUpload ? 'Uploaded file' : 'Link',
          if (resource.membersOnly) 'Members only',
        ].join(' · '),
        deleteLabel: '"${resource.title}"',
        actions: [Icon(iconForKind(resource.kind), size: 18, color: Colors.black45)],
        onEdit: () => openForm(existing: resource),
        onDelete: () async {
          await ref.read(resourceControllerProvider).delete(resource);
          await ref.read(auditLoggerProvider).record(
                action: 'deleted',
                entity: 'resource',
                details: resource.title,
              );
        },
      ),
    );
  }
}

class _ResourceForm extends ConsumerStatefulWidget {
  final Resource? existing;

  const _ResourceForm({this.existing});

  @override
  ConsumerState<_ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends ConsumerState<_ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _url;

  late bool _membersOnly;
  String _fileName = '';
  String _storagePath = '';
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _membersOnly = e?.membersOnly ?? false;
    _fileName = e?.fileName ?? '';
    _storagePath = e?.storagePath ?? '';
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _category, _url]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    // withData, because on web there is no file path to read from later.
    final picked = await FilePicker.pickFiles(withData: true);
    final file = picked?.files.singleOrNull;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final stored = await ref.read(resourceControllerProvider).uploadFile(
            fileName: file.name,
            bytes: bytes,
            contentType: _contentTypeFor(file.extension),
          );
      if (!mounted) return;
      setState(() {
        _url.text = stored.url;
        _storagePath = stored.storagePath;
        _fileName = file.name;
        _uploading = false;
      });
    } on UploadFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadError = error.message;
      });
    }
  }

  static String _contentTypeFor(String? extension) => switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'mp3' => 'audio/mpeg',
        'mp4' => 'video/mp4',
        _ => 'application/octet-stream',
      };

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Resource(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category.text.trim(),
        url: _url.text.trim(),
        fileName: _fileName,
        storagePath: _storagePath,
        membersOnly: _membersOnly,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = ref.watch(fileStorageProvider).supportsUpload;

    return AdminFormDialog(
      title: widget.existing == null ? 'New Resource' : 'Edit Resource',
      onSave: _uploading ? () {} : _save,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category', hintText: 'Kids, Small Groups, Forms'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _url,
              decoration: InputDecoration(
                labelText: 'Link',
                hintText: 'https://…',
                helperText: _fileName.isEmpty ? null : 'Uploaded: $_fileName',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Paste a link or upload a file';
                if (!value.startsWith('http')) return 'Links should start with http';
                return null;
              },
              onChanged: (_) {
                // Typing over an uploaded file's URL means this is a link
                // now; forget the blob so it gets cleaned up on save.
                if (_storagePath.isNotEmpty) {
                  setState(() {
                    _storagePath = '';
                    _fileName = '';
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            if (canUpload)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file, size: 18),
                  label: Text(_uploading ? 'Uploading…' : 'Upload a file instead'),
                ),
              )
            else
              // Say so up front rather than offering a control that
              // fails at the tap.
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.black45),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File uploads need a configured Firebase project. Paste a link for now.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                ],
              ),
            if (_uploadError != null) ...[
              const SizedBox(height: 10),
              Text(_uploadError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13)),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Members only'),
              subtitle: const Text('Hidden from signed-out visitors.'),
              value: _membersOnly,
              onChanged: (v) => setState(() => _membersOnly = v),
            ),
          ],
        ),
      ),
    );
  }
}
