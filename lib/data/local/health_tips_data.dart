import '../models/health_tip_model.dart';

class HealthTipsData {
  static const List<Map<String, dynamic>> _rawTips = [
    {
      "id": "tip_001",
      "question": "비타민D + 칼슘, 같이 먹어도 될까?",
      "teaser": "함께 먹으면 흡수율 UP! 👍\n하지만 마그네슘이랑 같이 먹으면 흡수를 방해할 수 있어요...",
      "cta": "내 영양제 조합은 괜찮을까?"
    },
    {
      "id": "tip_002",
      "question": "종합비타민 + 비타민D, 중복일까?",
      "teaser":
          "종합비타민에 이미 비타민D가 포함되어 있다면, 과다 섭취 위험이 있어요. 일일 상한량은 100mcg(4,000IU)...",
      "cta": "내 영양제도 중복인지 확인해볼까요?"
    },
    {
      "id": "tip_003",
      "question": "유산균 + 항생제, 같이 먹어도 돼?",
      "teaser": "항생제는 유산균을 죽일 수 있어요. 최소 2시간 간격을 두고 섭취하는 것이 좋습니다...",
      "cta": "내 영양제 복용 타이밍도 확인해보세요"
    },
    {
      "id": "tip_004",
      "question": "오메가3 + 비타민E, 따로 먹어야 할까?",
      "teaser": "대부분의 오메가3 제품에는 이미 비타민E가 산화 방지제로 포함되어 있어요...",
      "cta": "내 오메가3에도 비타민E가 있을까?"
    },
    {
      "id": "tip_005",
      "question": "철분 + 칼슘, 왜 따로 먹으라고 할까?",
      "teaser": "철분과 칼슘은 흡수 경쟁을 해요. 같이 먹으면 철분 흡수율이 최대 50%까지 감소할 수 있어요...",
      "cta": "내 영양제 조합도 확인해볼까요?"
    }
  ];

  static List<HealthTipModel> get tips {
    return _rawTips.map((e) => HealthTipModel.fromJson(e)).toList();
  }
}
