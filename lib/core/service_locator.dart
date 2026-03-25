import 'package:get_it/get_it.dart';

import '../services/gemini_analyzer_service.dart';
import '../services/iap_service.dart';

/// 전역 서비스 로케이터 인스턴스
final getIt = GetIt.instance;

/// 의존성 주입 설정
///
/// main.dart에서 앱 초기화 시 호출한다.
/// ```dart
/// await setupServiceLocator();
/// ```
Future<void> setupServiceLocator() async {
  // Hot restart 지원을 위해 기존 등록된 서비스 초기화
  await getIt.reset();

  // Service 등록 (싱글턴)
  getIt.registerLazySingleton<GeminiAnalyzerService>(
    () => GeminiAnalyzerService(),
  );

  // IAPService 초기화 및 등록
  final iapService = IAPService();
  await iapService.init();
  getIt.registerSingleton<IAPService>(iapService);
}
