// lib/views/profile/applied_jobs_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import 'applied_job_detail_page.dart';

class AppliedJobsPage extends StatefulWidget {
  const AppliedJobsPage({super.key});

  @override
  State<AppliedJobsPage> createState() => _AppliedJobsPageState();
}

class _AppliedJobsPageState extends State<AppliedJobsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String? _username;
  List<Map<String, dynamic>> _appliedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppliedJobs();
  }

  Future<void> _loadAppliedJobs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('logged_username');

    if (_username != null) {
      final jobs = await _dbHelper.getAppliedJobs(_username!);
      setState(() {
        _appliedJobs = jobs;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatTime(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Applied':
        return const Color(0xFF00D4AA);
      case 'Reviewed':
        return Colors.orange;
      case 'Interview':
        return const Color(0xFF6C63FF);
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Lamaran',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : _appliedJobs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off_outlined,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada lamaran pekerjaan',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Yuk cari pekerjaan impianmu!',
                        style: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppliedJobs,
                  color: const Color(0xFF6C63FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _appliedJobs.length,
                    itemBuilder: (context, index) {
                      final job = _appliedJobs[index];
                      final status = job['status'] ?? 'Applied';
                      final statusColor = _getStatusColor(status);
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppliedJobDetailPage(
                                appliedJob: job,
                              ),
                            ),
                          ).then((_) => _loadAppliedJobs()); // Refresh setelah kembali
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getStatusIcon(status),
                                      color: statusColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job['job_title'] ?? 'Unknown Job',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          job['company'] ?? 'Unknown Company',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today,
                                                size: 10,
                                                color: Colors.white.withOpacity(0.4)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(job['applied_date'] ?? ''),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(Icons.access_time,
                                                size: 10,
                                                color: Colors.white.withOpacity(0.4)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTime(job['applied_date'] ?? ''),
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: statusColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Lokasi (jika ada)
                              if (job['location'] != null && job['location'].toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 12,
                                          color: Colors.white.withOpacity(0.4)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          job['location'],
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Arrow indicator
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Lihat detail',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: statusColor,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Applied':
        return Icons.send;
      case 'Reviewed':
        return Icons.visibility;
      case 'Interview':
        return Icons.people;
      case 'Accepted':
        return Icons.celebration;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.work;
    }
  }
}