import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';

final sessionProvider = StateNotifierProvider<SessionController, Map<String,dynamic>?>((ref) => SessionController(ref.watch(apiClientProvider)));
class SessionController extends StateNotifier<Map<String,dynamic>?> {
  SessionController(this.api):super(null);
  final ApiClient api;
  Future<bool> restore() async { final token=await api.storage.read(key:'accessToken'); final raw=await api.storage.read(key:'usuario'); if(token==null||raw==null)return false; try { state=Map<String,dynamic>.from(jsonDecode(raw) as Map); return true; } catch (_) { await api.clearTokens(); return false; } }
  Future<void> set(Map<String,dynamic> user) async { state=user; await api.storage.write(key:'usuario',value:jsonEncode(user)); }
  void clear()=>state=null;
}
