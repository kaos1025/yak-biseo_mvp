
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // 1. 앱 실행 이벤트
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    print('Analytics: AppOpen logged');
  }

  // 2. '약 봉투 촬영하기' 버튼 클릭 이벤트
  Future<void> logCameraClick() async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {'button_name': 'camera_capture'},
    );
    print('Analytics: CameraClick logged');
  }

  // 3. '앨범에서 불러오기' 버튼 클릭 이벤트
  Future<void> logGalleryClick() async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {'button_name': 'gallery_import'},
    );
    print('Analytics: GalleryClick logged');
  }

  // 4. 분석 결과 화면 진입 이벤트
  Future<void> logAnalysisResult(bool isSuccess) async {
    await _analytics.logEvent(
      name: 'analysis_result',
      parameters: {'success': isSuccess.toString()},
    );
    print('Analytics: AnalysisResult logged (Success: $isSuccess)');
  }
}
