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

  static const Color _primaryBlue = Color(0xFF2F80ED);
  static const Color _bgColor = Color(0xFFEAF2FB);
  static const Color _darkText = Color(0xFF1A2E44);
  static const Color _subtleText = Color(0xFF7A92A8);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Observer ini akan mendeteksi saat app kembali ke foreground
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InterviewProvider>().loadInterviews();
    });
  }

  // Dipanggil otomatis saat app resume dari background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh supaya interview yang baru lewat langsung pindah tab
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
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Jadwal Interview',
          style: TextStyle(
            color: _darkText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _darkText),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: _subtleText,
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
            return const Center(
              child: CircularProgressIndicator(color: _primaryBlue),
            );
          }

          if (provider.state == InterviewState.error) {
            return _buildErrorState(provider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInterviewList(provider.upcomingInterviews, upcoming: true),
              _buildInterviewList(provider.pastInterviews, upcoming: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAdd(context),
        backgroundColor: _primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInterviewList(List<InterviewModel> list,
      {required bool upcoming}) {
    if (list.isEmpty) {
      return _buildEmptyState(upcoming);
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

  Widget _buildEmptyState(bool upcoming) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              upcoming ? Icons.event_available : Icons.event_busy,
              color: _primaryBlue,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            upcoming
                ? 'Belum ada jadwal mendatang'
                : 'Belum ada interview selesai',
            style: const TextStyle(
              color: _darkText,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            upcoming ? 'Tambahkan jadwal interview-mu' : '',
            style: const TextStyle(color: _subtleText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(InterviewProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            provider.errorMessage ?? 'Terjadi kesalahan',
            style: const TextStyle(color: _subtleText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadInterviews(),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            child: const Text('Coba Lagi',
                style: TextStyle(color: Colors.white)),
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
      MaterialPageRoute(
          builder: (_) => AddInterviewPage(interview: interview)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, InterviewModel interview) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Jadwal',
            style: TextStyle(fontWeight: FontWeight.w700, color: _darkText)),
        content: Text(
          'Hapus jadwal interview "${interview.jobTitle}" di ${interview.companyName}?',
          style: const TextStyle(color: _subtleText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: _subtleText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context
          .read<InterviewProvider>()
          .deleteInterview(interview.id!);
    }
  }
}

class _InterviewCard extends StatelessWidget {
  final InterviewModel interview;
  final bool upcoming;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Color _primaryBlue = Color(0xFF2F80ED);
  static const Color _darkText = Color(0xFF1A2E44);
  static const Color _subtleText = Color(0xFF7A92A8);

  const _InterviewCard({
    required this.interview,
    required this.upcoming,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMM yyyy', 'id_ID').format(interview.interviewDateTime);
    final timeStr = DateFormat('HH:mm').format(interview.interviewDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.07),
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
              color: upcoming
                  ? _primaryBlue
                  : const Color(0xFF8FA9BF),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.business_center,
                    color: Colors.white, size: 16),
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
                if (upcoming)
                  _buildCountdownChip(interview.timeUntilInterview),
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
                  style: const TextStyle(
                    color: _darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInfoChip(
                        Icons.calendar_today_outlined, dateStr),
                    const SizedBox(width: 10),
                    _buildInfoChip(Icons.access_time, timeStr),
                  ],
                ),
                if (interview.notes != null &&
                    interview.notes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes,
                          size: 14, color: _subtleText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          interview.notes!,
                          style: const TextStyle(
                              color: _subtleText, fontSize: 12),
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
                    if (upcoming)
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        color: _primaryBlue,
                        onTap: onEdit,
                      ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Hapus',
                      color: Colors.redAccent,
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownChip(Duration duration) {
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
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF2F80ED)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: Color(0xFF1A2E44),
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}