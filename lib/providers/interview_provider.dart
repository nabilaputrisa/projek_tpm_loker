import 'dart:async';
import 'package:flutter/material.dart';
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

  // Timer untuk auto-refresh status upcoming/past tiap menit
  Timer? _refreshTimer;

  List<InterviewModel> get interviews => _interviews;
  InterviewState get state => _state;
  String? get errorMessage => _errorMessage;

  List<InterviewModel> get upcomingInterviews =>
      _interviews.where((i) => i.isUpcoming).toList();

  List<InterviewModel> get pastInterviews =>
      _interviews.where((i) => !i.isUpcoming).toList();

  // Panggil ini saat provider pertama kali dipakai (di initState atau ProxyProvider)
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    // Cek tiap 1 menit — kalau ada interview yang baru lewat, UI langsung update
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_state == InterviewState.loaded) {
        // Tidak perlu hit DB lagi; cukup notifyListeners supaya getter
        // upcomingInterviews / pastInterviews dihitung ulang berdasarkan waktu sekarang
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadInterviews() async {
    _state = InterviewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await _db.getAllInterviews();
      _interviews = raw.map((m) => InterviewModel.fromMap(m)).toList();
      _state = InterviewState.loaded;

      // Pastikan timer jalan setelah data pertama kali dimuat
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
    try {
      final id = await _db.addInterview(
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
      );

      final newInterview = InterviewModel(
        id: id,
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
        createdAt: DateTime.now(),
      );

      _interviews.add(newInterview);
      _interviews.sort(
          (a, b) => a.interviewDateTime.compareTo(b.interviewDateTime));

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
    try {
      await _db.updateInterview(
        id: id,
        jobTitle: jobTitle,
        companyName: companyName,
        notes: notes,
        interviewDateTime: interviewDateTime,
      );

      final index = _interviews.indexWhere((i) => i.id == id);
      if (index != -1) {
        _interviews[index] = _interviews[index].copyWith(
          jobTitle: jobTitle,
          companyName: companyName,
          notes: notes,
          interviewDateTime: interviewDateTime,
        );
        _interviews.sort(
            (a, b) => a.interviewDateTime.compareTo(b.interviewDateTime));
      }

      // Cancel notif lama (3 ID) lalu jadwalkan ulang
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
    try {
      await _db.deleteInterview(id);
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
}