import 'package:flutter_test/flutter_test.dart';
import 'package:roomie_split/main.dart';

void main() {
  testWidgets('RoomieSplit smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomieSplitApp());
    await tester.pump();
    expect(find.text('RoomieSplit'), findsWidgets);
  });
}
