import 'package:firebase_auth/firebase_auth.dart';

import 'package:court_booking_app/features/assistant/data/assistant_api_client.dart';
import 'package:court_booking_app/features/assistant/models/assistant_message.dart';

class AssistantNotLoggedInException implements Exception {}

class AssistantRepository {
  AssistantRepository({
    FirebaseAuth? auth,
    AssistantApiClient? apiClient,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _apiClient = apiClient ?? AssistantApiClient();

  final FirebaseAuth _auth;
  final AssistantApiClient _apiClient;

  Future<AssistantMessage> sendHomeMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AssistantNotLoggedInException();
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw AssistantNotLoggedInException();
    }

    return _apiClient.sendHomeMessage(
      message: message,
      firebaseIdToken: token,
    );
  }

  void close() {
    _apiClient.close();
  }
}
