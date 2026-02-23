import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/analysis_input.dart';
import 'package:myapp/models/supplement_ingredient.dart';
import 'package:myapp/models/supplement_product.dart';
import 'package:myapp/models/supplecut_analysis_result.dart';

void main() {
  // ── 테스트용 더미 데이터 ──

  late SupplementProduct thorneMulti;
  late SupplementProduct vitaminD;

  setUp(() {
    thorneMulti = SupplementProduct(
      id: 'iherb_85476',
      name: 'Thorne, Basic Nutrients 2/Day, 60 Capsules',
      nameKo: 'Thorne, 기본 영양소 2/데이, 캡슐 60정',
      brand: 'Thorne',
      source: 'iherb',
      ingredients: const [],
      createdAt: DateTime(2026, 2, 19),
      localIngredients: const [
        SupplementIngredient(
          name: 'Vitamin D (as Vitamin D3)',
          nameKo: '비타민D(비타민D3)',
          amount: 50,
          unit: 'mcg',
          dailyValue: 250,
          nameNormalized: 'vitamin_d',
        ),
        SupplementIngredient(
          name: 'Vitamin C (as Ascorbic Acid)',
          nameKo: '비타민C(아스코르브산)',
          amount: 250,
          unit: 'mg',
          dailyValue: 278,
          nameNormalized: 'vitamin_c',
        ),
      ],
    );

    vitaminD = SupplementProduct(
      id: 'iherb_99999',
      name: 'NOW Foods, Vitamin D-3, 5000 IU',
      nameKo: 'NOW Foods, 비타민 D-3, 5000 IU',
      brand: 'NOW Foods',
      source: 'iherb',
      ingredients: const [],
      createdAt: DateTime(2026, 2, 19),
      localIngredients: const [
        SupplementIngredient(
          name: 'Vitamin D3',
          nameKo: '비타민D3',
          amount: 125,
          unit: 'mcg',
          dailyValue: 625,
          nameNormalized: 'vitamin_d',
        ),
      ],
    );
  });

  group('AnalysisInput', () {
    test('fromLocalDb로 생성하면 source가 localDb이다', () {
      final input = AnalysisInput.fromLocalDb(thorneMulti);

      expect(input.source, ProductSource.localDb);
      expect(input.localData, isNotNull);
      expect(input.productName, contains('Thorne'));
      expect(input.rawText, isNull);
    });

    test('fromFallback으로 생성하면 source가 geminiFallback이다', () {
      final input = AnalysisInput.fromFallback(
        productName: '센트룸 실버 50+',
        rawText: 'Centrum Silver 50+',
      );

      expect(input.source, ProductSource.geminiFallback);
      expect(input.localData, isNull);
      expect(input.productName, '센트룸 실버 50+');
      expect(input.rawText, 'Centrum Silver 50+');
    });

    test('fromFallback에서 rawText 생략 시 productName이 대체된다', () {
      final input = AnalysisInput.fromFallback(
        productName: '종근당 비타민D',
      );

      expect(input.rawText, '종근당 비타민D');
    });

    test('toPromptSection - localDb 제품은 DB 매칭 표시를 포함한다', () {
      final input = AnalysisInput.fromLocalDb(thorneMulti);
      final section = input.toPromptSection(0);

      expect(section, contains('제품 1'));
      expect(section, contains('DB 매칭'));
      expect(section, contains('비타민D'));
      expect(section, contains('비타민C'));
    });

    test('toPromptSection - fallback 제품은 AI 분석 요청을 포함한다', () {
      final input = AnalysisInput.fromFallback(
        productName: '센트룸 실버 50+',
      );
      final section = input.toPromptSection(1);

      expect(section, contains('제품 2'));
      expect(section, contains('DB 매칭 실패'));
      expect(section, contains('AI 분석 필요'));
      expect(section, contains('센트룸 실버 50+'));
    });
  });

  group('SuppleCutAnalysisResult', () {
    test('정상 JSON 파싱이 성공한다', () {
      final json = {
        'products': [
          {
            'name': 'Thorne Basic Nutrients',
            'source': 'local_db',
            'ingredients': [
              {'name': '비타민D', 'amount': 50, 'unit': 'mcg', 'dailyValue': 250},
            ],
          },
          {
            'name': '센트룸 실버 50+',
            'source': 'ai_estimated',
            'ingredients': [
              {'name': '비타민D', 'amount': 25, 'unit': 'mcg', 'dailyValue': 125},
            ],
            'confidence': 'high',
            'note': '일반적인 센트룸 실버 성분 기준',
          },
        ],
        'duplicates': [
          {
            'ingredient': '비타민D',
            'products': ['Thorne Basic Nutrients', '센트룸 실버 50+'],
            'totalAmount': '75mcg',
            'dailyLimit': '100mcg',
            'riskLevel': 'warning',
            'advice': '비타민D 중복. 총 섭취량 모니터링 권장',
          },
        ],
        'overallRisk': 'warning',
        'summary': '비타민D 중복 섭취에 주의가 필요합니다.',
        'recommendations': ['비타민D 단일제 제외 고려'],
        'disclaimer': '일부 제품은 AI 추정치 기반입니다.',
      };

      final result = SuppleCutAnalysisResult.fromJson(json);

      expect(result.products.length, 2);
      expect(result.products[0].source, 'local_db');
      expect(result.products[1].source, 'ai_estimated');
      expect(result.products[1].isEstimated, true);
      expect(result.products[1].confidence, 'high');
      expect(result.duplicates.length, 1);
      expect(result.duplicates[0].ingredient, '비타민D');
      expect(result.duplicates[0].riskLevel, 'warning');
      expect(result.overallRisk, 'warning');
      expect(result.hasDuplicates, true);
      expect(result.hasFallbackProducts, true);
      expect(result.disclaimer, isNotNull);
      // 새 필드 기본값 확인
      expect(result.monthlySavings, 0);
      expect(result.yearlySavings, 0);
      expect(result.excludedProduct, isNull);
      expect(result.hasSavings, false);
    });

    test('빈 JSON도 파싱이 성공한다', () {
      final json = <String, dynamic>{};

      final result = SuppleCutAnalysisResult.fromJson(json);

      expect(result.products, isEmpty);
      expect(result.duplicates, isEmpty);
      expect(result.overallRisk, 'safe');
      expect(result.summary, '');
      expect(result.recommendations, isEmpty);
      expect(result.disclaimer, isNull);
      expect(result.monthlySavings, 0);
      expect(result.yearlySavings, 0);
      expect(result.excludedProduct, isNull);
    });

    test('null 필드가 있어도 안전하게 파싱된다', () {
      final json = {
        'products': null,
        'duplicates': null,
        'overallRisk': null,
        'summary': null,
        'recommendations': null,
        'disclaimer': null,
      };

      final result = SuppleCutAnalysisResult.fromJson(json);

      expect(result.products, isEmpty);
      expect(result.duplicates, isEmpty);
      expect(result.overallRisk, 'safe');
    });
  });

  group('DuplicateIngredient', () {
    test('fromJson이 정상 동작한다', () {
      final json = {
        'ingredient': '비타민C',
        'products': ['제품A', '제품B'],
        'totalAmount': '350mg',
        'dailyLimit': '2000mg',
        'riskLevel': 'safe',
        'advice': '안전 범위 내입니다.',
      };

      final dup = DuplicateIngredient.fromJson(json);

      expect(dup.ingredient, '비타민C');
      expect(dup.products.length, 2);
      expect(dup.riskLevel, 'safe');
    });
  });

  group('시나리오 테스트 - Prompt 빌드', () {
    test('시나리오 1: 모두 로컬 DB - fallback 관련 지시가 없다', () {
      final inputs = [
        AnalysisInput.fromLocalDb(thorneMulti),
        AnalysisInput.fromLocalDb(vitaminD),
      ];

      // 모든 input이 localDb이므로 fallback 지시가 없어야 함
      expect(inputs.every((i) => i.source == ProductSource.localDb), true);

      // 각 제품의 prompt section에 DB 매칭 표시
      for (var i = 0; i < inputs.length; i++) {
        final section = inputs[i].toPromptSection(i);
        expect(section, contains('DB 매칭'));
        expect(section, isNot(contains('AI 분석 필요')));
      }
    });

    test('시나리오 2: 일부 fallback - DB 매칭과 AI 분석이 혼재한다', () {
      final inputs = [
        AnalysisInput.fromLocalDb(thorneMulti),
        AnalysisInput.fromFallback(productName: '센트룸 실버 50+'),
      ];

      expect(inputs[0].source, ProductSource.localDb);
      expect(inputs[1].source, ProductSource.geminiFallback);

      final section0 = inputs[0].toPromptSection(0);
      expect(section0, contains('DB 매칭'));
      expect(section0, contains('비타민D'));

      final section1 = inputs[1].toPromptSection(1);
      expect(section1, contains('AI 분석 필요'));
      expect(section1, contains('센트룸 실버 50+'));
    });

    test('시나리오 3: 모두 fallback - 모든 제품이 AI 분석 대상이다', () {
      final inputs = [
        AnalysisInput.fromFallback(productName: '고려은단 비타민C 1000'),
        AnalysisInput.fromFallback(productName: '종근당 칼슘 마그네슘'),
      ];

      expect(
          inputs.every((i) => i.source == ProductSource.geminiFallback), true);

      for (var i = 0; i < inputs.length; i++) {
        final section = inputs[i].toPromptSection(i);
        expect(section, contains('AI 분석 필요'));
        expect(section, isNot(contains('성분:')));
      }
    });
  });

  group('가격/절감액 필드', () {
    test('monthlySavings, excludedProduct이 JSON에서 파싱된다', () {
      final json = {
        'products': [
          {
            'name': '제품A',
            'source': 'local_db',
            'ingredients': [],
            'estimatedMonthlyPrice': 25000,
          },
        ],
        'duplicates': [],
        'overallRisk': 'safe',
        'summary': '안전합니다',
        'recommendations': [],
        'monthlySavings': 15000,
        'yearlySavings': 180000,
        'excludedProduct': '제품B',
      };

      final result = SuppleCutAnalysisResult.fromJson(json);

      expect(result.monthlySavings, 15000);
      expect(result.yearlySavings, 180000);
      expect(result.excludedProduct, '제품B');
      expect(result.hasSavings, true);
      expect(result.products[0].estimatedMonthlyPrice, 25000);
    });
  });
}
