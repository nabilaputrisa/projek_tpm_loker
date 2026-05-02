import 'package:flutter/material.dart';
import '../data/models/job_model.dart';
import '../data/services/api_job_service.dart'; // Class SalaryRange diambil dari sini
import '../data/database/database_helper.dart';

class JobProvider with ChangeNotifier {
  final ApiJobService _apiService = ApiJobService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // State
  List<JobModel> _jobs = [];
  List<JobModel> _wishlist = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalJobs = 0;

  // Filter & Search
  String _searchQuery = '';
  String _selectedLocation = 'Semua Lokasi';
  String _selectedCategory = 'Semua Kategori';
  String _sortBy = 'date';
  
  // Field Baru
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

  /// Fetch jobs dari API
  Future<void> fetchJobs({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _jobs.clear();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.fetchJobs(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        location: _selectedLocation == 'Semua Lokasi' ? null : _selectedLocation,
        category: _selectedCategory == 'Semua Kategori' ? null : _selectedCategory,
        page: _currentPage,
        sortBy: _sortBy,
        countryCode: _selectedCountry, // Menggunakan parameter countryCode agar sinkron dengan ApiJobService
        salaryMin: _selectedSalaryRange?.min,
        salaryMax: _selectedSalaryRange?.max, country: '',
      );

      if (result['success'] == true) {
        if (refresh) {
          _jobs = result['jobs'];
        } else {
          _jobs.addAll(result['jobs']);
        }
        
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

  /// Load more jobs (pagination)
  Future<void> loadMore() async {
    if (!_isLoading && hasMore) {
      _currentPage++;
      await fetchJobs();
    }
  }

  // ========== SETTERS ==========

  void setCountry(String code) {
    _selectedCountry = code;
    notifyListeners();
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
    notifyListeners();
  }

  // ========== WISHLIST FUNCTIONS ==========

  Future<void> loadWishlist() async {
    try {
      final data = await _dbHelper.getWishlist();
      _wishlist = data.map((json) {
        return JobModel(
          id: json['id'],
          title: json['title'],
          company: json['company'],
          location: json['location'],
          description: '',
          createdAt: DateTime.now(),
          redirectUrl: '',
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    }
  }

  bool isInWishlist(String jobId) {
    return _wishlist.any((job) => job.id == jobId);
  }

  Future<void> toggleWishlist(JobModel job) async {
    try {
      if (isInWishlist(job.id)) {
        await _dbHelper.removeFromWishlist(job.id);
        _wishlist.removeWhere((j) => j.id == job.id);
      } else {
        await _dbHelper.addToWishlist(job.toMap());
        _wishlist.add(job);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
    }
  }

  Future<void> clearWishlist() async {
    for (var job in _wishlist) {
      await _dbHelper.removeFromWishlist(job.id);
    }
    _wishlist.clear();
    notifyListeners();
  }
}