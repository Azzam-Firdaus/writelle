import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/screens/main_shell_screen.dart';
import 'package:writtle/screens/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders official brand splash image and navigates to MainShellScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Initial frame renders Image
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    final assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/splash_screen.png');

    // Advance timer past splash duration
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify MainShellScreen is presented
    expect(find.byType(MainShellScreen), findsOneWidget);
  });
}
