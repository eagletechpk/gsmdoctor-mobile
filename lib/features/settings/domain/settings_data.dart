class SettingsData {
  final Map<String, String> settings;
  final List<CurrencyRow> currencies;

  const SettingsData({required this.settings, required this.currencies});

  factory SettingsData.fromJson(Map<String, dynamic> json) => SettingsData(
        settings: Map<String, String>.from(
            (json['settings'] as Map<String, dynamic>? ?? {}).map(
                (k, v) => MapEntry(k, v?.toString() ?? ''))),
        currencies: (json['currencies'] as List? ?? [])
            .map((c) => CurrencyRow.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

  String get(String key, [String fallback = '']) => settings[key] ?? fallback;
  bool getBool(String key) => settings[key] == '1';
}

class CurrencyRow {
  final int id;
  final String code;
  final String name;
  final String symbol;
  final double? rate;
  final bool isBase;
  final bool isActive;

  const CurrencyRow({
    required this.id,
    required this.code,
    required this.name,
    required this.symbol,
    this.rate,
    required this.isBase,
    required this.isActive,
  });

  factory CurrencyRow.fromJson(Map<String, dynamic> json) => CurrencyRow(
        id: json['id'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        symbol: json['symbol'] as String,
        rate: (json['rate'] as num?)?.toDouble(),
        isBase: json['is_base'] == true,
        isActive: json['is_active'] == true,
      );
}
