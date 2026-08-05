import 'package:intl/intl.dart';

/// Formatting helpers used throughout the UI so number/date formatting
/// stays consistent everywhere (dashboard, lists, reports, PDF).
class Formatters {
  Formatters._();

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static final NumberFormat _currencyFormatDecimal =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  static String currency(num amount, {bool withDecimals = false}) {
    return withDecimals
        ? _currencyFormatDecimal.format(amount)
        : _currencyFormat.format(amount);
  }

  static String date(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String dateShort(DateTime date) => DateFormat('dd MMM').format(date);

  static String dateFull(DateTime date) =>
      DateFormat('EEEE, dd MMMM yyyy').format(date);

  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);

  static String time(DateTime date) => DateFormat('hh:mm a').format(date);

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return dateShort(date);
  }

  static String isoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
