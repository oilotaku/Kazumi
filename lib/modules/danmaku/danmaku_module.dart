import 'package:flutter/material.dart';
import 'package:kazumi/utils/danmaku.dart';

class DanmakuEntry {
  // 彈幕內容
  String message;
  // 彈幕時間
  double time;
  // 彈幕型別 (1-普通彈幕，4-底部彈幕，5-頂部彈幕)
  int type;
  // 彈幕顏色
  Color color;
  // 彈幕來源 ([BiliBili], [Gamer])
  String source;

  DanmakuEntry(
      {required this.message,
      required this.time,
      required this.type,
      required this.color,
      required this.source});

  factory DanmakuEntry.fromJson(Map<String, dynamic> json) {
    String messageValue = json['m'];
    List<String> parts = json['p'].split(',');
    double timeValue = double.parse(parts[0]);
    int typeValue = int.parse(parts[1]);
    Color color = generateDanmakuColor(int.parse(parts[2]));
    String sourceValue = parts[3];
    return DanmakuEntry(
        time: timeValue,
        message: messageValue,
        type: typeValue,
        color: color,
        source: sourceValue);
  }

  /// 序列化為 JSON 格式 (與 fromJson 格式一致)
  Map<String, dynamic> toJson() {
    // 只儲存 RGB 部分 (與 DanDanPlay API 格式一致)
    final colorValue = ((color.r * 255).toInt() << 16) |
        ((color.g * 255).toInt() << 8) |
        (color.b * 255).toInt();
    return {
      'm': message,
      'p': '$time,$type,$colorValue,$source',
    };
  }
}
