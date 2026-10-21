import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

Future<void> updateAllPluginsWithFeedback(
  PluginsController controller, {
  required bool ensureCatalog,
}) async {
  KazumiDialog.showToast(message: '更新中');
  try {
    final result = await controller.tryUpdateAllPlugin(
      ensureCatalog: ensureCatalog,
    );
    KazumiDialog.showToast(message: _batchUpdateMessage(result));
  } catch (_) {
    KazumiDialog.showToast(message: '更新規則失敗');
  }
}

Future<PluginUpdateResult> updatePluginWithFeedback(
  PluginsController controller,
  String name, {
  required bool installing,
}) async {
  KazumiDialog.showToast(message: installing ? '匯入中' : '更新中');
  late final PluginUpdateResult result;
  try {
    result = await controller.tryUpdatePluginByName(name);
  } catch (_) {
    KazumiDialog.showToast(message: '儲存規則失敗');
    return PluginUpdateResult.failed;
  }
  final message = switch (result) {
    PluginUpdateResult.updated => installing ? '匯入成功' : '更新成功',
    PluginUpdateResult.requiresNewerClient => '規則需要更高版本客戶端',
    PluginUpdateResult.failed => installing ? '匯入規則失敗' : '更新規則失敗',
    PluginUpdateResult.notNewer => '遠端規則版本不高於本地，已跳過更新',
  };
  KazumiDialog.showToast(message: message);
  return result;
}

String _batchUpdateMessage(PluginBatchUpdateResult result) {
  if (result.hasNoCandidates) {
    return '沒有可更新的規則';
  }
  if (result.failed == 0 &&
      result.requiresNewerClient == 0 &&
      result.notNewer == 0) {
    return '更新成功 ${result.updated} 條';
  }

  final parts = <String>['成功 ${result.updated} 條'];
  if (result.requiresNewerClient > 0) {
    parts.add('不相容 ${result.requiresNewerClient} 條');
  }
  if (result.notNewer > 0) {
    parts.add('已跳過 ${result.notNewer} 條');
  }
  if (result.failed > 0) {
    parts.add('失敗 ${result.failed} 條');
  }
  return '更新完成：${parts.join('，')}';
}
