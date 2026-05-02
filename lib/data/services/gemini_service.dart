// lib/data/services/gemini_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_keys.dart';

class ChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toGeminiPart() {
    return {
      'role': role,
      'parts': [
        {'text': text}
      ],
    };
  }
}

class GeminiService {
  static const String _baseUrl =
'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const String _systemPrompt = '''
Kamu adalah **CareerBot AI**, asisten karir profesional dalam aplikasi pencari kerja.

Kemampuan utamamu:
1. Review CV/Resume
2. Persiapan Interview
3. Analisis Lowongan
4. Pengembangan Karir
5. Negosiasi Gaji
6. Cover Letter

Panduan:
- Gunakan Bahasa Indonesia yang profesional namun ramah
- Jawaban terstruktur dengan poin-poin jelas
- Sertakan contoh konkret jika relevan
- Fokus pada topik pekerjaan dan pengembangan profesional
''';

  final List<ChatMessage> _history = [];

  // ─────────────────────────────────────────────
  // RATE LIMIT CONFIG
  // ─────────────────────────────────────────────

  DateTime? _lastRequestTime;

  // Delay minimal antar request
  static const int _minIntervalMs = 8000;

  // Retry cukup 1x saja
  static const int _maxRetries = 1;

  List<ChatMessage> get history => List.unmodifiable(_history);

  // ─────────────────────────────────────────────
  // SEND MESSAGE
  // ─────────────────────────────────────────────

  Future<String> sendMessage(String userMessage) async {
    final trimmed = userMessage.trim();

    if (trimmed.isEmpty) {
      throw Exception('Pesan kosong.');
    }

    // throttle supaya tidak spam request
    await _throttle();

    // simpan pesan user
    _history.add(
      ChatMessage(
        role: 'user',
        text: trimmed,
      ),
    );

    for (int attempt = 0; attempt < _maxRetries; ) {
      try {
        final result = await _doRequest();

        // simpan jawaban AI
        _history.add(
          ChatMessage(
            role: 'model',
            text: result,
          ),
        );

        return result;
      } on _RateLimitException {
        // hapus pesan user kalau gagal
        _history.removeLast();

        throw Exception(
          'Terlalu banyak permintaan.\n'
          'Tunggu 10-20 detik lalu coba lagi.',
        );
      } catch (e) {
        // rollback history kalau error
        _history.removeLast();

        throw Exception(
          e.toString().replaceAll('Exception: ', ''),
        );
      }
    }

    // fallback
    _history.removeLast();

    throw Exception('Gagal mengirim pesan.');
  }

  // ─────────────────────────────────────────────
  // THROTTLE
  // ─────────────────────────────────────────────

  Future<void> _throttle() async {
    if (_lastRequestTime != null) {
      final elapsed =
          DateTime.now().difference(_lastRequestTime!).inMilliseconds;

      if (elapsed < _minIntervalMs) {
        await Future.delayed(
          Duration(milliseconds: _minIntervalMs - elapsed),
        );
      }
    }

    _lastRequestTime = DateTime.now();
  }

  // ─────────────────────────────────────────────
  // REQUEST GEMINI
  // ─────────────────────────────────────────────

  Future<String> _doRequest() async {
    final url = Uri.parse(
      '$_baseUrl?key=${ApiKeys.geminiApiKey}',
    );

    // ambil 10 chat terakhir saja
    final recentHistory = _history.takeLast(10);

    final contents = recentHistory
        .map((message) => message.toGeminiPart())
        .toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': _systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    });

    print('==============================');
    print('REQUEST GEMINI');
    print(DateTime.now());
    print('History sent: ${contents.length}');
    print('==============================');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(
          const Duration(seconds: 30),
        );

    print('STATUS CODE: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body);

        final candidates = data['candidates'] as List?;

        if (candidates == null || candidates.isEmpty) {
          throw Exception('Tidak ada respons dari AI.');
        }

        final content = candidates[0]['content'];

        if (content == null) {
          throw Exception('Content AI kosong.');
        }

        final parts = content['parts'] as List?;

        if (parts == null || parts.isEmpty) {
          throw Exception('Respons AI kosong.');
        }

        final text = parts[0]['text'];

        if (text == null || text.toString().trim().isEmpty) {
          throw Exception('AI tidak memberikan jawaban.');
        }

        return text.toString();

      case 400:
        throw Exception(
          'API Key tidak valid.\n'
          'Periksa api_keys.dart',
        );

      case 429:
        throw _RateLimitException();

      case 500:
        throw Exception(
          'Server Gemini sedang bermasalah.\n'
          'Coba lagi beberapa saat.',
        );

      default:
        try {
          final err = jsonDecode(response.body);

          throw Exception(
            err['error']?['message'] ??
                'Terjadi kesalahan server.',
          );
        } catch (_) {
          throw Exception(
            'Error server (${response.statusCode})',
          );
        }
    }
  }

  // ─────────────────────────────────────────────
  // RESET CHAT
  // ─────────────────────────────────────────────

  void resetConversation() {
    _history.clear();
    _lastRequestTime = null;
  }

  // ─────────────────────────────────────────────
  // QUICK PROMPTS
  // ─────────────────────────────────────────────

  static List<String> getQuickPrompts() {
    return [
      '🎯 Tips interview kerja',
      '💡 Skill untuk Software Engineer',
      '💰 Cara negosiasi gaji',
        '🚀 Rekomendasi karir untuk fresh graduate',
        '🎯 Tips interview kerja',
    ];
  }
}

// ─────────────────────────────────────────────
// EXTENSION
// ─────────────────────────────────────────────

extension TakeLastExtension<E> on List<E> {
  List<E> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}

// ─────────────────────────────────────────────
// RATE LIMIT EXCEPTION
// ─────────────────────────────────────────────

class _RateLimitException implements Exception {}