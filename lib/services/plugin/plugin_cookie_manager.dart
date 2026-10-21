import 'package:cookie_jar/cookie_jar.dart';
import 'package:kazumi/services/logging/logger.dart';

/// 每條規則的 Cookie 管理器
///
/// 為每條規則維護一個獨立的記憶體 [CookieJar]，
/// 透過 [saveFromWebView] 將 WebView 捕獲的 document.cookie 字串
/// 解析後存入對應規則的 jar。規則請求執行器按需讀取並組裝 Cookie 請求頭。
/// 驗證 Cookie 通常與 User-Agent 綁定，故同時記錄 WebView 的 UA，
/// 供後續 dio 請求對齊指紋。
/// Cookie 僅在當前 App 會話內有效，重啟後需重新驗證。
class PluginCookieManager {
  PluginCookieManager._();
  static final PluginCookieManager instance = PluginCookieManager._();

  final Map<String, CookieJar> _jars = {};
  final Map<String, String> _userAgents = {};

  CookieJar _getJar(String pluginName) {
    return _jars.putIfAbsent(pluginName, () => CookieJar());
  }

  Future<void> saveFromWebView(
      String pluginName, String pageUrl, String cookieString,
      {String? userAgent}) async {
    if (userAgent != null && userAgent.trim().isNotEmpty) {
      _userAgents[pluginName] = userAgent.trim();
    }
    if (cookieString.trim().isEmpty) return;
    final uri = Uri.tryParse(pageUrl);
    if (uri == null) return;

    final jar = _getJar(pluginName);
    final cookies = _parseCookieString(cookieString, uri);
    if (cookies.isEmpty) return;

    await jar.saveFromResponse(uri, cookies);
    KazumiLogger().i(
        '[PluginCookieManager] Saved ${cookies.length} cookies for $pluginName');
  }

  /// 解析字串為 [Cookie] 列表
  List<Cookie> _parseCookieString(String raw, Uri uri) {
    final cookies = <Cookie>[];
    for (final part in raw.split(';')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) continue;
      final name = trimmed.substring(0, eqIndex).trim();
      final value = trimmed.substring(eqIndex + 1).trim();
      try {
        final cookie = Cookie(name, value)
          ..domain = uri.host
          ..path = '/';
        cookies.add(cookie);
      } catch (_) {}
    }
    return cookies;
  }

  Future<List<Cookie>> loadForRequest(
    String pluginName,
    Uri uri,
  ) async {
    final jar = _jars[pluginName];
    if (jar == null) return <Cookie>[];
    return jar.loadForRequest(uri);
  }

  /// 驗證時 WebView 使用的 User-Agent；未驗證過的規則返回 null
  String? userAgentFor(String pluginName) => _userAgents[pluginName];
}
