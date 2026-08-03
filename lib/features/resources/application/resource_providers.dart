import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/file_storage.dart';
import '../../auth/application/auth_providers.dart';
import '../data/resource_repository.dart';
import '../domain/resource.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  throw UnimplementedError('resourceRepositoryProvider must be overridden in ProviderScope');
});

/// Everything, for the staff CMS.
final allResourcesProvider = StreamProvider<List<Resource>>((ref) {
  return ref.watch(resourceRepositoryProvider).watchAll();
});

/// What the current viewer may see. Members-only items disappear for
/// signed-out visitors; the filter lives here so no screen can forget it.
final visibleResourcesProvider = Provider<AsyncValue<List<Resource>>>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  return ref.watch(allResourcesProvider).whenData(
        (all) => all.where((r) => signedIn || !r.membersOnly).toList(),
      );
});

/// Categories present in what the viewer can actually see, so the filter
/// row never offers a category that would come back empty.
final resourceCategoriesProvider = Provider<List<String>>((ref) {
  final visible = ref.watch(visibleResourcesProvider).valueOrNull ?? const <Resource>[];
  final categories = visible.map((r) => r.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
  return categories;
});

final resourceSearchQueryProvider = StateProvider<String>((ref) => '');
final resourceCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredResourcesProvider = Provider<AsyncValue<List<Resource>>>((ref) {
  final query = ref.watch(resourceSearchQueryProvider);
  final category = ref.watch(resourceCategoryFilterProvider);

  return ref.watch(visibleResourcesProvider).whenData(
        (visible) => visible
            .where((r) => (category == null || r.category == category) && r.matches(query))
            .toList(),
      );
});

final resourceControllerProvider = Provider<ResourceController>((ref) => ResourceController(ref));

class ResourceController {
  final Ref _ref;
  final Random _random = Random();

  ResourceController(this._ref);

  bool get canUpload => _ref.read(fileStorageProvider).supportsUpload;

  /// Store bytes and return the pair the record needs. Kept here rather
  /// than in the dialog so the upload path is testable without a widget.
  Future<({String url, String storagePath})> uploadFile({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    // Unique-prefixed so two files with the same name don't overwrite
    // each other, and sanitised so a name can't escape the resources/
    // prefix. The random component matters: a timestamp alone collides
    // for two uploads inside the same millisecond.
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final unique = '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1 << 20)}';
    final path = 'resources/${unique}_$safe';
    final url = await _ref.read(fileStorageProvider).upload(
          path: path,
          bytes: bytes,
          contentType: contentType,
        );
    return (url: url, storagePath: path);
  }

  Future<void> save(Resource resource, {Resource? replacing}) async {
    final repo = _ref.read(resourceRepositoryProvider);
    if (replacing == null) {
      await repo.create(resource);
    } else {
      await repo.update(resource);
      // An edit that swapped an uploaded file for a different one leaves
      // the old blob orphaned otherwise.
      if (replacing.isUpload && replacing.storagePath != resource.storagePath) {
        await _ref.read(fileStorageProvider).deleteAt(replacing.url);
      }
    }
    _ref.invalidate(allResourcesProvider);
  }

  Future<void> delete(Resource resource) async {
    await _ref.read(resourceRepositoryProvider).delete(resource.id);
    if (resource.isUpload) await _ref.read(fileStorageProvider).deleteAt(resource.url);
    _ref.invalidate(allResourcesProvider);
  }
}
