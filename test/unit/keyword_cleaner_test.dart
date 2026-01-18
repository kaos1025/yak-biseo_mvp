import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/utils/keyword_cleaner.dart';

void main() {
  group('KeywordCleaner Tests', () {
    test('Removed noise characters', () {
      expect(KeywordCleaner.clean('종근당[락토핏]'), '종근당 락토핏');
      expect(KeywordCleaner.clean('제품(괄호)'), '제품 괄호');
      expect(KeywordCleaner.clean('특수-문자/제거*'), '특수 문자 제거');
    });

    test('Removes units but keeps numbers in product names', () {
      expect(KeywordCleaner.clean('락토핏 50포'), '락토핏');
      expect(KeywordCleaner.clean('비타민C 1000 120정'), '비타민C 1000');
      expect(KeywordCleaner.clean('오메가3 1000mg'), '오메가3');
      expect(KeywordCleaner.clean('CoQ10 100mg'), 'CoQ10');
      expect(KeywordCleaner.clean('비타민B12 500mcg'),
          '비타민B12 500mcg'); // mcg not in removal list yet, should stick
    });

    test('Normalizes spaces', () {
      expect(KeywordCleaner.clean('  공백   제거  '), '공백 제거');
    });

    test('Clean and Encode works correctly', () {
      const input = '락토핏 50포';
      const cleaned = '락토핏';
      final encoded = Uri.encodeComponent(cleaned);
      expect(KeywordCleaner.cleanAndEncode(input), encoded);
    });
  });
}
