import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final pimServiceProvider = Provider((ref) => PimService(ref.watch(apiClientProvider)));
class PimService {
  PimService(this.api); final ApiClient api;
  Future<Map<String,dynamic>> login(String email,String senha) async => Map<String,dynamic>.from((await api.dio.post('/auth/login',data:{'email':email,'senha':senha})).data);
  Future<void> logout() async { final r=await api.storage.read(key:'refreshToken'); if(r!=null) await api.dio.post('/auth/logout',data:{'refreshToken':r}); await api.clearTokens(); }
  Map<String,dynamic> _query(Map<String,dynamic>? query) => Map.fromEntries((query ?? {}).entries.where((e) => e.value != null && e.value != ''));
  Future<List<dynamic>> list(String path,{Map<String,dynamic>? query}) async => (await api.dio.get(path,queryParameters:_query(query))).data as List<dynamic>;
  Future<Map<String,dynamic>> one(String path) async => Map<String,dynamic>.from((await api.dio.get(path)).data);
  Future<dynamic> get(String path,{Map<String,dynamic>? query}) async => (await api.dio.get(path,queryParameters:_query(query))).data;
  Future<dynamic> post(String path,[Object? body]) async => (await api.dio.post(path,data:body??{})).data;
  Future<dynamic> put(String path,Object body) async => (await api.dio.put(path,data:body)).data;
  Future<void> patch(String path,Object body) async { await api.dio.patch(path,data:body); }
  Future<void> delete(String path) async { await api.dio.delete(path); }
}
