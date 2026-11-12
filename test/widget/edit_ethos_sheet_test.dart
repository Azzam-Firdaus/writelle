import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writtle/core/widgets/writtle_edit_ethos_sheet.dart';

void main() {
  testWidgets('WrittleEditEthosSheet renders inputs and saves updated ethos', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: WrittleEditEthosSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Configure The Writelle Ethos'), findsOneWidget);
    expect(find.text('THE WRITELLE ETHOS'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    // Edit the quote
    final quoteFinder = find.byType(TextField).at(1);
    await tester.enterText(quoteFinder, 'Updated wisdom for test purposes.');

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
  });
}
