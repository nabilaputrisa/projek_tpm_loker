// lib/widgets/timezone_converter_sheet.dart

import 'package:flutter/material.dart';
import '../../data/services/api_timezone_service.dart';
import '../../core/utils/time_helper.dart';

class TimezoneConverterSheet extends StatefulWidget {
  final String jobLocation;

  const TimezoneConverterSheet({super.key, required this.jobLocation});

  @override
  State<TimezoneConverterSheet> createState() => _TimezoneConverterSheetState();
}

class _TimezoneConverterSheetState extends State<TimezoneConverterSheet> {
  final ApiTimezoneService _service = ApiTimezoneService();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  String _sourceTz = 'Asia/Jakarta';
  String _targetTz = 'Asia/Jakarta';

  String? _dynamicTz;
  String _dynamicLabel = '';

  bool _isConverting = false;
  TimezoneConversionResult? _result;
  String? _error;

  List<Map<String, String>> get _allSlots {
    final slots = List<Map<String, String>>.from(TimeHelper.indonesiaTimezones);
    if (_dynamicTz != null) {
      slots.add({'label': _dynamicLabel, 'tz': _dynamicTz!});
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _initZones();
  }

  void _initZones() {
    final detected = TimeHelper.detectForeignTimezone(widget.jobLocation);
    if (detected != null) {
      _dynamicTz = detected;
      _dynamicLabel = TimeHelper.labelFromTz(detected);
      _sourceTz = detected;
      _targetTz = 'Asia/Jakarta';
    } else {
      _dynamicTz = null;
      _sourceTz = 'Asia/Jakarta';
      _targetTz = 'Asia/Makassar';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _convert();
    });
  }

  Future<void> _convert() async {
    if (!mounted) return;

    setState(() {
      _isConverting = true;
      _error = null;
      _result = null;
    });

    // JIKA TIMEOZONE SAMA: Langsung render tanpa nunggu API/Statis crash/gantung
    if (_sourceTz == _targetTz) {
      final currentLabel = TimeHelper.labelFromTz(_sourceTz);
      setState(() {
        _result = TimezoneConversionResult(
          sourceTime: TimeOfDaySimple(
            hour: _selectedTime.hour,
            minute: _selectedTime.minute,
          ),
          fromTimezone: _sourceTz,
          toTimezone: _targetTz,
          fromOffset: currentLabel,
          toOffset: currentLabel,
          fromSource: 'statis',
          toSource: 'statis',
          targetHour: _selectedTime.hour,
          targetMinute: _selectedTime.minute,
          diffMinutes: 0,
        );
        _isConverting = false;
      });
      return;
    }

    try {
      final result = await _service.convert(
        sourceTime: TimeOfDaySimple(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
        ),
        fromTimezone: _sourceTz,
        toTimezone: _targetTz,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _isConverting = false;
      });
    } catch (e) {
      debugPrint('[TimezoneConverter] Error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Gagal mengambil data timezone. Cek koneksi internet.';
        _isConverting = false;
      });
    }
  }

  void _swapZones() {
    setState(() {
      final tmp = _sourceTz;
      _sourceTz = _targetTz;
      _targetTz = tmp;
      _result = null;
    });
    _convert();
  }

  void _selectSource(String tz) {
    setState(() {
      _sourceTz = tz;
      _result = null;
    });
    _convert();
  }

  void _selectTarget(String tz) {
    setState(() {
      _targetTz = tz;
      _result = null;
    });
    _convert();
  }

  void _openForeignPicker() {
    final searchController = TextEditingController();
    List<Map<String, String>> filtered = List.from(TimeHelper.foreignTimezones);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Zona Waktu Luar Negeri',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3C5E)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cari kota atau zona waktu...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFADB5BD)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7B3DD1), size: 20),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B7A8D)),
                          onPressed: () {
                            searchController.clear();
                            setModal(() => filtered = List.from(TimeHelper.foreignTimezones));
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  final q = val.toLowerCase();
                  setModal(() {
                    filtered = TimeHelper.foreignTimezones
                        .where((e) =>
                            (e['label'] ?? '').toLowerCase().contains(q) ||
                            (e['tz'] ?? '').toLowerCase().contains(q))
                        .toList();
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (_, i) {
                  final item = filtered[i];
                  final tz = item['tz'] ?? '';
                  final label = item['label'] ?? tz;
                  final isSelected = tz == _dynamicTz;

                  return ListTile(
                    dense: true,
                    title: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF1A3C5E),
                      ),
                    ),
                    subtitle: Text(tz, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7A8D))),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF7B3DD1), size: 20) : null,
                    onTap: () {
                      setState(() {
                        _dynamicTz = tz;
                        _dynamicLabel = label;
                        if (_sourceTz != 'Asia/Jakarta' && _sourceTz != 'Asia/Makassar' && _sourceTz != 'Asia/Jayapura') {
                          _sourceTz = tz;
                        }
                        if (_targetTz != 'Asia/Jakarta' && _targetTz != 'Asia/Makassar' && _targetTz != 'Asia/Jayapura') {
                          _targetTz = tz;
                        }
                        _result = null;
                      });
                      Navigator.pop(ctx);
                      _convert();
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _timeLabel(int hour) {
    if (hour >= 5 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  Widget _buildZoneChip({
    required Map<String, String> slot,
    required bool isSource,
    required bool isSelected,
  }) {
    final isDynamic = slot['tz'] != 'Asia/Jakarta' && slot['tz'] != 'Asia/Makassar' && slot['tz'] != 'Asia/Jayapura';
    final activeColor = isSource ? const Color(0xFF7B3DD1) : const Color(0xFF2D6A9F);

    return GestureDetector(
      onTap: () {
        if (isSource) {
          _selectSource(slot['tz']!);
        } else {
          _selectTarget(slot['tz']!);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? activeColor : const Color(0xFFDDE3EA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot['label'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1A3C5E),
              ),
            ),
            if (isDynamic) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _openForeignPicker,
                child: Icon(
                  Icons.edit_rounded,
                  size: 13,
                  color: isSelected ? Colors.white70 : const Color(0xFF7B3DD1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    final srcLabel = TimeHelper.labelFromTz(r.fromTimezone);
    final tgtLabel = TimeHelper.labelFromTz(r.toTimezone);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B3DD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$srcLabel  -  ${r.sourceTime.format12h()}  ${_timeLabel(r.sourceTime.hour)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              Expanded(child: Container(height: 1, color: Colors.white24)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _swapZones,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.swap_vert_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: Colors.white24)),
            ]),
          ),
          Text(tgtLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            r.targetFormatted,
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          Text(_timeLabel(r.targetHour), style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${r.fromOffset}  ke  ${r.toOffset}  (${r.diffLabel})',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(r.dataSourceLabel, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = _allSlots;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B3DD1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.schedule_rounded, color: Color(0xFF7B3DD1), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konversi Zona Waktu',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3C5E)),
                          ),
                          Text(
                            widget.jobLocation,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7A8D)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Zona waktu sumber:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) => _buildZoneChip(
                      slot: slot,
                      isSource: true,
                      isSelected: slot['tz'] == _sourceTz,
                    )).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Jam acara / interview:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF7B3DD1)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTime = picked;
                          _result = null;
                        });
                        _convert();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDE3EA)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFF7B3DD1), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A3C5E)),
                        ),
                        const SizedBox(width: 8),
                        Text(_timeLabel(_selectedTime.hour), style: const TextStyle(fontSize: 13, color: Color(0xFF6B7A8D))),
                        const Spacer(),
                        const Icon(Icons.edit_rounded, color: Color(0xFF7B3DD1), size: 18),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Zona waktu tujuan:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: slots.map((slot) => _buildZoneChip(
                      slot: slot,
                      isSource: false,
                      isSelected: slot['tz'] == _targetTz,
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isConverting ? null : _convert,
                      icon: _isConverting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                      label: Text(
                        _isConverting ? 'Mengambil data...' : 'Konversi',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B3DD1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Color(0xFFE57373), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_error!, style: const TextStyle(color: Color(0xFFE57373), fontSize: 13)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _convert,
                                child: const Text(
                                  'Coba lagi',
                                  style: TextStyle(color: Color(0xFF7B3DD1), fontSize: 12, decoration: TextDecoration.underline),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  if (_result != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}