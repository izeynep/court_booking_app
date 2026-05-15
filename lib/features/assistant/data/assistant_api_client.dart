import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:court_booking_app/features/assistant/models/assistant_message.dart';

class AssistantApiException implements Exception {}

class AssistantApiClient {
  AssistantApiClient({
    http.Client? client,
    Uri? endpoint,
  })  : _client = client ?? http.Client(),
        endpoint = endpoint ??
            Uri.parse('http://10.0.2.2:3000/v1/assistant/chat');

  final http.Client _client;
  final Uri endpoint;

  Future<AssistantMessage> sendHomeMessage({
    required String message,
    required String firebaseIdToken,
  }) async {
    final response = await _client.post(
      endpoint,
      headers: {
        'Authorization': 'Bearer $firebaseIdToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': message,
        'conversationId': null,
        'context': {
          'screen': 'home',
          'locale': 'tr-TR',
          'timezone': 'Europe/Istanbul',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw AssistantApiException();
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final messageJson = json['message'] as Map<String, dynamic>;
      final content = messageJson['content'] as String;
      final createdAtText = messageJson['createdAt'] as String?;

      return AssistantMessage.assistant(
        content: content,
        createdAt: createdAtText == null
            ? null
            : DateTime.tryParse(createdAtText),
      );
    } catch (_) {
      throw AssistantApiException();
    }
  }

  void close() {
    _client.close();
  }
}
