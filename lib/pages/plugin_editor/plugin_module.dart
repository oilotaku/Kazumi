import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/plugin_editor/plugin_editor_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_shop_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_test_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_view_page.dart';
import 'package:kazumi/pages/route_error_page.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

final pluginModule = createModule(
  path: '/plugin',
  register: (c) {
    c
      ..route(
        '/',
        child: (context, state) => PluginViewPage(
          controller: inject<PluginsController>(),
        ),
      )
      ..route(
        '/shop',
        child: (context, state) => PluginShopPage(
          controller: inject<PluginsController>(),
        ),
      )
      ..route(
        '/test',
        child: (context, state) {
          final plugin = state.arguments;
          if (plugin is! Plugin) {
            return const RouteErrorPage(message: '規則測試參數無效，請返回後重試。');
          }
          return PluginTestPage(plugin: plugin);
        },
      )
      ..route(
        '/editor',
        child: (context, state) {
          final plugin = state.arguments;
          if (plugin is! Plugin) {
            return const RouteErrorPage(message: '規則編輯參數無效，請返回後重試。');
          }
          return PluginEditorPage(
            plugin: plugin,
            controller: inject<PluginsController>(),
          );
        },
      );
  },
);
