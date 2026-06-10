import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/database_helper.dart';
import '../data/models/interview_model.dart';
import '../data/services/notification_service.dart';

enum InterviewState { initial, loading, loaded, error }

class InterviewProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  List<InterviewModel> _interviews = [];
  InterviewState _state = InterviewState.initial;
  String? _errorMessage;
  String? _currentUsername;
  Timer? _refreshTimer;

  List<InterviewModel> get interviews => _interviews;
  InterviewState get state => _state;
  String? get errorMessage => _errorMessage;

  List<InterviewModel> get upcomingInterviews =>
      _interviews.where((i) => i.isUpcoming).toList();

  List<InterviewModel> get pastInterviews =>
      _interviews.where((i) => !i.isUpcoming).toList();

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('logged_username');
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_state == InterviewState.loaded) {
        notifyListeners();
      }
    });
  }

  Future<void> loadInterviews() async {
    await _loadUsername();
    if (_currentUsername == null) return;
    
    _state = InterviewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await _db.getAllInterviews(_currentUsername!);
      _interviews = raw.map((m) => InterviewModel.fromMap(m)).toList();
      _state = InterviewState.loaded;
      startAutoRefresh();
    } catch (e) {
      _state = InterviewState.error;
      _errorMessage = 'Gagal memuat jadwal interview: $e';
    }
    notifyListeners();
  }

  Future<bool> addInterview({
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    await _loadUsername();
    if (_currentUsername == null) return false;
    
    try {
      final id = await _db.addInterview(
        username: _currentUsername!,
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
      );

      if (id == 0) return false;

      final newInterview = InterviewModel(
        id: id,
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
        createdAt: DateTime.now(),
      );

      _interviews.add(newInterview);
      _interviews.sort((a, b) => a.interviewDateTime.compareTo(b.interviewDateTime));

      await _notificationService.scheduleInterviewNotification(
        id: id,
        jobTitle: jobTitle,
        companyName: companyName,
        interviewDateTime: interviewDateTime,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah jadwal: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInterview({
    required int id,
    required String jobTitle,
    required String companyName,
    String? notes,
    required DateTime interviewDateTime,
  }) async {
    await _loadUsername();
    if (_currentUsername == null) return false;
    
    try {
      final rowsUpdated = await _db.updateInterview(
        id: id,
        username: _currentUsername!,
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
      );

      if (rowsUpdated == 0) return false;

      final index = _interviews.indexWhere((i) => i.id == id);
      if (index != -1) {
        _interviews[index] = _interviews[index].copyWith(
          jobTitle: jobTitle,
          companyName: companyName,
          notes: notes,
          interviewDateTime: interviewDateTime,
        );
        _interviews.sort((a, b) => a.interviewDateTime.compareTo(b.interviewDateTime));
      }

      await _notificationService.cancelNotification(id);
      await _notificationService.scheduleInterviewNotification(
        id: id,
        jobTitle: jobTitle,
        companyName: companyName,
        interviewDateTime: interviewDateTime,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate jadwal: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInterview(int id) async {
    await _loadUsername();
    if (_currentUsername == null) return false;
    
    try {
      final rowsDeleted = await _db.deleteInterview(id, _currentUsername!);
      if (rowsDeleted == 0) return false;
      
      _interviews.removeWhere((i) => i.id == id);
      await _notificationService.cancelNotification(id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus jadwal: $e';
      notifyListeners();
      return false;
    }
  }

  InterviewModel? getById(int id) {
    try {
      return _interviews.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearInterviews() {
    _interviews.clear();
    _currentUsername = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}