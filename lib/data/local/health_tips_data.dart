import '../models/health_tip_model.dart';

class HealthTipsData {
  static const List<Map<String, dynamic>> _rawTips = [
    {
      "id": "tip_001",
      "questionKo": "비타민D + 칼슘, 같이 먹어도 될까?",
      "questionEn": "Vitamin D + Calcium, can I take them together?",
      "teaserKo": "함께 먹으면 흡수율 UP! 👍\n하지만 마그네슘이랑 같이 먹으면 흡수를 방해할 수 있어요...",
      "teaserEn":
          "Taking them together increases absorption! 👍\nBut taking them with magnesium might interfere with absorption...",
      "ctaKo": "내 영양제 조합은 괜찮을까?",
      "ctaEn": "Are my supplement combinations okay?"
    },
    {
      "id": "tip_002",
      "questionKo": "종합비타민 + 비타민D, 중복일까?",
      "questionEn": "Multivitamin + Vitamin D, is it redundant?",
      "teaserKo":
          "종합비타민에 이미 비타민D가 포함되어 있다면, 과다 섭취 위험이 있어요. 일일 상한량은 100mcg(4,000IU)...",
      "teaserEn":
          "If your multivitamin already includes Vitamin D, there is a risk of overdose. The daily upper limit is 100mcg(4,000IU)...",
      "ctaKo": "내 영양제도 중복인지 확인해볼까요?",
      "ctaEn": "Shall we check if my supplements are redundant?"
    },
    {
      "id": "tip_003",
      "questionKo": "유산균 + 항생제, 같이 먹어도 돼?",
      "questionEn": "Probiotics + Antibiotics, can I take them together?",
      "teaserKo": "항생제는 유산균을 죽일 수 있어요. 최소 2시간 간격을 두고 섭취하는 것이 좋습니다...",
      "teaserEn":
          "Antibiotics can kill probiotics. It's best to take them at least 2 hours apart...",
      "ctaKo": "내 영양제 복용 타이밍도 확인해보세요",
      "ctaEn": "Check the timing for your supplements too"
    },
    {
      "id": "tip_004",
      "questionKo": "오메가3 + 비타민E, 따로 먹어야 할까?",
      "questionEn": "Omega 3 + Vitamin E, should I take them separately?",
      "teaserKo": "대부분의 오메가3 제품에는 이미 비타민E가 산화 방지제로 포함되어 있어요...",
      "teaserEn":
          "Most Omega 3 products already contain Vitamin E as an antioxidant...",
      "ctaKo": "내 오메가3에도 비타민E가 있을까?",
      "ctaEn": "Does my Omega 3 have Vitamin E too?"
    },
    {
      "id": "tip_005",
      "questionKo": "철분 + 칼슘, 왜 따로 먹으라고 할까?",
      "questionEn": "Iron + Calcium, why should I take them separately?",
      "teaserKo": "철분과 칼슘은 흡수 경쟁을 해요. 같이 먹으면 철분 흡수율이 최대 50%까지 감소할 수 있어요...",
      "teaserEn":
          "Iron and calcium compete for absorption. Taking them together can reduce iron absorption by up to 50%...",
      "ctaKo": "내 영양제 조합도 확인해볼까요?",
      "ctaEn": "Shall we check my supplement combinations too?"
    }
  ];

  static List<HealthTipModel> get tips {
    return _rawTips.map((e) => HealthTipModel.fromJson(e)).toList();
  }
}
