import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../data/services/api_job_service.dart';
import '../../widgets/job_card.dart';
import '../home/job_detail_page.dart';
import 'filter_bottom_sheet.dart';
import '../tools/ai_consultant_page.dart';
import '../games/memory_match_game.dart';
import '../profile/profile_page.dart';
import '../profile/saved_jobs_page.dart';
import '../interview/interview_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const AiConsultantPage(),
    const InterviewPage(),
    const MemoryMatchGame(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                index: 0,
                currentIndex: _currentIndex,
                icon: Icons.work_outline,
                activeIcon: Icons.work,
                label: 'Home',
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                index: 1,
                currentIndex: _currentIndex,
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'AI Career',
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _NavItem(
                index: 2,
                currentIndex: _currentIndex,
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: 'Interview',
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                index: 3,
                currentIndex: _currentIndex,
                icon: Icons.extension_outlined,
                activeIcon: Icons.extension,
                label: 'Mini Game',
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? cs.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? cs.primary : cs.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<JobProvider>().fetchJobs(refresh: true);
      context.read<JobProvider>().loadWishlist();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<JobProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest, // ✅ Background pakai tema
      appBar: AppBar(
        title: const Text(
          'Career Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark, color: cs.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedJobsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: cs.onPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.primary,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search jobs...',
                            hintStyle: TextStyle(color: cs.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search, color: cs.primary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<JobProvider>().setSearchQuery('');
                                      context.read<JobProvider>().fetchJobs(refresh: true);
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: cs.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (value) {
                            context.read<JobProvider>().setSearchQuery(value);
                            context.read<JobProvider>().fetchJobs(refresh: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.tune, color: cs.primary),
                        onPressed: _showFilterBottomSheet,
                        tooltip: 'Filter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Consumer<JobProvider>(
                  builder: (context, provider, _) {
                    final country = ApiJobService.countries[provider.selectedCountry];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: '${country?.flag ?? ''} ${country?.name ?? provider.selectedCountry}',
                            onRemove: null,
                            colorScheme: cs,
                          ),
                          if (provider.selectedLocation != 'Semua Lokasi')
                            _FilterChip(
                              label: '📍 ${provider.selectedLocation}',
                              onRemove: () {
                                provider.setLocation('Semua Lokasi');
                                provider.applyFilters();
                              },
                              colorScheme: cs,
                            ),
                          if (provider.selectedCategory != 'Semua Kategori')
                            _FilterChip(
                              label: '💼 ${provider.selectedCategory}',
                              onRemove: () {
                                provider.setCategory('Semua Kategori');
                                provider.applyFilters();
                              },
                              colorScheme: cs,
                            ),
                          if (provider.selectedSalaryRange != null)
                            _FilterChip(
                              label: '💰 ${provider.selectedSalaryRange!.label}',
                              onRemove: () {
                                provider.setSalaryRange(null);
                                provider.applyFilters();
                              },
                              colorScheme: cs,
                            ),
                          if (provider.sortBy != 'date')
                            _FilterChip(
                              label: provider.sortBy == 'salary'
                                  ? '↑ Highest Salary'
                                  : '⭐ Relevance',
                              onRemove: () {
                                provider.setSortBy('date');
                                provider.applyFilters();
                              },
                              colorScheme: cs,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, child) {
                if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }

                if (jobProvider.errorMessage != null && jobProvider.jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          jobProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => jobProvider.fetchJobs(refresh: true),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (jobProvider.jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing keywords or filters',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: cs.primary,
                  onRefresh: () async => jobProvider.fetchJobs(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: jobProvider.jobs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == jobProvider.jobs.length) {
                        return jobProvider.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(color: cs.primary),
                                ),
                              )
                            : const SizedBox(height: 16);
                      }

                      final job = jobProvider.jobs[index];
                      final isInWishlist = jobProvider.isInWishlist(job.id);

                      return JobCard(
                        job: job,
                        isInWishlist: isInWishlist,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JobDetailPage(job: job),
                            ),
                          );
                        },
                        onWishlistTap: () {
                          jobProvider.toggleWishlist(job);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isInWishlist
                                    ? 'Removed from wishlist'
                                    : 'Added to wishlist',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active Filter Chip Widget ────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  final ColorScheme colorScheme;

  const _FilterChip({
    required this.label,
    required this.colorScheme,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.onPrimary.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, color: colorScheme.onPrimary, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}