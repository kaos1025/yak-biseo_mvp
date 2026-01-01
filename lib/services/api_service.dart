
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
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
    );

    final prompt = TextPart(
      '''
      당신은 20년 경력 약사 '약비서'입니다. 사진 속의 약/영양제를 분석하세요.
      식약처 데이터를 기반으로 판단하되, 다음 JSON 포맷으로만 응답하세요. (마크다운, 잡담 금지)
      
      {
        "status": "SUCCESS",
        "summary": "3줄 요약 멘트",
        "cards": [
          {
            "type": "WARNING", // 또는 INFO, SAVING
            "title": "타이틀",
            "content": "상세 내용"
          }
        ]
      }
      ''',
    );

    final imageBytes = await image.readAsBytes();
    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);
      return response.text ?? '{"status": "ERROR", "summary": "모델로부터 응답을 받지 못했습니다.", "cards": []}';
    } catch (e) {
      return '{"status": "ERROR", "summary": "API 호출 중 오류가 발생했습니다: $e", "cards": []}';
    }
  }
}
