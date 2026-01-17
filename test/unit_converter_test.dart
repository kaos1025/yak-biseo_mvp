import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    test('cmToInches converts correctly', () {
      expect(UnitConverter.cmToInches(2.54), 1.0);
      expect(UnitConverter.cmToInches(254), 100.0);
    });

    test('inchesToCm converts correctly', () {
      expect(UnitConverter.inchesToCm(1.0), 2.54);
      expect(UnitConverter.inchesToCm(100.0), 254.0);
    });

    test('cmToFeetInches converts correctly', () {
      // 170cm is approx 5ft 7in (169.9cm)
      final res1 = UnitConverter.cmToFeetInches(170.18);
      expect(res1['feet'], 5);
      expect(res1['inches'], 7);

      // 182.88cm is exactly 6ft
      final res2 = UnitConverter.cmToFeetInches(182.88);
      expect(res2['feet'], 6);
      expect(res2['inches'], 0);
    });

    test('feetInchesToCm converts correctly', () {
      expect(UnitConverter.feetInchesToCm(5, 7), closeTo(170.18, 0.01));
      expect(UnitConverter.feetInchesToCm(6, 0), closeTo(182.88, 0.01));
    });

    test('kgToLb converts correctly', () {
      expect(UnitConverter.kgToLb(1.0), 2.20462);
      expect(UnitConverter.kgToLb(100.0), 220.462);
    });

    test('lbToKg converts correctly', () {
      expect(UnitConverter.lbToKg(2.20462), closeTo(1.0, 0.0001));
      expect(UnitConverter.lbToKg(220.462), closeTo(100.0, 0.001));
    });
  });
}
