class UnitConverter {
  /// Converts centimeters to inches.
  static double cmToInches(double cm) => cm / 2.54;

  /// Converts inches to centimeters.
  static double inchesToCm(double inches) => inches * 2.54;

  /// Converts centimeters to a map with 'feet' and 'inches'.
  static Map<String, int> cmToFeetInches(double cm) {
    double totalInches = cmToInches(cm);
    int feet = (totalInches / 12).floor();
    int inches = (totalInches % 12).round();
    if (inches == 12) {
      feet += 1;
      inches = 0;
    }
    return {'feet': feet, 'inches': inches};
  }

  /// Converts feet and inches to centimeters.
  static double feetInchesToCm(int feet, int inches) {
    int totalInches = (feet * 12) + inches;
    return inchesToCm(totalInches.toDouble());
  }

  /// Converts kilograms to pounds.
  static double kgToLb(double kg) => kg * 2.20462;

  /// Converts pounds to kilograms.
  static double lbToKg(double lb) => lb / 2.20462;
}
