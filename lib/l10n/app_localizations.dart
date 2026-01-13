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
