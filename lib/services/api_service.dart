import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  // API 키를 .env 파일에서 불러옵니다.
  static final String? _apiKey = dotenv.env['API_KEY'];

  static Future<String> analyzeDrugImage(XFile image) async {
    // 널이 될 수 있는 _apiKey를 지역 변수로 옮겨서 널 안전성 검사를 명확하게 합니다.
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      // API 키가 없으면 예외를 발생시켜 함수 실행을 중단합니다.
      throw Exception('API 키가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }

    // 이제 apiKey는 절대 널이 아니라고 확신할 수 있습니다.
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );

    final prompt = TextPart('''
Role: You are an expert AI Pharmacist for the Korean app "Yak-Biseo".

[Task: Group Shot Analysis]
The user will upload an image containing **MULTIPLE supplement bottles** (e.g., laid out on a table).
1. **Detection**: Identify ALL distinct supplement bottles visible in the image.
2. **Extraction**: For each bottle, extract 'Brand' and 'Product Name'.
3. **Logic (Redundancy Check)**:
   - Analyze ingredients based on product names (e.g., 'Triplus' -> Multivitamin+Mineral).
   - **CRITICAL**: If a 'Multivitamin' and a 'Single Ingredient' (like Vitamin C, Vitamin D, Calcium) are found together, flag the Single Ingredient as **"REDUNDANT"** (Warning).
4. **Savings Calculation**:
   - Estimate the monthly cost (KRW) for each item.
   - `total_saving_amount` = Sum of prices of ONLY the items flagged as "REDUNDANT".

[Output Format: JSON Only (Korean)]
{
  "summary": "회원님, 식탁 위에 5개 제품이 있네요. 그중 2개는 성분이 겹칩니다! 정리하면 월 25,000원을 아낄 수 있어요.",
  "total_saving_amount": 25000,
  "detected_items": [
    {
      "id": 1,
      "name": "종근당 락토핏 골드",
      "status": "SAFE",
      "desc": "유산균은 필수입니다. 계속 드세요.",
      "price": 15000
    },
    {
      "id": 2,
      "name": "고려은단 비타민C 1000",
      "status": "REDUNDANT",
      "desc": "종합비타민에 이미 비타민C가 충분해요. 이건 빼셔도 됩니다.",
      "price": 10000
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
    } catch (e, stackTrace) {
      print('Error in analyzeDrugImage: $e');
      print('Stack trace: $stackTrace');
      throw Exception('API 호출에 실패했습니다: ${e.toString()}');
    }
  }
}
