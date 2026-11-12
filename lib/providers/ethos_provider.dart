import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ethos_model.dart';

final ethosProvider =
    NotifierProvider<EthosNotifier, EthosModel>(EthosNotifier.new);

class EthosNotifier extends Notifier<EthosModel> {
  static const _spKeyHeader = 'writelle_ethos_header';
  static const _spKeyQuote = 'writelle_ethos_quote';
  static const _spKeySubtext = 'writelle_ethos_subtext';
  static const _spKeyButtonLabel = 'writelle_ethos_button_label';

  @override
  EthosModel build() {
    _loadEthos();
    return EthosModel.initial();
  }

  Future<void> _loadEthos() async {
    // 1. Memuat langsung dari SharedPreferences (offline & instan)
    try {
      final prefs = await SharedPreferences.getInstance();
      final header = prefs.getString(_spKeyHeader);
      final quote = prefs.getString(_spKeyQuote);
      final subtext = prefs.getString(_spKeySubtext);
      final buttonLabel = prefs.getString(_spKeyButtonLabel);

      if (header != null || quote != null || subtext != null || buttonLabel != null) {
        state = EthosModel(
          header: header ?? state.header,
          quote: quote ?? state.quote,
          subtext: subtext ?? state.subtext,
          buttonLabel: buttonLabel ?? state.buttonLabel,
        );
      }
    } catch (e) {
      debugPrint('[EthosNotifier] SharedPreferences load notice: $e');
    }

    // 2. Sinkronisasi dengan Supabase platform_config secara silent jika online
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('platform_config')
          .select('value')
          .eq('key', 'ethos')
          .maybeSingle();

      if (res != null && res['value'] != null) {
        final val = res['value'];
        final Map<String, dynamic> data =
            val is String ? jsonDecode(val) : Map<String, dynamic>.from(val);
        final remoteEthos = EthosModel.fromMap(data);
        state = remoteEthos;

        // Simpan pembaruan ke cache lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_spKeyHeader, remoteEthos.header);
        await prefs.setString(_spKeyQuote, remoteEthos.quote);
        await prefs.setString(_spKeySubtext, remoteEthos.subtext);
        await prefs.setString(_spKeyButtonLabel, remoteEthos.buttonLabel);
      }
    } catch (_) {
      // Supabase uninitialized atau tabel belum dibuat, cache lokal tetap aktif
    }
  }

  Future<void> updateEthos(EthosModel newEthos) async {
    state = newEthos;

    // 1. Simpan ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spKeyHeader, newEthos.header);
      await prefs.setString(_spKeyQuote, newEthos.quote);
      await prefs.setString(_spKeySubtext, newEthos.subtext);
      await prefs.setString(_spKeyButtonLabel, newEthos.buttonLabel);
    } catch (e) {
      debugPrint('[EthosNotifier] SharedPreferences save notice: $e');
    }

    // 2. Simpan ke Supabase jika tabel platform_config tersedia
    try {
      final client = Supabase.instance.client;
      await client.from('platform_config').upsert({
        'key': 'ethos',
        'value': newEthos.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Abaikan jika offline atau permission ditolak
    }
  }

  Future<void> resetToDefault() async {
    final defaultEthos = EthosModel.initial();
    await updateEthos(defaultEthos);
  }
}
