import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/pages/plugin_editor/rule_management_widgets.dart';
import 'package:kazumi/pages/plugin_editor/editor_form_widgets.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/plugins/api_rule_config.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/services/plugin/api_rule_engine.dart';

abstract final class _RuleEditorText {
  static const pageTitle = '規則編輯器';
  static const testRule = '測試規則';
  static const save = '儲存';

  static const modeXPath = 'XPath';
  static const modeApi = 'API';
  static const methodGet = 'GET';
  static const methodPost = 'POST';
  static const bodyTypeNone = '無';
  static const bodyTypeJson = 'JSON';
  static const bodyTypeForm = '表單';
  static const formatNested = '巢狀 JSON';
  static const formatDelimited = '分隔字串';

  static const legacyParser = '簡易解析';
  static const legacyParserDesc = '使用簡易解析器而不是現代解析器';
  static const adBlocker = '廣告過濾';
  static const adBlockerDesc = '啟用 HLS 廣告過濾';

  static const antiCrawlerEnable = '啟用反反爬蟲';
  static const antiCrawlerEnableDesc = '檢索失敗時顯示驗證碼驗證按鈕而非重試';
  static const captchaTypeLabel = '驗證型別';
  static const captchaTypeImage = '圖片驗證碼';
  static const captchaTypeAutoClick = '自動點選';
  static const captchaTypeScript = '自定義指令碼';
  static const captchaTypeImageDesc = '展示驗證碼圖片，由使用者手動輸入';
  static const captchaTypeAutoClickDesc = '檢測到驗證按鈕後自動模擬點選';
  static const captchaTypeScriptDesc = '載入頁面後執行規則內的驗證指令碼';
  static const captchaTypeUnknownDesc = '未知驗證型別';
  static const captchaDetectTypeLabel = '驗證頁檢測方式';
  static const captchaDetectTypeDesc = '優先使用該標記判斷搜尋響應是否為驗證頁';
  static const captchaDetectText = '文字';
  static const captchaDetectRegex = '正則';
  static const captchaDetectValueHintText = '身份驗證';
  static const captchaDetectValueHintRegex = '身份驗證|smart_verify';
  static const captchaDetectValueHintXPath = '//button[@id="verify"]';
  static const captchaImageHint = '//img[@class="captcha"]';
  static const captchaInputHint = '//input[@name="captcha"]';
  static const captchaButtonHint = '//button[@type="submit"]';
  static const captchaScriptHint =
      'KazumiCaptcha.log("ready"); KazumiCaptcha.done();';

  static const sectionBasic = '基本資訊';
  static const sectionBasicDesc = '規則的名稱、版本與站點地址';
  static const sectionSearch = '搜尋規則';
  static const sectionSearchDesc = '定義如何在站點內檢索條目';
  static const sectionChapter = '選集規則';
  static const sectionChapterDesc = '定義如何獲取播放線路與劇集列表';
  static const advancedOptions = '高階選項';
  static const advancedOptionsDesc = '行為、網路與反反爬蟲配置';
  static const groupBehavior = '行為設定';
  static const groupNetwork = '網路設定';
  static const groupAntiCrawler = '反反爬蟲';

  static const ruleName = '規則名稱';
  static const ruleVersion = '規則版本';
  static const baseUrl = '基礎地址（URL）';
  static const searchRuleType = '搜尋規則型別';
  static const chapterRuleType = '選集規則型別';

  static const searchUrl = '搜尋地址（URL）';
  static const searchListXPath = '搜尋結果列表（XPath）';
  static const itemNameXPath = '條目名稱（XPath）';
  static const itemLinkXPath = '條目連結（XPath）';
  static const roadListXPath = '播放線路列表（XPath）';
  static const episodeListXPath = '劇集列表（XPath）';

  static const searchMethod = '搜尋請求方法';
  static const searchRequestUrl = '搜尋請求地址（URL）';
  static const searchHeaders = '搜尋請求頭（JSON）';
  static const searchQuery = '搜尋查詢參數（JSON）';
  static const searchBodyType = '搜尋請求體型別';
  static const searchBody = '搜尋請求體（JSON）';
  static const searchListPath = '搜尋結果列表路徑（JSONPath）';
  static const itemNamePath = '條目名稱路徑（JSONPath，相對條目）';
  static const itemSourcePath = '條目來源路徑（JSONPath，相對條目）';
  static const detailPageUrl = '詳情頁地址模板（URL，可選）';
  static const detailPageUrlHelper = '@source 替換為條目來源，如 https://site/GV@source';

  static const chapterMethod = '選集請求方法';
  static const chapterRequestUrl = '選集請求地址（URL）';
  static const chapterHeaders = '選集請求頭（JSON）';
  static const chapterQuery = '選集查詢參數（JSON）';
  static const chapterBodyType = '選集請求體型別';
  static const chapterBody = '選集請求體（JSON）';
  static const chapterResponseFormat = '選集響應格式';
  static const roadListPath = '播放線路列表路徑（JSONPath，留空表示單線路）';
  static const roadNamePath = '線路名稱路徑（JSONPath，相對線路）';
  static const episodeListPath = '劇集列表路徑（JSONPath，相對線路）';
  static const episodeNamePath = '劇集名稱路徑（JSONPath，相對劇集）';
  static const playbackEntryPath = '播放入口地址路徑（JSONPath，使用播放頁地址模板時可留空）';
  static const playbackEntryPathHelper = '從劇集物件讀取交給 WebView 的地址，可以是播放頁面或媒體直鏈。';
  static const roadNamesPath = '線路名稱串路徑（JSONPath）';
  static const roadEpisodesPath = '線路劇集串路徑（JSONPath）';
  static const roadSeparator = '線路分隔符';
  static const episodeSeparator = '劇集分隔符';
  static const fieldSeparator = '名稱與地址分隔符';
  static const responseVariables = '響應變數（JSON：變數名 → JSONPath）';
  static const playPageUrl = '播放頁地址模板（URL，可選）';
  static const playPageUrlHelper = '可用變數：@source、@episodeUrl、'
      '@roadIndex/@episodeIndex（從 0 起）、@roadNumber/@episodeNumber（從 1 起）'
      '及響應變數。';
  static const playPageQuery = '播放頁查詢參數（JSON）';
  static const playPageQueryHelper = '與地址模板可用變數相同，合併進最終 URL 的查詢參數。';

  static const userAgent = '使用者代理（User-Agent）';
  static const userAgentHelper = '僅用於播放器和下載器。';
  static const referer = '播放請求來源（Referer）';
  static const refererHelper = '僅用於播放器和下載器。';

  static const captchaDetectValue = '驗證頁檢測值';
  static const captchaDetectValueHelper = '留空時使用驗證碼圖片或驗證按鈕的 XPath 進行檢測。';
  static const captchaImage = '驗證碼圖片（XPath）';
  static const captchaImageHelper = '填寫驗證碼圖片元素的 XPath。';
  static const captchaInput = '驗證碼輸入框（XPath）';
  static const captchaInputHelper = '填寫驗證碼輸入框元素的 XPath。';
  static const captchaSubmitButton = '驗證提交按鈕（XPath）';
  static const captchaSubmitButtonHelper = '填寫提交驗證碼按鈕元素的 XPath。';
  static const verifyButton = '驗證按鈕（XPath）';
  static const verifyButtonHelper = '填寫驗證按鈕元素的 XPath，檢測到後將自動點選。';
  static const captchaScript = '驗證指令碼（JavaScript）';
  static const captchaScriptHelper =
      '可呼叫 KazumiCaptcha.log、clicked、done 和 fail。';
}

class PluginEditorPage extends StatefulWidget {
  const PluginEditorPage({
    super.key,
    required this.plugin,
    required this.controller,
  });

  final Plugin plugin;
  final PluginsController controller;

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  PluginsController get pluginsController => widget.controller;
  final _formScroll = ScrollController();
  int _section = 0;
  bool _saving = false;
  String? _editorError;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController versionController = TextEditingController();
  final TextEditingController userAgentController = TextEditingController();
  final TextEditingController baseURLController = TextEditingController();
  final TextEditingController searchURLController = TextEditingController();
  final TextEditingController searchListController = TextEditingController();
  final TextEditingController searchNameController = TextEditingController();
  final TextEditingController searchResultController = TextEditingController();
  final TextEditingController chapterRoadsController = TextEditingController();
  final TextEditingController chapterResultController = TextEditingController();
  final TextEditingController refererController = TextEditingController();
  final TextEditingController searchApiURLController = TextEditingController();
  final TextEditingController searchApiHeadersController =
      TextEditingController();
  final TextEditingController searchApiQueryController =
      TextEditingController();
  final TextEditingController searchApiBodyController = TextEditingController();
  final TextEditingController searchApiListPathController =
      TextEditingController();
  final TextEditingController searchApiNamePathController =
      TextEditingController();
  final TextEditingController searchApiSourcePathController =
      TextEditingController();
  final TextEditingController searchApiSourceTemplateController =
      TextEditingController();
  final TextEditingController chapterApiURLController = TextEditingController();
  final TextEditingController chapterApiHeadersController =
      TextEditingController();
  final TextEditingController chapterApiQueryController =
      TextEditingController();
  final TextEditingController chapterApiBodyController =
      TextEditingController();
  final TextEditingController chapterApiRoadsPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadNamePathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodesPathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeNamePathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeURLPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadNamesPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadEpisodesPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiFieldSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiVariablesController =
      TextEditingController();
  final TextEditingController chapterApiPageURLController =
      TextEditingController();
  final TextEditingController chapterApiPageQueryController =
      TextEditingController();
  String searchMode = RuleMode.xpath;
  String chapterMode = RuleMode.xpath;
  String searchApiMethod = 'GET';
  String searchApiBodyType = ApiBodyType.none;
  String chapterApiMethod = 'GET';
  String chapterApiBodyType = ApiBodyType.none;
  String chapterApiFormat = ApiChapterFormat.nested;
  // Preserve legacy fields that the editor no longer exposes.
  late String _api;
  late String _type;
  late bool _muliSources;
  late bool _useWebview;
  late bool _useNativePlayer;
  bool usePost = false;
  bool useLegacyParser = false;
  bool adBlocker = false;

  final TextEditingController captchaImageController = TextEditingController();
  final TextEditingController captchaInputController = TextEditingController();
  final TextEditingController captchaButtonController = TextEditingController();
  final TextEditingController captchaDetectValueController =
      TextEditingController();
  final TextEditingController captchaScriptController = TextEditingController();
  bool antiCrawlerEnabled = false;
  int captchaType = CaptchaType.imageCaptcha;
  int captchaDetectType = CaptchaDetectType.xpath;

  static const List<ButtonSegment<String>> _ruleModeSegments = [
    ButtonSegment(
      value: RuleMode.xpath,
      label: Text(_RuleEditorText.modeXPath),
    ),
    ButtonSegment(value: RuleMode.api, label: Text(_RuleEditorText.modeApi)),
  ];

  static const List<ButtonSegment<String>> _methodSegments = [
    ButtonSegment(value: 'GET', label: Text(_RuleEditorText.methodGet)),
    ButtonSegment(value: 'POST', label: Text(_RuleEditorText.methodPost)),
  ];

  static const List<ButtonSegment<String>> _bodyTypeSegments = [
    ButtonSegment(
      value: ApiBodyType.none,
      label: Text(_RuleEditorText.bodyTypeNone),
    ),
    ButtonSegment(
      value: ApiBodyType.json,
      label: Text(_RuleEditorText.bodyTypeJson),
    ),
    ButtonSegment(
      value: ApiBodyType.form,
      label: Text(_RuleEditorText.bodyTypeForm),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final Plugin plugin = widget.plugin;
    _api = plugin.api;
    _type = plugin.type;
    nameController.text = plugin.name;
    versionController.text = plugin.version;
    userAgentController.text = plugin.userAgent;
    baseURLController.text = plugin.baseUrl;
    searchURLController.text = plugin.searchURL;
    searchListController.text = plugin.searchList;
    searchNameController.text = plugin.searchName;
    searchResultController.text = plugin.searchResult;
    chapterRoadsController.text = plugin.chapterRoads;
    chapterResultController.text = plugin.chapterResult;
    refererController.text = plugin.referer;
    searchMode = plugin.searchMode;
    chapterMode = plugin.chapterMode;
    searchApiMethod = plugin.searchApiConfig.request.method;
    searchApiBodyType = plugin.searchApiConfig.request.bodyType;
    searchApiURLController.text = plugin.searchApiConfig.request.url;
    searchApiHeadersController.text =
        _prettyJson(plugin.searchApiConfig.request.headers);
    searchApiQueryController.text =
        _prettyJson(plugin.searchApiConfig.request.query);
    searchApiBodyController.text =
        _prettyJson(plugin.searchApiConfig.request.body);
    searchApiListPathController.text = plugin.searchApiConfig.listPath;
    searchApiNamePathController.text = plugin.searchApiConfig.namePath;
    searchApiSourcePathController.text = plugin.searchApiConfig.sourcePath;
    searchApiSourceTemplateController.text =
        plugin.searchApiConfig.sourceTemplate;
    chapterApiMethod = plugin.chapterApiConfig.request.method;
    chapterApiBodyType = plugin.chapterApiConfig.request.bodyType;
    chapterApiFormat = plugin.chapterApiConfig.format;
    chapterApiURLController.text = plugin.chapterApiConfig.request.url;
    chapterApiHeadersController.text =
        _prettyJson(plugin.chapterApiConfig.request.headers);
    chapterApiQueryController.text =
        _prettyJson(plugin.chapterApiConfig.request.query);
    chapterApiBodyController.text =
        _prettyJson(plugin.chapterApiConfig.request.body);
    chapterApiRoadsPathController.text = plugin.chapterApiConfig.roadsPath;
    chapterApiRoadNamePathController.text =
        plugin.chapterApiConfig.roadNamePath;
    chapterApiEpisodesPathController.text =
        plugin.chapterApiConfig.episodesPath;
    chapterApiEpisodeNamePathController.text =
        plugin.chapterApiConfig.episodeNamePath;
    chapterApiEpisodeURLPathController.text =
        plugin.chapterApiConfig.episodeUrlPath;
    chapterApiRoadNamesPathController.text =
        plugin.chapterApiConfig.roadNamesPath;
    chapterApiRoadEpisodesPathController.text =
        plugin.chapterApiConfig.roadEpisodesPath;
    chapterApiRoadSeparatorController.text =
        plugin.chapterApiConfig.roadSeparator;
    chapterApiEpisodeSeparatorController.text =
        plugin.chapterApiConfig.episodeSeparator;
    chapterApiFieldSeparatorController.text =
        plugin.chapterApiConfig.fieldSeparator;
    chapterApiVariablesController.text =
        _prettyJson(plugin.chapterApiConfig.variables);
    chapterApiPageURLController.text =
        plugin.chapterApiConfig.episodePage?.url ?? '';
    chapterApiPageQueryController.text =
        _prettyJson(plugin.chapterApiConfig.episodePage?.query);
    _muliSources = plugin.muliSources;
    _useWebview = plugin.useWebview;
    _useNativePlayer = plugin.useNativePlayer;
    usePost = plugin.usePost;
    useLegacyParser = plugin.useLegacyParser;
    adBlocker = plugin.adBlocker;
    antiCrawlerEnabled = plugin.antiCrawlerConfig.enabled;
    captchaType = plugin.antiCrawlerConfig.captchaType;
    captchaImageController.text = plugin.antiCrawlerConfig.captchaImage;
    captchaInputController.text = plugin.antiCrawlerConfig.captchaInput;
    captchaButtonController.text = plugin.antiCrawlerConfig.captchaButton;
    captchaDetectType = plugin.antiCrawlerConfig.captchaDetectType;
    captchaDetectValueController.text =
        plugin.antiCrawlerConfig.captchaDetectValue;
    captchaScriptController.text = plugin.antiCrawlerConfig.captchaScript;
  }

  @override
  void dispose() {
    _formScroll.dispose();
    nameController.dispose();
    versionController.dispose();
    userAgentController.dispose();
    baseURLController.dispose();
    searchURLController.dispose();
    searchListController.dispose();
    searchNameController.dispose();
    searchResultController.dispose();
    chapterRoadsController.dispose();
    chapterResultController.dispose();
    refererController.dispose();
    searchApiURLController.dispose();
    searchApiHeadersController.dispose();
    searchApiQueryController.dispose();
    searchApiBodyController.dispose();
    searchApiListPathController.dispose();
    searchApiNamePathController.dispose();
    searchApiSourcePathController.dispose();
    searchApiSourceTemplateController.dispose();
    chapterApiURLController.dispose();
    chapterApiHeadersController.dispose();
    chapterApiQueryController.dispose();
    chapterApiBodyController.dispose();
    chapterApiRoadsPathController.dispose();
    chapterApiRoadNamePathController.dispose();
    chapterApiEpisodesPathController.dispose();
    chapterApiEpisodeNamePathController.dispose();
    chapterApiEpisodeURLPathController.dispose();
    chapterApiRoadNamesPathController.dispose();
    chapterApiRoadEpisodesPathController.dispose();
    chapterApiRoadSeparatorController.dispose();
    chapterApiEpisodeSeparatorController.dispose();
    chapterApiFieldSeparatorController.dispose();
    chapterApiVariablesController.dispose();
    chapterApiPageURLController.dispose();
    chapterApiPageQueryController.dispose();
    captchaImageController.dispose();
    captchaInputController.dispose();
    captchaButtonController.dispose();
    captchaDetectValueController.dispose();
    captchaScriptController.dispose();
    super.dispose();
  }

  static String _prettyJson(Object? value) {
    if (value == null) return '';
    if (value is Map && value.isEmpty) return '{}';
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  void _testRule() {
    final editedPlugin = _tryBuildEditedPlugin();
    if (editedPlugin == null) return;
    context.pushNamed('/settings/plugin/test', arguments: editedPlugin);
  }

  Future<void> _save() async {
    if (_saving) return;
    final editedPlugin = _tryBuildEditedPlugin();
    if (editedPlugin == null) return;
    setState(() {
      _saving = true;
      _editorError = null;
    });
    try {
      await pluginsController.updatePlugin(editedPlugin);
      if (mounted) context.pop();
    } catch (error) {
      _showEditorError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SettingsDetailScaffold(
      title: const Text(_RuleEditorText.pageTitle),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          controller: _formScroll,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RulePageIntro(
                    title: widget.plugin.name.isEmpty
                        ? '編寫新規則'
                        : widget.plugin.name,
                    description: '從站點資訊到搜尋與選集，逐步配置你的番劇來源。',
                    icon: Icons.edit_note_rounded,
                  ),
                  const SizedBox(height: 20),
                  if (_editorError != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(_editorError!,
                            style: TextStyle(color: colors.onErrorContainer)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  EditorChoiceGroup<int>(
                    value: _section,
                    segments: const [
                      ButtonSegment(value: 0, label: Text('基本')),
                      ButtonSegment(value: 1, label: Text('搜尋')),
                      ButtonSegment(value: 2, label: Text('選集')),
                      ButtonSegment(value: 3, label: Text('高階')),
                    ],
                    onChanged: (value) => setState(() => _section = value),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrentSection(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Material(
        color: colors.surfaceContainerLow,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Row(children: [
                  Expanded(
                      child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          onPressed: _saving ? null : _testRule,
                          icon: const Icon(Icons.science_outlined),
                          label: Text(
                              MediaQuery.textScalerOf(context).scale(14) > 20
                                  ? '測試'
                                  : _RuleEditorText.testRule))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const LoadingIndicator(size: 20)
                              : const Icon(Icons.check_rounded),
                          label: Text(_saving ? '儲存中' : _RuleEditorText.save))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    if (_section == 3) return _buildAdvancedOptionsCard();
    final isSearch = _section == 1;
    return RuleSection(
      key: ValueKey(_section),
      title: switch (_section) {
        0 => _RuleEditorText.sectionBasic,
        1 => _RuleEditorText.sectionSearch,
        _ => _RuleEditorText.sectionChapter,
      },
      description: switch (_section) {
        0 => _RuleEditorText.sectionBasicDesc,
        1 => _RuleEditorText.sectionSearchDesc,
        _ => _RuleEditorText.sectionChapterDesc,
      },
      icon: switch (_section) {
        0 => Icons.info_outline_rounded,
        1 => Icons.search_rounded,
        _ => Icons.video_library_outlined,
      },
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _section == 0
            ? [
                EditorTextField(
                    controller: nameController,
                    label: _RuleEditorText.ruleName),
                EditorTextField(
                    controller: versionController,
                    label: _RuleEditorText.ruleVersion),
                EditorTextField(
                    controller: baseURLController,
                    label: _RuleEditorText.baseUrl),
              ]
            : [
                EditorSegmentedField<String>(
                  label: isSearch
                      ? _RuleEditorText.searchRuleType
                      : _RuleEditorText.chapterRuleType,
                  value: isSearch ? searchMode : chapterMode,
                  segments: _ruleModeSegments,
                  description: (mode) => mode == RuleMode.api
                      ? '請求介面並從 JSON 響應中提取資料。'
                      : '從網頁 HTML 中定位並提取內容。',
                  onChanged: (value) => setState(() {
                    if (isSearch) {
                      searchMode = value;
                    } else {
                      chapterMode = value;
                    }
                  }),
                ),
                EditorAnimatedSection(
                  activeKey: isSearch ? searchMode : chapterMode,
                  child: Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: isSearch
                        ? (searchMode == RuleMode.xpath
                            ? _buildXPathSearchFields()
                            : _buildApiSearchFields())
                        : (chapterMode == RuleMode.xpath
                            ? _buildXPathChapterFields()
                            : _buildApiChapterFields()),
                  ),
                ),
              ],
      ),
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return RuleSection(
      title: _RuleEditorText.advancedOptions,
      description: _RuleEditorText.advancedOptionsDesc,
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const EditorSubheader(label: _RuleEditorText.groupBehavior),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(_RuleEditorText.legacyParser),
            subtitle: const Text(_RuleEditorText.legacyParserDesc),
            value: useLegacyParser,
            onChanged: (value) => setState(() => useLegacyParser = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(_RuleEditorText.adBlocker),
            subtitle: const Text(_RuleEditorText.adBlockerDesc),
            value: adBlocker,
            onChanged: (value) => setState(() => adBlocker = value),
          ),
          const EditorSubheader(label: _RuleEditorText.groupNetwork),
          EditorTextField(
            controller: userAgentController,
            label: _RuleEditorText.userAgent,
            helper: _RuleEditorText.userAgentHelper,
          ),
          const SizedBox(height: 16),
          EditorTextField(
            controller: refererController,
            label: _RuleEditorText.referer,
            helper: _RuleEditorText.refererHelper,
          ),
          if (searchMode == RuleMode.xpath) ...[
            const EditorSubheader(label: _RuleEditorText.groupAntiCrawler),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(_RuleEditorText.antiCrawlerEnable),
              subtitle: const Text(_RuleEditorText.antiCrawlerEnableDesc),
              value: antiCrawlerEnabled,
              onChanged: (value) => setState(() => antiCrawlerEnabled = value),
            ),
            EditorAnimatedSection(
              activeKey: antiCrawlerEnabled,
              child: antiCrawlerEnabled
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildAntiCrawlerFields(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildAntiCrawlerFields() => [
        EditorSegmentedField<int>(
          label: _RuleEditorText.captchaTypeLabel,
          value: captchaType,
          segments: const [
            ButtonSegment(
              value: CaptchaType.imageCaptcha,
              label: Text(_RuleEditorText.captchaTypeImage),
            ),
            ButtonSegment(
              value: CaptchaType.autoClickButton,
              label: Text(_RuleEditorText.captchaTypeAutoClick),
            ),
            ButtonSegment(
              value: CaptchaType.customJavaScript,
              label: Text(_RuleEditorText.captchaTypeScript),
            ),
          ],
          onChanged: (value) => setState(() => captchaType = value),
          description: (value) => switch (value) {
            CaptchaType.imageCaptcha => _RuleEditorText.captchaTypeImageDesc,
            CaptchaType.autoClickButton =>
              _RuleEditorText.captchaTypeAutoClickDesc,
            CaptchaType.customJavaScript =>
              _RuleEditorText.captchaTypeScriptDesc,
            _ => _RuleEditorText.captchaTypeUnknownDesc,
          },
        ),
        EditorSegmentedField<int>(
          label: _RuleEditorText.captchaDetectTypeLabel,
          value: captchaDetectType,
          segments: const [
            ButtonSegment(
              value: CaptchaDetectType.xpath,
              label: Text(_RuleEditorText.modeXPath),
            ),
            ButtonSegment(
              value: CaptchaDetectType.text,
              label: Text(_RuleEditorText.captchaDetectText),
            ),
            ButtonSegment(
              value: CaptchaDetectType.regex,
              label: Text(_RuleEditorText.captchaDetectRegex),
            ),
          ],
          onChanged: (value) => setState(() => captchaDetectType = value),
          description: (_) => _RuleEditorText.captchaDetectTypeDesc,
        ),
        EditorTextField(
          controller: captchaDetectValueController,
          label: _RuleEditorText.captchaDetectValue,
          hint: captchaDetectType == CaptchaDetectType.text
              ? _RuleEditorText.captchaDetectValueHintText
              : captchaDetectType == CaptchaDetectType.regex
                  ? _RuleEditorText.captchaDetectValueHintRegex
                  : _RuleEditorText.captchaDetectValueHintXPath,
          helper: _RuleEditorText.captchaDetectValueHelper,
        ),
        EditorAnimatedSection(
          activeKey: captchaType,
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (captchaType == CaptchaType.imageCaptcha) ...[
                EditorTextField(
                  controller: captchaImageController,
                  label: _RuleEditorText.captchaImage,
                  hint: _RuleEditorText.captchaImageHint,
                  helper: _RuleEditorText.captchaImageHelper,
                ),
                EditorTextField(
                  controller: captchaInputController,
                  label: _RuleEditorText.captchaInput,
                  hint: _RuleEditorText.captchaInputHint,
                  helper: _RuleEditorText.captchaInputHelper,
                ),
              ],
              if (captchaType != CaptchaType.customJavaScript)
                EditorTextField(
                  controller: captchaButtonController,
                  label: captchaType == CaptchaType.imageCaptcha
                      ? _RuleEditorText.captchaSubmitButton
                      : _RuleEditorText.verifyButton,
                  hint: _RuleEditorText.captchaButtonHint,
                  helper: captchaType == CaptchaType.imageCaptcha
                      ? _RuleEditorText.captchaSubmitButtonHelper
                      : _RuleEditorText.verifyButtonHelper,
                ),
              if (captchaType == CaptchaType.customJavaScript)
                EditorTextField(
                  controller: captchaScriptController,
                  label: _RuleEditorText.captchaScript,
                  hint: _RuleEditorText.captchaScriptHint,
                  helper: _RuleEditorText.captchaScriptHelper,
                  maxLines: 8,
                ),
            ],
          ),
        ),
      ];

  List<Widget> _buildXPathSearchFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchMethod,
          value: usePost ? 'POST' : 'GET',
          segments: _methodSegments,
          onChanged: (value) => setState(() => usePost = value == 'POST'),
        ),
        EditorTextField(
          controller: searchURLController,
          label: _RuleEditorText.searchUrl,
        ),
        EditorTextField(
          controller: searchListController,
          label: _RuleEditorText.searchListXPath,
        ),
        EditorTextField(
          controller: searchNameController,
          label: _RuleEditorText.itemNameXPath,
        ),
        EditorTextField(
          controller: searchResultController,
          label: _RuleEditorText.itemLinkXPath,
        ),
      ];

  List<Widget> _buildXPathChapterFields() => [
        EditorTextField(
          controller: chapterRoadsController,
          label: _RuleEditorText.roadListXPath,
        ),
        EditorTextField(
          controller: chapterResultController,
          label: _RuleEditorText.episodeListXPath,
        ),
      ];

  List<Widget> _buildApiSearchFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchMethod,
          value: searchApiMethod,
          segments: _methodSegments,
          onChanged: (value) => setState(() => searchApiMethod = value),
        ),
        EditorTextField(
          controller: searchApiURLController,
          label: _RuleEditorText.searchRequestUrl,
        ),
        EditorTextField(
          controller: searchApiHeadersController,
          label: _RuleEditorText.searchHeaders,
          maxLines: 4,
        ),
        EditorTextField(
          controller: searchApiQueryController,
          label: _RuleEditorText.searchQuery,
          maxLines: 4,
        ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchBodyType,
          value: searchApiBodyType,
          segments: _bodyTypeSegments,
          onChanged: (value) => setState(() => searchApiBodyType = value),
        ),
        if (searchApiBodyType != ApiBodyType.none)
          EditorTextField(
            controller: searchApiBodyController,
            label: _RuleEditorText.searchBody,
            maxLines: 5,
          ),
        EditorTextField(
          controller: searchApiListPathController,
          label: _RuleEditorText.searchListPath,
        ),
        EditorTextField(
          controller: searchApiNamePathController,
          label: _RuleEditorText.itemNamePath,
        ),
        EditorTextField(
          controller: searchApiSourcePathController,
          label: _RuleEditorText.itemSourcePath,
        ),
        EditorTextField(
          controller: searchApiSourceTemplateController,
          label: _RuleEditorText.detailPageUrl,
          helper: _RuleEditorText.detailPageUrlHelper,
        ),
      ];

  List<Widget> _buildApiChapterFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterMethod,
          value: chapterApiMethod,
          segments: _methodSegments,
          onChanged: (value) => setState(() => chapterApiMethod = value),
        ),
        EditorTextField(
          controller: chapterApiURLController,
          label: _RuleEditorText.chapterRequestUrl,
        ),
        EditorTextField(
          controller: chapterApiHeadersController,
          label: _RuleEditorText.chapterHeaders,
          maxLines: 4,
        ),
        EditorTextField(
          controller: chapterApiQueryController,
          label: _RuleEditorText.chapterQuery,
          maxLines: 4,
        ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterBodyType,
          value: chapterApiBodyType,
          segments: _bodyTypeSegments,
          onChanged: (value) => setState(() => chapterApiBodyType = value),
        ),
        if (chapterApiBodyType != ApiBodyType.none)
          EditorTextField(
            controller: chapterApiBodyController,
            label: _RuleEditorText.chapterBody,
            maxLines: 5,
          ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterResponseFormat,
          value: chapterApiFormat,
          segments: const [
            ButtonSegment(
              value: ApiChapterFormat.nested,
              label: Text(_RuleEditorText.formatNested),
            ),
            ButtonSegment(
              value: ApiChapterFormat.delimited,
              label: Text(_RuleEditorText.formatDelimited),
            ),
          ],
          onChanged: (value) => setState(() => chapterApiFormat = value),
        ),
        EditorAnimatedSection(
          activeKey: chapterApiFormat,
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: chapterApiFormat == ApiChapterFormat.nested
                ? [
                    EditorTextField(
                      controller: chapterApiRoadsPathController,
                      label: _RuleEditorText.roadListPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadNamePathController,
                      label: _RuleEditorText.roadNamePath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodesPathController,
                      label: _RuleEditorText.episodeListPath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeNamePathController,
                      label: _RuleEditorText.episodeNamePath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeURLPathController,
                      label: _RuleEditorText.playbackEntryPath,
                      helper: _RuleEditorText.playbackEntryPathHelper,
                    ),
                  ]
                : [
                    EditorTextField(
                      controller: chapterApiRoadNamesPathController,
                      label: _RuleEditorText.roadNamesPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadEpisodesPathController,
                      label: _RuleEditorText.roadEpisodesPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadSeparatorController,
                      label: _RuleEditorText.roadSeparator,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeSeparatorController,
                      label: _RuleEditorText.episodeSeparator,
                    ),
                    EditorTextField(
                      controller: chapterApiFieldSeparatorController,
                      label: _RuleEditorText.fieldSeparator,
                    ),
                  ],
          ),
        ),
        EditorTextField(
          controller: chapterApiVariablesController,
          label: _RuleEditorText.responseVariables,
          maxLines: 5,
        ),
        EditorTextField(
          controller: chapterApiPageURLController,
          label: _RuleEditorText.playPageUrl,
          helper: _RuleEditorText.playPageUrlHelper,
        ),
        EditorTextField(
          controller: chapterApiPageQueryController,
          label: _RuleEditorText.playPageQuery,
          helper: _RuleEditorText.playPageQueryHelper,
          maxLines: 5,
        ),
      ];

  Plugin? _tryBuildEditedPlugin() {
    try {
      return _buildEditedPlugin();
    } catch (error) {
      _showEditorError(error);
      return null;
    }
  }

  Plugin _buildEditedPlugin() {
    final searchConfig = _buildSearchApiConfig();
    final chapterConfig = _buildChapterApiConfig();
    return Plugin(
      api: searchMode == RuleMode.api || chapterMode == RuleMode.api
          ? ApiEndpoints.apiLevel.toString()
          : _api,
      type: _type,
      name: nameController.text,
      version: versionController.text,
      muliSources: _muliSources,
      useWebview: _useWebview,
      useNativePlayer: _useNativePlayer,
      usePost: usePost,
      useLegacyParser: useLegacyParser,
      adBlocker: adBlocker,
      userAgent: userAgentController.text,
      baseUrl: baseURLController.text,
      searchURL: searchURLController.text,
      searchList: searchListController.text,
      searchName: searchNameController.text,
      searchResult: searchResultController.text,
      chapterRoads: chapterRoadsController.text,
      chapterResult: chapterResultController.text,
      referer: refererController.text,
      searchMode: searchMode,
      chapterMode: chapterMode,
      searchApiConfig: searchConfig,
      chapterApiConfig: chapterConfig,
      antiCrawlerConfig: AntiCrawlerConfig(
        enabled: antiCrawlerEnabled,
        captchaType: captchaType,
        captchaImage: captchaImageController.text,
        captchaInput: captchaInputController.text,
        captchaButton: captchaButtonController.text,
        captchaDetectType: captchaDetectType,
        captchaDetectValue: captchaDetectValueController.text,
        captchaScript: captchaScriptController.text,
      ),
    );
  }

  ApiSearchConfig _buildSearchApiConfig() {
    final shouldValidate = searchMode == RuleMode.api;
    String valueOf(TextEditingController controller) =>
        shouldValidate ? controller.text.trim() : controller.text;
    final config = ApiSearchConfig(
      request: ApiRequestConfig(
        method: searchApiMethod,
        url: valueOf(searchApiURLController),
        headers: _parseJsonMap(searchApiHeadersController, '搜尋請求頭'),
        query: _parseJsonMap(searchApiQueryController, '搜尋查詢參數'),
        bodyType: searchApiBodyType,
        body: _parseBody(
          searchApiBodyController,
          searchApiBodyType,
          '搜尋請求體',
        ),
      ),
      listPath: valueOf(searchApiListPathController),
      namePath: valueOf(searchApiNamePathController),
      sourcePath: valueOf(searchApiSourcePathController),
      sourceTemplate: valueOf(searchApiSourceTemplateController),
    );
    if (!shouldValidate) return config;
    if (config.request.url.isEmpty) {
      throw const FormatException('搜尋請求地址不能為空');
    }
    const ApiRuleStrategy()
      ..prepareRequest(config.request, const {'keyword': 'test'})
      ..validateSearchConfig(config);
    return config;
  }

  ApiChapterConfig _buildChapterApiConfig() {
    final pageUrl = chapterApiPageURLController.text.trim();
    final variablesRaw = _parseJsonMap(
      chapterApiVariablesController,
      '選集響應變數',
    );
    final config = ApiChapterConfig(
      request: ApiRequestConfig(
        method: chapterApiMethod,
        url: chapterApiURLController.text.trim(),
        headers: _parseJsonMap(chapterApiHeadersController, '選集請求頭'),
        query: _parseJsonMap(chapterApiQueryController, '選集查詢參數'),
        bodyType: chapterApiBodyType,
        body: _parseBody(
          chapterApiBodyController,
          chapterApiBodyType,
          '選集請求體',
        ),
      ),
      format: chapterApiFormat,
      roadsPath: chapterApiRoadsPathController.text.trim(),
      roadNamePath: chapterApiRoadNamePathController.text.trim(),
      episodesPath: chapterApiEpisodesPathController.text.trim(),
      episodeNamePath: chapterApiEpisodeNamePathController.text.trim(),
      episodeUrlPath: chapterApiEpisodeURLPathController.text.trim(),
      roadNamesPath: chapterApiRoadNamesPathController.text.trim(),
      roadEpisodesPath: chapterApiRoadEpisodesPathController.text.trim(),
      roadSeparator: chapterApiRoadSeparatorController.text,
      episodeSeparator: chapterApiEpisodeSeparatorController.text,
      fieldSeparator: chapterApiFieldSeparatorController.text,
      variables: variablesRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      episodePage: pageUrl.isEmpty
          ? null
          : ApiEpisodePageConfig(
              url: pageUrl,
              query: _parseJsonMap(
                chapterApiPageQueryController,
                '播放頁查詢參數',
              ),
            ),
    );
    if (chapterMode != RuleMode.api) return config;
    if (config.request.url.isEmpty) {
      throw const FormatException('選集請求地址不能為空');
    }
    const ApiRuleStrategy()
      ..prepareRequest(config.request, const {'source': 'test'})
      ..validateChapterConfig(config);
    return config;
  }

  Map<String, dynamic> _parseJsonMap(
    TextEditingController controller,
    String label,
  ) {
    final text = controller.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final value = jsonDecode(text);
    if (value is! Map) throw FormatException('$label 必須是 JSON 物件');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  dynamic _parseBody(
    TextEditingController controller,
    String bodyType,
    String label,
  ) {
    if (bodyType == ApiBodyType.none) return null;
    final text = controller.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final dynamic value;
    try {
      value = jsonDecode(text);
    } on FormatException catch (error) {
      throw FormatException('$label 不是有效 JSON：${error.message}');
    }
    if (bodyType == ApiBodyType.form && value is! Map) {
      throw FormatException('$label 在表單模式下必須是 JSON 物件');
    }
    return value;
  }

  void _showEditorError(Object error) {
    if (!mounted) return;
    setState(() => _editorError = error.toString());
    if (_formScroll.hasClients) {
      _formScroll.animateTo(0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic);
    }
  }
}
