import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';
import 'package:kazumi/services/network/bangumi_acceleration.dart';

class BangumiMirrorErrorWidget extends StatelessWidget {
  const BangumiMirrorErrorWidget({
    super.key,
    required this.onRetry,
    this.onSettingsReturned,
  });

  final VoidCallback onRetry;
  final VoidCallback? onSettingsReturned;

  @override
  Widget build(BuildContext context) {
    final acceleration = BangumiAcceleration.current;

    return GeneralErrorWidget(
      title: '暫時無法載入番劇',
      errMsg: '請檢查網路連線，或調整加速設定後重試。\n番劇條目加速：${acceleration.label}',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
      actions: [
        StateActionButton.tonal(
          onPressed: () async {
            await context.pushNamed('/settings/proxy/');
            onSettingsReturned?.call();
          },
          icon: Icons.tune_rounded,
          text: '加速設定',
        ),
      ],
    );
  }
}
