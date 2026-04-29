class Env {
  // Simple compile-time string obfuscation via XOR.
  // This prevents credentials from showing up as plaintext strings in the compiled binary.
  
  static String get ttlockClientId => _decode([117, 115, 38, 122, 113, 32, 116, 115, 122, 118, 117, 35, 118, 39, 115, 119, 123, 114, 114, 115, 39, 117, 38, 123, 122, 38, 36, 117, 115, 123, 119, 112]);
  
  static String get ttlockClientSecret => _decode([39, 119, 115, 33, 114, 35, 122, 117, 35, 112, 122, 119, 118, 114, 119, 113, 123, 122, 113, 119, 114, 123, 32, 116, 113, 114, 32, 112, 115, 122, 123, 118]);
  
  static String get ttlockUsername => _decode([35, 42, 47, 39, 54, 41, 35, 59, 48, 35, 59, 35, 52, 55, 56, 2, 37, 47, 35, 43, 46, 108, 33, 45, 47]);
  
  static String get ttlockPassword => _decode([0, 35, 49, 35, 41, 49, 39, 42, 43, 48, 115, 122, 114, 116, 114, 118]);

  static String _decode(List<int> bytes) {
    return String.fromCharCodes(bytes.map((e) => e ^ 0x42));
  }
}
