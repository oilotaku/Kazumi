/// Bangumi 收藏型別列舉
/// via: https://bangumi.github.io/api/#/model-CollectionType
enum BangumiCollectionType {
  unknown(0, '未知'),

  planToWatch(1, '想看'),

  watched(2, '看過'),

  watching(3, '在看'),

  onHold(4, '擱置'),

  abandoned(5, '拋棄');

  const BangumiCollectionType(this.value, this.label);

  final int value;
  final String label;

  static BangumiCollectionType fromValue(int value) {
    return BangumiCollectionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BangumiCollectionType.unknown,
    );
  }
}
