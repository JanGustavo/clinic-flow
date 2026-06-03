import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  BackendService._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5000';
      default:
        return 'http://127.0.0.1:5000';
    }
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_token', token);
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('session_token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
  }

  static Future<Map<String, String>> authHeaders([String? token]) async {
    token ??= await readToken();
    return {
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
