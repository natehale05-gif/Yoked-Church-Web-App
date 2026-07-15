/// Lightweight, deterministic password hashing for the prototype's local auth.
///
/// IMPORTANT: this is NOT secure and exists only so the demo does not store
/// plain-text passwords in the browser. Production authentication must use a
/// real backend (e.g. Firebase Auth) with proper password handling.
String hashPassword(String password) {
  const salt = 'yoked-church-demo-v1';
  final input = '$salt:$password';
  // 64-bit FNV-1a hash rendered as hex.
  var hash = BigInt.parse('14695981039346656037');
  final prime = BigInt.parse('1099511628211');
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in input.codeUnits) {
    hash = (hash ^ BigInt.from(unit)) & mask;
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

bool verifyPassword(String password, String hash) =>
    hashPassword(password) == hash;
