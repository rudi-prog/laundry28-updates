import 'package:intl/intl.dart';

/// Helper utilities untuk formatting
class AppUtils {
  /// Format currency to Indonesian Rupiah
  static String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Format date to Indonesian locale
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  /// Format date to dd/MM/yyyy
  static String formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format time to HH:mm
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  /// Generate tracking code (e.g., LTY-001)
  static String generateTrackingCode(int number) {
    return 'LTY-${number.toString().padLeft(3, '0')}';
  }
}
