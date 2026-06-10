import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/job_model.dart';
import '../data/services/api_job_service.dart';
import '../data/database/database_helper.dart';

// ─── MODEL SALARY RANGE ───────────────────────────────────────────────────────
class SalaryRange {
  final double min;
  final double? max;
  final String label;

  SalaryRange({
    required this.min,
    this.max,
    required this.label,
  });
}

// ─── JOB PROVIDER ────────────────────────────────────────────────────────────
class JobProvider with ChangeNotifier {
  final ApiJobService _apiService = ApiJobService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<JobModel> _jobs = [];
  List<JobModel> _wishlist = [];
  List<JobModel> _allJobs = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalJobs = 0;

  String _searchQuery = '';
  String _selectedLocation = 'Semua Lokasi';
  String _selectedCategory = 'Semua Kategori';
  String _sortBy = 'date';
  String _selectedCountry = 'sg';
  SalaryRange? _selectedSalaryRange;

  // Getters
  List<JobModel> get jobs => _jobs;
  List<JobModel> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalJobs => _totalJobs;
  bool get hasMore => _currentPage < _totalPages;

  String get searchQuery => _searchQuery;
  String get selectedLocation => _selectedLocation;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  String get selectedCountry => _selectedCountry;
  SalaryRange? get selectedSalaryRange => _selectedSalaryRange;

  // ============================================
  // JOBS API
  // ============================================

  Future<void> fetchJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _jobs.clear();
      _allJobs.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      double? filterMin = _selectedSalaryRange?.min;
      double? filterMax = _selectedSalaryRange?.max;

      final result = await _apiService.fetchJobs(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        location: _selectedLocation == 'Semua Lokasi' ? null : _selectedLocation,
        category: _selectedCategory == 'Semua Kategori' ? null : _selectedCategory,
        page: _currentPage,
        sortBy: _sortBy,
        countryCode: _selectedCountry,
        salaryMin: (filterMin != null && filterMin > 0) ? filterMin : null,
        salaryMax: filterMax,
        country: '',
      );

      if (result['success'] == true) {
        List<JobModel> fetchedJobs = result['jobs'];
        
        if (refresh) {
          _allJobs = fetchedJobs;
        } else {
          _allJobs.addAll(fetchedJobs);
        }
        
        _applySalaryFilter();
        _totalJobs = result['total'];
        _totalPages = result['totalPages'];
        _errorMessage = null;
      } else {
        _errorMessage = result['error'];
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _applySalaryFilter() {
    if (_selectedSalaryRange == null) {
      _jobs = List.from(_allJobs);
      return;
    }

    final filterMin = _selectedSalaryRange!.min;
    final filterMax = _selectedSalaryRange!.max;

    _jobs = _allJobs.where((job) {
      if (job.salaryMin == null && job.salaryMax == null) {
        return false;
      }

      final jobMin = job.salaryMin ?? 0;
      final jobMax = job.salaryMax ?? jobMin;

      if (filterMin > 0 && jobMax < filterMin) {
        return false;
      }
      if (filterMax != null && jobMin > filterMax) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadMore() async {
    if (!_isLoading && hasMore) {
      _currentPage++;
      await fetchJobs();
    }
  }

  void setCountry(String code) {
    if (_selectedCountry != code) {
      _selectedCountry = code;
      _selectedLocation = 'Semua Lokasi';
      _selectedSalaryRange = null;
      notifyListeners();
    }
  }

  void setSalaryRange(SalaryRange? range) {
    _selectedSalaryRange = range;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  Future<void> applyFilters() async {
    await fetchJobs(refresh: true);
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedLocation = 'Semua Lokasi';
    _selectedCategory = 'Semua Kategori';
    _sortBy = 'date';
    _selectedCountry = 'sg';
    _selectedSalaryRange = null;
    _jobs.clear();
    _allJobs.clear();
    notifyListeners();
  }

  // ============================================
  // WISHLIST METHODS (DENGAN user_id)
  // ============================================

  Future<String?> _getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('logged_username');
  }

  Future<void> loadWishlist() async {
    final username = await _getCurrentUsername();
    if (username == null) return;
    
    try {
      final rows = await _dbHelper.getWishlist(username);
      _wishlist = rows.map((row) => JobModel(
        id: row['job_id'] as String,
        title: row['title'] as String,
        company: (row['company'] as String?) ?? '',
        location: (row['location'] as String?) ?? '',
        description: '',
        createdAt: DateTime.now(),
        redirectUrl: '',
        salaryDisplay: (row['salary'] as String?) ?? 'Gaji tidak tersedia',
        category: row['category'] as String?,
        contractType: row['contract_type'] as String?,
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  Future<void> toggleWishlist(JobModel job) async {
    final username = await _getCurrentUsername();
    if (username == null) return;
    
    try {
      if (isInWishlist(job.id)) {
        await _dbHelper.removeFromWishlist(username, job.id);
        _wishlist.removeWhere((j) => j.id == job.id);
      } else {
        await _dbHelper.addToWishlist(username, {
          'job_id': job.id,
          'title': job.title,
          'company': job.company,
          'location': job.location,
          'salary': job.salaryDisplay,
          'category': job.category,
          'contract_type': job.contractType,
        });
        _wishlist.add(job);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    }
  }

  Future<void> clearWishlist() async {
    final username = await _getCurrentUsername();
    if (username == null) return;
    
    try {
      await _dbHelper.clearWishlist(username);
      _wishlist.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing wishlist: $e');
    }
  }

  bool isInWishlist(String jobId) {
    return _wishlist.any((job) => job.id == jobId);
  }
}