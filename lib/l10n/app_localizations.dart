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
  /// **'SuppleCut'**
  String get appTitle;

  /// No description provided for @homeAppBarTitle.
  ///
  /// In ko, this message translates to:
  /// **'SuppleCut'**
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
  /// **'약통에 추가됨'**
  String get addedToCabinet;

  /// No description provided for @alreadyInCabinet.
  ///
  /// In ko, this message translates to:
  /// **'이미 약통에 있음'**
  String get alreadyInCabinet;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get undo;

  /// No description provided for @noResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get noResults;

  /// No description provided for @popularSearches.
  ///
  /// In ko, this message translates to:
  /// **'🔥 인기 검색어'**
  String get popularSearches;

  /// No description provided for @searchEmptyState.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 입력하여 영양제를 찾아보세요'**
  String get searchEmptyState;

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

  /// No description provided for @viewDetails.
  ///
  /// In ko, this message translates to:
  /// **'상세보기'**
  String get viewDetails;

  /// No description provided for @homeHeadline.
  ///
  /// In ko, this message translates to:
  /// **'혹시 영양제에\n돈 낭비 하고 계신가요? 💸'**
  String get homeHeadline;

  /// No description provided for @homeSubline.
  ///
  /// In ko, this message translates to:
  /// **'요즘 트렌드는 \'더하기\'가 아니라 \'빼기\'입니다.\n3초 만에 구조조정 해드려요.'**
  String get homeSubline;

  /// No description provided for @monthlySavings.
  ///
  /// In ko, this message translates to:
  /// **'평균 월 50,000원 절약 효과'**
  String get monthlySavings;

  /// No description provided for @btnTakePhoto.
  ///
  /// In ko, this message translates to:
  /// **'약 봉투 찍고 진단받기'**
  String get btnTakePhoto;

  /// No description provided for @btnFromAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 불러오기'**
  String get btnFromAlbum;

  /// No description provided for @healthTipTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 영양제 궁금증'**
  String get healthTipTitle;

  /// No description provided for @healthTipCta.
  ///
  /// In ko, this message translates to:
  /// **'알아보기 →'**
  String get healthTipCta;

  /// No description provided for @tipModalCta.
  ///
  /// In ko, this message translates to:
  /// **'내 영양제 조합은 괜찮을까?'**
  String get tipModalCta;

  /// No description provided for @tipModalBtn.
  ///
  /// In ko, this message translates to:
  /// **'내 영양제 분석해보기'**
  String get tipModalBtn;

  /// No description provided for @tip001Q.
  ///
  /// In ko, this message translates to:
  /// **'비타민D + 칼슘, 같이 먹어도 될까?'**
  String get tip001Q;

  /// No description provided for @tip001A.
  ///
  /// In ko, this message translates to:
  /// **'함께 먹으면 흡수율 UP! 👍\n하지만 마그네슘이랑 같이 먹으면 흡수를 방해할 수 있어요...'**
  String get tip001A;

  /// No description provided for @tip002Q.
  ///
  /// In ko, this message translates to:
  /// **'종합비타민 + 비타민D, 중복일까?'**
  String get tip002Q;

  /// No description provided for @tip002A.
  ///
  /// In ko, this message translates to:
  /// **'종합비타민에 이미 비타민D가 포함되어 있다면, 과다 섭취 위험이 있어요...'**
  String get tip002A;

  /// No description provided for @tip003Q.
  ///
  /// In ko, this message translates to:
  /// **'유산균 + 항생제, 같이 먹어도 돼?'**
  String get tip003Q;

  /// No description provided for @tip003A.
  ///
  /// In ko, this message translates to:
  /// **'항생제는 유산균을 죽일 수 있어요. 최소 2시간 간격을 두고...'**
  String get tip003A;

  /// No description provided for @recentAnalysisTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 분석 결과'**
  String get recentAnalysisTitle;

  /// No description provided for @recentAnalysisDate.
  ///
  /// In ko, this message translates to:
  /// **'{date} 분석'**
  String recentAnalysisDate(String date);

  /// No description provided for @btnReanalyze.
  ///
  /// In ko, this message translates to:
  /// **'다시 분석하기 →'**
  String get btnReanalyze;

  /// No description provided for @riskSafe.
  ///
  /// In ko, this message translates to:
  /// **'중복 성분 없음'**
  String get riskSafe;

  /// No description provided for @riskWarning.
  ///
  /// In ko, this message translates to:
  /// **'{ingredient} 과잉 주의'**
  String riskWarning(String ingredient);

  /// No description provided for @riskDanger.
  ///
  /// In ko, this message translates to:
  /// **'{ingredient} 상한 초과!'**
  String riskDanger(String ingredient);

  /// No description provided for @paymentTitle.
  ///
  /// In ko, this message translates to:
  /// **'상세 리포트 받기'**
  String get paymentTitle;

  /// No description provided for @paymentIncludes.
  ///
  /// In ko, this message translates to:
  /// **'포함 내용:'**
  String get paymentIncludes;

  /// No description provided for @paymentItem1.
  ///
  /// In ko, this message translates to:
  /// **'성분별 효능 상세 설명'**
  String get paymentItem1;

  /// No description provided for @paymentItem2.
  ///
  /// In ko, this message translates to:
  /// **'섭취 필요성 평가'**
  String get paymentItem2;

  /// No description provided for @paymentItem3.
  ///
  /// In ko, this message translates to:
  /// **'대체 제품 추천'**
  String get paymentItem3;

  /// No description provided for @paymentItem4.
  ///
  /// In ko, this message translates to:
  /// **'PDF 저장'**
  String get paymentItem4;

  /// No description provided for @paymentBtn.
  ///
  /// In ko, this message translates to:
  /// **'\$0.99 결제하기'**
  String get paymentBtn;

  /// No description provided for @paymentLater.
  ///
  /// In ko, this message translates to:
  /// **'다음에 할게요'**
  String get paymentLater;

  /// No description provided for @analysisSavings.
  ///
  /// In ko, this message translates to:
  /// **'월 절감 가능 금액'**
  String get analysisSavings;

  /// No description provided for @analysisYearly.
  ///
  /// In ko, this message translates to:
  /// **'연간 {amount} 아낄 수 있어요!'**
  String analysisYearly(String amount);

  /// No description provided for @analyzedProducts.
  ///
  /// In ko, this message translates to:
  /// **'분석된 제품'**
  String get analyzedProducts;

  /// No description provided for @badgeDbMatched.
  ///
  /// In ko, this message translates to:
  /// **'DB 확인'**
  String get badgeDbMatched;

  /// No description provided for @badgeAiEstimated.
  ///
  /// In ko, this message translates to:
  /// **'AI 추정'**
  String get badgeAiEstimated;

  /// No description provided for @badgeDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'중복'**
  String get badgeDuplicate;

  /// No description provided for @detailReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 상세 분석 리포트'**
  String get detailReportTitle;

  /// No description provided for @btnBackHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get btnBackHome;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'분석 중...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get errorGeneric;

  /// No description provided for @btnRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get btnRetry;

  /// No description provided for @btnClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get btnClose;

  /// No description provided for @btnCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get btnCancel;

  /// No description provided for @btnConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get btnConfirm;
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
