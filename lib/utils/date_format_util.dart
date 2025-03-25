import 'package:intl/intl.dart';

class DateFormatUtil {
  // Indian date format: DD/MM/YYYY
  static String formatDateIndian(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  // 24-hour time format: HH:MM
  static String formatTimeIndian(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // Complete date and time in Indian format: DD/MM/YYYY HH:MM
  static String formatDateTimeIndian(DateTime dateTime) {
    return '${formatDateIndian(dateTime)} ${formatTimeIndian(dateTime)}';
  }
  
  // Format currency in Indian format (₹ X,XX,XXX.XX)
  static String formatCurrencyIndian(double amount) {
    final indianCurrencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return indianCurrencyFormat.format(amount);
  }
  
  // Format numbers in Indian format (e.g. 1,00,000 instead of 100,000)
  static String formatNumberIndian(int number) {
    final indianNumberFormat = NumberFormat('#,##,###', 'en_IN');
    return indianNumberFormat.format(number);
  }
  
  // Format relative time (e.g. "2 hours ago") with Indian date fallback
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return formatDateIndian(dateTime);
    }
  }
} 