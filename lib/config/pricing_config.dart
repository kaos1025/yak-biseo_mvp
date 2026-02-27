class PricingConfig {
  /// 런칭일 (예: 2026년 2월 26일)
  static final DateTime launchDate = DateTime(2026, 2, 26);

  /// 특가 가격
  static const double promoPrice = 0.99;

  /// 정상 가격
  static const double normalPrice = 1.99;

  /// 특가 기간 활성화 여부 (런칭 후 7일간)
  static bool get isPromoActive {
    final now = DateTime.now();
    final promoEndDate = launchDate.add(const Duration(days: 7));
    return now.isBefore(promoEndDate);
  }

  /// 특가 남은 일수
  static int get remainingPromoDays {
    final now = DateTime.now();
    final promoEndDate = launchDate.add(const Duration(days: 7));
    if (now.isAfter(promoEndDate)) return 0;

    final difference = promoEndDate.difference(now);
    // 남은 시간이 24시간 미만이어도 1일로 표시하려면 올림 처리
    return difference.inDays > 0 ? difference.inDays : 1;
  }
}
