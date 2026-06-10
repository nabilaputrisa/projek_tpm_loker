import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/interview_model.dart';
import '../../providers/interview_provider.dart';
import 'add_interview_page.dart';

class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterviewProvider>().loadInterviews();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<InterviewProvider>().loadInterviews();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerHighest,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Jadwal Interview',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: cs.onSurface),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: cs.onPrimary,
              unselectedLabelColor: cs.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Mendatang'),
                Tab(text: 'Selesai'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<InterviewProvider>(
        builder: (context, provider, _) {
          if (provider.state == InterviewState.loading) {
            return Center(
              child: CircularProgressIndicator(color: cs.primary),
            );
          }

          if (provider.state == InterviewState.error) {
            return _buildErrorState(provider, cs);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInterviewList(provider.upcomingInterviews, true, cs),
              _buildInterviewList(provider.pastInterviews, false, cs),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: cs.onPrimary),
      ),
    );
  }

  Widget _buildInterviewList(List<InterviewModel> list, bool upcoming, ColorScheme cs) {
    if (list.isEmpty) {
      return _buildEmptyState(upcoming, cs);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _InterviewCard(
          interview: list[index],
          upcoming: upcoming,
          onEdit: () => _navigateToEdit(context, list[index]),
          onDelete: () => _confirmDelete(context, list[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(bool upcoming, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              upcoming ? Icons.event_available : Icons.event_busy,
              color: cs.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            upcoming ? 'Belum ada jadwal mendatang' : 'Belum ada interview selesai',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            upcoming ? 'Tambahkan jadwal interview-mu' : '',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(InterviewProvider provider, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 48),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'Terjadi kesalahan',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadInterviews(),
            style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
            child: Text('Coba Lagi', style: TextStyle(color: cs.onPrimary)),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddInterviewPage()),
    );
  }

  void _navigateToEdit(BuildContext context, InterviewModel interview) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddInterviewPage(interview: interview)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, InterviewModel interview) async {
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Jadwal', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
        content: Text(
          'Hapus jadwal interview "${interview.jobTitle}" di ${interview.companyName}?',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: TextStyle(color: cs.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hapus', style: TextStyle(color: cs.onError)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<InterviewProvider>().deleteInterview(interview.id!);
    }
  }
}

// ============================================
// Interview Card Widget
// ============================================
class _InterviewCard extends StatelessWidget {
  final InterviewModel interview;
  final bool upcoming;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InterviewCard({
    required this.interview,
    required this.upcoming,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(interview.interviewDateTime);
    final timeStr = DateFormat('HH:mm').format(interview.interviewDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: upcoming ? cs.primary : cs.onSurfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_center, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    interview.companyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (upcoming) _buildCountdownChip(interview.timeUntilInterview, cs),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interview.jobTitle,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInfoChip(cs, Icons.calendar_today_outlined, dateStr),
                    const SizedBox(width: 10),
                    _buildInfoChip(cs, Icons.access_time, timeStr),
                  ],
                ),
                if (interview.notes != null && interview.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes, size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          interview.notes!,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (upcoming) _buildActionButton(cs, Icons.edit_outlined, 'Edit', cs.primary, onEdit),
                    const SizedBox(width: 8),
                    _buildActionButton(cs, Icons.delete_outline, 'Hapus', cs.error, onDelete),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownChip(Duration duration, ColorScheme cs) {
    String label;
    if (duration.inDays > 0) {
      label = '${duration.inDays}h lagi';
    } else if (duration.inHours > 0) {
      label = '${duration.inHours}j lagi';
    } else {
      label = '${duration.inMinutes}m lagi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoChip(ColorScheme cs, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: cs.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(ColorScheme cs, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}