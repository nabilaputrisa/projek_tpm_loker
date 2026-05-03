// lib/widgets/conversion_popup.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/api_kurs_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// CURRENCY CONVERTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════
class CurrencyConverterSheet extends StatefulWidget {
  final double initialAmount;
  final String fromCurrency;

  const CurrencyConverterSheet({
    super.key,
    required this.initialAmount,
    required this.fromCurrency,
  });

  @override
  State<CurrencyConverterSheet> createState() => _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState extends State<CurrencyConverterSheet> {
  final ApiKursService _service = ApiKursService();
  late TextEditingController _amountController;
  final TextEditingController _searchController = TextEditingController();

  List<String> _allCurrencies = [];

  String _toCurrency = 'IDR';
  double? _result;
  double? _rate;
  bool _loadingCurrencies = true;
  bool _converting = false;
  String? _error;
  String? _listError;

  static const Map<String, String> _flags = {
    'IDR': '🇮🇩', 'USD': '🇺🇸', 'GBP': '🇬🇧', 'EUR': '🇪🇺',
    'SGD': '🇸🇬', 'AUD': '🇦🇺', 'JPY': '🇯🇵', 'MYR': '🇲🇾',
    'SAR': '🇸🇦', 'INR': '🇮🇳', 'CAD': '🇨🇦', 'CHF': '🇨🇭',
    'CNY': '🇨🇳', 'HKD': '🇭🇰', 'KRW': '🇰🇷', 'THB': '🇹🇭',
    'AED': '🇦🇪', 'NZD': '🇳🇿', 'SEK': '🇸🇪', 'NOK': '🇳🇴',
    'DKK': '🇩🇰', 'ZAR': '🇿🇦', 'BRL': '🇧🇷', 'MXN': '🇲🇽',
    'PHP': '🇵🇭', 'VND': '🇻🇳', 'PKR': '🇵🇰', 'BDT': '🇧🇩',
    'EGP': '🇪🇬', 'TRY': '🇹🇷', 'RUB': '🇷🇺', 'PLN': '🇵🇱',
    'CZK': '🇨🇿', 'HUF': '🇭🇺', 'ILS': '🇮🇱', 'QAR': '🇶🇦',
    'KWD': '🇰🇼', 'BHD': '🇧🇭', 'OMR': '🇴🇲', 'JOD': '🇯🇴',
  };

  String _flagOf(String code) => _flags[code] ?? '🌐';

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(0)
          : '',
    );
    _toCurrency = widget.fromCurrency == 'IDR' ? 'USD' : 'IDR';
    _loadCurrencyList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencyList() async {
    setState(() {
      _loadingCurrencies = true;
      _listError = null;
    });
    try {
      final codes = await _service.fetchAvailableCurrencies();
      setState(() {
        _allCurrencies = codes;
        _loadingCurrencies = false;
        if (_toCurrency == widget.fromCurrency && codes.isNotEmpty) {
          _toCurrency = codes.firstWhere(
            (c) => c != widget.fromCurrency,
            orElse: () => codes.first,
          );
        }
      });
      if (widget.initialAmount > 0) _convert();
    } catch (e) {
      setState(() {
        _listError = 'Gagal memuat daftar mata uang. Cek koneksi.';
        _loadingCurrencies = false;
      });
    }
  }

  Future<void> _convert() async {
    final raw = _amountController.text.replaceAll(',', '').replaceAll('.', '');
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() {
        _result = null;
        _error = 'Masukkan jumlah yang valid';
      });
      return;
    }
    setState(() {
      _converting = true;
      _error = null;
    });
    try {
      final res = await _service.convert(
        amount: amount,
        from: widget.fromCurrency,
        to: _toCurrency,
      );
      setState(() {
        _result = res.result;
        _rate = res.rate;
        _converting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil kurs. Periksa koneksi.';
        _converting = false;
      });
    }
  }

  String _fmt(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return value.toStringAsFixed(value < 1 ? 4 : 2);
  }

  void _openCurrencyPicker() {
    _searchController.clear();
    List<String> filtered = List.from(_allCurrencies);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Pilih Mata Uang Tujuan',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A3C5E)),
                    ),
                    const Spacer(),
                    Text(
                      '${_allCurrencies.length} mata uang',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7A8D)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Cari kode (misal: USD, EUR, JPY...)',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFFADB5BD)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF2D6A9F), size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF6B7A8D)),
                            onPressed: () {
                              _searchController.clear();
                              setModal(() => filtered =
                                  List.from(_allCurrencies));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    final q = val.toUpperCase().trim();
                    setModal(() {
                      filtered = q.isEmpty
                          ? List.from(_allCurrencies)
                          : _allCurrencies
                              .where((c) => c.contains(q))
                              .toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('Mata uang tidak ditemukan',
                            style: TextStyle(color: Color(0xFF6B7A8D))),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final code = filtered[i];
                          final isSelected = code == _toCurrency;
                          final isSource = code == widget.fromCurrency;
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            tileColor: isSelected
                                ? const Color(0xFFE8F1FB)
                                : null,
                            leading: Text(_flagOf(code),
                                style: const TextStyle(fontSize: 22)),
                            title: Text(
                              code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF2D6A9F)
                                    : const Color(0xFF1A3C5E),
                              ),
                            ),
                            subtitle: isSource
                                ? const Text('Mata uang loker ini',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFE67E22)))
                                : null,
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded,
                                    color: Color(0xFF2D6A9F))
                                : null,
                            onTap: isSource
                                ? null
                                : () {
                                    setState(() {
                                      _toCurrency = code;
                                      _result = null;
                                      _rate = null;
                                    });
                                    Navigator.pop(ctx);
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
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
                        color: const Color(0xFFE8F1FB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.currency_exchange_rounded,
                          color: Color(0xFF2D6A9F), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Konversi Mata Uang',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3C5E))),
                        Text(
                          'Kurs real-time · Dari ${widget.fromCurrency}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7A8D)),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 24),
                  const Text('Jumlah:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDE3EA)),
                      ),
                      child: Text(
                        '${_flagOf(widget.fromCurrency)} ${widget.fromCurrency}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E)),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFDDE3EA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF2D6A9F), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setState(() => _result = null),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  const Text('Ke mata uang:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7A8D))),
                  const SizedBox(height: 8),
                  if (_loadingCurrencies)
                    _buildLoadingBox()
                  else if (_listError != null)
                    _buildErrorBox()
                  else
                    _buildCurrencyDropdown(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                          (_converting || _loadingCurrencies) ? null : _convert,
                      icon: _converting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.swap_horiz_rounded,
                              color: Colors.white),
                      label: Text(
                        _converting ? 'Mengambil kurs...' : 'Konversi',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A9F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                        const Icon(Icons.error_outline,
                            color: Color(0xFFE57373), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: Color(0xFFE57373), fontSize: 13)),
                        ),
                      ]),
                    ),
                  if (_result != null) _buildResultCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBox() => Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF2D6A9F)),
            ),
            SizedBox(width: 10),
            Text('Memuat daftar mata uang...',
                style: TextStyle(color: Color(0xFF6B7A8D), fontSize: 13)),
          ]),
        ),
      );

  Widget _buildErrorBox() => GestureDetector(
        onTap: _loadCurrencyList,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: Row(children: [
            const Icon(Icons.refresh_rounded,
                color: Color(0xFFE57373), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_listError\nKetuk untuk coba lagi.',
                style:
                    const TextStyle(color: Color(0xFFE57373), fontSize: 12),
              ),
            ),
          ]),
        ),
      );

  Widget _buildCurrencyDropdown() => GestureDetector(
        onTap: _openCurrencyPicker,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: Row(children: [
            Text(_flagOf(_toCurrency),
                style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_toCurrency,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C5E))),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF2D6A9F)),
          ]),
        ),
      );

  Widget _buildResultCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3C5E), Color(0xFF2D6A9F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${_amountController.text} ${widget.fromCurrency} =',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmt(_result!)} $_toCurrency',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_rate != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1 ${widget.fromCurrency} = ${_fmt(_rate!)} $_toCurrency',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ]),
      );
}

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

// Hanya 7 negara yang dipakai
const Map<String, _TZone> _locationZoneMap = {
  // Singapura — tidak pakai DST
  'singapore': _TZone(id: 'SGT', name: 'SGT – Singapura', offsetHours: 8, flag: '🇸🇬'),

  // India — tidak pakai DST
  'india':     _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'mumbai':    _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'delhi':     _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'bangalore': _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'bengaluru': _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'chennai':   _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),
  'hyderabad': _TZone(id: 'IST', name: 'IST – India',     offsetHours: 5, offsetMinutes: 30, flag: '🇮🇳'),

  // UK — pakai DST (GMT+0 winter, BST+1 summer), pakai UTC+1 sebagai nilai tengah
  'london':    _TZone(id: 'BST', name: 'BST – UK',        offsetHours: 1, flag: '🇬🇧'),
  'uk':        _TZone(id: 'BST', name: 'BST – UK',        offsetHours: 1, flag: '🇬🇧'),
  'england':   _TZone(id: 'BST', name: 'BST – UK',        offsetHours: 1, flag: '🇬🇧'),

  // Australia — pakai DST (AEST+10 winter, AEDT+11 summer), pakai UTC+10
  'australia': _TZone(id: 'AEST', name: 'AEST – Australia', offsetHours: 10, flag: '🇦🇺'),
  'sydney':    _TZone(id: 'AEST', name: 'AEST – Sydney',    offsetHours: 10, flag: '🇦🇺'),
  'melbourne': _TZone(id: 'AEST', name: 'AEST – Melbourne', offsetHours: 10, flag: '🇦🇺'),

  // US — pakai DST (EST-5 winter, EDT-4 summer), pakai UTC-4
  'usa':           _TZone(id: 'EDT', name: 'EDT – Amerika',      offsetHours: -4, flag: '🇺🇸'),
  'new york':      _TZone(id: 'EDT', name: 'EDT – New York',     offsetHours: -4, flag: '🇺🇸'),
  'los angeles':   _TZone(id: 'PDT', name: 'PDT – Los Angeles',  offsetHours: -7, flag: '🇺🇸'),
  'san francisco': _TZone(id: 'PDT', name: 'PDT – San Francisco',offsetHours: -7, flag: '🇺🇸'),
  'chicago':       _TZone(id: 'CDT', name: 'CDT – Chicago',      offsetHours: -5, flag: '🇺🇸'),
  'seattle':       _TZone(id: 'PDT', name: 'PDT – Seattle',      offsetHours: -7, flag: '🇺🇸'),
  'boston':        _TZone(id: 'EDT', name: 'EDT – Boston',       offsetHours: -4, flag: '🇺🇸'),

  // Canada — pakai DST (EST-5 winter, EDT-4 summer), pakai UTC-4
  'canada':    _TZone(id: 'EDT', name: 'EDT – Kanada',    offsetHours: -4, flag: '🇨🇦'),
  'toronto':   _TZone(id: 'EDT', name: 'EDT – Toronto',   offsetHours: -4, flag: '🇨🇦'),
  'vancouver': _TZone(id: 'PDT', name: 'PDT – Vancouver', offsetHours: -7, flag: '🇨🇦'),

  // Germany — pakai DST (CET+1 winter, CEST+2 summer), pakai UTC+2
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