import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'약비서'**
  String get appTitle;

  /// No description provided for @homeAppBarTitle.
  ///
  /// In ko, this message translates to:
  /// **'💊 내 손안의 약비서'**
  String get homeAppBarTitle;

  /// No description provided for @homeMainQuestion.
  ///
  /// In ko, this message translates to:
  /// **'혹시 영양제에\n돈 낭비 하고 계신가요? 💸'**
  String get homeMainQuestion;

  /// No description provided for @homeSubQuestion.
  ///
  /// In ko, this message translates to:
  /// **'요즘 트렌드는 \'더하기\'가 아니라 \'빼기\'입니다.\n3초 만에 구조조정 해드려요.'**
  String get homeSubQuestion;

  /// No description provided for @homeSavingEstimate.
  ///
  /// In ko, this message translates to:
  /// **'평균 월 50,000원 절약 효과'**
  String get homeSavingEstimate;

  /// No description provided for @homeBtnCamera.
  ///
  /// In ko, this message translates to:
  /// **'약 봉투 찍고 진단받기'**
  String get homeBtnCamera;

  /// No description provided for @homeBtnGallery.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 불러오기'**
  String get homeBtnGallery;

  /// No description provided for @homeDisclaimer.
  ///
  /// In ko, this message translates to:
  /// **'결과는 참고용이며, 정확한 진단은 의사/약사와 상의하세요.'**
  String get homeDisclaimer;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 설정'**
  String get profileTitle;

  /// No description provided for @heightLabel.
  ///
  /// In ko, this message translates to:
  /// **'키'**
  String get heightLabel;

  /// No description provided for @weightLabel.
  ///
  /// In ko, this message translates to:
  /// **'몸무게'**
  String get weightLabel;

  /// No description provided for @saveBtn.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get saveBtn;

  /// No description provided for @disclaimerTitle.
  ///
  /// In ko, this message translates to:
  /// **'의학적 면책 고지'**
  String get disclaimerTitle;

  /// No description provided for @disclaimerAgree.
  ///
  /// In ko, this message translates to:
  /// **'동의합니다'**
  String get disclaimerAgree;

  /// No description provided for @analysisTitle.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과'**
  String get analysisTitle;

  /// No description provided for @estimatedSavings.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 예상 절약 금액'**
  String get estimatedSavings;

  /// No description provided for @noDuplicates.
  ///
  /// In ko, this message translates to:
  /// **'중복된 영양제가 없습니다!'**
  String get noDuplicates;

  /// No description provided for @keepItUp.
  ///
  /// In ko, this message translates to:
  /// **'지금처럼 잘 챙겨드세요 :)'**
  String get keepItUp;

  /// No description provided for @savingsMessage.
  ///
  /// In ko, this message translates to:
  /// **'동일 성분 제품을 더 저렴하게 구매할 수 있어요!'**
  String get savingsMessage;

  /// No description provided for @aiSummary.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석 요약'**
  String get aiSummary;

  /// No description provided for @detectedProducts.
  ///
  /// In ko, this message translates to:
  /// **'발견된 제품 목록'**
  String get detectedProducts;

  /// No description provided for @detectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 발견'**
  String detectedCount(int count);

  /// No description provided for @returnHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get returnHome;

  /// No description provided for @searchTitle.
  ///
  /// In ko, this message translates to:
  /// **'영양제 검색'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'브랜드, 제품명, 증상 등으로 검색'**
  String get searchHint;

  /// No description provided for @addedToCabinet.
  ///
  /// In ko, this message translates to:
  /// **'이(가) 내 약통에 추가되었습니다.'**
  String get addedToCabinet;

  /// No description provided for @alreadyInCabinet.
  ///
  /// In ko, this message translates to:
  /// **'이미 약통에 있는 영양제입니다.'**
  String get alreadyInCabinet;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'실행취소'**
  String get undo;

  /// No description provided for @noResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get noResults;

  /// No description provided for @ingredients.
  ///
  /// In ko, this message translates to:
  /// **'원재료'**
  String get ingredients;

  /// No description provided for @usage.
  ///
  /// In ko, this message translates to:
  /// **'섭취방법'**
  String get usage;

  /// No description provided for @description.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get description;

  /// No description provided for @estimatedPrice.
  ///
  /// In ko, this message translates to:
  /// **'예상 가격'**
  String get estimatedPrice;

  /// No description provided for @add.
  ///
  /// In ko, this message translates to:
  /// **'담기'**
  String get add;

  /// No description provided for @added.
  ///
  /// In ko, this message translates to:
  /// **'담김'**
  String get added;

  /// No description provided for @verified.
  ///
  /// In ko, this message translates to:
  /// **'식약처 인증'**
  String get verified;

  /// No description provided for @warning.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get warning;

  /// No description provided for @redundant.
  ///
  /// In ko, this message translates to:
  /// **'중복'**
  String get redundant;

  /// No description provided for @unknown.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get unknown;

  /// No description provided for @productNotFound.
  ///
  /// In ko, this message translates to:
  /// **'제품명 확인 불가'**
  String get productNotFound;

  /// No description provided for @analysisComplete.
  ///
  /// In ko, this message translates to:
  /// **'분석이 완료되었습니다.'**
  String get analysisComplete;

  /// No description provided for @analysisError.
  ///
  /// In ko, this message translates to:
  /// **'분석 중 오류가 발생했습니다. 다시 시도해주세요.'**
  String get analysisError;

  /// No description provided for @tagVerified.
  ///
  /// In ko, this message translates to:
  /// **'식약처 인증'**
  String get tagVerified;

  /// No description provided for @tagAiResult.
  ///
  /// In ko, this message translates to:
  /// **'AI 분석 결과'**
  String get tagAiResult;

  /// No description provided for @tagDuplicateWarning.
  ///
  /// In ko, this message translates to:
  /// **'중복 경고'**
  String get tagDuplicateWarning;

  /// No description provided for @tagImported.
  ///
  /// In ko, this message translates to:
  /// **'해외 직구'**
  String get tagImported;

  /// No description provided for @tagPopular.
  ///
  /// In ko, this message translates to:
  /// **'인기'**
  String get tagPopular;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
