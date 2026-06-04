import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/job_provider.dart';
import '../../data/services/api_job_service.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final ApiJobService _apiService = ApiJobService();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();

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

    if (_selectedSalaryRange != null) {
      if (_selectedSalaryRange!.min > 0) {
        _minSalaryController.text = _selectedSalaryRange!.min.toInt().toString();
      }
      if (_selectedSalaryRange!.max != null) {
        _maxSalaryController.text = _selectedSalaryRange!.max!.toInt().toString();
      }
    }
  }

  @override
  void dispose() {
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String countryCode) {
    setState(() {
      _selectedCountry = countryCode;
      _selectedLocation = 'Semua Lokasi';
      _minSalaryController.clear();
      _maxSalaryController.clear();
      _selectedSalaryRange = null;
    });
  }

  void _createSalaryRangeFromInputs() {
    final minText = _minSalaryController.text.trim();
    final maxText = _maxSalaryController.text.trim();

    if (minText.isEmpty && maxText.isEmpty) {
      _selectedSalaryRange = null;
      return;
    }

    final double min = minText.isNotEmpty ? double.tryParse(minText) ?? 0 : 0;
    final double? max = maxText.isNotEmpty ? double.tryParse(maxText) : null;

    final country = ApiJobService.countries[_selectedCountry];
    final symbol = country?.currencySymbol ?? 'S\$';

    String label;
    if (min > 0 && max != null) {
      label = '$symbol ${_formatNumber(min.toInt())} – ${_formatNumber(max.toInt())} / yr';
    } else if (min > 0) {
      label = 'Min $symbol ${_formatNumber(min.toInt())} / yr';
    } else if (max != null) {
      label = 'Max $symbol ${_formatNumber(max.toInt())} / yr';
    } else {
      label = 'Salary filter';
    }

    setState(() {
      _selectedSalaryRange = SalaryRange(min: min, max: max, label: label);
    });
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(0)}K';
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final countries = _apiService.getAvailableCountries();
    final locations = _apiService.getLocations(_selectedCountry);
    final country = ApiJobService.countries[_selectedCountry];
    final currencySymbol = country?.currencySymbol ?? 'S\$';

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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Filter Jobs',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
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
                        _minSalaryController.clear();
                        _maxSalaryController.clear();
                      });
                    },
                    child: const Text('Reset All'),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              _buildSectionLabel('🌍 Country'),
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

              _buildSectionLabel('📍 Location'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: _dropdownDecoration(),
                items: locations.map((loc) {
                  return DropdownMenuItem(value: loc, child: Text(loc));
                }).toList(),
                onChanged: (value) => setState(() => _selectedLocation = value!),
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('💼 Category'),
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
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('💰 Salary Filter'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Min Salary',
                        hintText: 'Any',
                        prefixText: '$currencySymbol ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('-', style: TextStyle(color: cs.onSurface)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _maxSalaryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Max Salary',
                        hintText: 'Any',
                        prefixText: '$currencySymbol ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionLabel('↕ Sort By'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: _dropdownDecoration(),
                items: const [
                  DropdownMenuItem(value: 'date', child: Text('📅 Newest First')),
                  DropdownMenuItem(value: 'relevance', child: Text('⭐ Relevance')),
                  DropdownMenuItem(value: 'salary', child: Text('💰 Highest Salary')),
                ],
                onChanged: (value) => setState(() => _sortBy = value!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _createSalaryRangeFromInputs();
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}