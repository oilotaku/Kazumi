import 'dart:io';
import 'dart:async';

import 'package:kazumi/webview/captcha/impl/captcha_webview_inappwebview_impl.dart';
import 'package:kazumi/webview/captcha/impl/captcha_webview_windows_impl.dart';
import 'package:kazumi/webview/captcha/impl/captcha_webview_linux_impl.dart';

abstract class CaptchaWebviewController<T> {
  /// WebView controller.
  T? webviewController;

  /// For type-1 (captcha image), whether a captcha image has been detected,
  /// used to determine if verification is successful after page navigation
  bool captchaWasFound = false;

  /// For automated flows, set when JavaScript has triggered a verification
  /// action. A later navigation can then confirm success even if no captcha
  /// element disappears in the current DOM.
  bool buttonWasClicked = false;

  final StreamController<String> captchaImageFoundController =
      StreamController<String>.broadcast();
  final StreamController<void> captchaDisappearedController =
      StreamController<void>.broadcast();
  final StreamController<bool> initEventController =
      StreamController<bool>.broadcast();
  final StreamController<String> logEventController =
      StreamController<String>.broadcast();

  /// WebView 初始化完成事件
  Stream<bool> get onInitialized => initEventController.stream;

  /// 驗證碼圖片 src 找到時觸發（攜帶圖片絕對 URL）
  Stream<String> get onCaptchaImageFound => captchaImageFoundController.stream;

  /// 驗證完成時觸發
  Stream<void> get onCaptchaDisappeared => captchaDisappearedController.stream;

  /// 除錯日誌
  Stream<String> get onLog => logEventController.stream;

  /// 初始化 WebView
  Future<void> init();

  /// 載入指定 URL，並注入監聽驗證碼圖片的 JS 指令碼（型別1：圖片驗證碼）
  ///
  /// [url] 要載入的頁面地址（一般為搜尋 URL）
  /// [captchaXpath] 驗證碼圖片元素的 XPath 選擇器
  /// [inputXpath] 可選，驗證碼輸入框的 XPath。如果提供，會在檢測驗證碼前先觸發輸入框的 focus 事件（某些站點需要）
  Future<void> loadPage(String url, String captchaXpath, {String? inputXpath});

  /// 載入指定 URL，並注入監聽驗證按鈕的 JS 指令碼（型別2：自動點選驗證按鈕）
  ///
  /// 檢測到 [buttonXpath] 元素後立即模擬點選；按鈕消失或頁面跳轉時觸發 [onCaptchaDisappeared]。
  /// [url] 要載入的頁面地址
  /// [buttonXpath] 驗證按鈕元素的 XPath 選擇器
  Future<void> loadPageForButtonClick(String url, String buttonXpath);

  /// 載入指定 URL，並在頁面內執行自定義驗證指令碼（型別3：自定義 JS 驗證）
  ///
  /// 指令碼可呼叫 window.KazumiCaptcha.log/clicked/done/fail。
  Future<void> loadPageForCustomScript(String url, String script);

  /// 在 WebView 內透過 JS 模擬輸入驗證碼並模擬點選提交按鈕
  ///
  /// [captchaCode] 使用者輸入的驗證碼文字
  /// [inputXpath]  驗證碼輸入框元素的 XPath
  /// [buttonXpath] 提交按鈕元素的 XPath
  Future<void> submitCaptchaInteract(
      String captchaCode, String inputXpath, String buttonXpath);

  /// 獲取當前頁面的 Cookie 字串（"key1=val1; key2=val2"）
  ///
  /// [pageUrl] 當前載入的頁面地址，部分平臺用於精確過濾 Cookie
  Future<String> getCookieString(String pageUrl);

  /// 獲取當前頁面的完整 HTML（document.documentElement.outerHTML）
  ///
  /// 頁面仍在載入（document.readyState === 'loading'）時返回空字串，
  /// 由呼叫方決定是否重試。
  Future<String> getPageHtml();

  /// 獲取 WebView 實際使用的 User-Agent（navigator.userAgent）
  Future<String> getUserAgent();

  /// 解除安裝當前頁面（跳轉到 about:blank）
  Future<void> unloadPage();

  /// 釋放 WebView 資源
  void dispose();
}

class CaptchaWebviewControllerFactory {
  static CaptchaWebviewController getController() {
    if (Platform.isWindows) {
      return CaptchaWebviewWindowsImpl();
    }
    if (Platform.isLinux) {
      return CaptchaWebviewLinuxImpl();
    }
    // Android, iOS, macOS
    return CaptchaWebviewInAppWebviewImpl();
  }
}
