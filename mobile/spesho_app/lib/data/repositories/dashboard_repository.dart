import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardRepository implements IDashboardRepository {
  final ApiClient _api;
  static const _cacheKey = 'dashboard_cache_v3';

  DashboardRepository(this._api);

  /// Returns cached data instantly (null if no cache).
  Future<DashboardEntity?> getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) return DashboardModel.fromJson(jsonDecode(raw));
    } catch (_) {}
    return null;
  }

  @override
  Future<DashboardModel> getDashboard() async {
    final res = await _api.get('/dashboard/');
    // Save to cache in background — don't await
    _saveCache(res as Map<String, dynamic>);
    return DashboardModel.fromJson(res);
  }

  void _saveCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }
}
