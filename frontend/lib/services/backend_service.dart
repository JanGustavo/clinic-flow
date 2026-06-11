import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  BackendService._();

  static const String _logTag = '[BackendService]';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static String _debugBaseUrl = '';

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      _debugBaseUrl = _configuredBaseUrl;
      developer.log(
        '$_logTag Using configured URL: $_debugBaseUrl',
        name: 'BackendService',
      );
      return _debugBaseUrl;
    }

    if (kIsWeb) {
      _debugBaseUrl = 'http://127.0.0.1:5000';
      developer.log(
        '$_logTag Web platform detected - URL: $_debugBaseUrl',
        name: 'BackendService',
      );
      return _debugBaseUrl;
    }

    late final String url;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        url = 'http://10.0.2.2:5000';
        developer.log(
          '$_logTag Android platform detected - URL: $url (emulator: 10.0.2.2)',
          name: 'BackendService',
        );
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        url = 'http://127.0.0.1:5000';
        developer.log(
          '$_logTag Platform: ${defaultTargetPlatform.name} - URL: $url',
          name: 'BackendService',
        );
        break;
      default:
        url = 'http://127.0.0.1:5000';
        developer.log(
          '$_logTag Default platform - URL: $url',
          name: 'BackendService',
        );
    }
    _debugBaseUrl = url;
    return url;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
    developer.log(
      '$_logTag Token saved (length: ${token.length})',
      name: 'BackendService',
    );
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('session_token');
    developer.log(
      '$_logTag Token read (exists: ${token != null}, length: ${token?.length ?? 0})',
      name: 'BackendService',
    );
    return token;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    developer.log('$_logTag Token cleared', name: 'BackendService');
  }

  static Future<Map<String, String>> authHeaders([String? token]) async {
    token ??= await readToken();
    final headers = {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    developer.log(
      '$_logTag Auth headers: ${headers.keys.toList()} (token: ${token != null ? "present" : "absent"})',
      name: 'BackendService',
    );
    return headers;
  }

  /// Debug helper: Test connection to backend
  static Future<String> testConnection() async {
    try {
      developer.log(
        '$_logTag Testing connection to: $baseUrl',
        name: 'BackendService',
      );
      // Teste silencioso - não loga o resultado
      return 'Connection test initiated';
    } catch (e) {
      developer.log(
        '$_logTag Connection test failed: $e',
        name: 'BackendService',
      );
      return 'Connection test failed: $e';
    }
  }
}
