import 'dart:async';

import 'package:kazumi/services/video_source/video_source_format.dart';

/// 影片源型別
enum VideoSourceType {
  /// 線上解析（WebView）
  online,

  /// 本地快取
  cached,
}

/// 影片源解析結果
class VideoSource {
  /// 影片 URL (M3U8/MP4/本地路徑)
  final String url;

  /// 播放偏移量（秒）
  final int offset;

  /// 影片源型別
  final VideoSourceType type;

  /// 解析影片源時確認的媒體格式提示
  final VideoSourceFormat format;

  const VideoSource({
    required this.url,
    required this.offset,
    required this.type,
    this.format = VideoSourceFormat.auto,
  });

  @override
  String toString() =>
      'VideoSource(url: $url, offset: $offset, type: $type, format: $format)';
}

/// 影片源未找到異常
class VideoSourceNotFoundException implements Exception {
  final String message;
  const VideoSourceNotFoundException([this.message = 'Video source not found']);

  @override
  String toString() => 'VideoSourceNotFoundException: $message';
}

/// 影片源解析超時異常
class VideoSourceTimeoutException implements Exception {
  final Duration timeout;
  const VideoSourceTimeoutException(this.timeout);

  @override
  String toString() =>
      'VideoSourceTimeoutException: Timed out after ${timeout.inSeconds}s';
}

/// 影片源解析取消異常
class VideoSourceCancelledException implements Exception {
  const VideoSourceCancelledException();

  @override
  String toString() =>
      'VideoSourceCancelledException: Resolution was cancelled';
}

/// 影片源解析服務介面
///
/// 抽象影片源的獲取方式，支援多種實現：
/// - WebView 解析（線上）
/// - 本地快取讀取
/// - 組合策略（優先快取，回退 WebView）
abstract class IVideoSourceService {
  /// 解析影片源 URL
  ///
  /// [episodeUrl] 集數頁面 URL
  /// [useLegacyParser] 是否使用舊版解析器（iframe 監聽）
  /// [offset] 播放偏移量（秒）
  /// [timeout] 解析超時時間
  ///
  /// 返回 [VideoSource] 包含解析後的影片 URL 和後設資料
  ///
  /// 可能丟擲：
  /// - [VideoSourceNotFoundException] 未找到影片源
  /// - [VideoSourceTimeoutException] 解析超時
  /// - [VideoSourceCancelledException] 解析被取消
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 30),
  });

  /// 取消當前正在進行的解析
  ///
  /// 呼叫後，正在進行的 [resolve] 會丟擲 [VideoSourceCancelledException]
  void cancel();

  /// 釋放資源
  Future<void> dispose();
}
