import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/services/storage/image_cache_service.dart';

class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  final _cache = ImageCacheService();
  late Future<int> _cacheSize = _cache.sizeInBytes();
  bool _clearing = false;

  void _refreshSize() => setState(() => _cacheSize = _cache.sizeInBytes());

  void _message(String message) {
    KazumiDialog.showToast(context: context, message: message);
  }

  Future<void> _confirmClear() async {
    if (_clearing) return;
    final confirmed = await KazumiDialog.show<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.cleaning_services_rounded),
        title: const Text('清除圖片快取？'),
        content: const Text('圖片會在下次載入時重新下載。影片、記錄和設定不會刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清除快取'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    try {
      await _cache.clear();
      if (!mounted) return;
      _message('圖片快取已清除');
      _refreshSize();
    } catch (_) {
      if (mounted) _message('清除失敗，請稍後重試');
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  String _cacheDescription(AsyncSnapshot<int> snapshot) {
    if (_clearing) return '正在清除…';
    if (snapshot.connectionState != ConnectionState.done) return '正在統計…';
    if (snapshot.hasError) return '統計失敗';
    return '${(snapshot.requireData / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: const Text('儲存與日誌'),
        body: FutureBuilder<int>(
          future: _cacheSize,
          builder: (context, snapshot) => SettingsList(
            sections: [
              SettingsSection(
                title: const Text('快取'),
                tiles: [
                  SettingsTile(
                    leading: Icons.image_outlined,
                    title: const Text('清除圖片快取'),
                    description: Text(_cacheDescription(snapshot)),
                    enabled: snapshot.connectionState == ConnectionState.done &&
                        !_clearing,
                    onPressed: (_) => _confirmClear(),
                    trailing:
                        snapshot.connectionState == ConnectionState.done &&
                                snapshot.hasError &&
                                !_clearing
                            ? IconButton(
                                tooltip: '重新統計',
                                onPressed: _refreshSize,
                                icon: const Icon(Icons.refresh_rounded),
                              )
                            : const Icon(Icons.cleaning_services_rounded),
                  ),
                ],
              ),
              SettingsSection(
                title: const Text('診斷'),
                tiles: [
                  SettingsTile(
                    leading: Icons.receipt_long_rounded,
                    title: const Text('錯誤日誌'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onPressed: (_) =>
                        context.pushNamed('/settings/storage/logs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
