import 'package:flutter/services.dart' show rootBundle;

/// 顯示用的簡體 → 台灣正體轉換(OpenCC s2twp 字典,最長詞優先)。
/// 只用在畫面上;送 API、搜尋片源/彈幕的字串一律保留原文。
class ZhConvert {
  ZhConvert._();

  static final Map<String, String> _dict = {};
  static final Map<String, String> _cache = {};
  static int _maxLen = 1;

  static Future<void> init() async {
    if (_dict.isNotEmpty) return;
    try {
      final raw = await rootBundle.loadString('assets/opencc/s2twp.txt');
      for (final line in raw.split('\n')) {
        final tab = line.indexOf('\t');
        if (tab <= 0) continue;
        final key = line.substring(0, tab);
        _dict[key] = line.substring(tab + 1);
        if (key.length > _maxLen) _maxLen = key.length;
      }
    } catch (_) {
      // 字典載入失敗就顯示原文
    }
  }

  static final RegExp _han = RegExp(r'[一-鿿]');

  static String tw(String text) {
    if (_dict.isEmpty || text.isEmpty || !_han.hasMatch(text)) return text;
    final cached = _cache[text];
    if (cached != null) return cached;
    final out = StringBuffer();
    var i = 0;
    while (i < text.length) {
      var matched = false;
      final end = i + _maxLen < text.length ? i + _maxLen : text.length;
      for (var j = end; j > i; j--) {
        final hit = _dict[text.substring(i, j)];
        if (hit != null) {
          out.write(hit);
          i = j;
          matched = true;
          break;
        }
      }
      if (!matched) {
        out.write(text[i]);
        i++;
      }
    }
    final result = out.toString();
    if (_cache.length > 4000) _cache.clear();
    _cache[text] = result;
    return result;
  }
}

extension ZhConvertString on String {
  /// 顯示用:簡體轉台灣正體
  String get tw => ZhConvert.tw(this);
}
