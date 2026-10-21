import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/network_mirror_settings.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';

class MirrorSettingsStep extends StatelessWidget {
  const MirrorSettingsStep({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingStepLayout(
    leading: OnboardingStepIcon(
      icon: Icons.public_rounded,
      shape: OnboardingIconShape.clover,
    ),
    title: '讓連線更順暢',
    subtitle: '番劇資訊與評論預設使用映象，也可選擇 ECH 或直連。圖片預設使用 ECH 加速。',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NetworkMirrorSettings(margin: EdgeInsets.zero),
        OnboardingHint(text: '可在「設定 → 網路設定」中調整。'),
      ],
    ),
  );
}
