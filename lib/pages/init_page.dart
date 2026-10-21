import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/services/sync/bangumi_sync_service.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';
import 'package:kazumi/services/sync/webdav.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/shaders/shader_asset_service.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/plugin_editor/plugin_update_actions.dart';
import 'package:kazumi/services/download/background_download_service.dart';
import 'package:kazumi/services/platform/windows_shortcut.dart';
import 'package:kazumi/services/platform/platform_environment_service.dart';
import 'package:kazumi/services/update/startup_update_check.dart';
import 'package:kazumi/navigation.dart';

class InitPage extends StatefulWidget {
  const InitPage({
    super.key,
    required this.pluginsController,
    required this.collectController,
    required this.shaderAssetService,
    required this.myController,
    required this.downloadController,
    required this.danmakuShieldSync,
  });

  final PluginsController pluginsController;
  final CollectController collectController;
  final ShaderAssetService shaderAssetService;
  final MyController myController;
  final DownloadController downloadController;
  final DanmakuShieldSyncService danmakuShieldSync;

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  PluginsController get pluginsController => widget.pluginsController;
  CollectController get collectController => widget.collectController;
  ShaderAssetService get shaderAssetService => widget.shaderAssetService;
  MyController get myController => widget.myController;
  DownloadController get downloadController => widget.downloadController;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeApp());
  }

  Future<void> _initializeApp() async {
    widget.danmakuShieldSync.start();
    _migrateStorage();
    _loadShaders();
    unawaited(myController.loadShieldList());
    _webDavInit();
    _bangumiInit();
    try {
      await downloadController.init();
      _setupBackgroundDownloadNavigation();
    } catch (e) {
      KazumiLogger().e('InitPage: downloadController.init() failed', error: e);
    }

    await _checkRunningOnX11();
    await _showShortcutDialog();
    await _pluginInit();

    if (!mounted) {
      return;
    }
    // Installs that predate the flag already have rules; don't re-onboard them.
    if (!GStorage.getSetting(SettingsKeys.onboardingCompleted) &&
        pluginsController.pluginList.isEmpty) {
      context.navigate('/onboarding');
      return;
    }

    final updateController = myController;
    unawaited(runStartupUpdateCheck(
      isEnabled: () => GStorage.getSetting(SettingsKeys.autoUpdate),
      checkForUpdate: () => updateController.checkUpdate(type: 'auto'),
    ));
    context.navigate(GStorage.getSetting(SettingsKeys.defaultStartupPage));
  }

  void _setupBackgroundDownloadNavigation() {
    final backgroundService = BackgroundDownloadService();

    backgroundService.onNavigateToDownloadRequested = () {
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          final navigationContext = rootNavigatorKey.currentContext;
          if (navigationContext == null || !navigationContext.mounted) return;
          final path = navigationContext.routeState(listen: false).uri.path;
          if (path.contains('/download')) return;
          navigationContext.pushNamed('/settings/download/');
        } catch (e) {
          KazumiLogger()
              .w('InitPage: failed to navigate to download page', error: e);
        }
      });
    };

    backgroundService.onNotificationPermissionRequired = () async {
      final result = await KazumiDialog.show<bool>(
        clickMaskDismiss: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('需要通知許可權'),
            content: const Text(
              '開啟通知許可權後，可以在後臺下載時顯示進度，並防止系統終止下載任務。\n\n'
              '如果拒絕，下載功能仍可使用，但在後臺時可能被系統中斷。',
            ),
            actions: [
              TextButton(
                onPressed: () => KazumiDialog.dismiss(popWith: false),
                child: Text(
                  '稍後再說',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              TextButton(
                onPressed: () => KazumiDialog.dismiss(popWith: true),
                child: const Text('允許'),
              ),
            ],
          );
        },
      );
      return result ?? false;
    };
  }

  // migrate collect from old version (favorites)
  Future<void> _migrateStorage() async {
    await collectController.migrateCollect();
  }

  Future<void> _loadShaders() async {
    await shaderAssetService.copyShadersToExternalDirectory();
  }

  Future<void> _webDavInit() async {
    bool webDavEnable = await GStorage.getSetting(SettingsKeys.webDavEnable);
    bool webDavEnableHistory =
        await GStorage.getSetting(SettingsKeys.webDavEnableHistory);
    if (webDavEnable) {
      var webDav = WebDav();
      KazumiLogger().i('WebDav: Starting WebDav initialization');
      try {
        await webDav.init();
        await widget.danmakuShieldSync.syncIfEnabled();
        if (webDavEnableHistory) {
          try {
            await webDav.syncHistory();
            KazumiLogger().i('WebDav: Completed syncing watch history');
          } catch (e, stackTrace) {
            KazumiLogger().w(
              'WebDav: automatic watch history sync failed',
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      } catch (e, stackTrace) {
        KazumiLogger().w(
          'WebDav: automatic initialization failed',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _bangumiInit() async {
    final bangumiEnable = GStorage.getSetting(SettingsKeys.bangumiSyncEnable);
    if (bangumiEnable) {
      final bangumi = BangumiSyncService();
      KazumiLogger().i('Bangumi: Starting Bangumi initialization');
      try {
        await bangumi.ping();
      } catch (e) {
        KazumiLogger().w(
          'Bangumi: initialization failed; keeping sync enabled for retry',
          error: e,
        );
        KazumiDialog.showToast(
          message:
              'Bangumi 暫未連線，同步設定已保留：${BangumiSyncService.describeError(e)}',
        );
      }
    }
  }

  Future<void> _checkRunningOnX11() async {
    if (!Platform.isLinux) {
      return;
    }
    bool isRunningOnX11 = await PlatformEnvironmentService.isRunningOnX11();
    if (isRunningOnX11) {
      await KazumiDialog.show(
        clickMaskDismiss: false,
        builder: (context) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('X11環境檢測'),
              content: const Text(
                  '檢測到您當前執行在X11環境下，Kazumi在X11環境下可能出現效能問題或介面異常，建議切換到Wayland以獲得更好的體驗。您是否希望在X11下繼續使用Kazumi？'),
              actions: [
                TextButton(
                  onPressed: () {
                    exit(0);
                  },
                  child: Text(
                    '退出',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    KazumiDialog.dismiss();
                  },
                  child: const Text('繼續'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Future<void> _showShortcutDialog() async {
    if (!Platform.isWindows) return;
    if (GStorage.getSetting(SettingsKeys.shortcutDialogShown)) {
      return;
    }

    final create = await KazumiDialog.show<bool>(
      clickMaskDismiss: false,
      builder: (context) => AlertDialog(
        title: const Text('建立桌面快捷方式'),
        content: const Text('是否在桌面建立 Kazumi 的快捷方式？'),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(popWith: false),
            child: Text('暫不建立',
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ),
          TextButton(
            onPressed: () => KazumiDialog.dismiss(popWith: true),
            child: const Text('建立'),
          ),
        ],
      ),
    );

    await GStorage.putSetting(SettingsKeys.shortcutDialogShown, true);
    if (create ?? false) {
      final success = await WindowsShortcut.createDesktopShortcut();
      KazumiDialog.showToast(message: success ? '桌面快捷方式已建立' : '桌面快捷方式建立失敗');
    }
  }

  Future<void> _pluginInit() async {
    try {
      await pluginsController.init();
      unawaited(_pluginUpdate());
    } catch (error, stackTrace) {
      KazumiLogger().e(
        'Plugin: failed to initialize rules',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _pluginUpdate() async {
    final checkOnStartup =
        GStorage.getSetting(SettingsKeys.checkPluginUpdateOnStartup);
    late final int count;
    try {
      count = await pluginsController.checkPluginUpdatesOnStartup(
        enabled: checkOnStartup,
      );
    } catch (_) {
      return;
    }
    if (count != 0) {
      KazumiDialog.showToast(
        message: '檢測到 $count 條規則可以更新',
        showActionButton: true,
        actionLabel: '全部更新',
        onActionPressed: () => updateAllPluginsWithFeedback(
          pluginsController,
          ensureCatalog: false,
        ),
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingWidget();
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container());
  }
}
