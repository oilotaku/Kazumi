import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/split_list_row.dart';
import 'package:kazumi/services/network/metered_network_service.dart';
import 'package:kazumi/services/player/low_memory_mode.dart';

class LowMemoryModeSettingsTile extends StatelessWidget {
  const LowMemoryModeSettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return _ModeBuilder(builder: (context, mode, isMetered) {
      return SettingsTile(
        leading: Icons.data_saver_on_rounded,
        title: const Text('低記憶體模式'),
        description: Text(mode.statusDescription(isMetered)),
        value: Text(mode.label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onPressed: (_) => KazumiDialog.show<void>(
          builder: (_) => const _LowMemoryModeDialog(),
        ),
      );
    });
  }
}

class _LowMemoryModeDialog extends StatefulWidget {
  const _LowMemoryModeDialog();

  @override
  State<_LowMemoryModeDialog> createState() => _LowMemoryModeDialogState();
}

class _LowMemoryModeDialogState extends State<_LowMemoryModeDialog> {
  bool _saving = false;

  Future<void> _selectMode(LowMemoryMode? mode) async {
    if (mode == null || _saving) return;
    setState(() => _saving = true);
    try {
      await mode.save();
      if (!mounted) return;
      KazumiDialog.dismiss(context: context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      KazumiDialog.showToast(context: context, message: '設定儲存失敗，請重試');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('低記憶體模式'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: _ModeBuilder(builder: (context, mode, isMetered) {
          final enabled = mode.isEnabled(isMetered: isMetered);
          final foreground =
              enabled ? colors.onSecondaryContainer : colors.onSurfaceVariant;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: enabled
                        ? colors.secondaryContainer
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        enabled
                            ? Icons.data_saver_on_rounded
                            : Icons.data_usage_rounded,
                        color: foreground,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          mode.statusDescription(isMetered),
                          style: textTheme.bodyMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RadioGroup<LowMemoryMode>(
                groupValue: mode,
                onChanged: _selectMode,
                child: SplitListGroup(
                  children: [
                    for (final option in LowMemoryMode.values)
                      SettingsTile<LowMemoryMode>.radioTile(
                        title: Text(option == LowMemoryMode.auto
                            ? '${option.label}（預設）'
                            : option.label),
                        description: Text(option.description),
                        radioValue: option,
                        enabled: !_saving,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '減少快取可降低記憶體佔用和額外流量，網路不穩定時可能更容易緩衝。'
                '\n選擇後立即生效並記住選擇；跟隨網路僅影響線上播放。',
                style: textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => KazumiDialog.dismiss(context: context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class _ModeBuilder extends StatefulWidget {
  const _ModeBuilder({required this.builder});

  final Widget Function(BuildContext, LowMemoryMode, bool) builder;

  @override
  State<_ModeBuilder> createState() => _ModeBuilderState();
}

extension _ModePresentation on LowMemoryMode {
  String get label => switch (this) {
        LowMemoryMode.auto => '跟隨網路',
        LowMemoryMode.always => '始終開啟',
        LowMemoryMode.never => '始終關閉',
      };

  String get description => switch (this) {
        LowMemoryMode.auto => '行動資料自動開啟，WLAN / 有線網路自動關閉',
        LowMemoryMode.always => '所有網路均減少快取，降低記憶體佔用',
        LowMemoryMode.never => '使用完整快取，行動資料下也不自動開啟',
      };

  String statusDescription(bool isMetered) => switch (this) {
        LowMemoryMode.auto =>
          isMetered ? '已自動開啟 · 行動資料下減少快取' : '已自動關閉 · 非行動網路使用完整快取',
        LowMemoryMode.always => '已手動開啟 · 所有網路均減少快取',
        LowMemoryMode.never =>
          isMetered ? '已手動關閉 · 行動資料使用完整快取' : '已手動關閉 · 使用完整快取',
      };
}

class _ModeBuilderState extends State<_ModeBuilder> {
  late final Stream<void> _settingsChanges = LowMemoryMode.watch();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _settingsChanges,
      builder: (context, _) => ValueListenableBuilder<bool>(
        valueListenable: MeteredNetworkService.listenable,
        builder: (context, isMetered, _) =>
            widget.builder(context, LowMemoryMode.current, isMetered),
      ),
    );
  }
}
