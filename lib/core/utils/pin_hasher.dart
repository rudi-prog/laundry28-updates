import 'package:bcrypt/bcrypt.dart';

/// Utility untuk hashing dan verifikasi PIN karyawan
/// Menggunakan bcrypt untuk hashing PIN (secure, slow hash yang tahan brute-force)
/// Salt otomatis di-generate oleh bcrypt dan tersimpan di dalam string hash
class PinHasher {
  /// Hash PIN menggunakan bcrypt (otomatis generate salt)
  static String hash(String pin) {
    return BCrypt.hashpw(pin, BCrypt.gensalt());
  }

  /// Verifikasi PIN dengan hash yang tersimpan
  static bool verify(String pin, String storedHash) {
    return BCrypt.checkpw(pin, storedHash);
  }

  /// Generate salt - tidak diperlukan lagi karena bcrypt handle sendiri
  /// Method ini dipertahankan untuk backward compatibility
  @Deprecated('Bcrypt handle salt secara otomatis, tidak perlu generate manual')
  static String generateSalt() {
    return '';
  }

  /// Hash PIN dengan salt - tidak diperlukan lagi
  /// Method ini dipertahankan untuk backward compatibility
  @Deprecated('Bcrypt handle salt secara otomatis, tidak perlu hashWithSalt')
  static String hashWithSalt(String pin, String salt) {
    return BCrypt.hashpw(pin, BCrypt.gensalt());
  }

  /// Verifikasi PIN dengan salt - tidak diperlukan lagi
  /// Method ini dipertahankan untuk backward compatibility
  @Deprecated('Bcrypt handle salt secara otomatis, tidak perlu verifyWithSalt')
  static bool verifyWithSalt(String pin, String storedHash, String salt) {
    return BCrypt.checkpw(pin, storedHash);
  }
}
