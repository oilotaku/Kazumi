import 'dart:io';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/services/player/external_player.dart';

class ExternalPlaybackLauncher {
  final String Function() videoUrl;
  final String Function() referer;

  ExternalPlaybackLauncher({
    required this.videoUrl,
    required this.referer,
  });

  Future<void> launch() async {
    final currentVideoUrl = videoUrl();
    final currentReferer = referer();
    if ((Platform.isAndroid || Platform.isWindows) && currentReferer.isEmpty) {
      if (await ExternalPlayer.launchUrlWithMime(
          currentVideoUrl, 'video/mp4')) {
        KazumiDialog.showToast(
          message: '嘗試喚起外部播放器',
        );
      } else {
        KazumiDialog.showToast(
          message: '喚起外部播放器失敗',
        );
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      if (await ExternalPlayer.launchUrlWithReferer(
          currentVideoUrl, currentReferer)) {
        KazumiDialog.showToast(
          message: '嘗試喚起外部播放器',
        );
      } else {
        KazumiDialog.showToast(
          message: '喚起外部播放器失敗',
        );
      }
    } else if (Platform.isLinux && currentReferer.isEmpty) {
      final result =
          await ExternalPlayer.launchLinuxDesktopPlayer(currentVideoUrl);
      switch (result) {
        case LinuxExternalPlayerResult.launched:
          KazumiDialog.showToast(message: '嘗試喚起外部播放器');
        case LinuxExternalPlayerResult.cancelled:
          break;
        case LinuxExternalPlayerResult.unavailable:
          KazumiDialog.showToast(message: '系統應用選擇器不可用');
        case LinuxExternalPlayerResult.failed:
          KazumiDialog.showToast(message: '喚起外部播放器失敗');
      }
    } else {
      if (currentReferer.isEmpty) {
        KazumiDialog.showToast(
          message: '暫不支援該裝置',
        );
      } else {
        KazumiDialog.showToast(
          message: '暫不支援該規則',
        );
      }
    }
  }
}
