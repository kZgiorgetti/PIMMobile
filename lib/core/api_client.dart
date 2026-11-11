import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());
final apiClientProvider = Provider((ref) => ApiClient(ref.watch(apiUrlProvider), ref.watch(secureStorageProvider)));

class ApiClient {
  ApiClient(String baseUrl, this.storage) : dio = Dio(BaseOptions(baseUrl: '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/v1', headers: {'Content-Type': 'application/json'})) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      final token = await storage.read(key: 'accessToken');
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }, onError: (e, h) async {
      final req = e.requestOptions;
      final refresh = await storage.read(key: 'refreshToken');
      if (e.response?.statusCode == 401 && refresh != null && req.path != '/auth/login' && req.extra['retried'] != true) {
        try {
          final tokens = await _refreshTokens(refresh);
          req.extra['retried'] = true;
          req.headers['Authorization'] = 'Bearer ${tokens['accessToken']}';
          final response = await dio.fetch(req);
          h.resolve(response);
          return;
        } catch (_) {
          await clearTokens();
          onSessionExpired?.call();
        }
      }
      h.next(e);
    }));
  }
  final Dio dio;
  final FlutterSecureStorage storage;
  Future<Map<String, dynamic>>? _refreshing;
  void Function()? onSessionExpired;
  Future<Map<String, dynamic>> _refreshTokens(String refresh) => _refreshing ??= (() async {
    try {
      final result = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post('/auth/refresh', data: {'refreshToken': refresh});
      final data = Map<String, dynamic>.from(result.data as Map);
      await saveTokens(data);
      return data;
    } finally {
      _refreshing = null;
    }
  })();
  Future<void> saveTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'accessToken', value: '${data['accessToken']}');
    await storage.write(key: 'refreshToken', value: '${data['refreshToken']}');
    if (data['usuario'] != null) await storage.write(key: 'usuario', value: jsonEncode(data['usuario']));
  }
  Future<void> clearTokens() async { await storage.deleteAll(); }
  String message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['errors'] is Map) return (data['errors'] as Map).values.expand((v) => v is List ? v : [v]).join(' ');
        return '${data['error'] ?? data['detail'] ?? 'Erro inesperado (${error.response?.statusCode ?? 'rede'}).'}';
      }
      return error.message ?? 'Falha de comunicação com a API.';
    }
    return error.toString();
  }
}
