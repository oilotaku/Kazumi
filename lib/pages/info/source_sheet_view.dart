part of 'source_sheet.dart';

class _SourceSearchGroup {
  const _SourceSearchGroup({
    required this.name,
    required this.keyword,
    required this.status,
    required this.results,
  });

  final String name;
  final String keyword;
  final PluginSearchStatus status;
  final List<SearchItem> results;

  bool get isSearching => status == PluginSearchStatus.pending;
  bool get hasResults =>
      status == PluginSearchStatus.success && results.isNotEmpty;

  String get statusLabel => switch (status) {
        PluginSearchStatus.pending => '檢索中…',
        PluginSearchStatus.success =>
          results.isEmpty ? '無結果' : '${results.length} 個結果',
        PluginSearchStatus.noResult => '無結果',
        PluginSearchStatus.error => '檢索失敗',
        PluginSearchStatus.captcha => '需要驗證',
      };
}

enum _SourceDisplay { preview, expanded, collapsed }

class _SourceSheetView extends StatefulWidget {
  const _SourceSheetView({
    required this.keyword,
    required this.groups,
    required this.firstResultSource,
    required this.onSourceSearch,
    required this.onSourceAliasSearch,
    required this.onRetry,
    required this.onVerify,
    required this.onOpenBrowser,
    required this.onPlay,
    required this.onClose,
  });

  final String keyword;
  final List<_SourceSearchGroup> groups;
  final String? firstResultSource;
  final ValueChanged<String> onSourceSearch;
  final ValueChanged<String> onSourceAliasSearch;
  final ValueChanged<String> onRetry;
  final ValueChanged<String> onVerify;
  final ValueChanged<String> onOpenBrowser;
  final void Function(String sourceName, SearchItem result) onPlay;
  final VoidCallback onClose;

  @override
  State<_SourceSheetView> createState() => _SourceSheetViewState();
}

class _SourceSheetViewState extends State<_SourceSheetView> {
  final _scrollController = ScrollController();
  final _display = <String, _SourceDisplay>{};
  final _headerKeys = <String, GlobalKey>{};
  bool _autoExpansionHandled = false;

  @override
  void initState() {
    super.initState();
    _autoExpandFirstResult();
  }

  @override
  void didUpdateWidget(covariant _SourceSheetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final names = widget.groups.map((group) => group.name).toSet();
    _display.removeWhere((name, _) => !names.contains(name));
    _headerKeys.removeWhere((name, _) => !names.contains(name));
    _autoExpandFirstResult();
  }

  void _autoExpandFirstResult() {
    final name = widget.firstResultSource;
    if (_autoExpansionHandled || name == null) return;
    _autoExpansionHandled = true;
    _display[name] = _SourceDisplay.preview;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setDisplay(String name, _SourceDisplay display) {
    setState(() {
      _autoExpansionHandled = true;
      _display[name] = display;
    });
  }

  void _collapseFromFooter(String name) {
    final headerContext = _headerKeys[name]?.currentContext;
    if (headerContext != null) {
      // Anchor before shrinking, while the header is still laid out.
      Scrollable.ensureVisible(headerContext, alignment: 0);
    }
    _setDisplay(name, _SourceDisplay.collapsed);
  }

  Widget _animateSize(Widget child) => MediaQuery.disableAnimationsOf(context)
      ? child
      : AnimatedSize(
          duration: splitListMotionDuration,
          curve: splitListMotionCurve,
          alignment: Alignment.topCenter,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final pending = widget.groups.where((group) => group.isSearching).length;
    final resultCount = widget.groups
        .where((group) => group.hasResults)
        .fold(0, (sum, group) => sum + group.results.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          MaterialBottomSheetHeader(
            title: '播放來源',
            description: pending > 0
                ? '檢索中 ${widget.groups.length - pending}/${widget.groups.length} · $resultCount 個結果'
                : '${widget.groups.length} 個來源 · $resultCount 個結果',
            compact: true,
            onClose: widget.onClose,
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList.builder(
                      itemCount: widget.groups.length,
                      findChildIndexCallback: (key) {
                        final index = widget.groups
                            .indexWhere((group) => ValueKey(group.name) == key);
                        return index < 0 ? null : index;
                      },
                      itemBuilder: (context, index) {
                        final group = widget.groups[index];
                        return Padding(
                          key: ValueKey(group.name),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSourceGroup(group),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SafeArea(top: false, child: SizedBox(height: 24)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceGroup(_SourceSearchGroup group) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final display = _display[group.name] ?? _SourceDisplay.collapsed;
    final collapsed = display == _SourceDisplay.collapsed;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : splitListMotionDuration;

    void toggle() => _setDisplay(group.name,
        collapsed ? _SourceDisplay.preview : _SourceDisplay.collapsed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: _headerKeys.putIfAbsent(group.name, GlobalKey.new),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  button: true,
                  expanded: !collapsed,
                  label: '來源規則：${group.name}，${group.statusLabel}',
                  onTap: toggle,
                  excludeSemantics: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: toggle,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                group.name,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              )),
                              const SizedBox(width: 8),
                              Text(
                                group.statusLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: collapsed ? 0 : 0.5,
                                duration: duration,
                                curve: splitListMotionCurve,
                                child: Icon(Icons.expand_more_rounded,
                                    size: 20, color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildSourceMenu(group),
            ],
          ),
        ),
        if (!collapsed && group.keyword != widget.keyword)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              '檢索詞：${group.keyword}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        _animateSize(
          collapsed
              ? const SizedBox.shrink()
              : _buildSourceBody(group,
                  showAll: display == _SourceDisplay.expanded),
        ),
      ],
    );
  }

  Widget _buildSourceBody(_SourceSearchGroup group, {required bool showAll}) {
    if (!group.hasResults) {
      return SplitListRow(
        topRadius: splitListOuterRadius,
        bottomRadius: splitListOuterRadius,
        child: switch (group.status) {
          PluginSearchStatus.pending => _buildSearching(),
          PluginSearchStatus.success ||
          PluginSearchStatus.noResult =>
            GeneralEmptyState(
              icon: Icons.search_off_rounded,
              title: '沒有找到匹配結果',
              compact: true,
              actions: [
                StateActionButton.tonal(
                  onPressed: () => widget.onSourceSearch(group.name),
                  text: '修改檢索詞',
                ),
                TextButton(
                  onPressed: () => widget.onSourceAliasSearch(group.name),
                  child: const Text('使用別名'),
                ),
              ],
            ),
          PluginSearchStatus.captcha =>
            _buildSourceIssue(group.name, requiresVerification: true),
          PluginSearchStatus.error =>
            _buildSourceIssue(group.name, requiresVerification: false),
        },
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final visibleCount = showAll ? group.results.length : 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visibleCount; index++) ...[
          if (index > 0) const SizedBox(height: splitListRowGap),
          _buildResult(group, index),
        ],
        if (group.results.length > 1) ...[
          const SizedBox(height: splitListRowGap),
          SplitListRow(
            bottomRadius: splitListOuterRadius,
            onTap: () => showAll
                ? _collapseFromFooter(group.name)
                : _setDisplay(group.name, _SourceDisplay.expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        showAll ? '收起全部條目' : '展開全部 ${group.results.length} 個結果',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      showAll
                          ? Icons.unfold_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceMenu(_SourceSearchGroup group) => TooltipVisibility(
        visible: false,
        child: KazumiMenuButton(
          animated: true,
          builder: (context, toggle) => IconButton(
            tooltip: '${group.name} 的更多操作',
            icon: const Icon(Icons.more_horiz_rounded, size: 20),
            onPressed: toggle,
          ),
          menuChildren: [
            KazumiMenuItem(
              label: '修改此來源的檢索詞',
              onPressed: () => widget.onSourceSearch(group.name),
            ),
            KazumiMenuItem(
              label: '使用別名檢索此來源',
              onPressed: () => widget.onSourceAliasSearch(group.name),
            ),
            KazumiMenuItem(
              label: '重新檢索此來源',
              onPressed: () => widget.onRetry(group.name),
            ),
            KazumiMenuItem(
              label: '在瀏覽器中開啟',
              onPressed: () => widget.onOpenBrowser(group.name),
            ),
          ],
        ),
      );

  Widget _buildResult(_SourceSearchGroup group, int index) {
    final theme = Theme.of(context);
    final result = group.results[index];
    return SplitListRow(
      topRadius: index == 0 ? splitListOuterRadius : splitListInnerRadius,
      bottomRadius: group.results.length == 1
          ? splitListOuterRadius
          : splitListInnerRadius,
      onTap: () => widget.onPlay(group.name, result),
      child: Semantics(
        button: true,
        label: '播放 ${result.name}，來源 ${group.name}',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(result.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      )),
                ),
                const SizedBox(width: 16),
                Icon(Icons.play_arrow_rounded,
                    color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearching() => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const LoadingIndicator(size: 20, semanticsLabel: '正在檢索'),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('正在檢索…',
                      style: Theme.of(context).textTheme.bodyMedium)),
            ],
          ),
        ),
      );

  Widget _buildSourceIssue(String sourceName,
      {required bool requiresVerification}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (icon, title, hint, action, onAction) = requiresVerification
        ? (
            Icons.verified_user_outlined,
            '需要驗證',
            '完成網站驗證後繼續檢索。',
            '進行驗證',
            () => widget.onVerify(sourceName),
          )
        : (
            Icons.error_outline_rounded,
            '檢索失敗',
            '可以重試，或開啟網站檢查是否可用。',
            '重試',
            () => widget.onRetry(sourceName),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  icon,
                  size: 20,
                  color: requiresVerification
                      ? colors.onSurfaceVariant
                      : colors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 2),
                    Text(hint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilledButton.tonal(onPressed: onAction, child: Text(action)),
              TextButton(
                onPressed: () => widget.onOpenBrowser(sourceName),
                child: const Text('開啟網站'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
