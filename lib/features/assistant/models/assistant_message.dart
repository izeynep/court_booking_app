class AssistantMessage {
  const AssistantMessage({
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  final String content;
  final bool isUser;
  final DateTime createdAt;

  factory AssistantMessage.user(String content) {
    return AssistantMessage(
      content: content,
      isUser: true,
      createdAt: DateTime.now(),
    );
  }

  factory AssistantMessage.assistant({
    required String content,
    DateTime? createdAt,
  }) {
    return AssistantMessage(
      content: content,
      isUser: false,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
