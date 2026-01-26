import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/services/my_pill_service.dart';
import 'package:myapp/models/pill.dart';

void main() {
  setUp(() {
    // SharedPreferences 초기화 (Mock)
    SharedPreferences.setMockInitialValues({});
  });

  const testPill = KoreanPill(
    id: '2024001',
    name: '테스트 비타민',
    brand: '테스트 브랜드',
    imageUrl: 'http://test.image',
    dailyDosage: '1일 1회',
    category: '건강기능식품',
    ingredients: '비타민C',
  );

  group('MyPillService Tests', () {
    test('영양제 저장 및 로드 테스트', () async {
      // 1. 초기 상태: 비어있음
      var pills = await MyPillService.loadMyPills();
      expect(pills, isEmpty);

      // 2. 저장 수행
      final result = await MyPillService.savePill(testPill);
      expect(result, 0); // 0 = Success

      // 3. 다시 로드하여 확인
      pills = await MyPillService.loadMyPills();
      expect(pills.length, 1);
      expect(pills.first.name, '테스트 비타민');
    });

    test('중복 저장 방지 테스트', () async {
      // 1. 1회 저장
      await MyPillService.savePill(testPill);

      // 2. 같은 ID로 다시 저장 시도
      final result = await MyPillService.savePill(testPill);

      // 3. 실패 코드(1) 확인 및 개수 유지 확인 (1개)
      expect(result, 1);
      final pills = await MyPillService.loadMyPills();
      expect(pills.length, 1);
    });

    test('영양제 삭제 테스트', () async {
      // 1. 저장 후 확인
      await MyPillService.savePill(testPill);
      var pills = await MyPillService.loadMyPills();
      expect(pills, isNotEmpty);

      // 2. 삭제 수행
      await MyPillService.removePill(testPill.id);

      // 3. 비어있는지 확인
      pills = await MyPillService.loadMyPills();
      expect(pills, isEmpty);
    });
  });
}
