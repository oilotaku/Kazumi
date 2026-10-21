import 'package:flutter/foundation.dart';
import 'package:kazumi/modules/collect/collect_sync_merger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/modules/bangumi/sync_priority.dart';
import 'package:kazumi/request/apis/bangumi_api.dart';
import 'package:kazumi/request/core/network_exception.dart';
import 'package:kazumi/utils/async_serial_queue.dart';

class BangumiSyncService extends ChangeNotifier {
  String _username = '';
  String get username => initialized ? _username : '';

  String? _verifiedToken;
  bool get initialized =>
      _verifiedToken != null && _verifiedToken == _configuredToken;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  String? _lastError;
  String? get lastError => _lastError;

  final _operations = AsyncSerialQueue();

  String get _configuredToken =>
      GStorage.getSetting(SettingsKeys.bangumiAccessToken).trim();

  BangumiSyncService._internal();
  static final BangumiSyncService _instance = BangumiSyncService._internal();
  factory BangumiSyncService() => _instance;

  @visibleForTesting
  void resetForTesting() {
    _verifiedToken = null;
    _username = '';
    _lastError = null;
    notifyListeners();
  }

  Future<void> ping() => _operations.run(_connectConfiguredToken);

  Future<void> setEnabled(bool enabled) {
    return _operations.run(() async {
      if (enabled) {
        await _connectConfiguredToken();
      }
      await GStorage.putSetting(SettingsKeys.bangumiSyncEnable, enabled);
      notifyListeners();
    });
  }

  Future<String> _validateToken(String token) async {
    if (token.isEmpty) {
      throw StateError('請先連線 Bangumi 帳號');
    }
    final user = await BangumiApi.getCurrentUser(accessToken: token);
    final name = user?.username;
    if (name == null || name.trim().isEmpty) {
      throw const FormatException('Bangumi 使用者資訊不完整');
    }
    return name;
  }

  Future<void> _connectConfiguredToken() async {
    _isConnecting = true;
    _lastError = null;
    notifyListeners();
    try {
      final token = _configuredToken;
      final name = await _validateToken(token);
      _verifiedToken = token;
      _username = name;
    } catch (e) {
      _verifiedToken = null;
      _username = '';
      _lastError = describeError(e);
      KazumiLogger().w('Bangumi: connection failed', error: e);
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  // Validate draft credentials before exposing them to other requests.
  Future<void> saveToken(String value) {
    return _operations.run(() async {
      final token = value.trim();
      _isConnecting = true;
      notifyListeners();
      try {
        final name = await _validateToken(token);
        await GStorage.putSetting(SettingsKeys.bangumiAccessToken, token);
        _verifiedToken = token;
        _username = name;
        _lastError = null;
      } catch (e) {
        if (token == _configuredToken) {
          _verifiedToken = null;
          _username = '';
          _lastError = describeError(e);
        }
        rethrow;
      } finally {
        _isConnecting = false;
        notifyListeners();
      }
    });
  }

  static String describeError(Object error) {
    if (error is NetworkException) {
      switch (error.statusCode) {
        case 401:
          return 'Access Token 無效或已過期，請在「Bangumi 帳號」中更換';
        case 403:
          return 'Bangumi 拒絕訪問，請檢查 Token 許可權或稍後重試';
        case 429:
          return 'Bangumi 請求過於頻繁，請稍後重試';
      }
      if (error.statusCode != null) {
        return 'Bangumi 服務請求失敗（HTTP ${error.statusCode}），請稍後重試';
      }
      return error.message;
    }
    if (error is FormatException || error is TypeError) {
      return 'Bangumi 返回的使用者資訊格式異常，請稍後重試';
    }
    if (error is StateError) return error.message.toString();
    return 'Bangumi 操作失敗，請稍後重試';
  }

  Future<bool> syncCollectibleWhenIdle(int bangumiId, int localType) {
    return _operations.run(() async {
      if (!initialized) await _connectConfiguredToken();
      return BangumiApi.updateBangumiByType(
        bangumiId,
        localType,
      );
    });
  }

  Future<void> _applyLocalMutation(BangumiLocalMutation mutation) async {
    await GStorage.putCollectible(mutation.collectible);
    // Remote changes must also reach WebDAV's incremental change log.
    await GStorage.appendCollectChange(
      bangumiId: mutation.collectible.bangumiItem.id,
      action: mutation.changeAction,
      type: mutation.collectible.type,
    );
  }

  Future<void> syncCollectibles({
    void Function(String message, int current, int total)? onProgress,
  }) {
    return _operations.run(() async {
      try {
        if (!GStorage.getSetting(SettingsKeys.bangumiSyncEnable)) {
          throw StateError('請先開啟 Bangumi 同步');
        }
        await _connectConfiguredToken();
        onProgress?.call('開始同步 Bangumi 狀態', 0, 0);

        final priority = BangumiSyncPriority.fromValue(
          GStorage.getSetting(SettingsKeys.bangumiSyncPriority),
        );

        final remoteCollection = await BangumiApi.getBangumiCollectibles(
          username: username,
          limit: 50,
          onProgress: onProgress,
        );

        final mergePlan = CollectSyncMerger.planBangumi(
          localCollectibles: GStorage.collectibles.values.toList(),
          remoteCollections: remoteCollection,
          priority: priority,
        );
        final totalOperations = mergePlan.totalOperations;

        if (totalOperations == 0) {
          onProgress?.call('未發現狀態差異，無需同步', 1, 1);
          return;
        }

        int syncedCount = 0;
        if (mergePlan.localOnlyUploads.isNotEmpty) {
          onProgress?.call('正在上傳本地新增狀態', syncedCount, totalOperations);
          for (final upload in mergePlan.localOnlyUploads) {
            final updated = await BangumiApi.updateBangumiByType(
              upload.bangumiId,
              upload.type,
            );
            if (!updated) {
              onProgress?.call('上傳本地新增狀態失敗', syncedCount, totalOperations);
              throw Exception('同步失敗：條目 ${upload.bangumiId} 上傳到 Bangumi 失敗');
            }
            syncedCount++;
            onProgress?.call('正在上傳本地新增狀態', syncedCount, totalOperations);
          }
        }

        if (mergePlan.remoteOnlyPuts.isNotEmpty) {
          onProgress?.call('正在補全本地缺失狀態', syncedCount, totalOperations);
          for (final mutation in mergePlan.remoteOnlyPuts) {
            await _applyLocalMutation(mutation);
            syncedCount++;
            onProgress?.call('正在補全本地缺失狀態', syncedCount, totalOperations);
          }
        }

        if (mergePlan.conflictUploads.isNotEmpty) {
          onProgress?.call(
              '${priority.label}：正在上傳衝突狀態', syncedCount, totalOperations);
          for (final upload in mergePlan.conflictUploads) {
            final updated = await BangumiApi.updateBangumiByType(
              upload.bangumiId,
              upload.type,
            );
            if (!updated) {
              throw Exception('同步失敗：條目 ${upload.bangumiId} 上傳到 Bangumi 失敗');
            }
            syncedCount++;
            onProgress?.call(
                '${priority.label}：正在上傳衝突狀態', syncedCount, totalOperations);
          }
        }
        if (mergePlan.conflictLocalUpdates.isNotEmpty) {
          onProgress?.call(
              '${priority.label}：正在更新本地衝突狀態', syncedCount, totalOperations);
          for (final mutation in mergePlan.conflictLocalUpdates) {
            await _applyLocalMutation(mutation);
            syncedCount++;
            onProgress?.call(
                '${priority.label}：正在更新本地衝突狀態', syncedCount, totalOperations);
          }
        }
        onProgress?.call('Bangumi 狀態同步完成', 1, 1);
      } catch (e) {
        KazumiLogger().e('Bangumi sync failed', error: e);
        rethrow;
      }
    });
  }
}
