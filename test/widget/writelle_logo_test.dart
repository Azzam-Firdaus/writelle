import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:writtle/core/widgets/writelle_logo.dart';

void main() {
  testWidgets('WritelleLogo.appBar renders official light logo asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WritelleLogo.appBar(),
        ),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    final assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/logo_light.png');
    expect(imageWidget.height, 34);
  });

  testWidgets('WritelleLogo.hero renders official light logo asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WritelleLogo.hero(),
        ),
      ),
    );

    final imageFinder = find.byType(Image);
    expect(imageFinder, findsOneWidget);

    final imageWidget = tester.widget<Image>(imageFinder);
    expect(imageWidget.image, isA<AssetImage>());
    final assetImage = imageWidget.image as AssetImage;
    expect(assetImage.assetName, 'assets/images/logo_light.png');
    expect(imageWidget.height, 140);
  });
}
