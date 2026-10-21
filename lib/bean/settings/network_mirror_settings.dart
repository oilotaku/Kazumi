import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/services/network/bangumi_acceleration.dart';
import 'package:kazumi/services/network/image_acceleration.dart';
import 'package:kazumi/services/storage/storage.dart';

class NetworkMirrorSettings extends StatefulWidget {
  const NetworkMirrorSettings({super.key, this.margin});

  final EdgeInsetsGeometry? margin;

  @override
  State<NetworkMirrorSettings> createState() => _NetworkMirrorSettingsState();
}

class _NetworkMirrorSettingsState extends State<NetworkMirrorSettings> {
  Future<void> _save<T>(SettingKey<T> key, T value) async {
    await GStorage.putSetting(key, value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bangumiAcceleration = BangumiAcceleration.current;
    final gitProxy = GStorage.getSetting(SettingsKeys.enableGitProxy);
    final imageAcceleration = ImageAcceleration.fromSetting(
      GStorage.getSetting(SettingsKeys.imageAcceleration),
    );
    return SettingsSection(
      title: const Text('訪問加速'),
      margin: widget.margin,
      tiles: [
        SettingsTile(
          leading: Icons.travel_explore_rounded,
          title: const Text('番劇條目加速'),
          description: const Text(
            '番劇資訊與評論',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          value: SizedBox(
            width: 60,
            child: Text(bangumiAcceleration.label, textAlign: TextAlign.center),
          ),
          onPressed: (context) => _selectAcceleration(
            context,
            title: '番劇條目加速',
            current: bangumiAcceleration,
            modes: BangumiAcceleration.values,
            label: (mode) => mode.label,
            description: (mode) => mode.description,
            setting: SettingsKeys.bangumiAcceleration,
          ),
        ),
        SettingsTile.switchTile(
          leading: Icons.extension_rounded,
          title: const Text('規則庫映象'),
          description: const Text('加速規則的下載與更新'),
          initialValue: gitProxy,
          onToggle: (value) =>
              _save(SettingsKeys.enableGitProxy, value ?? !gitProxy),
        ),
        SettingsTile(
          leading: Icons.image_rounded,
          title: const Text('圖片加速'),
          description: const Text(
            '封面與頭像',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          value: SizedBox(
            width: 60,
            child: Text(imageAcceleration.label, textAlign: TextAlign.center),
          ),
          onPressed: (context) => _selectAcceleration(
            context,
            title: '圖片加速',
            current: imageAcceleration,
            modes: ImageAcceleration.values,
            label: (mode) => mode.label,
            description: (mode) => mode.description,
            setting: SettingsKeys.imageAcceleration,
          ),
        ),
      ],
    );
  }

  Future<void> _selectAcceleration<T extends Enum>(
    BuildContext context, {
    required String title,
    required T current,
    required List<T> modes,
    required String Function(T) label,
    required String Function(T) description,
    required SettingKey<String> setting,
  }) async {
    final selected = await KazumiDialog.show<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<T>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in modes)
                  RadioListTile<T>(
                    value: mode,
                    title: Text(label(mode)),
                    subtitle: Text(
                      description(mode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (mounted && selected != null && selected != current) {
      await _save(setting, selected.name);
    }
  }
}

extension on BangumiAcceleration {
  String get description => switch (this) {
    BangumiAcceleration.direct => '訪問官方介面',
    BangumiAcceleration.ech => '啟用加密握手',
    BangumiAcceleration.mirror => '映象介面（預設）',
  };
}

extension on ImageAcceleration {
  String get label => switch (this) {
    ImageAcceleration.direct => '直連',
    ImageAcceleration.ech => 'ECH',
    ImageAcceleration.mirror => '映象',
  };

  String get description => switch (this) {
    ImageAcceleration.direct => '載入原始圖片',
    ImageAcceleration.ech => '加密握手（推薦）',
    ImageAcceleration.mirror => '使用圖片映象',
  };
}
