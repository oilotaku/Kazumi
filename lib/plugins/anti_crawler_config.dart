/// 反反爬蟲驗證型別
///
/// - [imageCaptcha] (1): WebView 抓取驗證碼圖片，引導使用者手動輸入後提交
/// - [autoClickButton] (2): WebView 檢測到驗證按鈕後自動點選，無需使用者互動
/// - [customJavaScript] (3): WebView 執行規則提供的驗證指令碼
///
/// 保留整數表示以便繼續新增驗證方式時向後相容。
class CaptchaType {
  static const int imageCaptcha = 1;
  static const int autoClickButton = 2;
  static const int customJavaScript = 3;
}

/// 反反爬蟲驗證頁檢測方式
class CaptchaDetectType {
  static const int xpath = 1;
  static const int text = 2;
  static const int regex = 3;
}

/// 反反爬蟲配置
///
/// 僅當 XPath 搜尋響應為驗證頁時，使用 WebView 載入搜尋頁，
/// 根據 [captchaType] 完成驗證並儲存 Cookie，隨後重試 XPath 搜尋。
class AntiCrawlerConfig {
  /// 是否啟用反反爬蟲功能
  bool enabled;

  /// 驗證型別，見 [CaptchaType] 中的常量
  ///
  /// - [CaptchaType.imageCaptcha] (1)：圖片驗證碼，需要使用者手動輸入
  /// - [CaptchaType.autoClickButton] (2)：自動點選驗證按鈕，無需使用者互動
  /// - [CaptchaType.customJavaScript] (3)：執行規則提供的驗證指令碼
  int captchaType;

  /// 驗證碼圖片元素的 XPath 選擇器（僅 captchaType == 1 時使用）
  /// 用於在 WebView 頁面中定位驗證碼圖片，透過 Canvas 抓取其畫素
  String captchaImage;

  /// 驗證碼輸入框元素的 XPath 選擇器（僅 captchaType == 1 時使用）
  /// 用於在 WebView 頁面中定位供使用者輸入驗證碼的 input 元素
  String captchaInput;

  /// 驗證按鈕元素的 XPath 選擇器
  ///
  /// - captchaType == 1：提交驗證碼的按鈕，模擬點選提交
  /// - captchaType == 2：目標驗證按鈕（如"我不是機器人"），檢測到後自動點選
  /// - captchaType == 3：不使用該欄位
  String captchaButton;

  /// 驗證頁檢測方式，見 [CaptchaDetectType] 中的常量
  int captchaDetectType;

  /// 驗證頁檢測內容
  ///
  /// 根據 [captchaDetectType] 可表示 XPath、普通文字或正規表示式。
  String captchaDetectValue;

  /// 自定義 JS 驗證指令碼（僅 captchaType == 3 時使用）
  String captchaScript;

  AntiCrawlerConfig({
    required this.enabled,
    required this.captchaType,
    required this.captchaImage,
    required this.captchaInput,
    required this.captchaButton,
    this.captchaDetectType = CaptchaDetectType.xpath,
    this.captchaDetectValue = '',
    this.captchaScript = '',
  });

  factory AntiCrawlerConfig.fromJson(Map<String, dynamic> json) {
    return AntiCrawlerConfig(
      enabled: json['enabled'] ?? false,
      captchaType: json['captchaType'] ?? CaptchaType.imageCaptcha,
      captchaImage: json['captchaImage'] ?? '',
      captchaInput: json['captchaInput'] ?? '',
      captchaButton: json['captchaButton'] ?? '',
      captchaDetectType: json['captchaDetectType'] ?? CaptchaDetectType.xpath,
      captchaDetectValue: json['captchaDetectValue'] ?? '',
      captchaScript: json['captchaScript'] ?? '',
    );
  }

  factory AntiCrawlerConfig.empty() {
    return AntiCrawlerConfig(
      enabled: false,
      captchaType: CaptchaType.imageCaptcha,
      captchaImage: '',
      captchaInput: '',
      captchaButton: '',
      captchaDetectType: CaptchaDetectType.xpath,
      captchaDetectValue: '',
      captchaScript: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'captchaType': captchaType,
      'captchaImage': captchaImage,
      'captchaInput': captchaInput,
      'captchaButton': captchaButton,
      'captchaDetectType': captchaDetectType,
      'captchaDetectValue': captchaDetectValue,
      'captchaScript': captchaScript,
    };
  }

  AntiCrawlerConfig copyWith({
    bool? enabled,
    int? captchaType,
    String? captchaImage,
    String? captchaInput,
    String? captchaButton,
    int? captchaDetectType,
    String? captchaDetectValue,
    String? captchaScript,
  }) {
    return AntiCrawlerConfig(
      enabled: enabled ?? this.enabled,
      captchaType: captchaType ?? this.captchaType,
      captchaImage: captchaImage ?? this.captchaImage,
      captchaInput: captchaInput ?? this.captchaInput,
      captchaButton: captchaButton ?? this.captchaButton,
      captchaDetectType: captchaDetectType ?? this.captchaDetectType,
      captchaDetectValue: captchaDetectValue ?? this.captchaDetectValue,
      captchaScript: captchaScript ?? this.captchaScript,
    );
  }
}
