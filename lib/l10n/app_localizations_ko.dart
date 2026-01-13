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
}
