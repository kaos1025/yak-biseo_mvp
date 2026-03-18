class PricingConfig {
  /// 런칭 프로모션 종료일
  static final DateTime launchPromoEndDate = DateTime(2026, 4, 18);

  /// 특가 기간 활성화 여부
  static bool get isPromoActive {
    return DateTime.now().isBefore(launchPromoEndDate);
  }

  /// 특가 남은 일수
  static int get remainingPromoDays {
    final now = DateTime.now();
    if (now.isAfter(launchPromoEndDate)) return 0;

    final difference = launchPromoEndDate.difference(now);
    // 남은 시간이 24시간 미만이어도 1일로 표시하려면 올림 처리
    return difference.inDays > 0 ? difference.inDays : 1;
  }
}
