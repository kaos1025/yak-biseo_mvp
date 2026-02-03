import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/ingredient.dart';
import 'package:myapp/models/redundancy_result.dart';
import 'package:myapp/services/redundancy_engine.dart';

void main() {
  group('RedundancyEngineV2', () {
    group('analyze', () {
      test('제품이 1개뿐이면 NO_OVERLAP 반환', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '멀티비타민',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.noOverlap));
        expect(result.hasRedundancy, isFalse);
        expect(result.redundantPairs, isEmpty);
      });

      test('두 제품의 성분이 50% 이상 겹치면 REDUNDANT', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '제품A',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
          ProductWithIngredients(
            productName: '제품B',
            productId: 'p2',
            ingredients: [
              _createIngredient('Vitamin A'), // 겹침
              _createIngredient('Vitamin C'), // 겹침
              _createIngredient('Zinc'),
            ],
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.redundant));
        expect(result.hasRedundancy, isTrue);
        expect(result.redundantPairs.length, equals(1));
        expect(
          result.redundantPairs.first.overlappingGroups,
          containsAll(['Vitamin A', 'Vitamin C']),
        );
      });

      test('두 제품의 성분이 1~49% 겹치면 PARTIAL_OVERLAP', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '제품A',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
              _createIngredient('Vitamin D'),
              _createIngredient('Vitamin E'),
            ],
          ),
          ProductWithIngredients(
            productName: '제품B',
            productId: 'p2',
            ingredients: [
              _createIngredient('Vitamin A'), // 겹침 (1/4 = 25%)
              _createIngredient('Calcium'),
              _createIngredient('Magnesium'),
              _createIngredient('Zinc'),
            ],
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.partialOverlap));
      });

      test('두 제품의 성분이 전혀 겹치지 않으면 NO_OVERLAP', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '비타민제',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
          ProductWithIngredients(
            productName: '미네랄제',
            productId: 'p2',
            ingredients: [
              _createIngredient('Calcium'),
              _createIngredient('Magnesium'),
            ],
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.noOverlap));
        expect(result.hasRedundancy, isFalse);
      });

      test('빈 제품 리스트는 빈 결과 반환', () {
        // Act
        final result = RedundancyEngineV2.analyze([]);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.noOverlap));
        expect(result.totalProductsAnalyzed, equals(0));
      });

      test('세 개 제품 중 두 쌍이 중복이면 둘 다 감지', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '제품A',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
          ProductWithIngredients(
            productName: '제품B',
            productId: 'p2',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
          ProductWithIngredients(
            productName: '제품C',
            productId: 'p3',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin C'),
            ],
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        expect(result.verdict, equals(RedundancyVerdict.redundant));
        // A-B, A-C, B-C 세 쌍 모두 중복
        expect(result.redundantPairs.length, equals(3));
      });
    });

    group('productStatuses', () {
      test('중복 제품은 REDUNDANT 상태를 가진다', () {
        // Arrange
        final products = [
          ProductWithIngredients(
            productName: '제품A',
            productId: 'p1',
            ingredients: [_createIngredient('Vitamin C')],
            price: 10000, // 가격 추가
          ),
          ProductWithIngredients(
            productName: '제품B',
            productId: 'p2',
            ingredients: [_createIngredient('Vitamin C')],
            price: 15000, // 더 비싼 제품 → REDUNDANT
          ),
        ];

        // Act
        final result = RedundancyEngineV2.analyze(products);

        // Assert
        // 더 비싼 제품(p2)이 REDUNDANT, 저렴한 제품(p1)이 SAFE
        expect(result.productStatuses['p2'], equals('REDUNDANT'));
        expect(result.productStatuses['p1'], equals('SAFE'));
      });
    });
  });

  group('RedundancyAnalysisResult', () {
    test('toAiContext는 올바른 구조를 반환한다', () {
      // Arrange
      const result = RedundancyAnalysisResult(
        verdict: RedundancyVerdict.redundant,
        redundantPairs: [
          RedundantPair(
            productAName: '제품A',
            productAId: 'p1',
            productBName: '제품B',
            productBId: 'p2',
            overlappingGroups: ['Vitamin C'],
            overlapPercentage: 1.0,
            pairVerdict: RedundancyVerdict.redundant,
          ),
        ],
        totalProductsAnalyzed: 2,
        redundantProductCount: 2,
        productStatuses: {'p1': 'REDUNDANT', 'p2': 'REDUNDANT'},
        estimatedSavings: 15000,
        currency: 'KRW',
      );

      // Act
      final aiContext = result.toAiContext();

      // Assert
      expect(aiContext['verdict'], equals('redundant'));
      expect(aiContext['totalProducts'], equals(2));
      expect(aiContext['estimatedSavings'], equals(15000));
      expect(aiContext['pairs'], isList);
    });

    test('empty() 팩토리는 빈 결과를 반환한다', () {
      // Act
      final result = RedundancyAnalysisResult.empty();

      // Assert
      expect(result.verdict, equals(RedundancyVerdict.noOverlap));
      expect(result.totalProductsAnalyzed, equals(0));
      expect(result.hasRedundancy, isFalse);
    });
  });
}

/// 테스트용 Ingredient 생성 헬퍼
Ingredient _createIngredient(String group) {
  return Ingredient(
    name: group,
    category: 'vitamin',
    ingredientGroup: group,
    amount: 100,
    unit: 'mg',
    source: 'test',
  );
}
