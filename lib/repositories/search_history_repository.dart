import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/modules/search/search_history_module.dart';
import 'package:kazumi/services/logging/logger.dart';

/// 搜尋歷史資料訪問介面
///
/// 提供搜尋歷史相關的資料訪問抽象
abstract class ISearchHistoryRepository {
  /// 獲取所有搜尋歷史（按時間戳倒序）
  List<SearchHistory> getAllHistories();

  /// 儲存搜尋歷史
  ///
  /// [keyword] 搜尋關鍵詞
  /// 返回是否成功
  Future<bool> saveHistory(String keyword);

  /// 刪除指定搜尋歷史
  ///
  /// [history] 要刪除的歷史記錄
  Future<void> deleteHistory(SearchHistory history);

  /// 清空所有搜尋歷史
  Future<void> clearAllHistories();

  /// 刪除重複的歷史記錄
  ///
  /// [keyword] 關鍵詞
  Future<void> deleteDuplicates(String keyword);

  /// 檢查是否達到最大歷史記錄數
  ///
  /// [maxCount] 最大記錄數
  /// 返回是否已滿
  bool isHistoryFull(int maxCount);

  /// 刪除最舊的歷史記錄
  Future<void> deleteOldest();
}

/// 搜尋歷史資料訪問實現類
///
/// 基於Hive實現的搜尋歷史資料訪問層
class SearchHistoryRepository implements ISearchHistoryRepository {
  final _searchHistoryBox = GStorage.searchHistory;

  @override
  List<SearchHistory> getAllHistories() {
    try {
      final histories = _searchHistoryBox.values.toList().cast<SearchHistory>();
      histories.sort((a, b) => b.timestamp - a.timestamp);
      return histories;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: get all search histories failed',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  @override
  Future<bool> saveHistory(String keyword) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final history = SearchHistory(keyword, timestamp);
      await _searchHistoryBox.put(timestamp.toString(), history);
      return true;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: save search history failed. keyword=$keyword',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> deleteHistory(SearchHistory history) async {
    try {
      await _searchHistoryBox.delete(history.key);
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: delete search history failed. key=${history.key}',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> clearAllHistories() async {
    try {
      await _searchHistoryBox.clear();
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: clear all search histories failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> deleteDuplicates(String keyword) async {
    try {
      final histories = getAllHistories();
      final duplicates = histories.where((h) => h.keyword == keyword);
      for (var history in duplicates) {
        await deleteHistory(history);
      }
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: delete duplicate search histories failed. keyword=$keyword',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  bool isHistoryFull(int maxCount) {
    try {
      return _searchHistoryBox.length >= maxCount;
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: check if search history is full failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<void> deleteOldest() async {
    try {
      final histories = getAllHistories();
      if (histories.isNotEmpty) {
        await deleteHistory(histories.last);
      }
    } catch (e, stackTrace) {
      KazumiLogger().e(
        'GStorage: delete oldest search history failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
