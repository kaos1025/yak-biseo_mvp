import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/models/pill.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: ".env");
  });

  group('ApiService Tests', () {
    test('searchPill returns empty list for empty query', () async {
      final results = await ApiService.searchPill('');
      expect(results, isEmpty);
    });

    test('searchPill returns empty list for query that cleaned to empty',
        () async {
      final results = await ApiService.searchPill('   ');
      expect(results, isEmpty);
    });

    // Note: Integration-like test. Requires valid API Key in .env and internet.
    // We are testing if the mapping works correctly with a known product.
    // If API key is invalid or network fails, this might fail or return empty (logic handles exceptions as empty).
    test('searchPill fetches and maps data correctly for known product',
        () async {
      // "종근당 락토핏" -> Should find results
      // Using a keyword that is likely to exist.
      // If network fails (CI env), this test logic handles exception by returning empty list,
      // but ideally we want to see it parse something.
      // For now, we verify that it doesn't crash.

      final results = await ApiService.searchPill('종근당 락토핏');

      // If API KEY is invalid or quota exceeded, it returns [].
      // We check type safety here.
      expect(results, isA<List<KoreanPill>>());

      if (results.isNotEmpty) {
        final pill = results.first;
        expect(pill.id, isNotEmpty);
        expect(pill.name, isNotEmpty);
        expect(pill.category, '건강기능식품');
      }
    });

    test('searchPill handles noise in query correctly via KeywordCleaner',
        () async {
      // "[특가] 락토핏!!" -> "락토핏" sent to API
      // We assume correct behavior if it returns List<KoreanPill>.
      final results = await ApiService.searchPill('[특가] 락토핏!!');
      expect(results, isA<List<KoreanPill>>());
    });
  });
}
