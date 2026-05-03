// lib/widgets/currency_converter_sheet.dart

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