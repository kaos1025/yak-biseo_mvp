// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '약비서';

  @override
  String get homeAppBarTitle => '💊 내 손안의 약비서';

  @override
  String get homeMainQuestion => '혹시 영양제에\n돈 낭비 하고 계신가요? 💸';

  @override
  String get homeSubQuestion =>
      '요즘 트렌드는 \'더하기\'가 아니라 \'빼기\'입니다.\n3초 만에 구조조정 해드려요.';

  @override
  String get homeSavingEstimate => '평균 월 50,000원 절약 효과';

  @override
  String get homeBtnCamera => '약 봉투 찍고 진단받기';

  @override
  String get homeBtnGallery => '앨범에서 불러오기';

  @override
  String get homeDisclaimer => '결과는 참고용이며, 정확한 진단은 의사/약사와 상의하세요.';

  @override
  String get profileTitle => '프로필 설정';

  @override
  String get heightLabel => '키';

  @override
  String get weightLabel => '몸무게';

  @override
  String get saveBtn => '저장하기';

  @override
  String get disclaimerTitle => '의학적 면책 고지';

  @override
  String get disclaimerAgree => '동의합니다';

  @override
  String get analysisTitle => '분석 결과';

  @override
  String get estimatedSavings => '이번 달 예상 절약 금액';

  @override
  String get noDuplicates => '중복된 영양제가 없습니다!';

  @override
  String get keepItUp => '지금처럼 잘 챙겨드세요 :)';

  @override
  String get savingsMessage => '동일 성분 제품을 더 저렴하게 구매할 수 있어요!';

  @override
  String get aiSummary => 'AI 분석 요약';

  @override
  String get detectedProducts => '발견된 제품 목록';

  @override
  String detectedCount(int count) {
    return '$count개 발견';
  }

  @override
  String get returnHome => '홈으로 돌아가기';

  @override
  String get searchTitle => '영양제 검색';

  @override
  String get searchHint => '브랜드, 제품명, 증상 등으로 검색';

  @override
  String get addedToCabinet => '약통에 추가됨';

  @override
  String get alreadyInCabinet => '이미 약통에 있음';

  @override
  String get undo => '실행 취소';

  @override
  String get noResults => '검색 결과가 없습니다';

  @override
  String get popularSearches => '🔥 인기 검색어';

  @override
  String get searchEmptyState => '검색어를 입력하여 영양제를 찾아보세요';

  @override
  String get ingredients => '원재료';

  @override
  String get usage => '섭취방법';

  @override
  String get description => '내용';

  @override
  String get estimatedPrice => '예상 가격';

  @override
  String get add => '담기';

  @override
  String get added => '담김';

  @override
  String get verified => '식약처 인증';

  @override
  String get warning => '주의';

  @override
  String get redundant => '중복';

  @override
  String get unknown => '정보 없음';

  @override
  String get productNotFound => '제품명 확인 불가';

  @override
  String get analysisComplete => '분석이 완료되었습니다.';

  @override
  String get analysisError => '분석 중 오류가 발생했습니다. 다시 시도해주세요.';

  @override
  String get tagVerified => '식약처 인증';

  @override
  String get tagAiResult => 'AI 분석 결과';

  @override
  String get tagDuplicateWarning => '중복 경고';

  @override
  String get tagImported => '해외 직구';

  @override
  String get tagPopular => '인기';

  @override
  String get viewDetails => '상세보기';
}
