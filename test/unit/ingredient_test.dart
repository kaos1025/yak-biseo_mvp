import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/ingredient.dart';
import 'package:myapp/models/ingredient_category.dart';

void main() {
  group('Ingredient', () {
    group('fromNihDsld', () {
      test('NIH API 응답에서 Ingredient 객체를 올바르게 생성한다', () {
        // Arrange
        final nihData = {
          'name': 'Vitamin D',
          'category': 'Vitamins',
          'ingredientGroup': 'Vitamin D',
          'quantity': [
            {'quantity': 600.0, 'unit': 'IU'}
          ],
          'notes': 'as cholecalciferol',
        };

        // Act
        final ingredient =
            Ingredient.fromNihDsld(nihData, productId: 'dsld123');

        // Assert
        expect(ingredient.name, equals('Vitamin D'));
        expect(ingredient.category, equals('Vitamins'));
        expect(ingredient.ingredientGroup, equals('Vitamin D'));
        expect(ingredient.amount, equals(600.0));
        expect(ingredient.unit, equals('IU'));
        expect(ingredient.notes, equals('as cholecalciferol'));
        expect(ingredient.source, equals('nih_dsld'));
        expect(ingredient.sourceProductId, equals('dsld123'));
      });

      test('quantity 배열이 비어있으면 amount와 unit이 null이다', () {
        // Arrange
        final nihData = {
          'name': 'Vitamin C',
          'category': 'Vitamins',
          'ingredientGroup': 'Vitamin C',
          'quantity': [],
        };

        // Act
        final ingredient = Ingredient.fromNihDsld(nihData);

        // Assert
        expect(ingredient.amount, isNull);
        expect(ingredient.unit, isNull);
      });
    });

    group('fromKrFoodSafety', () {
      test('한글 성분명을 영문 ingredientGroup으로 매핑한다', () {
        // Act
        final ingredient = Ingredient.fromKrFoodSafety(
          parsedName: '비타민A',
          parsedAmount: 600.0,
          parsedUnit: '㎍RAE',
          productId: 'kr123',
        );

        // Assert
        expect(ingredient.name, equals('비타민A'));
        expect(ingredient.ingredientGroup, equals('Vitamin A'));
        expect(ingredient.category, equals('vitamin'));
        expect(ingredient.amount, equals(600.0));
        expect(ingredient.unit, equals('㎍RAE'));
        expect(ingredient.source, equals('kr_food_safety'));
      });

      test('매핑되지 않은 성분명은 원본 이름을 group으로 사용한다', () {
        // Act
        final ingredient = Ingredient.fromKrFoodSafety(
          parsedName: '알수없는성분',
        );

        // Assert
        expect(ingredient.ingredientGroup, equals('알수없는성분'));
        expect(ingredient.category, equals('unknown'));
      });
    });

    group('toJson / fromJson', () {
      test('JSON 직렬화/역직렬화가 정상 동작한다', () {
        // Arrange
        const original = Ingredient(
          name: 'Calcium',
          category: 'mineral',
          ingredientGroup: 'Calcium',
          amount: 500.0,
          unit: 'mg',
          notes: 'from calcium carbonate',
          source: 'nih_dsld',
          sourceProductId: 'test123',
        );

        // Act
        final json = original.toJson();
        final restored = Ingredient.fromJson(json);

        // Assert
        expect(restored.name, equals(original.name));
        expect(restored.category, equals(original.category));
        expect(restored.ingredientGroup, equals(original.ingredientGroup));
        expect(restored.amount, equals(original.amount));
        expect(restored.unit, equals(original.unit));
        expect(restored.source, equals(original.source));
      });
    });
  });

  group('IngredientCategory', () {
    test('비타민A를 Vitamin A로 매핑한다', () {
      final result = IngredientCategory.fromKoreanName('비타민A');
      expect(result.group, equals('Vitamin A'));
      expect(result.category, equals('vitamin'));
    });

    test('공백이 있는 성분명도 매핑한다 (비타민 A)', () {
      final result = IngredientCategory.fromKoreanName('비타민 A');
      expect(result.group, equals('Vitamin A'));
    });

    test('칼슘을 Calcium으로 매핑한다', () {
      final result = IngredientCategory.fromKoreanName('칼슘');
      expect(result.group, equals('Calcium'));
      expect(result.category, equals('mineral'));
    });

    test('오메가3를 Omega-3로 매핑한다', () {
      final result = IngredientCategory.fromKoreanName('오메가3');
      expect(result.group, equals('Omega-3'));
    });

    test('매핑되지 않은 성분은 unknown 카테고리와 원본 이름을 반환한다', () {
      final result = IngredientCategory.fromKoreanName('미지의성분');
      expect(result.category, equals('unknown'));
      expect(result.group, equals('미지의성분'));
    });
  });
}
