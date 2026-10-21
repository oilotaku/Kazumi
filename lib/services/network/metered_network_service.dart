import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kazumi/services/logging/logger.dart';

class MeteredNetworkService {
  MeteredNetworkService._();

  static final ValueNotifier<bool> _metered = ValueNotifier<bool>(false);
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static int _revision = 0;

  static bool get _supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMetered => _metered.value;

  static ValueListenable<bool> get listenable => _metered;

  static Future<void> refresh() async {
    if (!_supported) return;
    final revision = ++_revision;
    try {
      // Reset event deduplication after missed background network changes.
      final previous = _subscription;
      _subscription = null;
      await previous?.cancel();
      if (revision != _revision) return;
      _subscription = Connectivity().onConnectivityChanged.listen(
        (results) {
          _revision++;
          _apply(results);
        },
        onError: (Object error) {
          KazumiLogger().w('Network: 網路型別監聽中斷 $error');
        },
      );
      final results = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 3));
      // Discard queries superseded by a refresh or a network event.
      if (revision == _revision) {
        _apply(results);
      }
    } catch (error) {
      KazumiLogger().w('Network: 讀取網路型別失敗，保留上次狀態 $error');
    }
  }

  static void _apply(List<ConnectivityResult> results) {
    final metered = _isMetered(results);
    if (metered == null || metered == _metered.value) {
      return;
    }
    KazumiLogger()
        .i(metered ? 'Network: 切換到行動資料網路' : 'Network: 切換到 WLAN / 區域網');
    _metered.value = metered;
  }

  // WLAN wins during handovers; unknown transports retain the last known state.
  static bool? _isMetered(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet)) {
      return false;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return true;
    }
    return null;
  }
}
