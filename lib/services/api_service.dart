// Pepper Clinical V6 — API Service
// Connects Flutter frontend to Cython-protected FastAPI backend
// © 2026 Lamya Fadlulmola Hamed Ali

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // ── Change this to your server IP ──────────────────────
  static const String BASE = 'http://10.18.102.113';
  // For production with domain: 'https://pepper-clinical.app'
  // ───────────────────────────────────────────────────────

  static final _storage = const FlutterSecureStorage();
  static String? _token;

  // ── Token management ────────────────────────────────────
  static Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: 'pep_token', value: token);
  }

  static Future<String?> getToken() async {
    _token ??= await _storage.read(key: 'pep_token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'pep_token');
    await _storage.delete(key: 'pep_user');
  }

  // ── HTTP helpers ─────────────────────────────────────────
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = auth ? await _authHeaders : _headers;
    final response = await http.post(
      Uri.parse('$BASE$path'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    final err = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(err['detail'] ?? 'Server error ${response.statusCode}');
  }

  static Future<dynamic> _get(String path) async {
    final headers = await _authHeaders;
    final response = await http.get(
      Uri.parse('$BASE$path'),
      headers: headers,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    final err = jsonDecode(utf8.decode(response.bodyBytes));
    throw ApiException(err['detail'] ?? 'Server error ${response.statusCode}');
  }

  // ── Health check ─────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final r = await http.get(Uri.parse('$BASE/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // AUTH
  // ══════════════════════════════════════════════════════════

  static Future<AuthResult> startTrial({
    required String fullName,
    required String email,
    required String childName,
    required int childAge,
    String lang = 'ar',
  }) async {
    final data = await _post('/api/auth/trial', {
      'full_name': fullName,
      'email': email,
      'child_name': childName,
      'child_age': childAge,
      'lang': lang,
    });
    await saveToken(data['access_token']);
    await _storage.write(
      key: 'pep_user',
      value: jsonEncode({
        'id': data['user_id'],
        'email': email,
        'full_name': fullName,
        'pin': data['pin'],
        'plan': data['plan'],
      }),
    );
    return AuthResult.fromJson(data);
  }

  static Future<AuthResult> loginPin({
    required String email,
    required String pin,
  }) async {
    final data = await _post('/api/auth/login/pin', {
      'email': email,
      'pin': pin,
    });
    await saveToken(data['access_token']);
    final me = await getMe();
    await _storage.write(key: 'pep_user', value: jsonEncode(me));
    return AuthResult.fromJson(data);
  }

  static Future<Map<String, dynamic>> getMe() async {
    return await _get('/api/auth/me');
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final str = await _storage.read(key: 'pep_user');
    if (str == null) return null;
    return jsonDecode(str);
  }

  // ══════════════════════════════════════════════════════════
  // CHILDREN
  // ══════════════════════════════════════════════════════════

  static Future<List<Map<String, dynamic>>> getChildren() async {
    final data = await _get('/api/children/');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> getChild(String childId) async {
    return await _get('/api/children/$childId');
  }

  static Future<Map<String, dynamic>> addChild({
    required String name,
    required int age,
    String? diagnosis,
    String? notes,
  }) async {
    return await _post('/api/children/', {
      'name': name,
      'age': age,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (notes != null) 'notes': notes,
    }, auth: true);
  }

  // ══════════════════════════════════════════════════════════
  // SESSIONS
  // ══════════════════════════════════════════════════════════

  static Future<String> startSession({
    required String childId,
    String protocol = 'ABA-DTT',
    String? mood,
  }) async {
    final data = await _post('/api/sessions/start', {
      'child_id': childId,
      'protocol': protocol,
      if (mood != null) 'mood': mood,
    }, auth: true);
    return data['session_id'];
  }

  static Future<void> endSession({
    required String sessionId,
    required int score,
    required int tasksTotal,
    required int tasksSuccess,
    required int tasksFail,
    required int tasksMastered,
    required double avgAttention,
    String? dominantEmotion,
    String? notes,
  }) async {
    await _post('/api/sessions/end', {
      'session_id':       sessionId,
      'score':            score,
      'tasks_total':      tasksTotal,
      'tasks_success':    tasksSuccess,
      'tasks_fail':       tasksFail,
      'tasks_mastered':   tasksMastered,
      'avg_attention':    avgAttention,
      if (dominantEmotion != null) 'dominant_emotion': dominantEmotion,
      if (notes != null) 'notes': notes,
    }, auth: true);
  }

  static Future<List<Map<String, dynamic>>> generateTasks({
    String? domain,
    int level = 1,
    int count = 20,
    String lang = 'ar',
  }) async {
    final data = await _post('/api/sessions/tasks/generate', {
      if (domain != null) 'domain': domain,
      'level': level,
      'count': count,
      'lang':  lang,
    }, auth: true);
    return List<Map<String, dynamic>>.from(data['tasks'] ?? []);
  }

  static Future<List<Map<String, dynamic>>> getSessionHistory(
      String childId) async {
    final data = await _get('/api/sessions/history/$childId');
    return List<Map<String, dynamic>>.from(data);
  }
}

// ── Models ───────────────────────────────────────────────

class AuthResult {
  final String accessToken;
  final String userId;
  final String pin;
  final String plan;
  final String? expiresAt;

  AuthResult({
    required this.accessToken,
    required this.userId,
    required this.pin,
    required this.plan,
    this.expiresAt,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    accessToken: j['access_token'] ?? '',
    userId:      j['user_id'] ?? '',
    pin:         j['pin'] ?? '',
    plan:        j['plan'] ?? 'trial',
    expiresAt:   j['expires_at'],
  );
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
