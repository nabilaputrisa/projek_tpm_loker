import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../data/services/api_job_service.dart';
import '../../widgets/job_card.dart';

// Import halaman-halaman lain
import '../tools/ai_consultant_page.dart'; // Ganti dengan path yang sesuai
import '../games/memory_match_game.dart';
// import '../views/interview_schedule_page.dart'; // Ganti dengan path yang sesuai

// ─── Main Navigation Shell ────────────────────────────────────────────────────

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeTab(),
    AiConsultantPage(),      // AI Career Assistant (dari ai_consultant_page.dart)
    InterviewSchedulePage(), // Jadwal Interview — ganti dengan import yang sesuai
    MemoryMatchGame(),       // Memory Game (dari memory_match_game.dart)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.15),
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

// ─── Nav Item Widget ──────────────────────────────────────────────────────────

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
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5E35B1).withOpacity(0.1)
              : Colors.transparent,
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
                color:
                    isActive ? const Color(0xFF5E35B1) : Colors.grey[500],
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color:
                    isActive ? const Color(0xFF5E35B1) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder untuk InterviewSchedulePage ──────────────────────────────────
// Hapus class ini dan ganti dengan import dari file yang sesuai

class InterviewSchedulePage extends StatelessWidget {
  const InterviewSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Jadwal Interview',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Color(0xFF5E35B1)),
            SizedBox(height: 16),
            Text(
              'Jadwal Interview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Hubungkan dengan interview_schedule_page.dart',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab (konten dari HomePage yang lama) ────────────────────────────────

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Career Portal',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Wishlist (Coming Soon)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Profile (Coming Soon)')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar & Filter ────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search jobs...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF5E35B1),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      context
                                          .read<JobProvider>()
                                          .setSearchQuery('');
                                      context
                                          .read<JobProvider>()
                                          .fetchJobs(refresh: true);
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (value) {
                            context
                                .read<JobProvider>()
                                .setSearchQuery(value);
                            context
                                .read<JobProvider>()
                                .fetchJobs(refresh: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune,
                            color: Color(0xFF5E35B1)),
                        onPressed: _showFilterBottomSheet,
                        tooltip: 'Filter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ─── Active Filter Chips ────────────────────────────────
                Consumer<JobProvider>(
                  builder: (context, provider, _) {
                    final country =
                        ApiJobService.countries[provider.selectedCountry];
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label:
                                '${country?.flag ?? ''} ${country?.name ?? provider.selectedCountry}',
                            onRemove: null,
                          ),
                          if (provider.selectedLocation != 'Semua Lokasi')
                            _FilterChip(
                              label: '📍 ${provider.selectedLocation}',
                              onRemove: () {
                                provider.setLocation('Semua Lokasi');
                                provider.applyFilters();
                              },
                            ),
                          if (provider.selectedCategory != 'Semua Kategori')
                            _FilterChip(
                              label: '💼 ${provider.selectedCategory}',
                              onRemove: () {
                                provider.setCategory('Semua Kategori');
                                provider.applyFilters();
                              },
                            ),
                          if (provider.selectedSalaryRange != null)
                            _FilterChip(
                              label:
                                  '💰 ${provider.selectedSalaryRange!.label}',
                              onRemove: () {
                                provider.setSalaryRange(null);
                                provider.applyFilters();
                              },
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
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ─── Job List ───────────────────────────────────────────────────
          Expanded(
            child: Consumer<JobProvider>(
              builder: (context, jobProvider, child) {
                if (jobProvider.isLoading && jobProvider.jobs.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF5E35B1)),
                  );
                }

                if (jobProvider.errorMessage != null &&
                    jobProvider.jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          jobProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              jobProvider.fetchJobs(refresh: true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5E35B1)),
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
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing keywords or filters',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: const Color(0xFF5E35B1),
                  onRefresh: () async =>
                      jobProvider.fetchJobs(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: jobProvider.jobs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == jobProvider.jobs.length) {
                        return jobProvider.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: Color(0xFF5E35B1)),
                                ),
                              )
                            : const SizedBox(height: 16);
                      }

                      final job = jobProvider.jobs[index];
                      final isInWishlist =
                          jobProvider.isInWishlist(job.id);

                      return JobCard(
                        job: job,
                        isInWishlist: isInWishlist,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Detail: ${job.title}')),
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

  const _FilterChip({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child:
                  const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Filter Bottom Sheet ──────────────────────────────────────────────────────

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final ApiJobService _apiService = ApiJobService();

  late String _selectedCountry;
  late String _selectedLocation;
  late String _selectedCategory;
  late String _sortBy;
  SalaryRange? _selectedSalaryRange;

  @override
  void initState() {
    super.initState();
    final provider = context.read<JobProvider>();
    _selectedCountry = provider.selectedCountry;
    _selectedLocation = provider.selectedLocation;
    _selectedCategory = provider.selectedCategory;
    _sortBy = provider.sortBy;
    _selectedSalaryRange = provider.selectedSalaryRange;
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountry = countryCode;
      _selectedLocation = 'Semua Lokasi';
      _selectedSalaryRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countries = _apiService.getAvailableCountries();
    final locations = _apiService.getLocations(_selectedCountry);
    final salaryRanges = _apiService.getSalaryRanges(_selectedCountry);
    final categories = [
      'Semua Kategori',
      'it-jobs',
      'engineering-jobs',
      'sales-jobs',
      'customer-services-jobs',
      'healthcare-nursing-jobs',
      'teaching-jobs',
      'accounting-finance-jobs',
      'legal-jobs',
      'marketing-jobs',
      'hr-jobs',
      'admin-jobs',
    ];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Filter',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCountry = 'sg';
                        _selectedLocation = 'Semua Lokasi';
                        _selectedCategory = 'Semua Kategori';
                        _sortBy = 'date';
                        _selectedSalaryRange = null;
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              _SectionLabel('🌍 Country'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: _dropdownDecoration(),
                items: countries.map((entry) {
                  final code = entry.key;
                  final config = entry.value;
                  return DropdownMenuItem(
                    value: code,
                    child: Text('${config.flag} ${config.name}'),
                  );
                }).toList(),
                onChanged: (value) => _onCountryChanged(value!),
              ),
              const SizedBox(height: 16),

              _SectionLabel('📍 Location'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: _dropdownDecoration(),
                items: locations.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedLocation = value!),
              ),
              const SizedBox(height: 16),

              _SectionLabel('💼 Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _dropdownDecoration(),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat == 'Semua Kategori'
                          ? cat
                          : cat
                              .replaceAll('-', ' ')
                              .split(' ')
                              .map((w) => w.isEmpty
                                  ? w
                                  : '${w[0].toUpperCase()}${w.substring(1)}')
                              .join(' '),
                    ),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              _SectionLabel('💰 Salary Range'),
              const SizedBox(height: 8),
              DropdownButtonFormField<SalaryRange?>(
                value: _selectedSalaryRange,
                decoration: _dropdownDecoration(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Salaries'),
                  ),
                  ...salaryRanges.map((range) {
                    return DropdownMenuItem(
                      value: range,
                      child: Text(range.label),
                    );
                  }),
                ],
                onChanged: (value) =>
                    setState(() => _selectedSalaryRange = value),
              ),
              const SizedBox(height: 16),

              _SectionLabel('↕ Sort By'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: _dropdownDecoration(),
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('Newest')),
                  DropdownMenuItem(
                      value: 'relevance', child: Text('Relevance')),
                  DropdownMenuItem(
                      value: 'salary', child: Text('Highest Salary')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final provider = context.read<JobProvider>();
                    provider.setCountry(_selectedCountry);
                    provider.setLocation(_selectedLocation);
                    provider.setCategory(_selectedCategory);
                    provider.setSalaryRange(_selectedSalaryRange);
                    provider.setSortBy(_sortBy);
                    provider.applyFilters();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E35B1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

// ─── Helper Widget ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}