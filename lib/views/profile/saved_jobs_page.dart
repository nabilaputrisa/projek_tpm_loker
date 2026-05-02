import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../data/models/job_model.dart';
import '../../widgets/job_card.dart';

class SavedJobsPage extends StatefulWidget {
  const SavedJobsPage({super.key});

  @override
  State<SavedJobsPage> createState() => _SavedJobsPageState();
}

class _SavedJobsPageState extends State<SavedJobsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<JobProvider>().loadWishlist());
  }

  void _removeJob(BuildContext context, JobModel job) {
    context.read<JobProvider>().toggleWishlist(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${job.title} dihapus dari wishlist'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Batal',
          textColor: const Color(0xFF7E57C2),
          onPressed: () {
            // Tambah lagi jika dibatalkan
            context.read<JobProvider>().toggleWishlist(job);
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Semua?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Semua lowongan tersimpan akan dihapus dari wishlist. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<JobProvider>().clearWishlist();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua wishlist telah dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Lowongan Tersimpan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          Consumer<JobProvider>(
            builder: (context, provider, _) {
              if (provider.wishlist.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined,
                    color: Colors.white),
                tooltip: 'Hapus Semua',
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, _) {
          // ── Loading ─────────────────────────────────────────────
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5E35B1)),
            );
          }

          // ── Empty State ─────────────────────────────────────────
          if (provider.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E35B1).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_outline,
                      size: 64,
                      color: Color(0xFF5E35B1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Belum ada lowongan tersimpan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan ikon 🔖 di kartu lowongan\nuntuk menyimpannya di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Lowongan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E35B1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Wishlist List ───────────────────────────────────────
          return Column(
            children: [
              // Header count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${provider.wishlist.length} lowongan tersimpan',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5E35B1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: provider.wishlist.length,
                  itemBuilder: (context, index) {
                    final job = provider.wishlist[index];

                    // Swipe ke kiri untuk hapus
                    return Dismissible(
                      key: ValueKey(job.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.white, size: 28),
                            SizedBox(height: 4),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => _removeJob(context, job),
                      child: JobCard(
                        job: job,
                        isInWishlist: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Detail: ${job.title}')),
                          );
                        },
                        onWishlistTap: () => _removeJob(context, job),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}