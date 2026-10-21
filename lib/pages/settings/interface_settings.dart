import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_dropdown_tile.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/modules/collect/collect_layout.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/device.dart';

class InterfaceSettingsPage extends StatefulWidget {
  const InterfaceSettingsPage({super.key});

  @override
  State<InterfaceSettingsPage> createState() => _InterfaceSettingsPageState();
}

class _InterfaceSettingsPageState extends State<InterfaceSettingsPage> {
  late bool showRating;
  late String defaultPage;
  late CollectLayout _defaultCollectLayout;
  bool _savingCollectLayout = false;
  static const _exitBehaviorTitles = ['退出 Kazumi', '最小化至託盤', '每次都詢問'];
  int _exitBehavior = GStorage.getSetting(SettingsKeys.exitBehavior)
      .clamp(0, _exitBehaviorTitles.length - 1);

  static const Map<String, String> defaultPageMap = {
    '/tab/popular/': '推薦',
    '/tab/timeline/': '時間表',
    '/tab/collect/': '追番',
    '/tab/my/': '我的',
  };

  @override
  void initState() {
    super.initState();
    showRating = GStorage.getSetting(SettingsKeys.showRating);
    defaultPage = GStorage.getSetting(SettingsKeys.defaultStartupPage);
    _defaultCollectLayout = CollectLayout.fromValue(
      GStorage.getSetting(SettingsKeys.defaultCollectLayout),
    );
  }

  void updateDefaultPage(String page) {
    GStorage.putSetting(SettingsKeys.defaultStartupPage, page);
    setState(() {
      defaultPage = page;
    });
  }

  Future<void> _updateDefaultCollectLayout(CollectLayout layout) async {
    if (_savingCollectLayout || layout == _defaultCollectLayout) return;
    setState(() => _savingCollectLayout = true);
    try {
      await GStorage.putSetting(SettingsKeys.defaultCollectLayout, layout.name);
      if (mounted) setState(() => _defaultCollectLayout = layout);
    } catch (_) {
      if (mounted) KazumiDialog.showToast(message: '追番預設佈局儲存失敗，請重試');
    } finally {
      if (mounted) setState(() => _savingCollectLayout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: Text('介面設定'),
      body: SettingsList(
        sections: [
          SettingsSection(title: Text('啟動'), tiles: [
            SettingsDropdownTile<String>(
              leading: Icons.home_rounded,
              title: const Text('啟動介面設定'),
              description: const Text('設定應用開啟時的預設頁面'),
              value: defaultPage,
              options: defaultPageMap,
              fallbackLabel: '推薦',
              onChanged: updateDefaultPage,
            ),
          ]),
          SettingsSection(title: Text('展示資訊'), tiles: [
            SettingsDropdownTile<CollectLayout>(
              leading: Icons.view_agenda_rounded,
              title: const Text('追番預設佈局'),
              description: const Text('下次開啟追番頁時使用，頁面內切換不會改變此設定'),
              enabled: !_savingCollectLayout,
              value: _defaultCollectLayout,
              options: {
                for (final layout in CollectLayout.values) layout: layout.label,
              },
              onChanged: _updateDefaultCollectLayout,
            ),
            SettingsTile.switchTile(
              leading: Icons.star_rounded,
              onToggle: (value) async {
                showRating = value ?? !showRating;
                await GStorage.putSetting(SettingsKeys.showRating, showRating);
                setState(() {});
              },
              title: Text('顯示評分'),
              description: Text('關閉後隱藏概覽和番劇列表中的評分資訊'),
              initialValue: showRating,
            ),
          ]),
          if (isDesktop())
            SettingsSection(
              title: const Text('視窗行為'),
              tiles: [
                SettingsDropdownTile<int>(
                  leading: Icons.exit_to_app_rounded,
                  title: const Text('關閉視窗時'),
                  description: const Text('設定點選視窗關閉按鈕後的行為'),
                  value: _exitBehavior,
                  options: {
                    for (var i = 0; i < _exitBehaviorTitles.length; i++)
                      i: _exitBehaviorTitles[i],
                  },
                  onChanged: (value) {
                    setState(() => _exitBehavior = value);
                    GStorage.putSetting(SettingsKeys.exitBehavior, value);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
