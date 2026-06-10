import 'package:intl/intl.dart';

class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final double? salaryMin;
  final double? salaryMax;
  final String currencySymbol;
  final String? contractType;
  final String? category;
  final DateTime? createdAt;
  final String redirectUrl;
  final double? latitude;
  final double? longitude;

  JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    this.salaryMin,
    this.salaryMax,
    this.currencySymbol = '\$',
    this.contractType,
    this.category,
    this.createdAt,
    required this.redirectUrl,
    this.latitude,
    this.longitude,
    required String salaryDisplay,
  });

// fromJson (dari API Adzuna) 
  factory JobModel.fromJson(
    Map<String, dynamic> json, {
    String? currencySymbol,
  }) {
    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      company: json['company']?['display_name'] ?? 'Unknown Company',
      location: json['location']?['display_name'] ?? 'Unknown Location',
      description: json['description'] ?? '',
      salaryMin: (json['salary_min'] as num?)?.toDouble(),
      salaryMax: (json['salary_max'] as num?)?.toDouble(),
      currencySymbol: currencySymbol ?? '\$',
      contractType: json['contract_type'],
      category: json['category']?['label'],
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'])
          : null,
      redirectUrl: json['redirect_url'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      salaryDisplay: '',
    );
  }

// Getter: Currency code deteksi dari symbol atau lokasi
  String get currencyCode {
    final fromSymbol = _currencyCodeFromSymbol(currencySymbol);
    if (fromSymbol != null) return fromSymbol;

    final fromLocation = _currencyCodeFromLocation(location);
    if (fromLocation != null) return fromLocation;

    return 'USD';
  }

// Deteksi currency code dari symbol (hanya beberapa simbol umum)
  String? _currencyCodeFromSymbol(String symbol) {
    const map = {
      'S\$': 'SGD', // Singapore
      '₹':   'INR', // India
      '£':   'GBP', // UK
      'A\$': 'AUD', // Australia
      'C\$': 'CAD', // Canada
      '€':   'EUR', // Germany
      '\$':  'USD', // US 
    };
    return map[symbol];
  }

  /// Deteksi currency dari string lokasi (hanya lokasi dari 7 negara Adzuna)
  String? _currencyCodeFromLocation(String location) {
    final loc = location.toLowerCase();
    final sorted = _locationCurrencyMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final keyword in sorted) {
      if (loc.contains(keyword)) return _locationCurrencyMap[keyword];
    }
    return null;
  }

// Map lokasi ke currency code untuk deteksi berdasarkan lokasi
  static const Map<String, String> _locationCurrencyMap = {
    // Singapore
    'singapore': 'SGD',
    'central region': 'SGD', 'east region': 'SGD',
    'north region': 'SGD', 'north-east region': 'SGD', 'west region': 'SGD',

    // India
    'india': 'INR', 'bangalore': 'INR', 'bengaluru': 'INR',
    'mumbai': 'INR', 'delhi': 'INR', 'hyderabad': 'INR',
    'chennai': 'INR', 'pune': 'INR', 'kolkata': 'INR',
    'ahmedabad': 'INR', 'noida': 'INR', 'gurgaon': 'INR',

    // United Kingdom
    'united kingdom': 'GBP', 'uk': 'GBP', 'london': 'GBP',
    'manchester': 'GBP', 'birmingham': 'GBP', 'leeds': 'GBP',
    'glasgow': 'GBP', 'bristol': 'GBP', 'edinburgh': 'GBP',
    'sheffield': 'GBP', 'liverpool': 'GBP', 'nottingham': 'GBP',

    // Australia
    'australia': 'AUD', 'sydney': 'AUD', 'melbourne': 'AUD',
    'brisbane': 'AUD', 'perth': 'AUD', 'adelaide': 'AUD',
    'gold coast': 'AUD', 'canberra': 'AUD', 'darwin': 'AUD', 'hobart': 'AUD',

    // United States
    'united states': 'USD', 'usa': 'USD', 'new york': 'USD',
    'los angeles': 'USD', 'chicago': 'USD', 'houston': 'USD',
    'san francisco': 'USD', 'seattle': 'USD', 'austin': 'USD',
    'boston': 'USD', 'miami': 'USD', 'denver': 'USD',

    // Canada
    'canada': 'CAD', 'toronto': 'CAD', 'vancouver': 'CAD',
    'montreal': 'CAD', 'calgary': 'CAD', 'ottawa': 'CAD',
    'edmonton': 'CAD', 'winnipeg': 'CAD', 'quebec': 'CAD',

    // Germany
    'germany': 'EUR', 'berlin': 'EUR', 'munich': 'EUR',
    'hamburg': 'EUR', 'frankfurt': 'EUR', 'cologne': 'EUR',
    'stuttgart': 'EUR', 'düsseldorf': 'EUR', 'dusseldorf': 'EUR',
    'leipzig': 'EUR',
  };

  // Format angka dengan currency symbol 
  String _formatSalary(double value) {
    if (currencySymbol == '₹' && value >= 100000) {
      final lakh = value / 100000;
      return '$currencySymbol${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 1)}L';
    }
    final formatter = NumberFormat('#,##0', 'en_US');
    return '$currencySymbol${formatter.format(value.toInt())}';
  }

  // Getter: Salary display 
  String get salaryDisplay {
    if (salaryMin != null && salaryMax != null) {
      return '${_formatSalary(salaryMin!)} – ${_formatSalary(salaryMax!)} / year';
    } else if (salaryMin != null) {
      return '${_formatSalary(salaryMin!)}+ / year';
    } else if (salaryMax != null) {
      return 'Up to ${_formatSalary(salaryMax!)} / year';
    }
    return 'Salary not specified';
  }

  // Getter: Apakah salary tersedia 
  bool get hasSalary => salaryMin != null || salaryMax != null;

  // Getter: Time ago 
  String get timeAgo {
    if (createdAt == null) return 'Unknown date';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }

  // Getter: Contract type display 
  String get contractTypeDisplay {
    if (contractType == null || contractType!.isEmpty) return 'Not specified';
    return contractType!
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // toMap 
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'currency_symbol': currencySymbol,
      'contract_type': contractType,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
      'redirect_url': redirectUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // fromMap
  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      company: map['company'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      salaryMin: (map['salary_min'] as num?)?.toDouble(),
      salaryMax: (map['salary_max'] as num?)?.toDouble(),
      currencySymbol: map['currency_symbol'] ?? '\$',
      contractType: map['contract_type'],
      category: map['category'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      redirectUrl: map['redirect_url'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      salaryDisplay: '',
    );
  }

  // copyWith 
  JobModel copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? description,
    double? salaryMin,
    double? salaryMax,
    String? currencySymbol,
    String? contractType,
    String? category,
    DateTime? createdAt,
    String? redirectUrl,
    double? latitude,
    double? longitude,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      description: description ?? this.description,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      contractType: contractType ?? this.contractType,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      salaryDisplay: '',
    );
  }

  @override
  String toString() => 'JobModel(id: $id, title: $title, company: $company)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is JobModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}