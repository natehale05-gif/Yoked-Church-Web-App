import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Somewhere to put a file and get a URL back.
///
/// [supportsUpload] mirrors `AuthRepository.supportsSocialSignIn`: it
/// lets the UI say plainly "this needs a configured Firebase project"
/// instead of offering a control that fails at the tap. A church that
/// only ever pastes links never needs an implementation that works.
abstract interface class FileStorage {
  bool get supportsUpload;

  /// Returns a public download URL for the stored bytes.
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  /// Best-effort removal. Failing to delete a blob must not block
  /// deleting the record that points at it, or a failed cleanup would
  /// leave an undeletable row in the library.
  Future<void> deleteAt(String url);
}

class UploadFailure implements Exception {
  final String message;

  const UploadFailure(this.message);

  @override
  String toString() => message;
}

class FirebaseFileStorage implements FileStorage {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  @override
  bool get supportsUpload => true;

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw UploadFailure(switch (error.code) {
        'unauthorized' => "You don't have permission to upload files.",
        'quota-exceeded' => 'This church has run out of file storage.',
        'retry-limit-exceeded' => 'The upload timed out. Check your connection and try again.',
        _ => "That file couldn't be uploaded. Please try again.",
      });
    }
  }

  @override
  Future<void> deleteAt(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // See the interface doc: never block the record delete.
    }
  }
}

/// Zero-backend mode. Uploading is impossible, and says so up front
/// rather than at the tap.
class UnavailableFileStorage implements FileStorage {
  const UnavailableFileStorage();

  @override
  bool get supportsUpload => false;

  @override
  Future<String> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async =>
      throw const UploadFailure('File uploads need a configured Firebase project. Paste a link instead.');

  @override
  Future<void> deleteAt(String url) async {}
}

final fileStorageProvider = Provider<FileStorage>((ref) {
  throw UnimplementedError('fileStorageProvider must be overridden in ProviderScope');
});
