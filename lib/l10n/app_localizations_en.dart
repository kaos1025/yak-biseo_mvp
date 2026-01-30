// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SuppleCut';

  @override
  String get homeAppBarTitle => 'SuppleCut';

  @override
  String get homeMainQuestion => 'Are you wasting money\non supplements? 💸';

  @override
  String get homeSubQuestion =>
      'Today\'s trend is \'Subtracting\', not \'Adding\'.\nWe optimize your supplements in 3 seconds.';

  @override
  String get homeSavingEstimate => 'Save \$40/month on average';

  @override
  String get homeBtnCamera => 'Scan Label';

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

  @override
  String get analysisTitle => 'Analysis Result';

  @override
  String get estimatedSavings => 'Estimated Monthly Savings';

  @override
  String get noDuplicates => 'No duplicates found!';

  @override
  String get keepItUp => 'Keep up the good work! :)';

  @override
  String get savingsMessage => 'Save money by reducing duplicates!';

  @override
  String get aiSummary => 'AI Analysis Summary';

  @override
  String get detectedProducts => 'Detected Products';

  @override
  String detectedCount(int count) {
    return '$count items detected';
  }

  @override
  String get returnHome => 'Return to Home';

  @override
  String get searchTitle => 'Search Supplements';

  @override
  String get searchHint => 'Search by brand, product, symptoms...';

  @override
  String get addedToCabinet => 'Added to My Cabinet';

  @override
  String get alreadyInCabinet => 'Already in My Cabinet';

  @override
  String get undo => 'Undo';

  @override
  String get noResults => 'No results found';

  @override
  String get popularSearches => '🔥 Popular Searches';

  @override
  String get searchEmptyState => 'Enter a search term to find supplements';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get usage => 'Usage';

  @override
  String get description => 'Description';

  @override
  String get estimatedPrice => 'Est. Price';

  @override
  String get add => 'Add';

  @override
  String get added => 'Added';

  @override
  String get verified => 'Verified';

  @override
  String get warning => 'Warning';

  @override
  String get redundant => 'Redundant';

  @override
  String get unknown => 'Unknown';

  @override
  String get productNotFound => 'Product name unavailable';

  @override
  String get analysisComplete => 'Analysis complete.';

  @override
  String get analysisError => 'Analysis error. Please try again.';

  @override
  String get tagVerified => 'Verified';

  @override
  String get tagAiResult => 'AI Result';

  @override
  String get tagDuplicateWarning => 'Duplicate Warning';

  @override
  String get tagImported => 'Imported';

  @override
  String get tagPopular => 'Popular';

  @override
  String get viewDetails => 'View Details';
}
