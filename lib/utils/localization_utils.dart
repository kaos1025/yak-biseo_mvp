import 'package:intl/intl.dart';

class LocalizationUtils {
  /// 로케일에 맞춰 가격을 포맷팅합니다.
  /// - `en`: USD 기준. 1250원으로 나눈 후 달러 포맷팅.
  /// - `ko`: KRW 기준. 기존 숫자 그대로 원단위 포맷팅.
  static String formatCurrency(double amount, String locale) {
    if (locale == 'en') {
      // 1250원으로 나눈 후 USD 포맷 (예: $10.00)
      final usdAmount = amount / 1250.0;
      final format = NumberFormat.currency(locale: 'en_US', symbol: '\$');
      return format.format(usdAmount);
    } else {
      // KRW 기준 포맷 (예: 50,000)
      final format = NumberFormat('#,###');
      return format.format(amount);
    }
  }
}
