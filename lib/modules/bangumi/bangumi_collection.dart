import 'package:kazumi/modules/bangumi/bangumi_item.dart';

import 'bangumi_collection_type.dart';

/// NOTE: 該類僅用於解析 Bangumi API 返回的收藏資料，不適用本地收藏
class BangumiCollection {
  /// 最後更新時間
  DateTime updatedAt;

  /// Bangumi ID
  int bangumiId;

  /// Bangumi 收藏型別。
  BangumiCollectionType type;

  /// 上映日期
  String? date;

  /// 番劇名稱
  String name;

  /// 番劇中文名稱
  String nameCn;

  /// 簡介
  String shortSummary;

  /// 平均評分
  double score;

  /// 總集數
  int eps;

  /// 排名
  int rank;

  /// 圖片連結，包含 large、common、medium、small、grid 五種尺寸
  Map<String, String> images;

  /// 標籤列表，每個標籤包含 name 和 count 欄位
  List<Map<String, dynamic>> tags;

  BangumiCollection(
      this.bangumiId,
      this.date,
      this.updatedAt,
      this.type,
      this.name,
      this.nameCn,
      this.shortSummary,
      this.score,
      this.eps,
      this.rank,
      this.images,
      this.tags);

  BangumiItem toBangumiItem() {
    return BangumiItem.fromJson({
      'id': bangumiId,
      'type': 2,
      'name': name,
      'name_cn': nameCn,
      'summary': shortSummary,
      'date': date ?? '',
      'images': images,
      'tags': tags,
      'rating': {
        'rank': rank,
        'score': score,
        'total': 0,
        'count': <int>[],
      },
      'info': '',
    });
  }

  factory BangumiCollection.fromJson(Map json) {
    final subject = json['subject'] as Map? ?? const <String, dynamic>{};
    final bangumiId = (subject['id'] as int?) ?? (json['subject_id'] as int?);
    if (bangumiId == null || bangumiId <= 0) {
      throw const FormatException(
          'BangumiCollection: invalid or missing bangumi id');
    }
    final subjectImages = Map<String, String>.from(
      (subject['images'] as Map?) ??
          const <String, String>{
            'large': '',
            'common': '',
            'medium': '',
            'small': '',
            'grid': '',
          },
    );
    final subjectTags = ((subject['tags'] ?? const <dynamic>[]) as List)
        .whereType<Map>()
        .map((tag) => Map<String, dynamic>.from(tag))
        .toList();
    final updatedAtStr = json['updated_at'] as String?;
    if (updatedAtStr == null || updatedAtStr.trim().isEmpty) {
      throw const FormatException(
          'BangumiCollection: missing or empty updated_at');
    }
    final updatedAt = DateTime.tryParse(updatedAtStr);
    if (updatedAt == null) {
      throw const FormatException(
          'BangumiCollection: invalid updated_at format');
    }
    return BangumiCollection(
      bangumiId,
      subject['date'] as String?,
      updatedAt,
      BangumiCollectionType.fromValue(json['type'] as int? ?? 0),
      subject['name'] as String? ?? '',
      subject['name_cn'] as String? ?? '',
      subject['short_summary'] as String? ?? '',
      (subject['score'] as num?)?.toDouble() ?? 0.0,
      subject['eps'] as int? ?? 0,
      subject['rank'] as int? ?? 0,
      subjectImages,
      subjectTags,
    );
  }
}
