import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/modules/collect/collect_type.dart';
import 'package:kazumi/services/logging/logger.dart';

/// 收藏資料訪問介面
///
/// 提供收藏相關的資料訪問抽象，解耦業務邏輯與資料儲存
abstract class ICollectRepository {
  /// 根據收藏型別獲取番劇ID集合
  ///
  /// [type] 收藏型別
  /// 返回符合條件的番劇ID集合
  Set<int> getBangumiIdsByType(CollectType type);

  /// 批次獲取多種型別的番劇ID集合
  ///
  /// [types] 收藏型別列表
  /// 返回符合條件的番劇ID集合（並集）
  Set<int> getBangumiIdsByTypes(List<CollectType> types);

  // ========== 搜尋頁過濾器設定 ==========

  /// 獲取搜尋頁"不顯示已看過番劇"設定

  /// 更新搜尋頁"不顯示已看過番劇"設定

  /// 獲取搜尋頁"不顯示已拋棄番劇"設定

  /// 更新搜尋頁"不顯示已拋棄番劇"設定

  // ========== 時間表頁過濾器設定 ==========

  /// 獲取時間表頁"不顯示已拋棄番劇"設定
  bool getTimelineNotShowAbandonedBangumis();

  /// 更新時間表頁"不顯示已拋棄番劇"設定
  Future<void> updateTimelineNotShowAbandonedBangumis(bool value);

  /// 獲取時間表頁"不顯示已看過番劇"設定
  bool getTimelineNotShowWatchedBangumis();

  /// 更新時間表頁"不顯示已看過番劇"設定
  Future<void> updateTimelineNotShowWatchedBangumis(bool value);

  /// 獲取時間表頁"只顯示在看的番劇"設定
  bool getTimelineOnlyShowWatchingBangumis();

  /// 更新時間表頁"只顯示在看的番劇"設定
  Future<void> updateTimelineOnlyShowWatchingBangumis(bool value);

  // ========== 其他設定 ==========

  /// 獲取隱私模式設定
  bool getPrivateMode();
}

/// 收藏資料訪問實現類
///
/// 基於Hive實現的收藏資料訪問層
class CollectRepository implements ICollectRepository {
  final _collectiblesBox = GStorage.collectibles;

  @override
  Set<int> getBangumiIdsByType(CollectType type) {
    try {
      return _collectiblesBox.values
          .where((item) => item.type == type.value)
          .map<int>((item) => item.bangumiItem.id)
          .toSet();
    } catch (e) {
      KazumiLogger().w(
        'GStorage: get bangumi IDs by type failed. type=${type.label}',
        error: e,
      );
      return <int>{};
    }
  }

  @override
  Set<int> getBangumiIdsByTypes(List<CollectType> types) {
    try {
      final typeValues = types.map((t) => t.value).toSet();
      return _collectiblesBox.values
          .where((item) => typeValues.contains(item.type))
          .map<int>((item) => item.bangumiItem.id)
          .toSet();
    } catch (e) {
      KazumiLogger().w(
        'GStorage: get bangumi IDs by types failed. types=${types.map((t) => t.label).join(", ")}',
        error: e,
      );
      return <int>{};
    }
  }

  // ========== 搜尋頁過濾器設定實現 ==========

  // ========== 時間表頁過濾器設定實現 ==========

  @override
  bool getTimelineNotShowAbandonedBangumis() {
    try {
      final value =
          GStorage.getSetting(SettingsKeys.timelineNotShowAbandonedBangumis);
      return value;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: get timeline not show abandoned bangumis setting failed, using default false',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> updateTimelineNotShowAbandonedBangumis(bool value) async {
    try {
      await GStorage.putSetting(
          SettingsKeys.timelineNotShowAbandonedBangumis, value);
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: update timeline not show abandoned bangumis setting failed. value=$value',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  bool getTimelineNotShowWatchedBangumis() {
    try {
      final value =
          GStorage.getSetting(SettingsKeys.timelineNotShowWatchedBangumis);
      return value;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: get timeline not show watched bangumis setting failed, using default false',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> updateTimelineNotShowWatchedBangumis(bool value) async {
    try {
      await GStorage.putSetting(
          SettingsKeys.timelineNotShowWatchedBangumis, value);
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: update timeline not show watched bangumis setting failed. value=$value',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  bool getTimelineOnlyShowWatchingBangumis() {
    try {
      final value =
          GStorage.getSetting(SettingsKeys.timelineOnlyShowWatchingBangumis);
      return value;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: get timeline only show watching bangumis setting failed, using default false',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> updateTimelineOnlyShowWatchingBangumis(bool value) async {
    try {
      await GStorage.putSetting(
          SettingsKeys.timelineOnlyShowWatchingBangumis, value);
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: update timeline only show watching bangumis setting failed. value=$value',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ========== 其他設定實現 ==========

  @override
  bool getPrivateMode() {
    try {
      final value = GStorage.getSetting(SettingsKeys.privateMode);
      return value;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: get private mode setting failed, using default false',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
