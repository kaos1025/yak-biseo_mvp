import 'package:get_it/get_it.dart';

import '../data/datasources/local/supplement_local_datasource.dart';
import '../data/repositories/local_supplement_repository.dart';
import '../data/repositories/supplement_repository.dart';
import '../services/gemini_analyzer_service.dart';

/// 전역 서비스 로케이터 인스턴스
final getIt = GetIt.instance;

/// 의존성 주입 설정
///
/// main.dart에서 앱 초기화 시 호출한다.
/// ```dart
/// await setupServiceLocator();
/// ```
Future<void> setupServiceLocator() async {
  // 1. Datasource 등록 (싱글턴)
  getIt.registerLazySingleton<SupplementLocalDatasource>(
    () => SupplementLocalDatasource.instance,
  );

  // 2. Repository 등록 (싱글턴, 인터페이스 바인딩)
  getIt.registerLazySingleton<SupplementRepository>(
    () => LocalSupplementRepository(
      getIt<SupplementLocalDatasource>(),
    ),
  );

  // 3. Service 등록 (싱글턴)
  getIt.registerLazySingleton<GeminiAnalyzerService>(
    () => GeminiAnalyzerService(),
  );

  // 4. 로컬 DB 데이터 로드
  await getIt<SupplementLocalDatasource>().loadData();
}
