import '../core/constants/ethos_constants.dart';

/// Model representasi data untuk kartu filosofi "The Writelle Ethos" di halaman Beranda.
class EthosModel {
  final String header;
  final String quote;
  final String subtext;
  final String buttonLabel;

  const EthosModel({
    required this.header,
    required this.quote,
    required this.subtext,
    required this.buttonLabel,
  });

  /// Nilai awal standar sesuai file konstanta
  factory EthosModel.initial() => const EthosModel(
        header: EthosConstants.header,
        quote: EthosConstants.quote,
        subtext: EthosConstants.subtext,
        buttonLabel: EthosConstants.buttonLabel,
      );

  factory EthosModel.fromMap(Map<String, dynamic> map) => EthosModel(
        header: (map['header'] as String?)?.trim().isNotEmpty == true
            ? map['header'] as String
            : EthosConstants.header,
        quote: (map['quote'] as String?)?.trim().isNotEmpty == true
            ? map['quote'] as String
            : EthosConstants.quote,
        subtext: (map['subtext'] as String?)?.trim().isNotEmpty == true
            ? map['subtext'] as String
            : EthosConstants.subtext,
        buttonLabel: (map['buttonLabel'] as String?)?.trim().isNotEmpty == true
            ? map['buttonLabel'] as String
            : EthosConstants.buttonLabel,
      );

  Map<String, dynamic> toMap() => {
        'header': header,
        'quote': quote,
        'subtext': subtext,
        'buttonLabel': buttonLabel,
      };

  EthosModel copyWith({
    String? header,
    String? quote,
    String? subtext,
    String? buttonLabel,
  }) {
    return EthosModel(
      header: header ?? this.header,
      quote: quote ?? this.quote,
      subtext: subtext ?? this.subtext,
      buttonLabel: buttonLabel ?? this.buttonLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthosModel &&
          runtimeType == other.runtimeType &&
          header == other.header &&
          quote == other.quote &&
          subtext == other.subtext &&
          buttonLabel == other.buttonLabel;

  @override
  int get hashCode =>
      header.hashCode ^ quote.hashCode ^ subtext.hashCode ^ buttonLabel.hashCode;
}
