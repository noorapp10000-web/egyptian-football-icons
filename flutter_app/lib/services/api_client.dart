import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../models/football_models.dart';
import 'offline_cache.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Future<Map<String, dynamic>> _get(String path) async {
    final cacheKey = path.replaceAll(RegExp(r'[^a-zA-Z0-9/_-]'), '_');
    try {
      final response = await _client.get(_uri(path)).timeout(
        const Duration(seconds: 12),
      );
      final decoded = _decode(response);
      // A cache write must never turn a successful network response into an
      // error. This is especially important on first launch, before storage
      // is ready or when the platform rejects a large cached payload.
      try {
        await OfflineCache.instance.write(cacheKey, decoded);
      } catch (_) {
        // The fresh response is still valid; just continue without caching.
      }
      markOnline();
      return decoded;
    } catch (error) {
      Map<String, dynamic>? cached;
      try {
        cached = await OfflineCache.instance.read(cacheKey);
      } catch (_) {
        // Storage failures should not hide the original network/API error.
      }
      markOffline();
      if (cached != null) return cached;
      if (error is ApiException) rethrow;
      throw const ApiException(
        'يرجى الاتصال بالإنترنت للحصول على آخر التحديثات',
      );
    }
  }

  Future<Map<String, dynamic>> _authed(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ApiException('تسجيل الدخول مطلوب');
    final headers = {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    };
    final response = method == 'PUT'
        ? await _client.put(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          )
        : await _client.post(
            _uri(path),
            headers: headers,
            body: jsonEncode(body),
          );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw const ApiException('السيرفر أعاد استجابة فارغة');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw const ApiException('استجابة السيرفر غير صالحة');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['error'] : null;
      throw ApiException(message?.toString() ?? 'تعذر الاتصال بالسيرفر');
    }
    if (decoded is! Map) {
      throw const ApiException('تنسيق استجابة السيرفر غير متوقع');
    }
    return decoded.cast<String, dynamic>();
  }

  Future<List<Match>> getMatches() async {
    final data = await _get('/football/matches');
    return _mapList(data['matches'] ?? data['items'], Match.fromJson);
  }

  Future<List<Standing>> getStandings() async {
    final data = await _get('/football/standings');
    return _mapList(data['standings'] ?? data['table'] ?? data['rows'], Standing.fromJson);
  }

  Future<List<Player>> getSquad() async {
    final data = await _get('/football/squad');
    return _mapList(data['players'] ?? data['squad'], Player.fromJson);
  }

  Future<List<NewsItem>> getNews() async {
    final data = await _get('/football/news');
    final news = _mapList(
      data['news'] ?? data['items'] ?? data['articles'],
      NewsItem.fromJson,
    );
    news.sort((a, b) {
      final aDate = DateTime.tryParse(a.publishedAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      final bDate = DateTime.tryParse(b.publishedAt ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      return bDate.compareTo(aDate);
    });
    return news;
  }

  Future<Map<String, dynamic>> getMatchDetail(int id) =>
      _get('/football/matches/$id');

  Future<Map<String, dynamic>> getPlayerDetail(int id) =>
      _get('/football/players/$id');

  Future<Preferences> getPreferences() async {
    final data = await _authed('/me/preferences');
    return Preferences.fromJson(
      (data['preferences'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Future<void> savePreferences({
    String? username,
    bool? notificationsEnabled,
    Map<String, bool>? notifications,
  }) async {
    await _authed(
      '/me/preferences',
      method: 'PUT',
      body: {
        if (username != null) 'username': username,
        if (notificationsEnabled != null)
          'notificationsEnabled': notificationsEnabled,
        if (notifications != null) 'notifications': notifications,
      },
    );
  }

  Future<void> registerDevice(String token) async {
    await _authed('/me/devices', method: 'POST', body: {'token': token});
  }

  List<T> _mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value is! List) return const [];
    final result = <T>[];
    for (final item in value) {
      if (item is! Map) continue;
      try {
        result.add(fromJson(item.cast<String, dynamic>()));
      } catch (_) {
        // Ignore one malformed upstream item instead of breaking the page.
      }
    }
    return result;
  }
}
