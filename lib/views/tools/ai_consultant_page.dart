// lib/views/tools/ai_consultant_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/gemini_service.dart';

// ─── Palet warna biru muda ───────────────────────────────────────────────────
class _C {
  static const primary     = Color(0xFF4A90D9); // biru utama
  //static const primaryDark = Color(0xFF2C6FAD); // biru lebih gelap (teks)
  static const surface     = Color(0xFFF0F7FF); // bg ringan biru
  static const bubble      = Color(0xFFE3F0FB); // bubble AI
  static const userBubble  = Color(0xFF4A90D9); // bubble user
  static const inputBg     = Color(0xFFEAF3FB); // bg input
  static const divider     = Color(0xFFCCE2F5); // garis pemisah
  static const textMain    = Color(0xFF1A3A5C); // teks utama gelap
  static const textMuted   = Color(0xFF6B8FAF); // teks redup
  static const chip        = Color(0xFFD8ECFA); // chip warna
  static const chipText    = Color(0xFF2C6FAD); // teks chip
  static const avatarBg    = Color(0xFF4A90D9); // avatar bot
}

class AiConsultantPage extends StatefulWidget {
  const AiConsultantPage({super.key});

  @override
  State<AiConsultantPage> createState() => _AiConsultantPageState();
}

class _AiConsultantPageState extends State<AiConsultantPage>
    with TickerProviderStateMixin {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _showQuickPrompts = true;
  String? _errorMessage;

  late AnimationController _dotAnimController;
  
  // Cooldown tracking
  DateTime? _lastSentTime;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  static const int _cooldownDuration = 15;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotAnimController.dispose();
    _cooldownTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Cooldown Logic ──────────────────────────────────────────────────────
  void _startCooldown() {
    _lastSentTime = DateTime.now();
    _cooldownSeconds = _cooldownDuration;
    
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(_lastSentTime!).inSeconds;
      final remaining = _cooldownDuration - elapsed;
      
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
          _cooldownTimer = null;
        });
      } else {
        setState(() {
          _cooldownSeconds = remaining;
        });
      }
    });
  }

  bool get _isInCooldown => _cooldownSeconds > 0;

  // ─── Kirim pesan ─────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping || _isInCooldown) return;

    _inputController.clear();
    setState(() {
      _isTyping = true;
      _showQuickPrompts = false;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      await _geminiService.sendMessage(trimmed);
      _startCooldown();
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
        _scrollToBottom(delayed: true);
      }
    }
  }

  void _scrollToBottom({bool delayed = false}) {
    Future.delayed(Duration(milliseconds: delayed ? 300 : 60), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset percakapan?',
            style: TextStyle(color: _C.textMain, fontSize: 16)),
        content: const Text('Semua riwayat chat akan dihapus.',
            style: TextStyle(color: _C.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Batal', style: TextStyle(color: _C.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _geminiService.resetConversation();
                _showQuickPrompts = true;
                _errorMessage = null;
                _cooldownTimer?.cancel();
                _cooldownSeconds = 0;
                _lastSentTime = null;
              });
            },
            child: const Text('Reset',
                style: TextStyle(color: _C.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final messages = _geminiService.history;

    return Scaffold(
      backgroundColor: _C.surface,
      appBar: _buildAppBar(messages.isNotEmpty),
      body: Column(
        children: [
          if (messages.isEmpty) _buildWelcomeBanner(),
          Expanded(
            child: messages.isEmpty && _showQuickPrompts
                ? _buildQuickPromptsView()
                : _buildChatList(messages),
          ),
          if (_errorMessage != null) _buildErrorBanner(),
          if (_isInCooldown) _buildCooldownBanner(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool hasMessages) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.divider),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _C.textMain, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.avatarBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CareerBot AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _C.textMain,
                  )),
              Text(
                _isTyping ? 'mengetik...' : 'Asisten Karir',
                style: TextStyle(
                  fontSize: 11,
                  color: _isTyping ? _C.primary : _C.textMuted,
                  fontWeight:
                      _isTyping ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (hasMessages)
          IconButton(
            onPressed: _resetChat,
            icon: const Icon(Icons.refresh_rounded,
                color: _C.textMuted, size: 20),
            tooltip: 'Reset chat',
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Welcome Banner ───────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.chip,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.waving_hand_rounded,
                color: _C.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo! Saya CareerBot AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _C.textMain,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review CV, tips interview, negosiasi gaji — siap membantu.',
                  style: TextStyle(color: _C.textMuted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Prompts ────────────────────────────────────────────────────────
  Widget _buildQuickPromptsView() {
    final prompts = GeminiService.getQuickPrompts();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      children: [
        const Text('Mulai dengan:',
            style: TextStyle(
                color: _C.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts
              .map((p) => _QuickChip(label: p, onTap: () => _sendMessage(p)))
              .toList(),
        ),
      ],
    );
  }

  // ─── Chat List ────────────────────────────────────────────────────────────
  Widget _buildChatList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == messages.length && _isTyping) {
          return _TypingBubble(animController: _dotAnimController);
        }
        return _ChatBubble(
          message: messages[i],
          onCopy: () {
            Clipboard.setData(ClipboardData(text: messages[i].text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Teks disalin'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  // ─── Error Banner ─────────────────────────────────────────────────────────
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFE53935), size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(
                    color: Color(0xFFC62828), fontSize: 12)),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFFE53935), size: 17),
          ),
        ],
      ),
    );
  }

  // ─── Cooldown Banner ──────────────────────────────────────────────────────
  Widget _buildCooldownBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _C.chip,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _C.primary,
              value: _cooldownSeconds / _cooldownDuration,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tunggu $_cooldownSeconds detik sebelum mengirim pesan lagi',
              style: const TextStyle(
                color: _C.chipText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input Area ───────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 14,
        right: 10,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 22,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 110),
              child: TextField(
                controller: _inputController,
                maxLines: null,
                enabled: !_isTyping && !_isInCooldown,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 14, color: _C.textMain),
                decoration: InputDecoration(
                  hintText: _isInCooldown 
                      ? 'Tunggu $_cooldownSeconds detik...'
                      : 'Tanya seputar karir...',
                  hintStyle:
                      const TextStyle(color: _C.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: _C.inputBg,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _C.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _C.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        const BorderSide(color: _C.primary, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: _C.divider.withOpacity(0.5)),
                  ),
                ),
                onSubmitted: (v) => _sendMessage(v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isTyping
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _C.primary),
                  ),
                )
              : AnimatedBuilder(
                  animation: _inputController,
                  builder: (_, __) {
                    final hasText = _inputController.text.trim().isNotEmpty;
                    final canSend = hasText && !_isInCooldown;
                    
                    return GestureDetector(
                      onTap: canSend
                          ? () => _sendMessage(_inputController.text)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: canSend ? _C.primary : _C.inputBg,
                          shape: BoxShape.circle,
                        ),
                        child: _isInCooldown
                            ? Center(
                                child: Text(
                                  '$_cooldownSeconds',
                                  style: const TextStyle(
                                    color: _C.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: canSend
                                    ? Colors.white
                                    : _C.textMuted,
                              ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onCopy;

  const _ChatBubble({required this.message, required this.onCopy});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin:
          Offset(widget.message.role == 'user' ? 0.15 : -0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  bool get _isUser => widget.message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!_isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6, bottom: 2),
                  decoration: BoxDecoration(
                    color: _C.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: widget.onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: _isUser ? _C.userBubble : _C.bubble,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(_isUser ? 16 : 4),
                        bottomRight: Radius.circular(_isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormattedText(
                          text: widget.message.text,
                          color: _isUser
                              ? Colors.white
                              : _C.textMain,
                          mutedColor: _isUser
                              ? Colors.white70
                              : _C.textMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _fmt(widget.message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: _isUser
                                ? Colors.white54
                                : _C.textMuted,
                          ),
                        ),
                      ],
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

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Formatted Text
// ─────────────────────────────────────────────────────────────────────────────
class _FormattedText extends StatelessWidget {
  final String text;
  final Color color;
  final Color mutedColor;

  const _FormattedText(
      {required this.text, required this.color, required this.mutedColor});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _line(line)).toList(),
    );
  }

  Widget _line(String line) {
    if (line.trim().isEmpty) return const SizedBox(height: 3);

    // Bullet
    if (RegExp(r'^\s*[•\-\*]\s').hasMatch(line)) {
      final content = line.replaceFirst(RegExp(r'^\s*[•\-\*]\s'), '');
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('• ', style: TextStyle(color: color, fontSize: 14)),
          Expanded(child: _rich(content)),
        ]),
      );
    }

    // Numbered
    final nm = RegExp(r'^\s*\d+\.\s').firstMatch(line);
    if (nm != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nm.group(0)!, style: TextStyle(color: color, fontSize: 14)),
          Expanded(
              child:
                  _rich(line.replaceFirst(RegExp(r'^\s*\d+\.\s'), ''))),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: _rich(line),
    );
  }

  Widget _rich(String text) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*');
    int last = 0;

    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(color: color, fontSize: 14, height: 1.45)));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(
            text: m.group(1),
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.45)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(
            text: m.group(2),
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.45)));
      }
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
          text: text.substring(last),
          style: TextStyle(color: color, fontSize: 14, height: 1.45)));
    }
    if (spans.isEmpty) {
      return Text(text,
          style: TextStyle(color: color, fontSize: 14, height: 1.45));
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Typing Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _TypingBubble extends StatelessWidget {
  final AnimationController animController;
  const _TypingBubble({required this.animController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 6, bottom: 2),
            decoration:
                const BoxDecoration(color: _C.avatarBg, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 14),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _C.bubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: animController,
                  builder: (_, __) {
                    final progress =
                        (animController.value - i * 0.15) % 1.0;
                    final opacity =
                        (0.3 + 0.7 * (1 - (progress - 0.5).abs() * 2))
                            .clamp(0.3, 1.0);
                    return Container(
                      margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _C.primary.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Quick Chip
// ─────────────────────────────────────────────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _C.divider),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 13,
              color: _C.chipText,
              fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}