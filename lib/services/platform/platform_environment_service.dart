import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kazumi/services/logging/logger.dart';

class PlatformEnvironmentService {
  PlatformEnvironmentService._();

  static const _intentChannel = MethodChannel('com.predidit.kazumi/intent');

  static Future<bool> isRunningOnX11() async {
    if (!Platform.isLinux) {
      return false;
    }
    try {
      return await _intentChannel.invokeMethod('isRunningOnX11');
    } on PlatformException catch (e) {
      KazumiLogger().e("Failed to check X11 environment: '${e.message}'.");
      return false;
    }
  }

  /// Android TV or set-top box; set once by [detectTelevision] at startup.
  static bool isTelevision = false;

  static Future<void> detectTelevision() async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      isTelevision =
          await _intentChannel.invokeMethod<bool>('isTelevision') ?? false;
    } on PlatformException catch (e) {
      KazumiLogger().e("Failed to detect television: '${e.message}'.");
    }
  }

  static Future<int> getAndroidSdkVersion() async {
    if (!Platform.isAndroid) {
      return 0;
    }
    try {
      return await _intentChannel.invokeMethod('getAndroidSdkVersion');
    } on PlatformException catch (e) {
      KazumiLogger().e("Failed to get Android SDK version: '${e.message}'.");
      return 0;
    }
  }
}
