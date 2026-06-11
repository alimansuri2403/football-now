import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

class ChatMessage {
  final String user;
  final String text;
  final DateTime time;
  final String? emoji;

  ChatMessage({
    required this.user,
    required this.text,
    required this.time,
    this.emoji,
  });
}

class FanChatScreen extends StatefulWidget {
  final String matchId;
  final String matchTitle;

  const FanChatScreen({
    super.key,
    required this.matchId,
    required this.matchTitle,
  });

  @override
  State<FanChatScreen> createState() => _FanChatScreenState();
}

class _FanChatScreenState extends State<FanChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _username;

  @override
  void initState() {
    super.initState();
    // Generate random username
    final rand = math.Random().nextInt(9000) + 1000;
    _username = 'Fan$rand';

    // Prepopulate 5 mock messages
    _messages.addAll([
      ChatMessage(
        user: 'GoalMachine99',
        text: 'Can\'t wait for this match! ⚽ Let\'s go!',
        time: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        user: 'FootballFan23',
        text: 'Argentina all the way! 🇦🇷 Messi is ready.',
        time: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      ChatMessage(
        user: 'WCViewer',
        text: 'This is going to be epic 🔥',
        time: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      ChatMessage(
        user: 'TacticsGuru',
        text: 'I think we\'ll see a high-pressing game from the start.',
        time: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
      ChatMessage(
        user: 'StadiumLive',
        text: 'Atmosphere here in the stands is unbelievable! 🤩 Stadium is packed!',
        time: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) {
    final msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          user: _username,
          text: msgText,
          time: DateTime.now(),
        ),
      );
    });

    if (text == null) {
      _controller.clear();
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.matchTitle,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text(
              'LIVE FAN CHAT',
              style: TextStyle(fontSize: 10, color: AppTheme.liveColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg.user == _username;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              msg.user,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? (isDark ? Colors.black : Colors.white) : null,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Emoji Reaction Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['⚽', '🔥', '❤️', '👏', '😂'].map((emoji) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _sendMessage(emoji),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Text Input Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Say something as $_username...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 22,
                    child: IconButton(
                      icon: Icon(Icons.send, color: isDark ? Colors.black : Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
