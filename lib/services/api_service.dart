
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ApiService {
  // API 키를 .env 파일에서 불러옵니다.
  static final String? _apiKey = dotenv.env['API_KEY'];

  static Future<String> analyzeDrugImage(File image) async {
    if (_apiKey == null) {
      return '{"status": "ERROR", "summary": "API 키가 설정되지 않았습니다. .env 파일을 확인하세요.", "cards": []}';
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // 가성비/속도 최적화 모델 [cite: 720]
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2, // 할루시네이션 방지를 위해 낮은 창의성 설정 [cite: 726]
      ),
    );

    final prompt = TextPart('''
      당신은 4050 세대를 위한 '디지털 헬스케어 비서'이자 '약물 구조조정 전문가'입니다. [cite: 684]
      사용자가 업로드한 약/영양제 이미지를 분석하여 다음 작업을 수행하세요.

      [분석 지침]
      1. 이미지 내 텍스트를 인식하여 제품명과 성분을 식별하세요. (Vision API 대체)
      2. 식약처 기준 및 약학 지식을 바탕으로 다음을 분석하세요:
         - [RED] 병용 금기 및 위험한 상호작용 (식약처 DUR 기준) [cite: 730]
         - [YELLOW] 성분 중복 및 과다 섭취 (돈 낭비 요인)
         - [GREEN] 필수 영양소 및 안전 조합
      3. **[핵심: 비용 절감 계산]**
         - 중복/과다로 분류된 제품의 '한국 시장 평균 월간 비용(KRW)'을 추정하세요.
         - 이를 합산하여 'total_saving_amount'를 계산하세요. (예: 월 5만 원 절약 가능) [cite: 760]

      [출력 포맷 (JSON Only)]
      {
        "status": "SUCCESS",
        "total_saving_amount": 50000,
        "summary": "김영희님, 현재 드시는 영양제 중 2가지는 겹칩니다. 정리하면 월 5만 원을 아낄 수 있어요!",
        "cards": [
          {
            "type": "WARNING", 
            "title": "루테인 중복 (월 15,000원 낭비)",
            "content": "종합비타민에 이미 루테인이 포함되어 있습니다. 추가 섭취는 불필요합니다.",
            "estimated_price": 15000
          }
        ]
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
      return '{"status": "ERROR", "message": "${e.toString()}"}';
    }
  }
}
