import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:writtle/core/constants/ethos_constants.dart';
import 'package:writtle/models/ethos_model.dart';
import 'package:writtle/providers/ethos_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EthosModel Tests', () {
    test('initial model matches EthosConstants', () {
      final ethos = EthosModel.initial();
      expect(ethos.header, EthosConstants.header);
      expect(ethos.quote, EthosConstants.quote);
      expect(ethos.subtext, EthosConstants.subtext);
      expect(ethos.buttonLabel, EthosConstants.buttonLabel);
    });

    test('toMap and fromMap serialize and deserialize correctly', () {
      const ethos = EthosModel(
        header: 'CUSTOM ETHOS',
        quote: 'Custom philosophical quote here.',
        subtext: 'Custom subtext',
        buttonLabel: 'Custom Button',
      );

      final map = ethos.toMap();
      final parsed = EthosModel.fromMap(map);

      expect(parsed.header, 'CUSTOM ETHOS');
      expect(parsed.quote, 'Custom philosophical quote here.');
      expect(parsed.subtext, 'Custom subtext');
      expect(parsed.buttonLabel, 'Custom Button');
    });

    test('fromMap with missing fields falls back gracefully', () {
      final parsed = EthosModel.fromMap({});
      expect(parsed.header, EthosConstants.header);
      expect(parsed.quote, EthosConstants.quote);
      expect(parsed.subtext, EthosConstants.subtext);
      expect(parsed.buttonLabel, EthosConstants.buttonLabel);
    });
  });

  group('EthosNotifier Tests', () {
    test('updateEthos updates state and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(ethosProvider.notifier);

      const newEthos = EthosModel(
        header: 'NEW ETHOS',
        quote: 'New inspiring words.',
        subtext: 'New sanctuary',
        buttonLabel: 'Write Now',
      );

      await notifier.updateEthos(newEthos);
      expect(container.read(ethosProvider).header, 'NEW ETHOS');
      expect(container.read(ethosProvider).quote, 'New inspiring words.');
      expect(container.read(ethosProvider).subtext, 'New sanctuary');
      expect(container.read(ethosProvider).buttonLabel, 'Write Now');

      await notifier.resetToDefault();
      expect(container.read(ethosProvider).header, EthosConstants.header);
      expect(container.read(ethosProvider).quote, EthosConstants.quote);
    });
  });
}
