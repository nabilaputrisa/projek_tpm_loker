// lib/views/profile/applied_job_detail_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';


class AppliedJobDetailPage extends StatefulWidget {
  final Map<String, dynamic> appliedJob;

  const AppliedJobDetailPage({
    super.key,
    required this.appliedJob,
  });

  @override
  State<AppliedJobDetailPage> createState() => _AppliedJobDetailPageState();
}

class _AppliedJobDetailPageState extends State<AppliedJobDetailPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final job = widget.appliedJob;
    final status = job['status'] ?? 'Applied';
    final statusColor = _getStatusColor(status, cs);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Lamaran',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Job Info Card
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.work,
                            color: cs.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['job_title'] ?? 'Unknown Job',
                                style: TextStyle(
                                  color: cs.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job['company'] ?? 'Unknown Company',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Lokasi',
                          value: job['location'] ?? 'Tidak disebutkan',
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.attach_money,
                          label: 'Estimasi Gaji',
                          value: job['salary'] ?? 'Tidak disebutkan',
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Tanggal Melamar',
                          value: _formatDate(job['applied_date']),
                          cs: cs,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.numbers,
                          label: 'ID Lamaran',
                          value: '#${job['job_id'] ?? job['id']}',
                          cs: cs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: cs.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Perusahaan akan menghubungi Anda melalui email atau telepon jika Anda lolos seleksi.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme cs,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (status) {
      case 'Applied':
        return cs.secondary;
      case 'Reviewed':
        return Colors.orange;
      case 'Interview':
        return cs.primary;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return cs.error;
      default:
        return cs.onSurfaceVariant;
    }
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
        return Icons.info_outline;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Applied':
        return 'Lamaran Anda telah terkirim dan sedang dalam proses review';
      case 'Reviewed':
        return 'Lamaran Anda sedang direview oleh tim HRD';
      case 'Interview':
        return 'Selamat! Anda lolos ke tahap interview. Cek email untuk informasi jadwal.';
      case 'Accepted':
        return 'Selamat! Anda diterima. Cek email untuk informasi selanjutnya.';
      case 'Rejected':
        return 'Mohon maaf, lamaran Anda belum berhasil. Tetap semangat mencoba yang lain!';
      default:
        return 'Lamaran sedang diproses';
    }
  }

  void _showDeleteConfirmation() {
    final cs = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Lamaran',
          style: TextStyle(color: cs.onSurface),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus lamaran ini dari riwayat?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => _deleteAppliedJob(ctx),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppliedJob(BuildContext ctx) async {
    final cs = Theme.of(context).colorScheme;
    setState(() => _isDeleting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('logged_username');
      
      if (username != null) {
        await _dbHelper.removeAppliedJob(username, widget.appliedJob['job_id'] ?? widget.appliedJob['id']);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lamaran berhasil dihapus'),
              backgroundColor: cs.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context); // Tutup dialog
          Navigator.pop(context); // Kembali ke halaman riwayat
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: cs.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }
}