import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:court_booking_app/features/assistant/data/assistant_api_client.dart';
import 'package:court_booking_app/features/assistant/data/assistant_repository.dart';
import 'package:court_booking_app/features/assistant/models/assistant_message.dart';
import 'package:court_booking_app/features/assistant/models/assistant_state.dart';

class AssistantChatController extends ChangeNotifier {
  AssistantChatController({
    AssistantRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? AssistantRepository(),
        _auth = auth ?? FirebaseAuth.instance {
    if (!_isLoggedIn) {
      _state = const AssistantChatState(
        status: AssistantChatStatus.unauthenticated,
      );
    }
  }

  final AssistantRepository _repository;
  final FirebaseAuth _auth;

  final messages = <AssistantMessage>[
    AssistantMessage.assistant(
      content: 'Selam! Bugunku kort ritmini birlikte ayarlayalim.',
    ),
  ];

  AssistantChatState _state = AssistantChatState.idle;
  bool _isDisposed = false;

  AssistantChatState get state => _state;
  bool get _isLoggedIn => _auth.currentUser != null;

  void _updateState(AssistantChatState state) {
    if (_isDisposed) return;
    _state = state;
    notifyListeners();
  }

  void _addMessage(AssistantMessage message) {
    if (_isDisposed) return;
    messages.add(message);
  }

  Future<void> sendMessage(String text) async {
    final message = text.trim();
    if (message.isEmpty || _state.isSending || _isDisposed) return;

    if (!_isLoggedIn) {
      _updateState(
        const AssistantChatState(
          status: AssistantChatStatus.unauthenticated,
          errorText: 'Asistanla konusmak icin giris yapmalisin.',
        ),
      );
      return;
    }

    _addMessage(AssistantMessage.user(message));
    _updateState(const AssistantChatState(status: AssistantChatStatus.sending));

    try {
      final reply = await _repository.sendHomeMessage(message);
      if (_isDisposed) return;
      _addMessage(reply);
      _updateState(AssistantChatState.idle);
    } on AssistantNotLoggedInException {
      _updateState(
        const AssistantChatState(
          status: AssistantChatStatus.unauthenticated,
          errorText: 'Asistanla konusmak icin giris yapmalisin.',
        ),
      );
    } on AssistantApiException {
      _updateState(
        const AssistantChatState(
          status: AssistantChatStatus.error,
          errorText: 'Asistana su an ulasilamiyor. Birazdan tekrar dene.',
        ),
      );
    } catch (_) {
      _updateState(
        const AssistantChatState(
          status: AssistantChatStatus.error,
          errorText: 'Bir sey ters gitti. Birazdan tekrar dene.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.close();
    super.dispose();
  }
}
