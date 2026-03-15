import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/usecases/dashboard_usecases.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardUseCases _useCases;
  final DashboardRepository _repo;

  DashboardEntity? _data;
  bool _loading = false;
  String? _error;
  DateTime? _lastUpdated;
  Timer? _timer;

  DashboardProvider(this._useCases, this._repo);

  DashboardEntity? get data => _data;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isAutoRefreshing => _timer != null && _timer!.isActive;

  /// Fire network + cache fetch in PARALLEL — whichever is faster shows first.
  Future<void> init() async {
    // Start network fetch immediately (don't wait for cache)
    final networkFuture = _fetchNetwork();
    // Load cache concurrently — usually done in <5ms
    final cached = await _repo.getCached();
    if (cached != null && _data == null) {
      _data = cached;
      notifyListeners();
    }
    await networkFuture;
  }

  Future<void> _fetchNetwork() async {
    try {
      final fresh = await _useCases.getDashboard();
      _data = fresh;
      _error = null;
      _lastUpdated = DateTime.now();
    } catch (e) {
      if (_data == null) _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    await _fetchNetwork();
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 3)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => load(silent: true));
  }

  void stopAutoRefresh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
