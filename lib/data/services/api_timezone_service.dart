// lib/data/services/api_timezone_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_keys.dart';

// ─── MODEL CLASSES ───────────────────────────────────────────────────────────

class TimezoneResult {
  final String timezone;
  final int utcOffsetMinutes;
  final String source; // 'api' atau 'static'

  TimezoneResult({
    required this.timezone,
    required this.utcOffsetMinutes,
    required this.source,
  });

  String get utcOffsetLabel {
    final sign = utcOffsetMinutes >= 0 ? '+' : '-';
    final abs = utcOffsetMinutes.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }
}

class TimeOfDaySimple {
  final int hour;
  final int minute;
  const TimeOfDaySimple({required this.hour, required this.minute});

  String format12h() {
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${h12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
  }
}

class TimezoneConversionResult {
  final TimeOfDaySimple sourceTime;
  final String fromTimezone;
  final String toTimezone;
  final String fromOffset;
  final String toOffset;
  final String fromSource;
  final String toSource;
  final int targetHour;
  final int targetMinute;
  final int diffMinutes;

  TimezoneConversionResult({
    required this.sourceTime,
    required this.fromTimezone,
    required this.toTimezone,
    required this.fromOffset,
    required this.toOffset,
    required this.fromSource,
    required this.toSource,
    required this.targetHour,
    required this.targetMinute,
    required this.diffMinutes,
  });

  String get targetFormatted {
    final h12 = targetHour == 0 ? 12 : (targetHour > 12 ? targetHour - 12 : targetHour);
    return '${h12.toString().padLeft(2, '0')}:${targetMinute.toString().padLeft(2, '0')} ${targetHour < 12 ? 'AM' : 'PM'}';
  }

  String get diffLabel {
    if (diffMinutes == 0) return 'Sama';
    final sign = diffMinutes > 0 ? '+' : '';
    final abs = diffMinutes.abs();
    if (abs % 60 == 0) return '$sign${diffMinutes ~/ 60} jam';
    return '$sign${diffMinutes ~/ 60}j ${abs % 60}m';
  }

  String get dataSourceLabel {
    if (fromSource == toSource) {
      return fromSource == 'api' ? 'Data real-time via RapidAPI' : 'Data offset statis';
    }
    final fromLabel = fromSource == 'api' ? 'real-time' : 'statis';
    final toLabel = toSource == 'api' ? 'real-time' : 'statis';
    return 'Sumber: $fromLabel → $toLabel';
  }
}

class _TZCacheEntry {
  final TimezoneResult result;
  final DateTime timestamp;
  _TZCacheEntry({required this.result, required this.timestamp});
}

// ─── DATA FALLBACK STATIS ────────────────────────────────────────────────────

const Map<String, int> _staticOffsets = {
  'Asia/Jakarta':        420,   // UTC+7
  'Asia/Makassar':       480,   // UTC+8
  'Asia/Jayapura':       540,   // UTC+9
  'Europe/London':       0,     
  'Asia/Singapore':      480,
  'Asia/Kuala_Lumpur':   480,
  'Asia/Tokyo':          540,
  'Asia/Seoul':          540,
  'Asia/Shanghai':       480,
  'Asia/Hong_Kong':      480,
  'Asia/Taipei':         480,
  'Asia/Kolkata':          330,
  'Asia/Dubai':          240,
  'Asia/Riyadh':         180,
  'Asia/Bangkok':        420,
  'Asia/Ho_Chi_Minh':    420,
  'Asia/Manila':         480,
  'Australia/Sydney':    600,
  'Australia/Melbourne': 600,
  'Australia/Brisbane':  600,
  'Australia/Perth':     480,
  'Australia/Adelaide':  570,
  'Australia/Darwin':    570,
  'Australia/Hobart':    600,
  'Pacific/Auckland':    720,
  'Europe/Paris':        60,
  'Europe/Berlin':       60,
  'Europe/Amsterdam':    60,
  'Europe/Moscow':       180,
  'America/New_York':   -300,
  'America/Chicago':    -360,
  'America/Denver':     -420,
  'America/Los_Angeles':-480,
  'America/Toronto':    -300,
  'America/Edmonton':   -420,
  'America/Winnipeg':   -360,
  'America/Vancouver':  -480,
  'America/Sao_Paulo':  -180,
  'Africa/Johannesburg': 120,
};

// ─── SERVICE ─────────────────────────────────────────────────────────────────

class ApiTimezoneService {
  // Base URL diubah ke endpoint timezone RapidAPI
  static const String _baseUrl = 'https://world-time-api3.p.rapidapi.com/timezone/';
  
  static final Map<String, _TZCacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  Future<TimezoneResult> fetchTime(String timezoneString) async {
    final cached = _cache[timezoneString];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < _cacheDuration) {
      return cached.result;
    }

    return _fetchFromRapidApi(timezoneString);
  }

  Future<TimezoneResult> _fetchFromRapidApi(String tz) async {
    try {
      final url = Uri.parse('$_baseUrl$tz');
      
      // Mengirimkan request dengan Header autentikasi dari RapidAPI Anda
      final response = await http.get(
        url, 
        headers: {
          'Content-Type': 'application/json',
          'x-rapidapi-host': '${ApiKeys.rapidApiHost}',
          'x-rapidapi-key': '${ApiKeys.rapidApiKey}',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Mengambil string offset (contoh: "+07:00")
        final offsetStr = data['utc_offset'] as String? ?? '+00:00';
        final offset = _parseOffsetString(offsetStr) ?? 0;

        debugPrint('[RapidAPI SUCCESS] $tz → ${offset}min');
        return _cacheAndReturn(tz, offset, 'api');
      } else {
        debugPrint('[RapidAPI ERROR] Code: ${response.statusCode} → Pakai fallback statis');
        return _fromStatic(tz);
      }
    } catch (e) {
      debugPrint('[RapidAPI FAILED] Gagal koneksi ($e) → Pakai fallback statis');
      return _fromStatic(tz);
    }
  }

  TimezoneResult _fromStatic(String tz) {
    final offset = _staticOffsets[tz] ?? 0;
    debugPrint('[TZ Static Fallback Used] $tz → ${offset}min');
    return _cacheAndReturn(tz, offset, 'static');
  }

  TimezoneResult _cacheAndReturn(String tz, int offsetMinutes, String source) {
    final result = TimezoneResult(
      timezone: tz,
      utcOffsetMinutes: offsetMinutes,
      source: source,
    );
    _cache[tz] = _TZCacheEntry(result: result, timestamp: DateTime.now());
    return result;
  }

  static int? _parseOffsetString(String raw) {
    try {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed == 'Z') return 0;
      final sign = trimmed.startsWith('-') ? -1 : 1;
      final clean = trimmed.replaceAll(RegExp(r'[+\-]'), '');
      final parts = clean.split(':');
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return sign * (hours * 60 + minutes);
    } catch (_) {
      return null;
    }
  }

  Future<TimezoneConversionResult> convert({
    required TimeOfDaySimple sourceTime,
    required String fromTimezone,
    required String toTimezone,
  }) async {
    final results = await Future.wait([
      fetchTime(fromTimezone),
      fetchTime(toTimezone),
    ]);

    final fromResult = results[0];
    final toResult = results[1];

    final diffMinutes = toResult.utcOffsetMinutes - fromResult.utcOffsetMinutes;
    final sourceTotal = sourceTime.hour * 60 + sourceTime.minute;
    final targetTotal = ((sourceTotal + diffMinutes) % 1440 + 1440) % 1440;

    return TimezoneConversionResult(
      sourceTime: sourceTime,
      fromTimezone: fromTimezone,
      toTimezone: toTimezone,
      fromOffset: fromResult.utcOffsetLabel,
      toOffset: toResult.utcOffsetLabel,
      fromSource: fromResult.source,
      toSource: toResult.source,
      targetHour: targetTotal ~/ 60,
      targetMinute: targetTotal % 60,
      diffMinutes: diffMinutes,
    );
  }
}