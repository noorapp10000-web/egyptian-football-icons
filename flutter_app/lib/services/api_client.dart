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
      await OfflineCache.instance.write(cacheKey, decoded);
      markOnline();
      return decoded;
    } catch (error) {
      final cached = await OfflineCache.instance.read(cacheKey);
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
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['error'] : null;
      throw ApiException(message?.toString() ?? 'تعذر الاتصال بالسيرفر');
    }
    return (decoded as Map).cast<String, dynamic>();
  }

  Future<List<Match>> getMatches() async {
    final data = await _get('/football/matches');
    return _list(data['matches']).map(Match.fromJson).toList();
  }

  Future<List<Standing>> getStandings() async {
    final data = await _get('/football/standings');
    return _list(data['standings']).map(Standing.fromJson).toList();
  }

  Future<List<Player>> getSquad() async {
    final data = await _get('/football/squad');
    return _list(data['players']).map(Player.fromJson).toList();
  }

  Future<List<NewsItem>> getNews() async {
    final data = await _get('/football/news');
    return _list(data['news']).map(NewsItem.fromJson).toList();
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

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList()
      : const [];
}
