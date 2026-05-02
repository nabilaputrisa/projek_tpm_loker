import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';

class ApiJobService {
  static const String _appId = '091323f3';
  static const String _appKey = '1592c4f9b5d73ab7ef63f3ec54dd2de6';
  static const String _baseUrl = 'https://api.adzuna.com/v1/api/jobs';

  // ─── Country Config ────────────────────────────────────────────────────────
  static const Map<String, CountryConfig> countries = {
    'sg': CountryConfig(
      name: 'Singapore',
      currency: 'SGD',
      currencySymbol: 'S\$',
      flag: '🇸🇬',
    ),
    'in': CountryConfig(
      name: 'India',
      currency: 'INR',
      currencySymbol: '₹',
      flag: '🇮🇳',
    ),
    'gb': CountryConfig(
      name: 'United Kingdom',
      currency: 'GBP',
      currencySymbol: '£',
      flag: '🇬🇧',
    ),
    'au': CountryConfig(
      name: 'Australia',
      currency: 'AUD',
      currencySymbol: 'A\$',
      flag: '🇦🇺',
    ),
    'us': CountryConfig(
      name: 'United States',
      currency: 'USD',
      currencySymbol: '\$',
      flag: '🇺🇸',
    ),
    'ca': CountryConfig(
      name: 'Canada',
      currency: 'CAD',
      currencySymbol: 'C\$',
      flag: '🇨🇦',
    ),
    'de': CountryConfig(
      name: 'Germany',
      currency: 'EUR',
      currencySymbol: '€',
      flag: '🇩🇪',
    ),
  };

  // ─── Locations per Country ─────────────────────────────────────────────────
  static const Map<String, List<String>> _locationsByCountry = {
    'sg': [
      'Central Region',
      'East Region',
      'North Region',
      'North-East Region',
      'West Region',
    ],
    'in': [
      'Bangalore',
      'Mumbai',
      'Delhi',
      'Hyderabad',
      'Chennai',
      'Pune',
      'Kolkata',
      'Ahmedabad',
      'Noida',
      'Gurgaon',
    ],
    'gb': [
      'London',
      'Manchester',
      'Birmingham',
      'Leeds',
      'Glasgow',
      'Bristol',
      'Edinburgh',
      'Sheffield',
      'Liverpool',
      'Nottingham',
    ],
    'au': [
      'Sydney',
      'Melbourne',
      'Brisbane',
      'Perth',
      'Adelaide',
      'Gold Coast',
      'Canberra',
      'Darwin',
      'Hobart',
    ],
    'us': [
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'San Francisco',
      'Seattle',
      'Austin',
      'Boston',
      'Miami',
      'Denver',
    ],
    'ca': [
      'Toronto',
      'Vancouver',
      'Montreal',
      'Calgary',
      'Ottawa',
      'Edmonton',
      'Winnipeg',
      'Quebec City',
    ],
    'de': [
      'Berlin',
      'Munich',
      'Hamburg',
      'Frankfurt',
      'Cologne',
      'Stuttgart',
      'Düsseldorf',
      'Leipzig',
    ],
  };

  // ─── Salary Ranges per Country (annual) ────────────────────────────────────
  static const Map<String, List<SalaryRange>> _salaryRangesByCountry = {
    'sg': [
      SalaryRange(label: 'S\$ 30,000 – 50,000', min: 30000, max: 50000),
      SalaryRange(label: 'S\$ 50,000 – 80,000', min: 50000, max: 80000),
      SalaryRange(label: 'S\$ 80,000 – 120,000', min: 80000, max: 120000),
      SalaryRange(label: 'S\$ 120,000+', min: 120000, max: null),
    ],
    'in': [
      SalaryRange(label: '₹ 3L – 6L', min: 300000, max: 600000),
      SalaryRange(label: '₹ 6L – 12L', min: 600000, max: 1200000),
      SalaryRange(label: '₹ 12L – 25L', min: 1200000, max: 2500000),
      SalaryRange(label: '₹ 25L+', min: 2500000, max: null),
    ],
    'gb': [
      SalaryRange(label: '£20,000 – £35,000', min: 20000, max: 35000),
      SalaryRange(label: '£35,000 – £55,000', min: 35000, max: 55000),
      SalaryRange(label: '£55,000 – £80,000', min: 55000, max: 80000),
      SalaryRange(label: '£80,000+', min: 80000, max: null),
    ],
    'au': [
      SalaryRange(label: 'A\$ 50,000 – 75,000', min: 50000, max: 75000),
      SalaryRange(label: 'A\$ 75,000 – 110,000', min: 75000, max: 110000),
      SalaryRange(label: 'A\$ 110,000 – 150,000', min: 110000, max: 150000),
      SalaryRange(label: 'A\$ 150,000+', min: 150000, max: null),
    ],
    'us': [
      SalaryRange(label: '\$40,000 – \$70,000', min: 40000, max: 70000),
      SalaryRange(label: '\$70,000 – \$110,000', min: 70000, max: 110000),
      SalaryRange(label: '\$110,000 – \$160,000', min: 110000, max: 160000),
      SalaryRange(label: '\$160,000+', min: 160000, max: null),
    ],
    'ca': [
      SalaryRange(label: 'C\$ 45,000 – 70,000', min: 45000, max: 70000),
      SalaryRange(label: 'C\$ 70,000 – 100,000', min: 70000, max: 100000),
      SalaryRange(label: 'C\$ 100,000 – 140,000', min: 100000, max: 140000),
      SalaryRange(label: 'C\$ 140,000+', min: 140000, max: null),
    ],
    'de': [
      SalaryRange(label: '€30,000 – €50,000', min: 30000, max: 50000),
      SalaryRange(label: '€50,000 – €75,000', min: 50000, max: 75000),
      SalaryRange(label: '€75,000 – €100,000', min: 75000, max: 100000),
      SalaryRange(label: '€100,000+', min: 100000, max: null),
    ],
  };

  // ─── Fetch Jobs ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchJobs({
    String countryCode = 'sg',
    String? query,
    String? location,
    int page = 1,
    int resultsPerPage = 20,
    String sortBy = 'date', // date | salary | relevance
    String? category,
    double? salaryMin,
    double? salaryMax, required String country,
  }) async {
    try {
      final url = '$_baseUrl/$countryCode/search/$page';

      final Map<String, String> queryParams = {
        'app_id': _appId,
        'app_key': _appKey,
        'results_per_page': resultsPerPage.toString(),
        'sort_by': sortBy,
        'content-type': 'application/json',
      };

      if (query != null && query.isNotEmpty) queryParams['what'] = query;
      if (location != null && location.isNotEmpty) queryParams['where'] = location;
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (salaryMin != null) queryParams['salary_min'] = salaryMin.toInt().toString();
      if (salaryMax != null) queryParams['salary_max'] = salaryMax.toInt().toString();

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      print('🔍 Fetching: $uri');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final countryConfig = countries[countryCode];

        List<JobModel> jobs = [];
        if (data['results'] != null) {
          jobs = (data['results'] as List)
              .map((j) => JobModel.fromJson(j, currencySymbol: countryConfig?.currencySymbol))
              .toList();
        }

        return {
          'success': true,
          'jobs': jobs,
          'total': data['count'] ?? 0,
          'page': page,
          'totalPages': ((data['count'] ?? 0) / resultsPerPage).ceil(),
          'country': countryConfig,
        };
      } else {
        print('❌ HTTP ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'Gagal memuat lowongan. Status: ${response.statusCode}',
          'jobs': <JobModel>[],
        };
      }
    } catch (e) {
      print('❌ Exception: $e');
      return {
        'success': false,
        'error': 'Error: $e',
        'jobs': <JobModel>[],
      };
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Daftar negara yang tersedia
  List<MapEntry<String, CountryConfig>> getAvailableCountries() {
    return countries.entries.toList();
  }

  /// Lokasi berdasarkan kode negara
  List<String> getLocations(String countryCode) {
    return ['Semua Lokasi', ...(_locationsByCountry[countryCode] ?? [])];
  }

  /// Range salary berdasarkan kode negara
  List<SalaryRange> getSalaryRanges(String countryCode) {
    return _salaryRangesByCountry[countryCode] ?? [];
  }

  /// Format salary dengan mata uang negara
  String formatSalary(double? min, double? max, String countryCode) {
    final symbol = countries[countryCode]?.currencySymbol ?? '';
    if (min == null && max == null) return 'Salary not specified';

    String fmt(double v) {
      if (v >= 1000000) return '${symbol}${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${symbol}${(v / 1000).toStringAsFixed(0)}K';
      return '$symbol${v.toStringAsFixed(0)}';
    }

    if (min != null && max != null) return '${fmt(min)} – ${fmt(max)}';
    if (min != null) return '${fmt(min)}+';
    return 'Up to ${fmt(max!)}';
  }

  Future<List<String>> fetchCategories() async {
    return [
      'Semua Kategori',
      'it-jobs',
      'engineering-jobs',
      'sales-jobs',
      'customer-services-jobs',
      'healthcare-nursing-jobs',
      'teaching-jobs',
      'accounting-finance-jobs',
      'legal-jobs',
      'marketing-jobs',
      'hr-jobs',
      'admin-jobs',
      'hospitality-catering-jobs',
      'manufacturing-jobs',
    ];
  }
}

// ─── Supporting Classes ──────────────────────────────────────────────────────

class CountryConfig {
  final String name;
  final String currency;
  final String currencySymbol;
  final String flag;

  const CountryConfig({
    required this.name,
    required this.currency,
    required this.currencySymbol,
    required this.flag,
  });
}

class SalaryRange {
  final String label;
  final double min;
  final double? max;

  const SalaryRange({
    required this.label,
    required this.min,
    this.max,
  });
}
