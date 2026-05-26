// lib/widgets/timezone_converter_sheet.dart

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TIMEZONE CONVERTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _TZone {
  final String id;
  final String name;
  final int offsetHours;
  final int offsetMinutes;
  final String flag;

  const _TZone({
    required this.id,
    required this.name,
    required this.offsetHours,
    this.offsetMinutes = 0,
    required this.flag,
  });

  int get totalMinutes => offsetHours * 60 + offsetMinutes;
}

const List<_TZone> _indonesiaZones = [
  _TZone(id: 'WIB',  name: 'WIB – Jakarta', offsetHours: 7, flag: '🇮🇩'),
  _TZone(id: 'WITA', name: 'WITA – Bali',   offsetHours: 8, flag: '🇮🇩'),
  _TZone(id: 'WIT',  name: 'WIT – Papua',   offsetHours: 9, flag: '🇮🇩'),
];

const Map<String, _TZone> _locationZoneMap = {
  'singapore': _TZone(id: 'SGT',  name: 'SGT – Singapura',      offsetHours: 8,  flag: '🇸🇬'),

  'india':     _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'mumbai':    _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'delhi':     _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'bangalore': _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'bengaluru': _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'chennai':   _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'hyderabad': _TZone(id: 'IST',  name: 'IST – India',          offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),

  'london':    _TZone(id: 'BST',  name: 'BST – UK',             offsetHours: 1,  flag: '🇬🇧'),
  'uk':        _TZone(id: 'BST',  name: 'BST – UK',             offsetHours: 1,  flag: '🇬🇧'),
  'england':   _TZone(id: 'BST',  name: 'BST – UK',             offsetHours: 1,  flag: '🇬🇧'),

  'australia': _TZone(id: 'AEST', name: 'AEST – Australia',     offsetHours: 10, flag: '🇦🇺'),
  'sydney':    _TZone(id: 'AEST', name: 'AEST – Sydney',        offsetHours: 10, flag: '🇦🇺'),
  'melbourne': _TZone(id: 'AEST', name: 'AEST – Melbourne',     offsetHours: 10, flag: '🇦🇺'),

  'usa':           _TZone(id: 'EDT', name: 'EDT – Amerika',      offsetHours: -4, flag: '🇺🇸'),
  'new york':      _TZone(id: 'EDT', name: 'EDT – New York',     offsetHours: -4, flag: '🇺🇸'),
  'los angeles':   _TZone(id: 'PDT', name: 'PDT – Los Angeles',  offsetHours: -7, flag: '🇺🇸'),
  'san francisco': _TZone(id: 'PDT', name: 'PDT – San Francisco',offsetHours: -7, flag: '🇺🇸'),
  'chicago':       _TZone(id: 'CDT', name: 'CDT – Chicago',      offsetHours: -5, flag: '🇺🇸'),
  'seattle':       _TZone(id: 'PDT', name: 'PDT – Seattle',      offsetHours: -7, flag: '🇺🇸'),
  'boston':        _TZone(id: 'EDT', name: 'EDT – Boston',       offsetHours: -4, flag: '🇺🇸'),

  'canada':    _TZone(id: 'EDT', name: 'EDT – Kanada',    offsetHours: -4, flag: '🇨🇦'),
  'toronto':   _TZone(id: 'EDT', name: 'EDT – Toronto',   offsetHours: -4, flag: '🇨🇦'),
  'vancouver': _TZone(id: 'PDT', name: 'PDT – Vancouver', offsetHours: -7, flag: '🇨🇦'),

  'germany':   _TZone(id: 'CEST', name: 'CEST – Jerman',  offsetHours: 2, flag: '🇩🇪'),
  'berlin':    _TZone(id: 'CEST', name: 'CEST – Berlin',  offsetHours: 2, flag: '🇩🇪'),
  'frankfurt': _TZone(id: 'CEST', name: 'CEST – Jerman',  offsetHours: 2, flag: '🇩🇪'),
};

_TZone? _detectForeignZone(String location) {
  final loc = location.toLowerCase();
  final sorted = _locationZoneMap.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final keyword in sorted) {
    if (loc.contains(keyword)) {
      return _locationZoneMap[keyword];
    }
  }
  return null;
}

class TimezoneConverterSheet extends StatefulWidget {
  final String jobLocation;

  const TimezoneConverterSheet({super.key, required this.jobLocation});

  @override
  State<TimezoneConverterSheet> createState() =>
      _TimezoneConverterSheetState();
}

class _TimezoneConverterSheetState extends State<TimezoneConverterSheet> {
  late List<_TZone> _zones;
  late TimeOfDay _selectedTime;
  late String _sourceZoneId;
  late String _targetZoneId;

  @override
  void initState() {
    super.initState();
    _selectedTime = const TimeOfDay(hour: 9, minute: 0);

    _zones = List.from(_indonesiaZones);

    final foreign = _detectForeignZone(widget.jobLocation);
    if (foreign != null) {
      final alreadyExists = _zones.any((z) => z.id == foreign.id);
      if (!alreadyExists) _zones.add(foreign);
      _sourceZoneId = foreign.id;
      _targetZoneId = 'WIB';
    } else {
      _sourceZoneId = 'WIB';
      _targetZoneId = 'WITA';
    }
  }

  _TZone _zoneById(String id) => _zones.firstWhere((z) => z.id == id);

  int _convertTotalMinutes(String targetId) {
    final src = _zoneById(_sourceZoneId);
    final tgt = _zoneById(targetId);
    final diff = tgt.totalMinutes - src.totalMinutes;
    final srcTotal = _selectedTime.hour * 60 + _selectedTime.minute;
    return ((srcTotal + diff) % 1440 + 1440) % 1440;
  }

  String _formatTime(int totalMins) {
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} ${h < 12 ? 'AM' : 'PM'}';
  }

  String _timeLabel(int hour) {
    if (hour >= 5 && hour < 11) return 'Pagi';
    if (hour >= 11 && hour < 15) return 'Siang';
    if (hour >= 15 && hour < 18) return 'Sore';
    return 'Malam';
  }

  void _swapZones() {
    setState(() {
      final tmp = _sourceZoneId;
      _sourceZoneId = _targetZoneId;
      _targetZoneId = tmp;
    });
  }

  String _offsetLabel(_TZone z) {
    final sign = z.offsetHours >= 0 ? '+' : '';
    if (z.offsetMinutes != 0) {
      return 'UTC$sign${z.offsetHours}:${z.offsetMinutes.toString().padLeft(2, '0')}';
    }
    return 'UTC$sign${z.offsetHours}';
  }

  Widget _buildZoneChip(_TZone z,
      {required bool isSelected,
      required bool isExcluded,
      required Color activeColor,
      required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: isExcluded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : isExcluded
                  ? const Color(0xFFEEEEEE)
                  : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : isExcluded
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFFDDE3EA),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${z.flag} ${z.id}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : isExcluded
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF1A3C5E),
              ),
            ),
            Text(
              _offsetLabel(z),
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : const Color(0xFF6B7A8D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final src = _zoneById(_sourceZoneId);
    final tgt = _zoneById(_targetZoneId);
    final targetTotal = _convertTotalMinutes(_targetZoneId);
    final targetH = targetTotal ~/ 60;
    final convertedTime = _formatTime(targetTotal);

    final diffMin = tgt.totalMinutes - src.totalMinutes;
    final diffSign = diffMin >= 0 ? '+' : '';
    final diffH = diffMin ~/ 60;
    final diffM = (diffMin % 60).abs();
    final diffLabel =
        diffM == 0 ? '$diffSign${diffH}h' : '$diffSign${diffH}h ${diffM}m';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EAFD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: Color(0xFF7B3DD1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Konversi Zona Waktu',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3C5E))),
                        Text(
                          _zones.map((z) => z.id).join(' · '),
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A8D)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 24),

                const Text('Zona waktu sumber:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _zones
                      .map((z) => _buildZoneChip(
                            z,
                            isSelected: z.id == _sourceZoneId,
                            isExcluded: z.id == _targetZoneId,
                            activeColor: const Color(0xFF7B3DD1),
                            onTap: () => setState(() => _sourceZoneId = z.id),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),

                const Text('Jam acara / interview:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF7B3DD1)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE3EA)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time_rounded,
                          color: Color(0xFF7B3DD1), size: 22),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeLabel(_selectedTime.hour),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7A8D)),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_rounded,
                          color: Color(0xFF7B3DD1), size: 18),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Zona waktu tujuan:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _zones
                      .map((z) => _buildZoneChip(
                            z,
                            isSelected: z.id == _targetZoneId,
                            isExcluded: z.id == _sourceZoneId,
                            activeColor: const Color(0xFF2D6A9F),
                            onTap: () => setState(() => _targetZoneId = z.id),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),

                Container(
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
                      Row(children: [
                        Text(src.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${src.name}  •  ${_selectedTime.format(context)} ${_timeLabel(_selectedTime.hour)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ]),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(children: [
                          Expanded(
                              child: Container(
                                  height: 1, color: Colors.white24)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _swapZones,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.swap_vert_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Container(
                                  height: 1, color: Colors.white24)),
                        ]),
                      ),
                      Row(children: [
                        Text(tgt.flag,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(tgt.name,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        convertedTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _timeLabel(targetH),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_sourceZoneId → $_targetZoneId  ($diffLabel)',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}