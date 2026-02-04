import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/ingredient.dart';
import 'package:myapp/models/redundancy_result.dart';
import 'package:myapp/services/redundancy_engine.dart';
import 'package:myapp/models/product_with_ingredients.dart';

void main() {
  group('RedundancyEngine (Deterministic)', () {
    group('analyze (Jaccard Index)', () {
      test('제품이 1개일 때: 중복 없지만 UL 체크 수행', () {
        final products = [
          ProductWithIngredients(
            productName: 'Safe Vitamin',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin C', amount: 500),
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        expect(result.verdict, equals(RedundancyVerdict.noOverlap));
        expect(result.hasRedundancy, isFalse);
        expect(result.ulRdaReport, isNotNull);
        expect(result.productStatuses['p1'], equals('SAFE'));
      });

      test('Jaccard < 0.5 이면 Partial Overlap (1/5 겹침)', () {
        // A: {Vit A} (1개)
        // B: {Vit A, B, C, D, E} (5개)
        // Union: 5개, Inter: 1개 -> Jaccard: 0.2 -> Partial
        final products = [
          ProductWithIngredients(
            productName: 'Single A',
            productId: 'p1',
            ingredients: [_createIngredient('Vitamin A')],
          ),
          ProductWithIngredients(
            productName: 'Multi 5',
            productId: 'p2',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin B'),
              _createIngredient('Vitamin C'),
              _createIngredient('Vitamin D'),
              _createIngredient('Vitamin E'),
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        expect(result.verdict, equals(RedundancyVerdict.partialOverlap));
        expect(
            result.redundantPairs.first.overlapPercentage, closeTo(0.2, 0.01));
      });

      test('Jaccard >= 0.5 이면 Redundant (2/3 겹침)', () {
        // A: {Vit A, B}
        // B: {Vit A, B, C}
        // Union: 3, Inter: 2 -> Jaccard: 0.66 -> Redundant
        final products = [
          ProductWithIngredients(
            productName: 'Bi-Vit',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin B'),
            ],
          ),
          ProductWithIngredients(
            productName: 'Tri-Vit',
            productId: 'p2',
            ingredients: [
              _createIngredient('Vitamin A'),
              _createIngredient('Vitamin B'),
              _createIngredient('Vitamin C'),
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        expect(result.verdict, equals(RedundancyVerdict.redundant));
        expect(
            result.redundantPairs.first.overlapPercentage, closeTo(0.66, 0.01));
      });
    });

    group('UL/RDA Analysis', () {
      test('Magnesium UL(350mg) 초과 시 WARNING 승격', () {
        final products = [
          ProductWithIngredients(
            productName: 'Mega Mag',
            productId: 'p1',
            ingredients: [
              _createIngredient('Magnesium', amount: 500, unit: 'mg'),
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        // UL Report 확인
        expect(result.ulRdaReport!.exceededUlNutrients, contains('magnesium'));

        // Status가 WARNING이어야 함
        expect(result.productStatuses['p1'], equals('WARNING'));
      });

      test('Vitamin D IU 변환 및 UL(100mcg = 4000IU) 초과 테스트', () {
        // 5000 IU = 125 mcg > 100 mcg (UL)
        final products = [
          ProductWithIngredients(
            productName: 'High D',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin D', amount: 5000, unit: 'IU'),
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        expect(result.ulRdaReport!.exceededUlNutrients, contains('vitamin_d'));
        expect(result.productStatuses['p1'], equals('WARNING'));
      });

      test('안전한 범위일 경우 SAFE 유지', () {
        final products = [
          ProductWithIngredients(
            productName: 'Safe D',
            productId: 'p1',
            ingredients: [
              _createIngredient('Vitamin D',
                  amount: 1000, unit: 'IU'), // 25mcg (OK)
            ],
          ),
        ];

        final result = RedundancyEngine.analyze(products);

        expect(result.ulRdaReport!.exceededUlNutrients, isEmpty);
        expect(result.productStatuses['p1'], equals('SAFE'));
      });
    });
  });
}

Ingredient _createIngredient(String group,
    {double amount = 100, String unit = 'mg'}) {
  return Ingredient(
    name: group,
    category: 'vitamin',
    ingredientGroup: group,
    amount: amount,
    unit: unit,
    source: 'test',
  );
}
