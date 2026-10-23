import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/main.dart';

void main() {
  testWidgets('WrittleApp smoke test loads brand title, navigation, and write action', (tester) async {
    await tester.pumpWidget(const WrittleApp());
    await tester.pump();

    // Verify brand title in app bar
    expect(find.text('Writtle'), findsOneWidget);

    // Verify Write FAB is visible
    expect(find.text('Write'), findsOneWidget);

    // Verify bottom navigation bar tabs
    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
