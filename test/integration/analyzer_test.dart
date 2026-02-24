// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/services/gemini_analyzer_service.dart';
import 'package:myapp/data/repositories/local_supplement_repository.dart';
import 'package:myapp/data/datasources/local/supplement_local_datasource.dart';

void main() {
  setUpAll(() async {
    // 1. Load the real .env file for Gemini API
    await dotenv.load(fileName: '.env');

    // 2. Initialize the local DB
    final dataSource = SupplementLocalDatasource.instance;
    await dataSource.loadData();
    // 싱글톤 초기화이므로 객체 주입 대신 getter로 확보
    // LocalSupplementRepository는 _instance가 null일 때 기본적으로
    // SupplementLocalDatasource.instance를 사용하므로 여기서 따로 주입하지 않아도 됩니다.
    await LocalSupplementRepository.instance.initialize();
  });

  test('Integration Test: Real Analyzer Response with test_bottles.jpg',
      () async {
    // 이 테스트를 실행하려면 프로젝트 폴더 안의
    // assets/images/test_bottles.jpg 위치에 분석하고 싶은 사진을 넣으세요.
    final file = File('assets/images/test_bottles.jpg');

    if (!file.existsSync()) {
      print('======================================================');
      print('🚨 테스트 실패: assets/images/test_bottles.jpg 파일을 찾을 수 없습니다.');
      print('사진을 위 경로에 저장한 뒤 다시 실행해주세요.');
      print('======================================================');
      return;
    }

    print('======================================================');
    print('📦 이미지 읽기 완료: \${file.lengthSync() / 1024} KB');
    print('🚀 분석 시작...');
    print('======================================================');

    final bytes = await file.readAsBytes();
    final service = GeminiAnalyzerService();

    final stopwatch = Stopwatch()..start();

    try {
      final result = await service.analyzeWithImage(bytes);

      stopwatch.stop();

      print('\\n✅ 분석 완료! (소요 시간: \${stopwatch.elapsed.inSeconds}초)');
      print('------------------------------------------------------');
      final names = result.products.map((p) => p.name).join(', ');
      print('제품명 리스트: $names');
      print('중복 성분 개수: \${result.duplicates.length}개');
      print('월 예상 절감액: \${result.monthlySavings}원');
      final excluded = result.excludedProduct ?? '없음';
      print('제외 권장 제품: $excluded');
      print('전체 위험도 판별: \${result.overallRisk}');
      print('------------------------------------------------------\\n');

      // 중복 배지가 떴는데 절감 배너가 안 뜨는지(monthlySavings가 0인지) 체크하는 AssertionError 방지
      if (result.hasDuplicates) {
        expect(result.monthlySavings > 0, isTrue,
            reason: '중복이 있으면 무조건 1개 이상의 제품을 제외하고 절감액을 계산해야 합니다.');
      }
    } catch (e) {
      stopwatch.stop();
      print('\\n❌ 분석 실패 (소요 시간: \${stopwatch.elapsed.inSeconds}초)');
      print('에러 사유: \$e');
      fail('Analysis failed: \$e');
    }
  }, timeout: const Timeout(Duration(seconds: 120)));
}
