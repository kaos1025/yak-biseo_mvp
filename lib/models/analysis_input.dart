import 'supplement_product.dart';

/// 제품 정보 소스 타입
///
/// [localDb] 로컬 DB에서 매칭된 제품
/// [geminiFallback] 로컬 DB에 없어서 Gemini가 직접 분석할 제품
enum ProductSource {
  localDb,
  geminiFallback,
}

/// Gemini 분석 입력 모델
///
/// 로컬 DB 매칭 제품과 Fallback 제품을 통합하여 분석에 전달한다.
class AnalysisInput {
  /// 사용자에게 표시할 제품명
  final String productName;

  /// 데이터 소스 (로컬 DB / Gemini Fallback)
  final ProductSource source;

  /// 로컬 DB 매칭 데이터 ([ProductSource.localDb]일 때만 non-null)
  final SupplementProduct? localData;

  /// Fallback 시 사용할 원본 텍스트 (OCR 결과 또는 사용자 직접 입력)
  final String? rawText;

  const AnalysisInput({
    required this.productName,
    required this.source,
    this.localData,
    this.rawText,
  });

  /// 로컬 DB 매칭 성공 시 생성
  factory AnalysisInput.fromLocalDb(SupplementProduct product) {
    return AnalysisInput(
      productName: product.nameKo ?? product.name,
      source: ProductSource.localDb,
      localData: product,
    );
  }

  /// 로컬 DB 매칭 실패 시 (Fallback) 생성
  factory AnalysisInput.fromFallback({
    required String productName,
    String? rawText,
  }) {
    return AnalysisInput(
      productName: productName,
      source: ProductSource.geminiFallback,
      rawText: rawText ?? productName,
    );
  }

  /// Gemini prompt용 문자열 변환
  String toPromptSection(int index) {
    final buffer = StringBuffer();
    buffer.writeln('### 제품 ${index + 1}');

    if (source == ProductSource.localDb && localData != null) {
      buffer.writeln('(DB 매칭 - 정확한 성분 정보)');
      buffer.write(localData!.toGeminiContext());
    } else {
      buffer.writeln('(DB 매칭 실패 - AI 분석 필요)');
      buffer.writeln('사용자 입력: "$productName"');
      if (rawText != null && rawText != productName) {
        buffer.writeln('추가 정보: $rawText');
      }
      buffer.writeln('→ 이 제품의 일반적인 성분 정보를 기반으로 분석해주세요.');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    return 'AnalysisInput($productName, source: $source)';
  }
}
