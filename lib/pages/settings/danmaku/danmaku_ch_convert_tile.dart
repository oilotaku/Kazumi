import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_dropdown_tile.dart';
import 'package:kazumi/modules/danmaku/danmaku_ch_convert.dart';
import 'package:kazumi/services/storage/storage.dart';

extension _ConversionLabel on DanmakuChConvert {
  String get label => switch (this) {
    DanmakuChConvert.none => '不轉換',
    DanmakuChConvert.simplified => '轉為簡體',
    DanmakuChConvert.traditional => '轉為繁體',
  };
}

class DanmakuChConvertTile extends StatefulWidget {
  const DanmakuChConvertTile({super.key});

  @override
  State<DanmakuChConvertTile> createState() => _DanmakuChConvertTileState();
}

class _DanmakuChConvertTileState extends State<DanmakuChConvertTile> {
  late final _settingsChanges = GStorage.watchSettings([
    SettingsKeys.danmakuChConvert,
  ]);
  bool _saving = false;

  Future<void> _selectMode(DanmakuChConvert mode) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await GStorage.putSetting(SettingsKeys.danmakuChConvert, mode.value);
    } catch (_) {
      if (mounted) {
        KazumiDialog.showToast(context: context, message: '簡繁轉換設定儲存失敗，請重試');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _settingsChanges,
      builder: (context, _) {
        final mode = DanmakuChConvert.fromValue(
          GStorage.getSetting(SettingsKeys.danmakuChConvert),
        );
        return SettingsDropdownTile<DanmakuChConvert>(
          leading: Icons.translate_rounded,
          title: const Text('簡繁轉換'),
          description: const Text('下次聯網載入彈幕時生效，已快取彈幕保留下載時的文字'),
          enabled: !_saving,
          value: mode,
          options: {
            for (final option in DanmakuChConvert.values) option: option.label,
          },
          onChanged: _selectMode,
        );
      },
    );
  }
}
