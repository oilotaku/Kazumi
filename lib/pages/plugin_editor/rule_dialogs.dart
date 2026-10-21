import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/pages/plugin_editor/rule_management_widgets.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/services/plugin/plugin_import_parser.dart';
import 'package:kazumi/utils/encoding.dart';

enum RuleAddSource { catalog, clipboard, file, create }

Future<RuleAddSource?> showRuleAddDialog(BuildContext context) =>
    KazumiDialog.show<RuleAddSource>(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return _RuleDialog(
          title: '新增規則',
          icon: Icons.add_circle_outline_rounded,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('選擇一種方式，新增新的番劇來源。'),
              const SizedBox(height: 20),
              for (final option in [
                (
                  RuleAddSource.catalog,
                  Icons.travel_explore_rounded,
                  '瀏覽規則庫',
                  '發現並安裝社群規則'
                ),
                (
                  RuleAddSource.clipboard,
                  Icons.content_paste_rounded,
                  '從剪貼簿匯入',
                  '貼上規則連結或 JSON'
                ),
                (
                  RuleAddSource.file,
                  Icons.file_open_outlined,
                  '從檔案匯入',
                  '讀取本地 JSON 規則檔案'
                ),
                (
                  RuleAddSource.create,
                  Icons.edit_note_rounded,
                  '新建規則',
                  '從模板開始編寫'
                ),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: option.$1 == RuleAddSource.catalog
                        ? colors.secondaryContainer
                        : colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(
                        option.$1 == RuleAddSource.catalog ? 20 : 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      minVerticalPadding: 14,
                      leading: Icon(option.$2, color: colors.onSurfaceVariant),
                      title: Text(option.$3),
                      subtitle: Text(option.$4),
                      trailing:
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                      onTap: () => Navigator.of(context).pop(option.$1),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消')),
          ],
        );
      },
    );

Future<bool> confirmRuleDeletion(
        BuildContext context, Set<String> names) async =>
    await KazumiDialog.show<bool>(
      context: context,
      builder: (context) => _RuleDialog(
        title: names.length == 1 ? '刪除這條規則？' : '刪除 ${names.length} 條規則？',
        icon: Icons.delete_outline_rounded,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(names.take(5).join('、') + (names.length > 5 ? ' 等' : ''),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text('刪除後將不再使用這些來源搜尋番劇。你可以稍後重新匯入規則。'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('保留')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
                minimumSize: const Size(88, 48)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('刪除'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> showRuleShareDialog(BuildContext context, Plugin plugin) async {
  final link = jsonToKazumiBase64(jsonEncode(plugin.toJson()));
  await KazumiDialog.show<void>(
    context: context,
    builder: (context) => _RuleDialog(
      title: '分享規則',
      icon: Icons.ios_share_rounded,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(plugin.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('複製規則連結，對方可在「新增規則」中從剪貼簿匯入。'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16)),
            constraints: const BoxConstraints(maxHeight: 180),
            child: SingleChildScrollView(
              child: SelectableText(link,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFamily: 'monospace')),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉')),
        FilledButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('複製連結'),
          onPressed: () async {
            try {
              await Clipboard.setData(ClipboardData(text: link));
              if (!context.mounted) return;
              KazumiDialog.dismiss(context: context);
              KazumiDialog.showToast(message: '規則連結已複製');
            } catch (_) {
              if (context.mounted) {
                KazumiDialog.showToast(context: context, message: '複製失敗，請重試');
              }
            }
          },
        ),
      ],
    ),
  );
}

Future<void> showRuleImportDialog(
  BuildContext context,
  PluginsController controller, {
  String initialValue = '',
}) =>
    KazumiDialog.show<void>(
      context: context,
      clickMaskDismiss: false,
      builder: (context) =>
          _RuleImportDialog(controller: controller, initialValue: initialValue),
    );

class _RuleImportDialog extends StatefulWidget {
  const _RuleImportDialog(
      {required this.controller, required this.initialValue});
  final PluginsController controller;
  final String initialValue;

  @override
  State<_RuleImportDialog> createState() => _RuleImportDialogState();
}

class _RuleImportDialogState extends State<_RuleImportDialog> {
  late final _text = TextEditingController(text: widget.initialValue);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    if (_saving) return;
    final result = PluginImportParser.parse(_text.text);
    if (result.plugins.isEmpty) {
      setState(() => _error = result.failures.isEmpty
          ? '沒有識別到規則，請貼上規則連結或 JSON。'
          : result.failures.first);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.updatePlugins(result.plugins);
      if (!mounted) return;
      KazumiDialog.dismiss(context: context);
      KazumiDialog.showToast(
          message: '已匯入 ${result.plugins.length} 條規則'
              '，跳過重複 ${result.duplicateCount} 條，失敗 ${result.failureCount} 條');
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '儲存失敗，內容已保留，請重試。';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: _RuleDialog(
          title: '匯入規則',
          icon: Icons.content_paste_go_rounded,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('支援多條 kazumi:// 連結、單條 JSON 或 JSON 陣列。同名規則會被替換。'),
              const SizedBox(height: 20),
              TextField(
                controller: _text,
                enabled: !_saving,
                minLines: 4,
                maxLines: 8,
                onChanged: (_) => setState(() => _error = null),
                decoration: ruleInputDecoration(context,
                        label: '規則內容', hint: '在這裡貼上規則連結或 JSON')
                    .copyWith(
                        alignLabelWithHint: true,
                        errorText: _error,
                        errorMaxLines: 4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton.icon(
              onPressed: _saving || _text.text.trim().isEmpty ? null : _import,
              icon: _saving
                  ? const LoadingIndicator(size: 20)
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_saving ? '正在匯入' : '匯入規則'),
            ),
          ],
        ),
      );
}

class _RuleDialog extends StatelessWidget {
  const _RuleDialog({
    required this.title,
    required this.icon,
    required this.content,
    required this.actions,
  });

  final String title;
  final IconData icon;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      constraints: const BoxConstraints(maxWidth: 560),
      insetPadding: const EdgeInsets.all(24),
      scrollable: true,
      icon: Icon(icon, color: colors.secondary, size: 32),
      title: Text(title),
      content: SizedBox(width: 480, child: content),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      actionsOverflowButtonSpacing: 8,
      actions: actions,
    );
  }
}
