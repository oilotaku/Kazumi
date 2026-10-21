import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:kazumi/services/logging/logger.dart';

/// Android 後臺下載服務
///
/// 使用 Foreground Service 保持 app 程式存活，防止系統在後臺時殺死下載程式。
/// 下載邏輯仍在主 Isolate 執行，此服務僅負責：
/// 1. 顯示通知欄進度
/// 2. 保持程式存活
/// 3. 提供通知欄互動（暫停全部）
class BackgroundDownloadService {
  static final BackgroundDownloadService _instance =
      BackgroundDownloadService._internal();
  factory BackgroundDownloadService() => _instance;
  BackgroundDownloadService._internal();

  bool _isInitialized = false;
  bool _isRunning = false;

  void Function()? onPauseAll;
  void Function()? onNavigateToDownloadRequested;

  /// 返回 true 表示使用者同意請求許可權，false 表示使用者拒絕
  Future<bool> Function()? onNotificationPermissionRequired;

  bool get isSupported => Platform.isAndroid;
  bool get isRunning => _isRunning;
  Future<void> init() async {
    if (!isSupported || _isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'kazumi_download_channel',
        channelName: '下載服務',
        channelDescription: '影片下載後臺服務',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.initCommunicationPort();

    _isInitialized = true;
    KazumiLogger().i('BackgroundDownloadService: initialized');
  }

  Future<bool> needsNotificationPermission() async {
    if (!isSupported) return false;
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    return permission != NotificationPermission.granted;
  }

  Future<bool> requestNotificationPermission() async {
    if (!isSupported) return true;
    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  Future<bool> startService() async {
    if (!isSupported) return false;
    if (_isRunning) return true;

    if (!_isInitialized) {
      await init();
    }

    final needsPermission = await needsNotificationPermission();
    if (needsPermission) {
      if (onNotificationPermissionRequired != null) {
        final userAgreed = await onNotificationPermissionRequired!();
        if (userAgreed) {
          final granted = await requestNotificationPermission();
          if (!granted) {
            KazumiLogger().w(
                'BackgroundDownloadService: notification permission denied by user');
          }
        } else {
          KazumiLogger()
              .i('BackgroundDownloadService: user declined permission dialog');
        }
      } else {
        // 沒有設定回撥，直接請求許可權（相容舊行為）
        final granted = await requestNotificationPermission();
        if (!granted) {
          KazumiLogger()
              .w('BackgroundDownloadService: notification permission denied');
        }
      }
    }

    try {
      final result = await FlutterForegroundTask.startService(
        notificationTitle: '正在下載',
        notificationText: '準備中...',
        notificationButtons: [
          const NotificationButton(id: 'pause_all', text: '暫停全部'),
        ],
        callback: _backgroundCallback,
      );

      _isRunning = result is ServiceRequestSuccess;

      if (_isRunning) {
        KazumiLogger().i('BackgroundDownloadService: service started');
      } else {
        KazumiLogger().w(
            'BackgroundDownloadService: service start returned non-success: $result');
      }
      return _isRunning;
    } catch (e) {
      KazumiLogger()
          .e('BackgroundDownloadService: failed to start service', error: e);
      return false;
    }
  }

  Future<void> stopService() async {
    if (!isSupported || !_isRunning) return;

    try {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
      KazumiLogger().i('BackgroundDownloadService: service stopped');
    } catch (e) {
      KazumiLogger()
          .e('BackgroundDownloadService: failed to stop service', error: e);
    }
  }

  Future<void> updateNotification({
    required String title,
    required String text,
  }) async {
    if (!isSupported || !_isRunning) return;

    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (e) {
      // 忽略更新失敗，不影響下載
    }
  }

  Future<void> updateProgress({
    required int activeCount,
    required int totalCount,
    required double overallProgress,
    required String speedText,
  }) async {
    if (!isSupported || !_isRunning) return;

    String title;
    String text;

    if (activeCount == 0) {
      title = '下載已暫停';
      text = '共 $totalCount 個任務';
    } else {
      final percent = (overallProgress * 100).toInt();
      title = '正在下載 ($activeCount/$totalCount)';
      text = '$percent% · $speedText';
    }

    await updateNotification(title: title, text: text);
  }

  void handleNotificationAction(String buttonId) {
    if (buttonId == 'pause_all') {
      onPauseAll?.call();
    }
  }

  void handleNavigateToDownload() {
    onNavigateToDownloadRequested?.call();
  }

  void addTaskDataCallback(void Function(Object) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  void removeTaskDataCallback(void Function(Object) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}

/// 後臺任務回撥（在獨立 Isolate 中執行）
///
/// 注意：此回撥主要用於保持服務存活和處理通知互動。
/// 實際下載邏輯在主 Isolate 中執行。
@pragma('vm:entry-point')
void _backgroundCallback() {
  FlutterForegroundTask.setTaskHandler(_DownloadTaskHandler());
}

class _DownloadTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('BackgroundDownloadService: task handler started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // eventAction 配置為 nothing，不會觸發
  }

  @override
  void onNotificationButtonPressed(String id) {
    debugPrint('BackgroundDownloadService: notification button pressed: $id');
    FlutterForegroundTask.sendDataToMain(
        {'action': 'button_pressed', 'id': id});
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.sendDataToMain({'action': 'navigate_to_download'});
    FlutterForegroundTask.launchApp();
  }

  @override
  void onNotificationDismissed() {
    // 前臺服務通知通常不可劃掉
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    debugPrint(
        'BackgroundDownloadService: task handler destroyed (isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {
    debugPrint('BackgroundDownloadService: received data: $data');
  }
}
