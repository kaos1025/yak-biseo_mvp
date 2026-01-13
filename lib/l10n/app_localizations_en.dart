// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YakBiseo';

  @override
  String get homeAppBarTitle => '💊 Your AI Pharmacist';

  @override
  String get homeMainQuestion => 'Are you wasting money\non supplements? 💸';

  @override
  String get homeSubQuestion =>
      'Today\'s trend is \'Subtracting\', not \'Adding\'.\nWe optimize your prescriptions in 3 seconds.';

  @override
  String get homeSavingEstimate => 'Save \$40/month on average';

  @override
  String get homeBtnCamera => 'Scan Prescription';

  @override
  String get homeBtnGallery => 'Import from Gallery';

  @override
  String get homeDisclaimer =>
      'Results are for reference; consult a doctor or pharmacist.';

  @override
  String get profileTitle => 'Profile Setup';

  @override
  String get heightLabel => 'Height';

  @override
  String get weightLabel => 'Weight';

  @override
  String get saveBtn => 'Save';

  @override
  String get disclaimerTitle => 'Medical Disclaimer';

  @override
  String get disclaimerAgree => 'I Agree';
}
