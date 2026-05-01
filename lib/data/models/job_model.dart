class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String? salaryMin;
  final String? salaryMax;
  final String? contractType;
  final String? category;
  final DateTime createdAt;
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
    this.contractType,
    this.category,
    required this.createdAt,
    required this.redirectUrl,
    this.latitude,
    this.longitude,
  });

  // Parse dari JSON Adzuna API
  factory JobModel.fromJson(Map<String, dynamic> json) {
    // Format salary
    String? salaryMin;
    String? salaryMax;
    
    if (json['salary_min'] != null) {
      salaryMin = 'Rp ${_formatNumber(json['salary_min'])}';
    }
    if (json['salary_max'] != null) {
      salaryMax = 'Rp ${_formatNumber(json['salary_max'])}';
    }

    return JobModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      company: json['company']['display_name'] ?? 'Unknown Company',
      location: json['location']['display_name'] ?? 'Unknown Location',
      description: json['description'] ?? '',
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      contractType: json['contract_type'],
      category: json['category']['label'],
      createdAt: DateTime.parse(json['created']),
      redirectUrl: json['redirect_url'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  // Format number dengan separator
  static String _formatNumber(dynamic number) {
    if (number == null) return '0';
    int value = number is int ? number : (number as double).toInt();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Getter untuk salary display
  String get salaryDisplay {
    if (salaryMin != null && salaryMax != null) {
      return '$salaryMin - $salaryMax per bulan';
    } else if (salaryMin != null) {
      return 'Mulai dari $salaryMin per bulan';
    } else if (salaryMax != null) {
      return 'Hingga $salaryMax per bulan';
    } else {
      return 'Gaji negotiable';
    }
  }

  // Getter untuk waktu posting
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan yang lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Convert to Map untuk simpan ke database wishlist
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'salary': salaryDisplay,
    };
  }
}