import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/ingredient.dart';
import 'package:myapp/models/supplement_product.dart';

void main() {
  group('SupplementProduct', () {
    late SupplementProduct sampleProduct;

    setUp(() {
      sampleProduct = SupplementProduct(
        id: 'test123',
        name: '멀티비타민',
        brand: '한국제약',
        source: 'kr_food_safety',
        ingredients: [
          const Ingredient(
            name: '비타민A',
            category: 'vitamin',
            ingredientGroup: 'Vitamin A',
            amount: 600,
            unit: '㎍RAE',
            source: 'kr_food_safety',
          ),
          const Ingredient(
            name: '비타민C',
            category: 'vitamin',
            ingredientGroup: 'Vitamin C',
            amount: 100,
            unit: 'mg',
            source: 'kr_food_safety',
          ),
        ],
        createdAt: DateTime(2026, 2, 2, 12, 0, 0),
      );
    });

    group('toJson / fromJson', () {
      test('JSON 직렬화/역직렬화가 정상 동작한다', () {
        // Act
        final json = sampleProduct.toJson();
        final restored = SupplementProduct.fromJson(json);

        // Assert
        expect(restored.id, equals(sampleProduct.id));
        expect(restored.name, equals(sampleProduct.name));
        expect(restored.brand, equals(sampleProduct.brand));
        expect(restored.source, equals(sampleProduct.source));
        expect(restored.ingredients.length, equals(2));
        expect(
          restored.ingredients.first.ingredientGroup,
          equals('Vitamin A'),
        );
      });

      test('updatedAt이 null이어도 정상 동작한다', () {
        // Act
        final json = sampleProduct.toJson();
        final restored = SupplementProduct.fromJson(json);

        // Assert
        expect(restored.updatedAt, isNull);
      });
    });

    group('copyWith', () {
      test('일부 필드만 변경된 복사본을 생성한다', () {
        // Act
        final updated = sampleProduct.copyWith(
          name: '새 멀티비타민',
          updatedAt: DateTime.now(),
        );

        // Assert
        expect(updated.name, equals('새 멀티비타민'));
        expect(updated.brand, equals(sampleProduct.brand)); // 변경 안 됨
        expect(updated.id, equals(sampleProduct.id)); // 변경 안 됨
        expect(updated.updatedAt, isNotNull);
      });

      test('ingredients 변경 시 새 리스트로 교체된다', () {
        // Act
        final newIngredients = [
          const Ingredient(
            name: 'Zinc',
            category: 'mineral',
            ingredientGroup: 'Zinc',
            source: 'test',
          ),
        ];
        final updated = sampleProduct.copyWith(ingredients: newIngredients);

        // Assert
        expect(updated.ingredients.length, equals(1));
        expect(updated.ingredients.first.ingredientGroup, equals('Zinc'));
      });
    });

    group('toString', () {
      test('읽기 쉬운 문자열을 반환한다', () {
        // Act
        final str = sampleProduct.toString();

        // Assert
        expect(str, contains('멀티비타민'));
        expect(str, contains('한국제약'));
        expect(str, contains('2 ingredients'));
      });
    });

    group('edge cases', () {
      test('빈 ingredients 리스트도 정상 처리된다', () {
        // Arrange
        final emptyProduct = SupplementProduct(
          id: 'empty123',
          name: '빈 제품',
          brand: '테스트',
          source: 'test',
          ingredients: [],
          createdAt: DateTime.now(),
        );

        // Act
        final json = emptyProduct.toJson();
        final restored = SupplementProduct.fromJson(json);

        // Assert
        expect(restored.ingredients, isEmpty);
      });

      test('특수문자가 포함된 제품명도 정상 처리된다', () {
        // Arrange
        final specialProduct = SupplementProduct(
          id: 'special123',
          name: '비타민 (고함량) [프리미엄]',
          brand: '한국제약 & Co.',
          source: 'test',
          ingredients: [],
          createdAt: DateTime.now(),
        );

        // Act
        final json = specialProduct.toJson();
        final restored = SupplementProduct.fromJson(json);

        // Assert
        expect(restored.name, equals('비타민 (고함량) [프리미엄]'));
        expect(restored.brand, equals('한국제약 & Co.'));
      });
    });
  });
}
