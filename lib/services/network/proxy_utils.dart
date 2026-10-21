/// 代理相關的工具函式
class ProxyUtils {
  // 防止例項化
  ProxyUtils._();

  /// 解析代理 URL，返回 (主機, 埠)
  ///
  /// 支援的格式:
  /// - http://127.0.0.1:7890
  /// - 127.0.0.1:7890
  static (String, int)? parseProxyUrl(String url) {
    url = url.trim();
    if (url.isEmpty) return null;

    String hostPort = url;

    // 移除 http:// 字首
    if (url.toLowerCase().startsWith('http://')) {
      hostPort = url.substring(7);
    } else if (url.toLowerCase().startsWith('https://')) {
      hostPort = url.substring(8);
    }

    // 解析主機和埠
    final parts = hostPort.split(':');
    if (parts.length != 2) return null;

    final host = parts[0];
    final port = int.tryParse(parts[1]);
    if (host.isEmpty || port == null) return null;

    return (host, port);
  }

  /// 獲取格式化的代理 URL（用於 mpv）
  static String? getFormattedProxyUrl(String url) {
    final parsed = parseProxyUrl(url);
    if (parsed == null) return null;
    return 'http://${parsed.$1}:${parsed.$2}';
  }

  /// 驗證代理 URL 是否有效
  static bool isValidProxyUrl(String url) {
    return parseProxyUrl(url) != null;
  }
}
