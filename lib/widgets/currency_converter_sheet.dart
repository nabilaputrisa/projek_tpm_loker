import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/api_kurs_service.dart';

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
      text: widget.initialAmount > 0 ? widget.initialAmount.toStringAsFixed(0) : '',
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

  void _openCurrencyPicker(BuildContext context, ColorScheme cs) {
    _searchController.clear();
    List<String> filtered = List.from(_allCurrencies);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Pilih Mata Uang Tujuan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_allCurrencies.length} mata uang',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Cari kode (misal: USD, EUR, JPY...)',
                    hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18, color: cs.onSurfaceVariant),
                            onPressed: () {
                              _searchController.clear();
                              setModal(() => filtered = List.from(_allCurrencies));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    final q = val.toUpperCase().trim();
                    setModal(() {
                      filtered = q.isEmpty
                          ? List.from(_allCurrencies)
                          : _allCurrencies.where((c) => c.contains(q)).toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('Mata uang tidak ditemukan', style: TextStyle(color: cs.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final code = filtered[i];
                          final isSelected = code == _toCurrency;
                          final isSource = code == widget.fromCurrency;
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: isSelected ? cs.primary.withOpacity(0.08) : null,
                            leading: Text(_flagOf(code), style: const TextStyle(fontSize: 22)),
                            title: Text(
                              code,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? cs.primary : cs.onSurface,
                              ),
                            ),
                            subtitle: isSource
                                ? Text('Mata uang loker ini', style: TextStyle(fontSize: 11, color: cs.primary))
                                : null,
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: cs.primary)
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
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
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
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.currency_exchange_rounded, color: cs.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konversi Mata Uang',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Kurs real-time · Dari ${widget.fromCurrency}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Text('Jumlah:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Text(
                        '${_flagOf(widget.fromCurrency)} ${widget.fromCurrency}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cs.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: (_) => setState(() => _result = null),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Text('Ke mata uang:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  if (_loadingCurrencies)
                    _buildLoadingBox(cs)
                  else if (_listError != null)
                    _buildErrorBox(cs)
                  else
                    _buildCurrencyDropdown(cs, context),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_converting || _loadingCurrencies) ? null : _convert,
                      icon: _converting
                          ? SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                            )
                          : Icon(Icons.swap_horiz_rounded, color: cs.onPrimary),
                      label: Text(
                        _converting ? 'Mengambil kurs...' : 'Konversi',
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
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
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.error.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: cs.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: TextStyle(color: cs.onErrorContainer, fontSize: 13)),
                        ),
                      ]),
                    ),
                  if (_result != null) _buildResultCard(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBox(ColorScheme cs) => Container(
        height: 56,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            ),
            const SizedBox(width: 10),
            Text('Memuat daftar mata uang...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ]),
        ),
      );

  Widget _buildErrorBox(ColorScheme cs) => GestureDetector(
        onTap: _loadCurrencyList,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.error.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.refresh_rounded, color: cs.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$_listError\nKetuk untuk coba lagi.',
                style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
              ),
            ),
          ]),
        ),
      );

  Widget _buildCurrencyDropdown(ColorScheme cs, BuildContext context) => GestureDetector(
        onTap: () => _openCurrencyPicker(context, cs),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(children: [
            Text(_flagOf(_toCurrency), style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_toCurrency, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: cs.primary),
          ]),
        ),
      );

  Widget _buildResultCard(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            '${_amountController.text} ${widget.fromCurrency} =',
            style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmt(_result!)} $_toCurrency',
            style: TextStyle(color: cs.onPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_rate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1 ${widget.fromCurrency} = ${_fmt(_rate!)} $_toCurrency',
                style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 12),
              ),
            ),
        ]),
      );
}