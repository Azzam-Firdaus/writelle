import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/main.dart';

void main() {
  testWidgets('WrittleApp smoke test loads brand title and tagline', (tester) async {
    await tester.pumpWidget(const WrittleApp());
    await tester.pump();

    // Verify brand title and tagline are displayed
    expect(find.text('Writtle'), findsOneWidget);
    expect(
      find.text('“Your story matters, even when your name doesn’t.”'),
      findsOneWidget,
    );
    expect(find.text('Explore Stories'), findsOneWidget);
  });
}
