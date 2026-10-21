import 'package:flutter/material.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';
import 'package:kazumi/pages/plugin_editor/plugin_catalog_view.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

class PluginShopStep extends StatelessWidget {
  const PluginShopStep({
    super.key,
    required this.controller,
  });

  final PluginsController controller;

  @override
  Widget build(BuildContext context) => PluginCatalogView.onboarding(
        controller: controller,
        builder: (context, slivers) => OnboardingStepLayout.slivers(
          leading: const OnboardingStepIcon(
            icon: Icons.extension_rounded,
            shape: OnboardingIconShape.flower,
          ),
          title: '新增番劇來源',
          subtitle: '規則決定從哪些站點搜尋和播放番劇，新增至少一條即可開始觀看。',
          slivers: slivers,
        ),
      );
}
