import 'package:flutter/material.dart';

import 'package:court_booking_app/features/assistant/models/assistant_message.dart';
import 'package:court_booking_app/features/assistant/presentation/assistant_chat_controller.dart';
import 'package:court_booking_app/features/assistant/presentation/assistant_mascot.dart';

class AssistantChatSheet extends StatefulWidget {
  const AssistantChatSheet({super.key});

  @override
  State<AssistantChatSheet> createState() => _AssistantChatSheetState();
}

class _AssistantChatSheetState extends State<AssistantChatSheet> {
  late final AssistantChatController _chatController;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatController = AssistantChatController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text;
    _textController.clear();
    _chatController.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _chatController,
      builder: (context, _) {
        final state = _chatController.state;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _AssistantSheetHeader(),
                  const SizedBox(height: 12),
                  if (state.isUnauthenticated) const _NotLoggedInNotice(),
                  if (state.hasError) _ErrorNotice(text: state.errorText!),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount:
                          _chatController.messages.length +
                          (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (state.isSending &&
                            index == _chatController.messages.length) {
                          return const _LoadingBubble();
                        }
                        return _MessageBubble(
                          message: _chatController.messages[index],
                        );
                      },
                    ),
                  ),
                  _Composer(
                    controller: _textController,
                    isEnabled: !state.isSending && !state.isUnauthenticated,
                    isLoading: state.isSending,
                    onSend: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssistantSheetHeader extends StatelessWidget {
  const _AssistantSheetHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AssistantMascot(size: Size(42, 54)),
        SizedBox(width: 10),
        Text(
          'KortSaha Asistani',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF141414),
          ),
        ),
      ],
    );
  }
}

class _NotLoggedInNotice extends StatelessWidget {
  const _NotLoggedInNotice();

  @override
  Widget build(BuildContext context) {
    return const _Notice(
      icon: Icons.lock_outline_rounded,
      text: 'Asistanla konusmak icin once giris yapmalisin.',
      color: Color(0xFF8A6D1D),
      backgroundColor: Color(0xFFFFF7D6),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _Notice(
      icon: Icons.error_outline_rounded,
      text: text,
      color: const Color(0xFF9B2C2C),
      backgroundColor: const Color(0xFFFFE8E8),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final background = message.isUser
        ? const Color(0xFF2D6A4F)
        : const Color(0xFFF4F4F4);
    final textColor = message.isUser ? Colors.white : const Color(0xFF141414);

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isEnabled,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: isEnabled,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: InputDecoration(
              hintText: isEnabled
                  ? 'Kort, etkinlik veya partner sor...'
                  : 'Giris yaptiktan sonra yazabilirsin',
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: isEnabled ? onSend : null,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            disabledBackgroundColor: const Color(0xFFE0E0E0),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
