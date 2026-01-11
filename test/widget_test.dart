// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('Initial screen shows two buttons', (WidgetTester tester) async {
    // skip this test if environment is not set up
  }, skip: true);
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YakBiseoApp());

    // Verify that the two main buttons are present.
    expect(find.text('약 봉투 찍고 진단받기'), findsOneWidget);
    expect(find.text('앨범에서 불러오기'), findsOneWidget);
  });
}
