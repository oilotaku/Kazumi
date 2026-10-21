/// 收藏型別列舉
///
/// 用於標識番劇的收藏狀態
enum CollectType {
  /// 未收藏
  none(0, '未收藏'),

  /// 在看
  watching(1, '在看'),

  /// 想看
  planToWatch(2, '想看'),

  /// 擱置
  onHold(3, '擱置'),

  /// 看過
  watched(4, '看過'),

  /// 拋棄
  abandoned(5, '拋棄');

  const CollectType(this.value, this.label);

  /// 數值表示
  final int value;

  /// 顯示標籤
  final String label;

  /// 根據數值獲取列舉
  static CollectType fromValue(int value) {
    return CollectType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CollectType.none,
    );
  }

  /// 是否為有效的收藏狀態（排除未收藏）
  bool get isCollected => this != CollectType.none;
}
