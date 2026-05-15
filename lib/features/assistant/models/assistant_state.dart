enum AssistantChatStatus {
  idle,
  sending,
  error,
  unauthenticated,
}

class AssistantChatState {
  const AssistantChatState({
    required this.status,
    this.errorText,
  });

  final AssistantChatStatus status;
  final String? errorText;

  bool get isSending => status == AssistantChatStatus.sending;
  bool get hasError => errorText != null && errorText!.isNotEmpty;
  bool get isUnauthenticated => status == AssistantChatStatus.unauthenticated;

  AssistantChatState copyWith({
    AssistantChatStatus? status,
    String? errorText,
    bool clearError = false,
  }) {
    return AssistantChatState(
      status: status ?? this.status,
      errorText: clearError ? null : errorText ?? this.errorText,
    );
  }

  static const idle = AssistantChatState(status: AssistantChatStatus.idle);
}
