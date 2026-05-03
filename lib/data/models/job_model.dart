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

  // ─── Factory: Parse dari JSON Adzuna API ───────────────────────────────────
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

  // ─── Getter: Currency Code ─────────────────────────────────────────────────
  // Deteksi dari currencySymbol dulu (paling akurat karena dari API),
  // lalu fallback ke deteksi lokasi, lalu fallback ke USD.
  String get currencyCode {
    // 1. Deteksi dari currencySymbol yang sudah ada
    final fromSymbol = _currencyCodeFromSymbol(currencySymbol);
    if (fromSymbol != null) return fromSymbol;

    // 2. Fallback: deteksi dari string lokasi
    final fromLocation = _currencyCodeFromLocation(location);
    if (fromLocation != null) return fromLocation;

    // 3. Fallback terakhir
    return 'USD';
  }

  /// Map symbol → currency code
  String? _currencyCodeFromSymbol(String symbol) {
    const map = {
      '£': 'GBP',
      '€': 'EUR',
      '¥': 'JPY',
      '₹': 'INR',
      'A\$': 'AUD',
      'C\$': 'CAD',
      'S\$': 'SGD',
      'HK\$': 'HKD',
      'NZ\$': 'NZD',
      'RM': 'MYR',
      '฿': 'THB',
      '₩': 'KRW',
      '₫': 'VND',
      '₱': 'PHP',
      'Rp': 'IDR',
      'R': 'ZAR',
      'R\$': 'BRL',
      'Fr': 'CHF',
      'kr': 'SEK',
      'zł': 'PLN',
      '₺': 'TRY',
      '₽': 'RUB',
      '﷼': 'SAR',
      'د.إ': 'AED',
      'ر.ق': 'QAR',
      'د.ك': 'KWD',
      '.د.ب': 'BHD',
      'ر.ع.': 'OMR',
      'د.أ': 'JOD',
      '₪': 'ILS',
      'Kč': 'CZK',
      'Ft': 'HUF',
      '\$': 'USD', // paling akhir karena paling umum/ambigu
    };
    return map[symbol];
  }

  /// Deteksi currency dari string lokasi (keyword matching)
  String? _currencyCodeFromLocation(String location) {
    final loc = location.toLowerCase();

    // Sort keyword terpanjang dulu supaya "hong kong" tidak match "kong"
    final sorted = _locationCurrencyMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sorted) {
      if (loc.contains(keyword)) {
        return _locationCurrencyMap[keyword];
      }
    }
    return null;
  }

  /// Keyword lokasi → currency code
  static const Map<String, String> _locationCurrencyMap = {
    // ── Indonesia ──────────────────────────────────────────────────────
    'indonesia': 'IDR', 'jakarta': 'IDR', 'surabaya': 'IDR',
    'bandung': 'IDR', 'bali': 'IDR', 'yogyakarta': 'IDR',
    'medan': 'IDR', 'semarang': 'IDR', 'makassar': 'IDR',
    'palembang': 'IDR', 'depok': 'IDR', 'tangerang': 'IDR',
    'bekasi': 'IDR', 'bogor': 'IDR',

    // ── UK ────────────────────────────────────────────────────────────
    'london': 'GBP', 'uk': 'GBP', 'england': 'GBP',
    'manchester': 'GBP', 'birmingham': 'GBP', 'edinburgh': 'GBP',
    'glasgow': 'GBP', 'liverpool': 'GBP', 'leeds': 'GBP',
    'bristol': 'GBP', 'sheffield': 'GBP', 'cambridge': 'GBP',
    'oxford': 'GBP', 'united kingdom': 'GBP', 'britain': 'GBP',

    // ── Eropa (EUR) ───────────────────────────────────────────────────
    'germany': 'EUR', 'berlin': 'EUR', 'munich': 'EUR',
    'frankfurt': 'EUR', 'hamburg': 'EUR', 'cologne': 'EUR',
    'düsseldorf': 'EUR', 'dusseldorf': 'EUR', 'stuttgart': 'EUR',
    'france': 'EUR', 'paris': 'EUR', 'lyon': 'EUR', 'marseille': 'EUR',
    'netherlands': 'EUR', 'amsterdam': 'EUR', 'rotterdam': 'EUR',
    'spain': 'EUR', 'madrid': 'EUR', 'barcelona': 'EUR',
    'italy': 'EUR', 'rome': 'EUR', 'milan': 'EUR',
    'portugal': 'EUR', 'lisbon': 'EUR', 'porto': 'EUR',
    'belgium': 'EUR', 'brussels': 'EUR',
    'austria': 'EUR', 'vienna': 'EUR',
    'finland': 'EUR', 'helsinki': 'EUR',
    'ireland': 'EUR', 'dublin': 'EUR',
    'greece': 'EUR', 'athens': 'EUR',
    'luxembourg': 'EUR',

    // ── Swiss ─────────────────────────────────────────────────────────
    'switzerland': 'CHF', 'zurich': 'CHF', 'geneva': 'CHF', 'bern': 'CHF',

    // ── Nordik (non-EUR) ──────────────────────────────────────────────
    'sweden': 'SEK', 'stockholm': 'SEK', 'gothenburg': 'SEK',
    'norway': 'NOK', 'oslo': 'NOK',
    'denmark': 'DKK', 'copenhagen': 'DKK',

    // ── Eropa Timur ───────────────────────────────────────────────────
    'poland': 'PLN', 'warsaw': 'PLN', 'krakow': 'PLN',
    'czech': 'CZK', 'prague': 'CZK',
    'hungary': 'HUF', 'budapest': 'HUF',
    'russia': 'RUB', 'moscow': 'RUB', 'saint petersburg': 'RUB',
    'turkey': 'TRY', 'istanbul': 'TRY', 'ankara': 'TRY',

    // ── Amerika Serikat ───────────────────────────────────────────────
    'united states': 'USD', 'usa': 'USD', 'new york': 'USD',
    'san francisco': 'USD', 'los angeles': 'USD', 'chicago': 'USD',
    'seattle': 'USD', 'boston': 'USD', 'austin': 'USD',
    'dallas': 'USD', 'houston': 'USD', 'miami': 'USD',
    'denver': 'USD', 'atlanta': 'USD', 'washington': 'USD',

    // ── Kanada ────────────────────────────────────────────────────────
    'canada': 'CAD', 'toronto': 'CAD', 'vancouver': 'CAD',
    'montreal': 'CAD', 'calgary': 'CAD', 'ottawa': 'CAD',

    // ── Australia ─────────────────────────────────────────────────────
    'australia': 'AUD', 'sydney': 'AUD', 'melbourne': 'AUD',
    'brisbane': 'AUD', 'perth': 'AUD', 'adelaide': 'AUD',

    // ── Selandia Baru ─────────────────────────────────────────────────
    'new zealand': 'NZD', 'auckland': 'NZD', 'wellington': 'NZD',

    // ── Asia Tenggara ─────────────────────────────────────────────────
    'singapore': 'SGD',
    'malaysia': 'MYR', 'kuala lumpur': 'MYR', 'penang': 'MYR',
    'thailand': 'THB', 'bangkok': 'THB', 'chiang mai': 'THB',
    'vietnam': 'VND', 'hanoi': 'VND', 'ho chi minh': 'VND',
    'philippines': 'PHP', 'manila': 'PHP', 'cebu': 'PHP',
    'myanmar': 'MMK', 'yangon': 'MMK',
    'cambodia': 'KHR', 'phnom penh': 'KHR',

    // ── Asia Selatan ──────────────────────────────────────────────────
    'india': 'INR', 'mumbai': 'INR', 'delhi': 'INR',
    'bangalore': 'INR', 'bengaluru': 'INR', 'hyderabad': 'INR',
    'chennai': 'INR', 'pune': 'INR', 'kolkata': 'INR',
    'ahmedabad': 'INR', 'noida': 'INR', 'gurgaon': 'INR',
    'pakistan': 'PKR', 'karachi': 'PKR', 'lahore': 'PKR',
    'bangladesh': 'BDT', 'dhaka': 'BDT',
    'sri lanka': 'LKR', 'colombo': 'LKR',
    'nepal': 'NPR', 'kathmandu': 'NPR',

    // ── Asia Timur ────────────────────────────────────────────────────
    'china': 'CNY', 'beijing': 'CNY', 'shanghai': 'CNY',
    'shenzhen': 'CNY', 'guangzhou': 'CNY', 'chengdu': 'CNY',
    'japan': 'JPY', 'tokyo': 'JPY', 'osaka': 'JPY', 'kyoto': 'JPY',
    'korea': 'KRW', 'seoul': 'KRW', 'busan': 'KRW',
    'hong kong': 'HKD', 'hongkong': 'HKD',
    'taiwan': 'TWD', 'taipei': 'TWD',

    // ── Timur Tengah ──────────────────────────────────────────────────
    'saudi': 'SAR', 'riyadh': 'SAR', 'jeddah': 'SAR',
    'uae': 'AED', 'dubai': 'AED', 'abu dhabi': 'AED',
    'qatar': 'QAR', 'doha': 'QAR',
    'kuwait': 'KWD',
    'bahrain': 'BHD', 'manama': 'BHD',
    'oman': 'OMR', 'muscat': 'OMR',
    'jordan': 'JOD', 'amman': 'JOD',
    'israel': 'ILS', 'tel aviv': 'ILS',
    'egypt': 'EGP', 'cairo': 'EGP',

    // ── Afrika ────────────────────────────────────────────────────────
    'south africa': 'ZAR', 'johannesburg': 'ZAR', 'cape town': 'ZAR',
    'nigeria': 'NGN', 'lagos': 'NGN', 'abuja': 'NGN',
    'kenya': 'KES', 'nairobi': 'KES',

    // ── Amerika Latin ─────────────────────────────────────────────────
    'brazil': 'BRL', 'sao paulo': 'BRL', 'rio de janeiro': 'BRL',
    'mexico': 'MXN', 'mexico city': 'MXN',
  };

  // ─── Format angka dengan currency symbol ──────────────────────────────────
  String _formatSalary(double value) {
    if (currencySymbol == '₹' && value >= 100000) {
      final lakh = value / 100000;
      return '$currencySymbol${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 1)}L';
    }
    final formatter = NumberFormat('#,##0', 'en_US');
    return '$currencySymbol${formatter.format(value.toInt())}';
  }

  // ─── Getter: Salary display ────────────────────────────────────────────────
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

  // ─── Getter: Apakah salary tersedia ───────────────────────────────────────
  bool get hasSalary => salaryMin != null || salaryMax != null;

  // ─── Getter: Time ago ─────────────────────────────────────────────────────
  String get timeAgo {
    if (createdAt == null) return 'Unknown date';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} month(s) ago';
    if (diff.inDays > 0) return '${diff.inDays} day(s) ago';
    if (diff.inHours > 0) return '${diff.inHours} hour(s) ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute(s) ago';
    return 'Just now';
  }

  // ─── Getter: Contract type display ────────────────────────────────────────
  String get contractTypeDisplay {
    if (contractType == null || contractType!.isEmpty) return 'Not specified';
    return contractType!
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // ─── toMap ────────────────────────────────────────────────────────────────
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

  // ─── fromMap ──────────────────────────────────────────────────────────────
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

  // ─── copyWith ─────────────────────────────────────────────────────────────
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