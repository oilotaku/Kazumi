enum BangumiSyncPriority {
  localFirst(0, '本地優先'),
  bangumiFirst(1, 'Bangumi優先'),
  timeFirst(2, '最新優先');

  const BangumiSyncPriority(this.value, this.label);

  final int value;
  final String label;

  static BangumiSyncPriority fromValue(int value) {
    return BangumiSyncPriority.values.firstWhere(
      (item) => item.value == value,
      orElse: () => BangumiSyncPriority.localFirst,
    );
  }
}
