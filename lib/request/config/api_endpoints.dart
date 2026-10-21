import 'package:flutter/services.dart' show appBuildName;

class ApiEndpoints {
  /// 當前版本
  static const String version = appBuildName ?? '0.0.0';

  /// 規則API級別
  static const int apiLevel = 9;

  /// 專案主頁
  static const String projectUrl = "https://kazumi.app/";

  /// Github 專案主頁
  static const String sourceUrl = "https://github.com/Predidit/Kazumi";

  /// 圖示作者
  static const String iconUrl = "https://www.pixiv.net/users/66219277";

  /// 規則庫
  static const String pluginShop =
      'https://raw.githubusercontent.com/Predidit/KazumiRules/main/';

  /// 規則庫映象
  static const String pluginShopMirror =
      'https://raw.gitcode.com/gh_mirrors/ka/KazumiRules/raw/main/';

  /// 線上升級
  static const String latestApp =
      'https://api.github.com/repos/Predidit/Kazumi/releases/latest';

  /// Bangumi 映象測試後端
  static const String bangumiMirrorDomain = 'https://api.kazumi.fyi';

  /// Kazumi 映象後端應用更新
  static const String latestAppMirror =
      '$bangumiMirrorDomain/kazumi/v1/app/latest';

  /// 彈彈官網
  static const String dandanIndex = 'https://www.dandanplay.com/';

  /// Bangumi 官網
  static const String bangumiIndex = 'https://bangumi.tv/';

  /// bangumi API
  static const String bangumiAPIDomain = 'https://api.bgm.tv';

  /// Bangumi 鑑權 API
  static const String bangumiAuthAPIMirrorDomain = 'https://api.bgmapi.com';

  /// Telegram 群組
  static const String telegramGroup = 'https://t.me/kazumi_app';

  /// 番劇資訊
  static const String bangumiInfoByID = '/v0/subjects/{0}';

  /// 條目關聯資訊
  static const String bangumiRelationsByID = '/v0/subjects/{0}/subjects';

  /// 條目搜尋
  static const String bangumiRankSearch =
      '/v0/search/subjects?limit={0}&offset={1}';

  /// 從條目ID獲取角色資訊
  static const String bangumiCharacterByID = '/v0/subjects/{0}/characters';

  /// 從條目ID獲取工作人員資訊
  static const String bangumiStaffByID = '/v0/subjects/{0}/persons';

  /// 從條目ID獲取劇集ID
  static const String bangumiEpisodeByID = '/v0/episodes';

  /// 返回當前 Access Token 對應的使用者資訊
  static const String bangumiUsernameByToken = '/v0/me';

  /// 新增或修改使用者單個條目收藏
  static const String bangumiSetCollection = '/v0/users/-/collections/{0}';

  /// 獲取使用者全部收藏（不限型別）。使用者名稱，分頁參數1(limit)，分頁參數2(offset)
  static const String bangumiGetAllCollections =
      '/v0/users/{0}/collections?subject_type=2&limit={1}&offset={2}';

  /// Bangumi Next API Domain
  static const String bangumiAPINextDomain = 'https://next.bgm.tv';

  static const bangumiPublicApiHosts = {'api.bgm.tv', 'next.bgm.tv'};

  /// 每日放送
  static const String bangumiCalendar = '/p1/calendar';

  /// 番劇趨勢
  static const String bangumiTrendsNext = '/p1/trending/subjects';

  /// Kazumi Bangumi 映象快取榜單
  static const String bangumiMirrorPopularSubjects =
      '/kazumi/v1/popular/subjects';

  /// Kazumi Bangumi 映象季節時間表
  static const String bangumiMirrorSeasonCalendar =
      '/kazumi/v1/calendar/season';

  /// 番劇資訊
  static const String bangumiInfoByIDNext = '/p1/subjects/{0}';

  /// 番劇評論
  static const String bangumiCommentsByIDNext =
      '/p1/subjects/{0}/comments?limit={1}&offset={2}';

  /// 番劇劇集評論
  static const String bangumiEpisodeCommentsByIDNext =
      '/p1/episodes/{0}/comments';

  /// 番劇角色資訊
  static const String bangumiCharacterInfoByCharacterIDNext =
      '/p1/characters/{0}';

  /// 番劇角色評論
  static const String bangumiCharacterCommentsByIDNext =
      '/p1/characters/{0}/comments';

  /// DanDanPlay API Domain
  static const String dandanAPIDomain = 'https://api.dandanplay.net';

  /// 獲取彈幕
  static const String dandanAPIComment = "/api/v2/comment/";

  /// 檢索彈彈番劇後設資料
  static const String dandanAPISearchEpisodes = "/api/v2/search/episodes";

  /// 獲取彈彈番劇後設資料
  static const String dandanAPIInfo = "/api/v2/bangumi/";

  /// 獲取彈彈番劇後設資料（透過BGM番劇ID）
  static const String dandanAPIInfoByBgmBangumiId = "/api/v2/bangumi/bgmtv/{0}";

  /// 圖片識別番劇
  static const String traceApi = 'https://api.trace.moe/search';

  static String formatUrl(String url, List<dynamic> params) {
    for (int i = 0; i < params.length; i++) {
      url = url.replaceAll('{$i}', params[i].toString());
    }
    return url;
  }
}
