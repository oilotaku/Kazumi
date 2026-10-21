// 記錄規則有效性狀態
// 目前僅追蹤搜尋有效性：在本次啟動後，規則是否成功返回過搜尋結果
class PluginValidityTracker {
  // 記錄搜尋有效的規則集合
  final Set<String> _searchValidPlugins = {};

  // 標記規則搜尋有效（成功返回過搜尋結果）
  void markSearchValid(String pluginName) {
    _searchValidPlugins.add(pluginName);
  }

  // 檢查規則搜尋是否有效（是否成功返回過搜尋結果）
  bool isSearchValid(String pluginName) {
    return _searchValidPlugins.contains(pluginName);
  }
}
