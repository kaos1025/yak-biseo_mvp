import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

void registerPretendardLicense() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'assets/fonts/Pretendard-LICENSE.txt',
    );
    yield LicenseEntryWithLineBreaks(['Pretendard'], license);
  });
}
