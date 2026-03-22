import 'package:flutter_test/flutter_test.dart';
import 'package:science_voice_learnings/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Science Voice Learning'), findsOneWidget);
  });
}
