import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isThinking = false;
  bool _onlineMode = false;
  bool _inputFocused = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // ── Design tokens ─────────────────────────────────────────────────────────
  static const _bg        = Color(0xFF111111);
  static const _card      = Color(0xFF1A1A1A);
  static const _sheet     = Color(0xFF1E1E1E);
  static const _border    = Color(0xFF2A2A2A);
  static const _input     = Color(0xFF222222);
  static const _muted     = Color(0xFF888888);
  static const _dimmed    = Color(0xFF555555);
  static const _green     = Color(0xFF1D9E75);
  static const _greenDark = Color(0xFF085041);
  static const _greenSoft = Color(0xFF9FE1CB);
  static const _red       = Color(0xFFD85A30);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _inputFocus.addListener(() {
      setState(() => _inputFocused = _inputFocus.hasFocus);
    });

    _messages.add({
      "role": "advisor",
      "text":
          "Hey Jay! 👋 I'm your GRAYVAULT financial advisor.\n\nI have full access to your wallet, escrow locks, and transaction history. Ask me anything — or tap ⚡ for quick prompts.",
      "time": _now(),
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  String _now() => DateFormat('HH:mm').format(DateTime.now());

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? override]) async {
    final text = (override ?? _inputController.text).trim();
    if (text.isEmpty || _isThinking) return;

    _inputController.clear();
    setState(() {
      _messages.add({"role": "user", "text": text, "time": _now()});
      _isThinking = true;
    });
    _scrollToBottom();

    try {
      final api = context.read<AuthService>().api;
      final result = await api.askAdvisor(text, onlineMode: _onlineMode);
      final response =
          result["response"] ?? "Sorry, I couldn't generate a response.";
      final poweredBy = result["powered_by"] ?? "";

      setState(() {
        _messages.add({
          "role": "advisor",
          "text": response,
          "time": _now(),
          "powered_by": poweredBy,
        });
        _isThinking = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "advisor",
          "text":
              "Couldn't reach the advisor. Make sure the backend is running.",
          "time": _now(),
          "error": true,
        });
        _isThinking = false;
      });
    }
    _scrollToBottom();
  }

  void _clearChat() {
    setState(() {
      _messages = [
        {
          "role": "advisor",
          "text":
              "Chat cleared. What can I help you with?",
          "time": _now(),
        }
      ];
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isThinking) _buildThinkingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Pulsing orb
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [_green, _greenDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GRAYVAULT Advisor',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isThinking ? 'Thinking...' : (_onlineMode ? '● Live news on' : '● Ready'),
                    key: ValueKey(_isThinking),
                    style: TextStyle(
                      color: _isThinking ? _green : (_onlineMode ? const Color(0xFF378ADD) : _muted),
                      fontSize: 11,
                      fontWeight: _isThinking ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Online mode toggle (compact)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Live', style: TextStyle(color: _muted, fontSize: 11)),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _onlineMode,
                  onChanged: (v) => setState(() => _onlineMode = v),
                  activeColor: _green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),

          // Clear chat
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined,
                color: _muted, size: 20),
            tooltip: 'Clear chat',
            onPressed: _messages.length <= 1 ? null : _clearChat,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildMessage(_messages[i]),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isAdvisor = msg["role"] == "advisor";
    final isError   = msg["error"] == true;
    final poweredBy = msg["powered_by"] as String? ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isAdvisor ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          // Advisor avatar
          if (isAdvisor) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isError
                    ? const LinearGradient(
                        colors: [Color(0xFFD85A30), Color(0xFF8B3820)])
                    : const RadialGradient(
                        colors: [_green, _greenDark]),
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.psychology,
                color: Colors.white, size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble + meta
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAdvisor ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isError
                        ? _red.withOpacity(0.12)
                        : isAdvisor
                            ? _sheet
                            : _greenDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isAdvisor ? 4 : 16),
                      bottomRight: Radius.circular(isAdvisor ? 16 : 4),
                    ),
                    border: isAdvisor
                        ? Border.all(color: isError ? _red.withOpacity(0.3) : _border)
                        : null,
                  ),
                  child: Text(
                    msg["text"] ?? "",
                    style: TextStyle(
                      color: isError ? _red : Colors.white,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Timestamp + powered-by badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isAdvisor)
                      Text(msg["time"] ?? "",
                          style: const TextStyle(color: _dimmed, fontSize: 10)),

                    if (poweredBy.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: poweredBy.contains("Claude")
                              ? _green.withOpacity(0.12)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          poweredBy.contains("Claude") ? "✦ Claude" : "Basic",
                          style: TextStyle(
                            color: poweredBy.contains("Claude")
                                ? _green
                                : _muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],

                    if (isAdvisor) ...[
                      const SizedBox(width: 6),
                      Text(msg["time"] ?? "",
                          style: const TextStyle(color: _dimmed, fontSize: 10)),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (!isAdvisor) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Thinking indicator ────────────────────────────────────────────────────
  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_green, _greenDark]),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _sheet,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: _border),
            ),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final offset = sin(
                    (_waveController.value - i * 0.28) * 2 * pi,
                  ).clamp(-1.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Transform.translate(
                      offset: Offset(0, -5 * offset),
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: _green, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Quick prompts button
          GestureDetector(
            onTap: _showQuickPrompts,
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: _green, size: 19),
            ),
          ),
          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _input,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _inputFocused ? _green : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Ask your advisor...',
                  hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 14),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _isThinking ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _isThinking ? const Color(0xFF2A2A2A) : _green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _isThinking ? _muted : Colors.white,
                size: 19,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick prompts sheet ───────────────────────────────────────────────────
  void _showQuickPrompts() {
    final prompts = [
      ("📊", "Analyze my spending"),
      ("💰", "How is my savings rate?"),
      ("🧠", "What should I do with my money?"),
      ("🔒", "Show my escrow locks"),
      ("💵", "How much do I have?"),
      ("💡", "Give me financial advice"),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.bolt, color: _green, size: 17),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Prompts',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    Text('Tap to ask instantly',
                        style: TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Prompt chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prompts.map((p) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(p.$2);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _green.withOpacity(0.25)),
                    ),
                    child: Text(
                      '${p.$1}  ${p.$2}',
                      style: const TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
