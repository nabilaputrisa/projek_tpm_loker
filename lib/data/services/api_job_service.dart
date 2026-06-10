import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import '../../core/constants/api_keys.dart';

class ApiJobService {
  static const String _appId = ApiKeys.adzunaAppId;
  static const String _appKey = ApiKeys.adzunaAppKey;
  static const String _baseUrl = 'https://api.adzuna.com/v1/api/jobs';

  // Country Config 
  static const Map<String, CountryConfig> countries = {
    'sg': CountryConfig(name: 'Singapore', currency: 'SGD', currencySymbol: 'S\$', flag: '🇸🇬'),
    'in': CountryConfig(name: 'India', currency: 'INR', currencySymbol: '₹', flag: '🇮🇳'),
    'gb': CountryConfig(name: 'United Kingdom', currency: 'GBP', currencySymbol: '£', flag: '🇬🇧'),
    'au': CountryConfig(name: 'Australia', currency: 'AUD', currencySymbol: 'A\$', flag: '🇦🇺'),
    'us': CountryConfig(name: 'United States', currency: 'USD', currencySymbol: '\$', flag: '🇺🇸'),
    'ca': CountryConfig(name: 'Canada', currency: 'CAD', currencySymbol: 'C\$', flag: '🇨🇦'),
    'de': CountryConfig(name: 'Germany', currency: 'EUR', currencySymbol: '€', flag: '🇩🇪'),
  };

  // Locations per Country 
  static const Map<String, List<String>> _locationsByCountry = {
    'sg': ['Central Region', 'East Region', 'North Region', 'North-East Region', 'West Region'],
    'in': ['Bangalore', 'Mumbai', 'Delhi', 'Hyderabad', 'Chennai', 'Pune', 'Kolkata', 'Ahmedabad', 'Noida', 'Gurgaon'],
    'gb': ['London', 'Manchester', 'Birmingham', 'Leeds', 'Glasgow', 'Bristol', 'Edinburgh', 'Sheffield', 'Liverpool', 'Nottingham'],
    'au': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Gold Coast', 'Canberra', 'Darwin', 'Hobart'],
    'us': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'San Francisco', 'Seattle', 'Austin', 'Boston', 'Miami', 'Denver'],
    'ca': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa', 'Edmonton', 'Winnipeg', 'Quebec City'],
    'de': ['Berlin', 'Munich', 'Hamburg', 'Frankfurt', 'Cologne', 'Stuttgart', 'Düsseldorf', 'Leipzig'],
  };

  // Fetch Jobs From Adzuna API 
  Future<Map<String, dynamic>> fetchJobs({
    String countryCode = 'sg',
    String? query,
    String? location,
    int page = 1,
    int resultsPerPage = 20,
    String sortBy = 'date',
    String? category,
    double? salaryMin,
    double? salaryMax,
    required String country,
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

  List<MapEntry<String, CountryConfig>> getAvailableCountries() {
    return countries.entries.toList();
  }

  List<String> getLocations(String countryCode) {
    return ['Semua Lokasi', ...(_locationsByCountry[countryCode] ?? [])];
  }

  String formatSalary(double? min, double? max, String countryCode) {
    final symbol = countries[countryCode]?.currencySymbol ?? '';
    if (min == null && max == null) return 'Salary not specified';

    String fmt(double v) {
      if (v >= 1000000) return '$symbol${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '$symbol${(v / 1000).toStringAsFixed(0)}K';
      return '$symbol${v.toStringAsFixed(0)}';
    }

    if (min != null && max != null) return '${fmt(min)} – ${fmt(max)} / yr';
    if (min != null) return '${fmt(min)}+ / yr';
    return 'Up to ${fmt(max!)} / yr';
  }

  Future<List<String>> fetchCategories() async {
    return [
      'Semua Kategori', 'it-jobs', 'engineering-jobs', 'sales-jobs',
      'customer-services-jobs', 'healthcare-nursing-jobs', 'teaching-jobs',
      'accounting-finance-jobs', 'legal-jobs', 'marketing-jobs', 'hr-jobs',
      'admin-jobs', 'hospitality-catering-jobs', 'manufacturing-jobs',
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