/// 集數源站 URL 歸一化。
///
/// 把插件抓取到的原始 `href`（可能是相對路徑、缺協議、帶尾斜槓或多餘噪聲）
/// 轉換為一個穩定一致的絕對 URL，使"同一集"在播放、下載、歷史回填等不同入口
/// 始終得到同一個字串，可作為身份匹配的主鍵（`pageUrl`）。
///
/// 歸一化規則：
/// - 去除首尾空白；空輸入返回空串（呼叫方據此判斷"無 URL"）。
/// - 相對路徑基於 [baseUrl] 補全為絕對 URL。
/// - 與 [baseUrl] 同站（同 host、同顯式埠）的 URL，協議統一到 [baseUrl]
///   宣告的協議，避免同一集因 `http`/`https` 混用產生兩個 key；跨站或埠
///   不同的 URL 保持原協議不動——規則站點可能僅支援 http（如自建反代），
///   改寫協議會導致無法訪問。
/// - 去除 path 多餘尾斜槓（根路徑 `/` 保留）。
/// - 去除空 query。
/// - 冪等：`normalizeEpisodeUrl(b, normalizeEpisodeUrl(b, x))` 等於
///   `normalizeEpisodeUrl(b, x)`。
///
/// 歸一化結果同時作為"身份 key"與可訪問的"請求 URL"使用，因此歸一化
/// 不得改變 URL 實際指向的端點，協議口徑以規則中使用者宣告的 [baseUrl] 為準。
String normalizeEpisodeUrl(String baseUrl, String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final rawUri = Uri.tryParse(trimmed);
  final baseUri = Uri.tryParse(baseUrl.trim());
  final hasValidBase =
      baseUri != null && baseUri.hasScheme && baseUri.host.isNotEmpty;

  Uri? resolved;
  if (rawUri != null && rawUri.hasScheme && rawUri.host.isNotEmpty) {
    // 已是絕對 URL。
    resolved = rawUri;
  } else if (hasValidBase) {
    try {
      resolved = baseUri.resolve(trimmed);
    } catch (_) {
      resolved = null;
    }
  }

  // 無法解析為絕對 URL（baseUrl 缺失/非法），原樣返回去空白後的輸入。
  if (resolved == null || resolved.host.isEmpty) {
    return trimmed;
  }

  // 同站 URL 的協議統一到 baseUrl 宣告的協議。
  if (hasValidBase &&
      _isHttpScheme(baseUri.scheme) &&
      _isHttpScheme(resolved.scheme) &&
      resolved.scheme != baseUri.scheme &&
      resolved.host == baseUri.host &&
      resolved.hasPort == baseUri.hasPort &&
      (!resolved.hasPort || resolved.port == baseUri.port)) {
    resolved = resolved.replace(scheme: baseUri.scheme);
  }

  // 去除 path 尾斜槓（根路徑除外）。
  String path = resolved.path;
  while (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  final bool hasQuery = resolved.hasQuery && resolved.query.isNotEmpty;
  final bool hasFragment =
      resolved.hasFragment && resolved.fragment.isNotEmpty;

  final normalized = Uri(
    scheme: resolved.scheme,
    host: resolved.host,
    port: resolved.hasPort ? resolved.port : null,
    path: path,
    query: hasQuery ? resolved.query : null,
    fragment: hasFragment ? resolved.fragment : null,
  );

  return normalized.toString();
}

bool _isHttpScheme(String scheme) => scheme == 'http' || scheme == 'https';
