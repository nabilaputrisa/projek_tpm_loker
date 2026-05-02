import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mengambil data kurs mata uang real-time.
/// Menggunakan exchangerate-api.com (free tier, tidak perlu API key).
/// Endpoint: https://api.exchangerate-api.com/v4/latest/{BASE}
class ApiKursService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  // Cache sederhana agar tidak terlalu sering hit API
  static Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Ambil semua nilai tukar dari [baseCurrency].
  /// Return map: { 'USD': 1.0, 'IDR': 15800.0, ... }
  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    final cacheKey = baseCurrency.toUpperCase();

    // Kembalikan dari cache jika masih valid
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

  /// Ambil daftar semua kode mata uang yang tersedia (dari hasil fetch USD).
  /// Berguna untuk mengisi dropdown "pilih mata uang".
  Future<List<String>> fetchAvailableCurrencies() async {
    final rates = await fetchRates('USD');
    final codes = rates.keys.toList()..sort();
    return codes;
  }

  /// Konversi [amount] dari [from] ke [to].
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

/// Model hasil konversi (bisa juga diletakkan di currency_model.dart)
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