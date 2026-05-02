// lib/views/home/job_detail_page.dart
//
// Halaman detail lowongan kerja.
// Sheet konversi dipindah ke: lib/widgets/conversion_popup.dart

import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';
import '../../data/models/job_model.dart';
import '../../widgets/conversion_popup.dart'; // ← sheet konversi
import '../../widgets/map_preview_widget.dart';

class JobDetailPage extends StatelessWidget {
  final JobModel job;

  const JobDetailPage({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyCard(),
                  const SizedBox(height: 16),
                  _buildInfoGrid(),
                  const SizedBox(height: 16),
                  _buildSalaryCard(context),
                  const SizedBox(height: 16),
                  _buildDescriptionCard(),
                  const SizedBox(height: 16),
                  _buildLocationCard(),
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
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF1A3C5E),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A3C5E), Color(0xFF2D6A9F)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF7EC8F5), size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: const TextStyle(
                          color: Color(0xFF7EC8F5), fontSize: 13),
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
  Widget _buildCompanyCard() {
    return _Card(
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.business_rounded,
              color: Color(0xFF2D6A9F), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.company,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3C5E)),
              ),
              const SizedBox(height: 4),
              if (job.category != null)
                Text(job.category!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7A8D))),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Info Grid ──────────────────────────────────────────────────────────────
  Widget _buildInfoGrid() {
    return Row(children: [
      Expanded(
        child: _InfoTile(
          icon: Icons.work_outline_rounded,
          label: "Tipe Kontrak",
          value: job.contractTypeDisplay,
          color: const Color(0xFF2D6A9F),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _InfoTile(
          icon: Icons.schedule_rounded,
          label: "Diposting",
          value: job.timeAgo,
          color: const Color(0xFF2D9F6A),
        ),
      ),
    ]);
  }

  // ── Salary Card ────────────────────────────────────────────────────────────
  Widget _buildSalaryCard(BuildContext context) {
    return _Card(
      child: Column(children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFFE67E22), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Estimasi Gaji",
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B7A8D))),
                const SizedBox(height: 4),
                Text(
                  job.salaryDisplay,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C5E)),
                ),
              ],
            ),
          ),
          if (job.hasSalary)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("Per tahun",
                  style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2D9F6A),
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
              color: const Color(0xFF2D6A9F),
              onTap: () => _showCurrencySheet(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OutlineButton(
              icon: Icons.access_time_rounded,
              label: "Konversi Waktu",
              color: const Color(0xFF7B3DD1),
              onTap: () => _showTimezoneSheet(context),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Description Card ───────────────────────────────────────────────────────
  Widget _buildDescriptionCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(title: "Deskripsi Pekerjaan"),
          const SizedBox(height: 14),
          ReadMoreText(
            job.description,
            trimLines: 5,
            trimMode: TrimMode.Line,
            trimCollapsedText: 'Lihat Selengkapnya',
            trimExpandedText: ' Sembunyikan',
            moreStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6A9F)),
            lessStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D6A9F)),
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.7,
                letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(children: [
              const _SectionHeader(title: "Lokasi Kantor"),
              const Spacer(),
              Text(job.location,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7A8D)),
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
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A3C5E), Color(0xFF2D6A9F)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3C5E).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: const Center(
            child: Text(
              "LAMAR SEKARANG",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.2),
            ),
          ),
        ),
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
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B7A8D))),
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
    return Row(children: [
      Container(
        width: 4, height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A9F),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A3C5E)),
      ),
    ]);
  }
}