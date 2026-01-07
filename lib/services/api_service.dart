import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // API 키를 .env 파일에서 불러옵니다.
  static final String? _apiKey = dotenv.env['API_KEY'];

  static Future<String> analyzeDrugImage(File image) async {
    // 널이 될 수 있는 _apiKey를 지역 변수로 옮겨서 널 안전성 검사를 명확하게 합니다.
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // API 키가 없으면 예외를 발생시켜 함수 실행을 중단합니다.
      throw Exception('API 키가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 이제 apiKey는 절대 널이 아니라고 확신할 수 있습니다.
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey, // 불필요한 '!' 연산자를 제거했습니다.
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );

    final prompt = TextPart('''
      # 역할
      당신은 '약비서' 앱을 위한 AI 약사이자 이미지 분석 전문가입니다.

      # 임무
      사용자가 업로드한 이미지에는 여러 개의 영양제/약통이 섞여 있을 수 있습니다.
      1. 이미지에서 식별 가능한 **모든 영양제 약통**을 찾아내세요.
      2. 각 약통에 대해 다음 정보를 추출하세요:
         - brand_name (브랜드명): 예 - 종근당, 고려은단 (로고나 텍스트 기반 추론)
         - product_name (제품명): 예 - 락토핏 골드, 비타민C 1000
         - key_ingredients (주요 성분): 예 - 유산균, 마그네슘
         - estimated_price (한국 시장 평균가 추정치, 정수형): 예 - 15000
      3. **반드시 JSON 형식으로만** 응답하세요. (마크다운 포맷팅 제외)

      # JSON 스키마 예시
      {
        "detected_items": [
          {
            "id": 1,
            "brand_name": "종근당건강",
            "product_name": "락토핏 골드",
            "key_ingredients": "유산균",
            "confidence_level": "high",
            "estimated_price": 18000
          },
          {
            "id": 2,
            "brand_name": "알수없음",
            "product_name": "종합비타민 추정",
            "key_ingredients": "확인필요",
            "confidence_level": "low",
            "estimated_price": 0
          }
        ],
        "total_count": 2,
        "summary": "총 2개의 영양제가 발견되었습니다. 중복 성분을 확인해보세요."
      }
    ''');

    final imageBytes = await image.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      return response.text ?? '{"status": "ERROR", "message": "No response"}';
    } catch (e) {
      throw Exception('API 호출에 실패했습니다: ${e.toString()}');
    }
  }
}
