// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Backend address. For local testing use your laptop's Wi-Fi IPv4 address.
/// Later this will be replaced by the Render HTTPS URL.
const String kBaseUrl = 'https://android-smart-campus-management.onrender.com';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 90);

  static Future<String> chat(String question) {
    return _post('/api/chat', {'question': question});
  }

  static Future<String> academic(String topic, String mode) {
    return _post('/api/academic', {'topic': topic, 'mode': mode});
  }
    static Future<String> career(String skills, String interests) {
    return _post('/api/career', {'skills': skills, 'interests': interests});
  }
    /// Fire-and-forget request that wakes the free Render server.
  static Future<void> wakeUp() async {
    try {
      await http
          .get(Uri.parse('$kBaseUrl/api/health'))
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      // Ignore errors: this is only a warm-up request.
    }
  }

  static Future<String> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _parse(response);
    } on SocketException {
      throw ApiException(
        'Cannot reach the server. Check your internet connection and try again.',
      );
    } on http.ClientException {
      throw ApiException(
        'Cannot reach the server. Check your internet connection and try again.',
      );
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Please try again.');
    }
  }

  static String _parse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException('The server sent an unexpected response. Please try again.');
    }

    if (data is Map<String, dynamic>) {
      if (data['success'] == true && data['answer'] is String) {
        return data['answer'] as String;
      }
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        throw ApiException(error);
      }
    }
    throw ApiException('Something went wrong. Please try again.');
  }
}