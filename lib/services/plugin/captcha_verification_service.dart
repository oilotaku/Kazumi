import 'dart:async';

import 'package:kazumi/services/plugin/plugin_cookie_manager.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/utils/async_single_flight.dart';
import 'package:kazumi/webview/captcha/captcha_webview_controller.dart';

/// 驗證碼驗證服務
///
/// 三種驗證流程各自載入搜尋頁並等待驗證透過：
///
/// - **型別1：圖片驗證碼**（[loadForCaptcha] + [submitCaptcha]）
///   監聽驗證碼圖片並經 [onCaptchaImageUrl] 交給 UI，UI 回傳使用者輸入後
///   在頁面內填寫並提交，驗證碼圖片消失即視為透過。
/// - **型別2：自動點選驗證按鈕**（[loadForButtonClick]）
///   檢測到按鈕後自動點選，按鈕消失或頁面跳轉即視為透過。
/// - **型別3：自定義 JavaScript 驗證**（[loadForCustomScript]）
///   注入規則提供的指令碼，指令碼呼叫 KazumiCaptcha.done 或返回 true 即透過。
///
/// 驗證透過後統一收尾：收割驗證後頁面的 HTML，儲存 Cookie 與 User-Agent 到
/// [PluginCookieManager]，再將 HTML 交給 onVerified。UI 能解析該 HTML 時直接
/// 展示結果，否則回落到重新檢索。
class CaptchaVerificationService {
  CaptchaWebviewController? _controller;

  final StreamController<String?> _captchaImageStreamController =
      StreamController<String?>.broadcast();

  Stream<String?> get onCaptchaImageUrl => _captchaImageStreamController.stream;

  StreamSubscription? _imageFoundSub;
  StreamSubscription? _disappearedSub;
  StreamSubscription? _logSub;

  bool _isInitialized = false;
  bool _disposed = false;
  String _pageUrl = '';

  /// 共享收尾任務。收割頁面需要數秒，期間使用者仍可取消，兩條路徑便會同時
  /// 對同一個 WebView 解除安裝頁面和讀取內容。匯合到同一次收尾以避免併發訪問，
  /// 也使 [cancelAndSave] 的 await 覆蓋住呼叫方隨後的 dispose。
  final AsyncSingleFlight<String> _finalize = AsyncSingleFlight<String>();

  bool _outcomeClaimed = false;

  /// 認領向 UI 提交結果的權利。
  ///
  /// 收尾任務的歸屬與結果的歸屬可以不同：成功路徑先啟動收尾，使用者隨後取消，
  /// 此時應由取消提交結果。故在共享收尾之外單獨仲裁——取消在 [cancelAndSave]
  /// 入口同步認領，成功路徑在收尾結束後認領，後到者放棄提交。
  bool _claimOutcome() {
    if (_outcomeClaimed) return false;
    _outcomeClaimed = true;
    return true;
  }

  /// 訂閱驗證透過事件：收尾後把收割到的 HTML 交給 [onVerified]。
  ///
  /// [onFinalizing] 在觀察到驗證透過、開始收尾之前觸發。收尾需要數秒，
  /// 呼叫方若對驗證設有超時，必須以此為準而非 [onVerified]，
  /// 否則超時會在收尾途中把已經成功的驗證判成失敗。
  void _listenForVerification(
    String pluginName,
    void Function(String pageHtml) onVerified, {
    String logPrefix = '',
    void Function()? onFinalizing,
  }) {
    final controller = _controller;
    if (controller == null) return;

    Future<void> onDisappeared() async {
      _disappearedSub?.cancel();
      // 重新讀取：訂閱到事件之間可能已被 dispose 置空。
      final current = _controller;
      if (current == null) return;
      onFinalizing?.call();
      final pageHtml = await _finalize.run(() =>
          _saveCookiesAndUnload(current, pluginName, logPrefix: logPrefix));
      if (_disposed || !_claimOutcome()) return;
      onVerified(pageHtml);
    }

    _disappearedSub?.cancel();
    _disappearedSub = controller.onCaptchaDisappeared.listen((_) {
      onDisappeared();
    });
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized || _disposed) return;
    _controller = CaptchaWebviewControllerFactory.getController();
    final initializedFuture = _controller!.onInitialized.first
        .timeout(const Duration(seconds: 10), onTimeout: () => false);

    await _controller!.init();
    if (_disposed) return;
    await initializedFuture;
    if (_disposed) return;

    _logSub?.cancel();
    _logSub = _controller!.onLog.listen((msg) => KazumiLogger().d(msg));

    _isInitialized = true;
    KazumiLogger().i('[CaptchaVerificationService] WebView initialized');
  }

  /// 載入指定頁面並開始監聽驗證碼圖片
  ///
  /// [url] 要載入的頁面地址
  /// [captchaXpath] 驗證碼圖片元素的 XPath
  /// [inputXpath] 可選，驗證碼輸入框的 XPath。如果提供，會在檢測驗證碼前先觸發輸入框的 focus 事件
  Future<void> loadForCaptcha(String url, String captchaXpath,
      {String? inputXpath}) async {
    _pageUrl = url;
    await _ensureInitialized();
    if (_disposed || _controller == null) return;

    _imageFoundSub?.cancel();
    _imageFoundSub = _controller!.onCaptchaImageFound.listen((src) {
      KazumiLogger()
          .i('[CaptchaVerificationService] Captcha image found: $src');
      if (!_captchaImageStreamController.isClosed) {
        _captchaImageStreamController.add(src);
      }
    });

    await _controller!.loadPage(url, captchaXpath, inputXpath: inputXpath);
    KazumiLogger().i('[CaptchaVerificationService] Page loading: $url');
  }

  /// 在頁面中填寫 [captchaCode] 並點選 [buttonXpath] 提交
  ///
  /// [onFinalizing] 在驗證透過、開始收尾時觸發，早於 [onVerified] 數秒。
  Future<void> submitCaptcha({
    required String captchaCode,
    required String inputXpath,
    required String buttonXpath,
    required String pluginName,
    required void Function(String pageHtml) onVerified,
    void Function()? onFinalizing,
  }) async {
    if (_controller == null) {
      KazumiLogger()
          .w('[CaptchaVerificationService] submitCaptcha called before init');
      return;
    }

    KazumiLogger()
        .i('[CaptchaVerificationService] Submitting captcha code via interact');

    _listenForVerification(pluginName, onVerified, onFinalizing: onFinalizing);
    await _controller!
        .submitCaptchaInteract(captchaCode, inputXpath, buttonXpath);
  }

  /// 載入 [url] 並在檢測到 [buttonXpath] 後自動點選
  Future<void> loadForButtonClick({
    required String url,
    required String buttonXpath,
    required String pluginName,
    required void Function(String pageHtml) onVerified,
  }) async {
    _pageUrl = url;
    await _ensureInitialized();
    if (_disposed || _controller == null) return;

    _listenForVerification(pluginName, onVerified, logPrefix: '(type2) ');
    await _controller!.loadPageForButtonClick(url, buttonXpath);
    KazumiLogger().i(
        '[CaptchaVerificationService] (type2) Page loading for button click: $url');
  }

  /// 載入 [url] 並注入規則提供的驗證指令碼 [script]
  Future<void> loadForCustomScript({
    required String url,
    required String script,
    required String pluginName,
    required void Function(String pageHtml) onVerified,
  }) async {
    _pageUrl = url;
    await _ensureInitialized();
    if (_disposed || _controller == null) return;

    _listenForVerification(pluginName, onVerified, logPrefix: '(type3) ');
    await _controller!.loadPageForCustomScript(url, script);
    KazumiLogger().i(
        '[CaptchaVerificationService] (type3) Page loading for custom script: $url');
  }

  /// 使用者取消驗證：認領結果提交權並儲存已有 Cookie。
  ///
  /// 認領必須發生在任何 await 之前，這樣即使驗證恰好在此刻透過，
  /// 其 onVerified 也不會再提交結果，由呼叫方按取消語義收尾。
  Future<void> cancelAndSave(String pluginName) async {
    _claimOutcome();
    _disappearedSub?.cancel();
    _disappearedSub = null;
    // 先取到本地：dispose 可能在兩次 await 之間把 _controller 置空。
    final controller = _controller;
    if (controller == null || _pageUrl.isEmpty) return;
    // 若驗證成功路徑已在收尾，這裡會匯合到那一次並等它把 Cookie 存完。
    await _finalize.run(() => _saveCookiesAndUnload(
          controller,
          pluginName,
          logPrefix: 'on cancel ',
          harvestHtml: false,
        ));
  }

  /// 儲存 Cookie 與 User-Agent 並解除安裝頁面。
  ///
  /// [harvestHtml] 為 true 時先收割驗證後頁面的 HTML 並返回，
  /// 供上層直接解析檢索結果；取消路徑不收割。
  ///
  /// 按契約不拋異常：成功與取消兩條路徑共享這一個 Future，任何異常都會同時
  /// 打斷兩邊——成功路徑的 onVerified 不再觸發，取消路徑 onDismiss 裡的
  /// dispose 與回落檢索也會被跳過。故內部兜住異常，盡力返回已取到的內容。
  Future<String> _saveCookiesAndUnload(
    CaptchaWebviewController controller,
    String pluginName, {
    String logPrefix = '',
    bool harvestHtml = true,
  }) async {
    String pageHtml = '';
    try {
      // 先收割：等待結果頁穩定的同時，也讓 JS 寫入的 Cookie 落地後再讀取。
      if (harvestHtml) {
        pageHtml = await _waitForPageHtml(controller);
        KazumiLogger().i(
            '[CaptchaVerificationService] ${logPrefix}Harvested page html length: ${pageHtml.length}');
      }
      final cookieString = await controller.getCookieString(_pageUrl);
      final userAgent = await controller.getUserAgent();
      KazumiLogger().i(
          '[CaptchaVerificationService] ${logPrefix}Captured cookies: $cookieString');
      if (cookieString.isNotEmpty) {
        await PluginCookieManager.instance.saveFromWebView(
            pluginName, _pageUrl, cookieString,
            userAgent: userAgent);
        KazumiLogger().i(
            '[CaptchaVerificationService] ${logPrefix}Cookies saved for plugin: $pluginName');
      }
      await controller.unloadPage();
    } catch (error, stackTrace) {
      KazumiLogger().w(
        '[CaptchaVerificationService] ${logPrefix}Finalize failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return pageHtml;
  }

  /// 等待驗證後的頁面載入完成並返回其 HTML。
  /// 驗證消失事件可能早於結果頁載入完成，因此短暫輪詢；
  /// 超時返回空字串，由上層回落到重新檢索。
  Future<String> _waitForPageHtml(CaptchaWebviewController controller) async {
    const maxAttempts = 10;
    const interval = Duration(milliseconds: 300);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (_disposed) return '';
      final html = await controller.getPageHtml();
      if (html.trim().isNotEmpty) return html;
      await Future.delayed(interval);
    }
    return '';
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _imageFoundSub?.cancel();
    _disappearedSub?.cancel();
    _logSub?.cancel();
    if (!_captchaImageStreamController.isClosed) {
      _captchaImageStreamController.close();
    }
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    KazumiLogger().i('[CaptchaVerificationService] Disposed');
  }
}
