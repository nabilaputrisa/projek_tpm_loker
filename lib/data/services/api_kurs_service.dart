import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiKursService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  static Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Ambil kurs mata uang terhadap [baseCurrency].
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    final cacheKey = baseCurrency.toUpperCase();

    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        return entry.rates;
      }
    }

    final url = Uri.parse('$_baseUrl/$cacheKey');
    final response =
        await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRates = data['rates'] as Map<String, dynamic>;
      final rates = rawRates
          .map((key, value) => MapEntry(key, (value as num).toDouble()));

      // Simpan ke cache
      _cache[cacheKey] = _CacheEntry(rates: rates, timestamp: DateTime.now());
      return rates;
    } else {
      throw Exception('Gagal mengambil kurs (status ${response.statusCode})');
    }
  }

  Future<List<String>> fetchAvailableCurrencies() async {
    final rates = await fetchRates('USD');
    final codes = rates.keys.toList()..sort();
    return codes;
  }

// Konversi mata uang
  Future<ConversionResult> convert({
    required double amount,
    required String from,
    required String to,
  }) async {
    final rates = await fetchRates(from);
    final rate = rates[to.toUpperCase()];
    if (rate == null) throw Exception('Mata uang $to tidak ditemukan');

    return ConversionResult(
      amount: amount,
      from: from.toUpperCase(),
      to: to.toUpperCase(),
      rate: rate,
      result: amount * rate,
    );
  }
}

class _CacheEntry {
  final Map<String, double> rates;
  final DateTime timestamp;
  _CacheEntry({required this.rates, required this.timestamp});
}

// Model untuk hasil konversi mata uang
class ConversionResult {
  final double amount;
  final String from;
  final String to;
  final double rate;
  final double result;

  ConversionResult({
    required this.amount,
    required this.from,
    required this.to,
    required this.rate,
    required this.result,
  });
}