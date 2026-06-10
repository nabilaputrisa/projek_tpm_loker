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
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${job.title} dihapus dari wishlist'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Batal',
          textColor: cs.primary,
          onPressed: () {
            context.read<JobProvider>().toggleWishlist(job);
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Semua?',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        content: Text(
          'Semua lowongan tersimpan akan dihapus dari wishlist. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Semua'),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Lowongan Tersimpan',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: cs.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<JobProvider>(
            builder: (context, provider, _) {
              if (provider.wishlist.isEmpty) return const SizedBox();
              return IconButton(
                icon: Icon(Icons.delete_sweep_outlined, color: cs.onSurface),
                tooltip: 'Hapus Semua',
                onPressed: () => _confirmClearAll(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, _) {
        //loading state
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }

   //statement untuk kondisi ketika tidak ada lowongan tersimpan
          if (provider.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bookmark_outline,
                      size: 64,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada lowongan tersimpan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tekan ikon 🔖 di kartu lowongan\nuntuk menyimpannya di sini',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Lowongan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
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

         // Kondisi ketika ada lowongan tersimpan
          return Column(
            children: [
              // Header count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                child: Text(
                  '${provider.wishlist.length} lowongan tersimpan',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.primary,
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

                    return Dismissible(
                      key: ValueKey(job.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_outline,
                                color: cs.onError, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              'Hapus',
                              style: TextStyle(
                                color: cs.onError,
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