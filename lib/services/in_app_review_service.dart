import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InAppReviewService {
  static const String _countKey = 'analysis_complete_count';
  static const String _shownKey = 'has_shown_review';
  static const int _triggerCount = 3;

  /// Increments analysis count and requests review on the 3rd completion.
  /// Silently fails if review is unavailable — never disrupts analysis flow.
  static Future<void> recordAnalysisAndPromptReview() async {
    final prefs = await SharedPreferences.getInstance();

    final int count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);

    if (count != _triggerCount) return;

    final bool hasShown = prefs.getBool(_shownKey) ?? false;
    if (hasShown) return;

    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool(_shownKey, true);
      }
    } catch (_) {
      // Silently fail — review prompt is non-critical.
      // PlatformException can occur on emulators or devices without Play Store.
    }
  }
}
