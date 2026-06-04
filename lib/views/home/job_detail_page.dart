// lib/views/home/job_detail_page.dart

import 'package:flutter/material.dart';
import 'package:projektpm/data/services/notification_service.dart';
import 'package:readmore/readmore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/job_model.dart';
import '../../widgets/currency_converter_sheet.dart';
import '../../widgets/timezone_converter_sheet.dart';
import '../../widgets/map_preview_widget.dart';
import '../../data/database/database_helper.dart';
import '../profile/edit_profile_page.dart';


class JobDetailPage extends StatelessWidget {
  final JobModel job;

  const JobDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyCard(context),
                  const SizedBox(height: 16),
                  _buildInfoGrid(context),
                  const SizedBox(height: 16),
                  _buildSalaryCard(context),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(context),
                  const SizedBox(height: 16),
                  _buildLocationCard(context),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildApplyButton(context),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: cs.primary,
      iconTheme: IconThemeData(color: cs.onPrimary),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: cs.primary, // Warna solid, tanpa gradasi
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.location_on,
                      color: cs.onPrimary.withOpacity(0.8), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: TextStyle(
                          color: cs.onPrimary.withOpacity(0.8), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Company Card ───────────────────────────────────────────────────────────
  Widget _buildCompanyCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return _Card(
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.business_rounded,
              color: cs.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.company,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              if (job.category != null)
                Text(job.category!,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Info Grid ──────────────────────────────────────────────────────────────
  Widget _buildInfoGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Row(children: [
      Expanded(
        child: _InfoTile(
          icon: Icons.work_outline_rounded,
          label: "Tipe Kontrak",
          value: job.contractTypeDisplay,
          color: cs.primary,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _InfoTile(
          icon: Icons.schedule_rounded,
          label: "Diposting",
          value: job.timeAgo,
          color: cs.secondary,
        ),
      ),
    ]);
  }

  // ── Salary Card ────────────────────────────────────────────────────────────
  Widget _buildSalaryCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return _Card(
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_rounded,
                color: cs.secondary, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Estimasi Gaji",
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(
                  job.salaryDisplay,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface),
                ),
              ],
            ),
          ),
          if (job.hasSalary)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("Per tahun",
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 14),
        // ── Dua tombol konversi ────────────────────────────────────────
        Row(children: [
          Expanded(
            child: _OutlineButton(
              icon: Icons.currency_exchange_rounded,
              label: "Konversi Mata Uang",
              color: cs.primary,
              onTap: () => _showCurrencySheet(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OutlineButton(
              icon: Icons.access_time_rounded,
              label: "Konversi Waktu",
              color: cs.secondary,
              onTap: () => _showTimezoneSheet(context),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Description Card ───────────────────────────────────────────────────────
  Widget _buildDescriptionCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: "Deskripsi Pekerjaan"),
          const SizedBox(height: 14),
          ReadMoreText(
            job.description,
            trimLines: 5,
            trimMode: TrimMode.Line,
            trimCollapsedText: 'Lihat Selengkapnya',
            trimExpandedText: ' Sembunyikan',
            moreStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary),
            lessStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary),
            style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
                height: 1.7,
                letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────────────────────
  Widget _buildLocationCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              _SectionHeader(title: "Lokasi Kantor"),
              const Spacer(),
              Text(job.location,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: MapPreviewWidget(
              lat: job.latitude ?? -6.2000,
              lng: job.longitude ?? 106.8166,
              title: job.company,
            ),
          ),
        ],
      ),
    );
  }

  // ── Apply Button ───────────────────────────────────────────────────────────
  Widget _buildApplyButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return FutureBuilder<bool>(
      future: _hasApplied(),
      builder: (context, snapshot) {
        final hasApplied = snapshot.data ?? false;
        
        return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 56,
          decoration: BoxDecoration(
            color: hasApplied ? cs.onSurfaceVariant : cs.primary, // Warna solid
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (hasApplied ? cs.onSurfaceVariant : cs.primary)
                    .withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: hasApplied
                  ? null
                  : () => _applyForJob(context),
              child: Center(
                child: Text(
                  hasApplied ? "✓ SUDAH DILAMAR" : "LAMAR SEKARANG",
                  style: TextStyle(
                      color: hasApplied ? cs.onSurface : cs.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Apply Logic ────────────────────────────────────────────────────────────
  Future<bool> _hasApplied() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('logged_username');
      if (username == null) return false;
      
      final dbHelper = DatabaseHelper();
      return await dbHelper.hasApplied(username, job.id);
    } catch (e) {
      return false;
    }
  }

  Future<void> _applyForJob(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    
    // Cek apakah user sudah login
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('logged_username');
    
    if (username == null) {
      _showSnackBar(context, 'Silakan login terlebih dahulu', isError: true);
      return;
    }

    // Cek apakah user sudah memiliki CV
    final dbHelper = DatabaseHelper();
    final userData = await dbHelper.getUserByUsername(username);
    final hasCV = userData?['cv_path'] != null && 
                  userData!['cv_path'].toString().isNotEmpty;
    
    if (!hasCV) {
      _showApplyErrorDialog(
        context,
        'CV Belum Diupload',
        'Silakan upload CV terlebih dahulu di halaman Edit Profile sebelum melamar pekerjaan.',
      );
      return;
    }

    // Cek apakah sudah pernah melamar
    final alreadyApplied = await dbHelper.hasApplied(username, job.id);
    if (alreadyApplied) {
      _showSnackBar(context, 'Anda sudah melamar pekerjaan ini sebelumnya');
      return;
    }

    // Proses lamaran
    try {
      // Konversi JobModel ke Map
      final jobMap = {
        'id': job.id,
        'title': job.title,
        'company': job.company,
        'location': job.location,
        'salary': job.salaryDisplay,
      };
      
      await dbHelper.saveAppliedJob(username, jobMap);
      
      // Kirim notifikasi menggunakan NotificationService yang sudah ada
      await NotificationService().showJobAppliedNotification(
        jobTitle: job.title,
        companyName: job.company,
      );
      
      // Tampilkan dialog sukses
      _showApplySuccessDialog(context);
      
    } catch (e) {
      debugPrint('Error applying for job: $e');
      _showSnackBar(context, 'Gagal melamar: $e', isError: true);
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showApplySuccessDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle, color: cs.primary, size: 60),
            const SizedBox(height: 16),
            Text('Lamaran Terkirim!', style: TextStyle(color: cs.onSurface)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lamaran untuk posisi "${job.title}" di ${job.company} telah berhasil dikirim.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Refresh halaman dengan push replacement
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailPage(job: job),
                ),
              );
            },
            child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
          ),
        ],
      ),
    );
  }

  void _showApplyErrorDialog(BuildContext context, String title, String message) {
    final cs = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: cs.error, size: 28),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 18, color: cs.onSurface)),
          ],
        ),
        content: Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            child: Text('Upload CV', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet triggers ──────────────────────────────────────────────────

  void _showCurrencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CurrencyConverterSheet(
        initialAmount: job.salaryMin ?? 0,
        fromCurrency: job.currencyCode,
      ),
    );
  }

  void _showTimezoneSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TimezoneConverterSheet(jobLocation: job.location),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Row(children: [
      Container(
        width: 4, height: 20,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface),
      ),
    ]);
  }
}