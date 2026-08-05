/// Turning "St. Mary's Church, Riverside" into `st-marys-church-riverside`.
///
/// The slug is the church's address forever - it is in every link they
/// print, so it is derived once at signup and never changed. Renaming
/// would break every link already shared, which is why the signup screen
/// shows it before you commit rather than after.
///
/// The same rules run again inside the Cloud Function. A client deciding
/// its own document id is a client that can be edited, so the server
/// re-derives and re-validates rather than trusting what it is handed;
/// this copy exists so a person can *see* their address as they type.
library;

/// Characters that survive: lowercase letters, digits, and the hyphens
/// that replace everything else.
String slugify(String name) {
  final lowered = name.toLowerCase().trim();
  final buffer = StringBuffer();

  for (final rune in lowered.runes) {
    final char = String.fromCharCode(rune);
    if (RegExp(r'[a-z0-9]').hasMatch(char)) {
      buffer.write(char);
    } else if (char == ' ' || char == '-' || char == '_' || char == '.' || char == ',') {
      buffer.write('-');
    }
    // Apostrophes and everything else are dropped rather than
    // hyphenated, so "St Mary's" is `st-marys`, not `st-mary-s`.
  }

  return _tidy(buffer.toString());
}

String _tidy(String slug) {
  var out = slug;
  while (out.contains('--')) {
    out = out.replaceAll('--', '-');
  }
  out = out.replaceAll(RegExp(r'^-+|-+$'), '');
  return out.length > _maxLength ? _tidy(out.substring(0, _maxLength)) : out;
}

const int _maxLength = 40;
const int _minLength = 3;

/// Ids the routing or the platform needs for itself.
///
/// `c` would collide with the route prefix; the rest would make an
/// address that reads like a mistake, or a page that shadows one of the
/// product's own.
const Set<String> reservedSlugs = {
  'c',
  'start',
  'choose-church',
  'admin',
  'api',
  'app',
  'assets',
  'yoked',
  'www',
  'help',
  'support',
  'about',
  'new',
  'signup',
  'sign-up',
  'login',
  'sign-in',
};

/// Why a slug cannot be used, or null if it can.
///
/// Returns a sentence to show a person, not an error code: this is read
/// straight out onto the signup form under the field they are typing in.
String? slugProblem(String slug) {
  if (slug.length < _minLength) {
    return 'Your address needs at least $_minLength letters. Try adding your town.';
  }
  if (slug.length > _maxLength) return 'That is too long for a web address.';
  if (!RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(slug)) {
    return 'Use letters and numbers only.';
  }
  if (reservedSlugs.contains(slug)) return 'That address is taken. Try adding your town.';
  return null;
}

/// The next free variant of a slug, given what is already taken.
///
/// Two churches called Grace Chapel is not an edge case, it is Tuesday.
/// The second one becomes `grace-chapel-2` rather than being turned away,
/// because a signup that fails on somebody else's name is a signup that
/// does not happen.
String availableSlug(String desired, Set<String> taken) {
  if (!taken.contains(desired) && !reservedSlugs.contains(desired)) return desired;
  for (var n = 2; n < 1000; n++) {
    final candidate = '$desired-$n';
    if (!taken.contains(candidate)) return candidate;
  }
  return '$desired-${DateTime.now().millisecondsSinceEpoch}';
}
