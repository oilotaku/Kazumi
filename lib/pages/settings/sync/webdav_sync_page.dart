import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/pages/settings/sync/sync_settings_widgets.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/sync/webdav.dart';
import 'package:kazumi/services/sync/danmaku_shield_sync_service.dart';

class WebDavSyncPage extends StatefulWidget {
  const WebDavSyncPage({super.key, required this.danmakuShieldSync});

  final DanmakuShieldSyncService danmakuShieldSync;

  @override
  State<WebDavSyncPage> createState() => _WebDavSyncPageState();
}

class _WebDavSyncPageState extends State<WebDavSyncPage> {
  bool _busy = false;
  bool _failed = false;
  String? _message;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
      _message = '正在連線 WebDAV…';
    });
    try {
      await action();
    } catch (e) {
      KazumiLogger().w('WebDAV settings operation failed', error: e);
      if (mounted) {
        _failed = true;
        _message = '未能完成，請檢查網路或伺服器配置後重試。';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setEnabled(bool enabled) => _run(() async {
        await WebDav().setEnabled(enabled);
        _message = null;
      });

  Future<void> _syncHistory() => _run(() async {
        final webDav = WebDav();
        if (!webDav.initialized) {
          await webDav.init();
        } else if (!webDav.isHistorySyncing) {
          await webDav.ping();
        }
        if (mounted) setState(() => _message = '正在同步觀看記錄…');
        await webDav.syncHistory();
        _message = '觀看記錄已同步';
      });

  Future<void> _configure() async {
    await context.pushNamed('/settings/webdav/editor');
    if (mounted) {
      setState(() {
        _message = null;
        _failed = false;
      });
    }
  }

  Future<void> _syncDanmakuShield() => _run(() async {
        if (mounted) setState(() => _message = '正在同步彈幕遮蔽詞…');
        await widget.danmakuShieldSync.sync();
        _message = '彈幕遮蔽詞已同步';
      });

  @override
  Widget build(BuildContext context) {
    final enabled = GStorage.getSetting(SettingsKeys.webDavEnable);
    final history = GStorage.getSetting(SettingsKeys.webDavEnableHistory);
    final collect = GStorage.getSetting(SettingsKeys.webDavEnableCollect);
    final shield = GStorage.getSetting(SettingsKeys.webDavEnableDanmakuShield);
    final url = GStorage.getSetting(SettingsKeys.webDavURL).trim();
    final configured = url.isNotEmpty;
    final host = Uri.tryParse(url)?.host;
    return PopScope(
      canPop: !_busy,
      child: SettingsDetailScaffold(
        title: const Text('多裝置同步'),
        body: SyncPageBody(
          maxWidth: 720,
          children: [
            const SyncPageIntro(
              icon: Icons.devices_rounded,
              title: 'WebDAV',
              description: '連線自己的雲盤，同步觀看記錄、收藏與彈幕遮蔽詞。',
            ),
            SettingsSection(
              margin: EdgeInsets.zero,
              tiles: [
                SettingsTile(
                  leading: Icons.dns_rounded,
                  title: Text(configured ? '同步伺服器' : '連線你的雲盤'),
                  description: Text(configured
                      ? (host == null || host.isEmpty ? '已儲存伺服器地址' : host)
                      : '需要支援 WebDAV 的雲盤或伺服器'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  enabled: !_busy,
                  onPressed: (_) => _configure(),
                ),
                SettingsTile.switchTile(
                  leading: Icons.cloud_sync_rounded,
                  title: const Text('啟用 WebDAV'),
                  description: Text(configured
                      ? (enabled ? '已開啟，選擇下方要同步的內容' : '開啟後選擇要同步的內容')
                      : '請先配置伺服器'),
                  initialValue: enabled,
                  enabled: configured && !_busy,
                  onToggle: (value) => _setEnabled(value ?? !enabled),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('同步內容'),
              margin: EdgeInsets.zero,
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.history_rounded,
                  title: const Text('觀看記錄'),
                  description: const Text('自動同步播放進度與歷史記錄'),
                  initialValue: history,
                  enabled: enabled && !_busy,
                  onToggle: (value) async {
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnableHistory, value ?? !history);
                    if (mounted) setState(() {});
                  },
                ),
                SettingsTile.switchTile(
                  leading: Icons.favorite_rounded,
                  title: const Text('收藏'),
                  description: const Text('在收藏頁同步所有追番分類'),
                  initialValue: collect,
                  enabled: enabled && !_busy,
                  onToggle: (value) async {
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnableCollect, value ?? !collect);
                    if (mounted) setState(() {});
                  },
                ),
                SettingsTile.switchTile(
                  leading: Icons.filter_alt_rounded,
                  title: const Text('彈幕遮蔽詞'),
                  description: const Text('啟動和修改規則後自動同步，包含關鍵詞與正規表示式'),
                  initialValue: shield,
                  enabled: enabled && !_busy,
                  onToggle: (value) async {
                    final syncEnabled = value ?? !shield;
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnableDanmakuShield, syncEnabled);
                    if (!mounted) return;
                    setState(() {});
                    if (syncEnabled) await _syncDanmakuShield();
                  },
                ),
              ],
            ),
            StateActionButton(
              onPressed: enabled && !_busy ? _syncHistory : null,
              text: _busy ? '請稍候…' : '立即同步觀看記錄',
              icon: Icons.sync_rounded,
            ),
            StateActionButton.tonal(
              onPressed:
                  enabled && shield && !_busy ? _syncDanmakuShield : null,
              text: '立即同步彈幕遮蔽詞',
              icon: Icons.sync_rounded,
            ),
            if (_message != null)
              SyncFeedback(message: _message!, error: _failed, busy: _busy),
          ],
        ),
      ),
    );
  }
}
