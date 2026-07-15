import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/seed.dart';
import '../models/site_content.dart';

/// Holds the editable website content and persists changes. The public site
/// and the Site Editor both read from here.
class SiteContentController extends ChangeNotifier {
  SiteContentController(this._store) {
    final saved = _store.readMap(_key);
    _content = saved != null ? SiteContent.fromJson(saved) : defaultSiteContent();
    if (saved == null) {
      _store.writeMap(_key, _content.toJson());
    }
  }

  static const _key = 'site_content';
  final LocalStore _store;
  late SiteContent _content;

  SiteContent get content => _content;

  Future<void> update(SiteContent content) async {
    _content = content;
    await _store.writeMap(_key, content.toJson());
    notifyListeners();
  }

  Future<void> resetToDefaults() => update(defaultSiteContent());
}
