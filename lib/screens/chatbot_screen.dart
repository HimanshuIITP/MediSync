// lib/screens/chatbot_screen.dart
// Feature D: AI Medical Chatbot – powered by Google Gemini API.
// Supports real multi-turn conversations about symptoms, medications, health advice.

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ⚠️  PASTE YOUR GEMINI API KEY BELOW (same key as analyzer_screen.dart)
//     Get it free at: https://aistudio.google.com → Get API Key
// ─────────────────────────────────────────────────────────────────────────────
const String _geminiApiKey = 'AIzaSyDFRLOua3kIgdsh_KmPFaMmAb8w_UBaunI';

// System prompt that makes Gemini behave as a medical assistant
const String _systemPrompt = '''
You are MedBot, a compassionate and knowledgeable AI medical assistant built into the MedAssist app.

Your role:
- Help patients understand their symptoms and get basic health guidance
- Suggest safe over-the-counter medications with appropriate dosages based on age and weight when relevant
- Explain medical terms in simple, easy-to-understand language
- Help patients decide if they need to see a doctor urgently
- Provide general wellness, nutrition, and lifestyle advice
- Answer questions about medications, side effects, and interactions

Your personality:
- Warm, empathetic, and reassuring
- Clear and concise — avoid medical jargon unless explained
- Always responsible — never replace professional medical advice

Critical rules you MUST always follow:
1. Always remind users that your advice does not replace a real doctor's diagnosis
2. For any symptoms that sound serious (chest pain, difficulty breathing, stroke signs, severe bleeding, high fever in infants) — immediately urge them to call emergency services or go to the ER
3. Never diagnose diseases definitively — say "this may indicate" or "this could be consistent with"
4. For medication dosages, always factor in age and weight if the user mentions them
5. Keep responses concise and well-structured — use bullet points where helpful
6. If someone seems distressed or mentions self-harm, respond with empathy and provide crisis helpline information
7. You can discuss sensitive health topics (mental health, reproductive health, etc.) professionally and without judgment

Format your responses clearly. Use **bold** for important terms. Use bullet points (•) for lists.
Keep responses focused and not overly long — aim for 150-250 words unless a detailed explanation is needed.
''';

// ── Message model ─────────────────────────────────────────────────────────────
enum _Sender { user, bot }

class _ChatMessage {
  final String   text;
  final _Sender  sender;
  final DateTime time;
  final bool     isError;

  _ChatMessage({
    required this.text,
    required this.sender,
    this.isError = false,
  }) : time = DateTime.now();
}

// ── Main Screen ───────────────────────────────────────────────────────────────
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _msgController    = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  bool _isBotTyping = false;
  bool _apiKeyMissing = false;

  // Gemini chat session — maintains conversation history automatically
  ChatSession? _chatSession;
  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Initialize Gemini with system prompt ───────────────────────────────────
  void _initGemini() {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      setState(() => _apiKeyMissing = true);
      _addBotMessageSync(
        '⚠️ API key not configured. Please add your Gemini API key in chatbot_screen.dart\n\n'
        'Get a free key at: https://aistudio.google.com',
        isError: true,
      );
      return;
    }

    _model = GenerativeModel(
      model:  'gemini-2.5-flash', // Flash is faster and cheaper for chat
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature:     0.7,
        maxOutputTokens: 1024,
      ),
    );

    _chatSession = _model!.startChat();

    // Welcome message
    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcomeMessage());
  }

  // ── Welcome message ────────────────────────────────────────────────────────
  Future<void> _addWelcomeMessage() async {
    final user = AuthService().currentUser;
    final name = user?.name.split(' ').first ?? 'there';

    await _addBotMessage(
      '👋 Hello, $name! I\'m **MedBot**, your AI health assistant.\n\n'
      'I can help you with:\n'
      '• Understanding symptoms\n'
      '• Safe medication guidance\n'
      '• General health & wellness advice\n'
      '• Deciding if you need to see a doctor\n\n'
      'What\'s on your mind today?',
      delayMs: 300,
    );
  }

  // ── Add bot message with typing delay ─────────────────────────────────────
  Future<void> _addBotMessage(String text,
      {int delayMs = 800, bool isError = false}) async {
    setState(() => _isBotTyping = true);
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!mounted) return;
    setState(() {
      _isBotTyping = false;
      _messages.add(_ChatMessage(text: text, sender: _Sender.bot, isError: isError));
    });
    _scrollToBottom();
  }

  // Instant version for init (no async needed)
  void _addBotMessageSync(String text, {bool isError = false}) {
    _messages.add(_ChatMessage(text: text, sender: _Sender.bot, isError: isError));
  }

  // ── Send message to Gemini ─────────────────────────────────────────────────
  Future<void> _sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || _isBotTyping || _apiKeyMissing) return;

    _msgController.clear();

    // Add user message
    setState(() {
      _messages.add(_ChatMessage(text: trimmed, sender: _Sender.user));
      _isBotTyping = true;
    });
    _scrollToBottom();

    try {
      // Send to Gemini — chat session automatically includes history
      final response = await _chatSession!.sendMessage(
        Content.text(trimmed),
      );

      final text = response.text ?? '';
      if (!mounted) return;

      setState(() {
        _isBotTyping = false;
        _messages.add(_ChatMessage(text: text, sender: _Sender.bot));
      });
      _scrollToBottom();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBotTyping = false;
        _messages.add(_ChatMessage(
          text:    _friendlyError(e.toString()),
          sender:  _Sender.bot,
          isError: true,
        ));
      });
      _scrollToBottom();
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('API_KEY') || raw.contains('api key')) {
      return '❌ Invalid API key. Please check your Gemini API key.';
    }
    if (raw.contains('quota') || raw.contains('RESOURCE_EXHAUSTED')) {
      return '⏳ Too many requests. Please wait a moment and try again.';
    }
    if (raw.contains('network') || raw.contains('SocketException')) {
      return '📶 No internet connection. Please check your network and try again.';
    }
    return '❌ Something went wrong. Please try again.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  // ── Restart conversation ───────────────────────────────────────────────────
  void _restart() {
    setState(() {
      _messages.clear();
      // Start a fresh chat session (clears Gemini history too)
      if (_model != null) {
        _chatSession = _model!.startChat();
      }
    });
    _addWelcomeMessage();
  }

  // ── Quick suggestion chips ─────────────────────────────────────────────────
  static const List<String> _suggestions = [
    'I have a headache 🤕',
    'I have a fever 🌡️',
    'I feel anxious 😟',
    'Is my BP reading normal? 💓',
    'What are symptoms of diabetes?',
    'I have a cold & sore throat',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MedBot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('AI Health Assistant',
                  style: TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ]),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'New conversation',
            onPressed: _restart,
          ),
        ],
      ),
      body: Column(children: [
        // Warning banner
        const _WarningBanner(),

        // Quick suggestions (only shown when conversation just started)
        if (_messages.length <= 1 && !_isBotTyping)
          _SuggestionChips(
            suggestions: _suggestions,
            onTap:       _sendMessage,
          ),

        // Messages
        Expanded(
          child: _messages.isEmpty && !_isBotTyping
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryTeal))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length && _isBotTyping) {
                      return const _TypingIndicator();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
        ),

        // Input bar
        _InputBar(
          controller: _msgController,
          onSend:     _sendMessage,
          enabled:    !_isBotTyping && !_apiKeyMissing,
        ),
      ]),
    );
  }
}

// ── Warning Banner ────────────────────────────────────────────────────────────
class _WarningBanner extends StatelessWidget {
  const _WarningBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color:   const Color(0xFFFFF3E0),
      child: Row(children: [
        const Icon(Icons.emergency, color: AppTheme.warning, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'For emergencies call 112. This AI does not replace a doctor.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      const Color(0xFFE65100),
          ),
        )),
      ]),
    );
  }
}

// ── Suggestion Chips ──────────────────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final List<String>       suggestions;
  final void Function(String) onTap;

  const _SuggestionChips({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text('Quick questions:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11, color: AppTheme.textLight,
                  fontWeight: FontWeight.w600)),
        ),
        Wrap(spacing: 8, runSpacing: 6,
          children: suggestions.map((s) => GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        AppTheme.accentMint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
              ),
              child: Text(s, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppTheme.primaryDark)),
            ),
          )).toList(),
        ),
      ]),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  bool get _isUser => message.sender == _Sender.user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: message.isError
                    ? AppTheme.error
                    : AppTheme.primaryTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy,
                size: 18, color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                color: _isUser
                    ? AppTheme.primaryTeal
                    : message.isError
                        ? AppTheme.error.withValues(alpha: 0.08)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(_isUser ? 18 : 4),
                  bottomRight: Radius.circular(_isUser ? 4  : 18),
                ),
                border: message.isError
                    ? Border.all(color: AppTheme.error.withValues(alpha: 0.3))
                    : null,
                boxShadow: [BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RichText(text: message.text, isUser: _isUser,
                      isError: message.isError),
                  const SizedBox(height: 4),
                  Text(
                    '${message.time.hour}:'
                    '${message.time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: _isUser
                          ? Colors.white60
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Rich text renderer (handles **bold** markdown) ────────────────────────────
class _RichText extends StatelessWidget {
  final String text;
  final bool   isUser;
  final bool   isError;
  const _RichText({required this.text, required this.isUser, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final baseColor = isUser
        ? Colors.white
        : isError
            ? AppTheme.error
            : AppTheme.textDark;

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int   last  = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text:  text.substring(last, match.start),
          style: TextStyle(color: baseColor, fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text:  match.group(1),
        style: TextStyle(color: baseColor, fontSize: 14,
            fontWeight: FontWeight.w800, height: 1.5),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text:  text.substring(last),
        style: TextStyle(color: baseColor, fontSize: 14, height: 1.5),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
              color: AppTheme.primaryTeal, shape: BoxShape.circle),
          child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(18),
              topRight:    Radius.circular(18),
              bottomLeft:  Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => Row(
              children: List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: (_anim.value - i * 0.15).clamp(0.2, 1.0),
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal, shape: BoxShape.circle),
                  ),
                ),
              )),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool                  enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left:   16,
        right:  8,
        top:    10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color:      Colors.black.withValues(alpha: 0.07),
            blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller:      controller,
              enabled:         enabled,
              textInputAction: TextInputAction.send,
              onSubmitted:     enabled ? onSend : null,
              maxLines:        3,
              minLines:        1,
              decoration: InputDecoration(
                hintText: enabled
                    ? 'Ask about symptoms, medications…'
                    : 'MedBot is thinking…',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                fillColor: AppTheme.scaffoldBg,
                filled:    true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: enabled ? AppTheme.primaryTeal : AppTheme.textLight,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon:      const Icon(Icons.send_rounded,
                  color: Colors.white, size: 22),
              onPressed: enabled ? () => onSend(controller.text) : null,
            ),
          ),
        ]),
      ),
    );
  }
}