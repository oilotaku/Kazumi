part of 'timeline_page.dart';

const _timelineOptionsTitle = '排序與篩選';

extension _TimelineSortLabel on TimelineSort {
  String get label => switch (this) {
        TimelineSort.popularity => '熱度優先',
        TimelineSort.rating => '評分優先',
        TimelineSort.defaultOrder => '預設順序',
      };
}

class _TimelineOptionsButton extends StatelessWidget {
  const _TimelineOptionsButton({
    required this.availableWidth,
    required this.sort,
    required this.filterCount,
    required this.onPressed,
  });

  final double availableWidth;
  final TimelineSort sort;
  final int filterCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final compact =
        availableWidth < scaler.scale(16) * 22 || scaler.scale(14) > 28;
    final style = StateActionButton.styleOf(context).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
    final summary = '${sort.label}，'
        '${filterCount > 0 ? '已启用 $filterCount 项筛选' : '未启用筛选'}';
    final icon = Badge(
      isLabelVisible: filterCount > 0,
      label: Text('$filterCount'),
      child: const Icon(Icons.tune_rounded, size: 20),
    );
    return Semantics(
      label: _timelineOptionsTitle,
      value: summary,
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: '$_timelineOptionsTitle：$summary',
        child: compact
            ? FilledButton.tonal(
                style: style,
                onPressed: onPressed,
                child: icon,
              )
            : FilledButton.tonalIcon(
                style: style,
                onPressed: onPressed,
                icon: icon,
                label: Text(sort.label, maxLines: 1),
              ),
      ),
    );
  }
}

class _TimelineOptionsSheet extends StatelessWidget {
  const _TimelineOptionsSheet({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MaterialBottomSheetHeader(
            title: _timelineOptionsTitle,
            onClose: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: materialBottomSheetContentPadding,
              children: [
                ContentSection(
                  title: '排序',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in TimelineSort.values)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: controller.sort == option,
                          onSelected: (_) => controller.changeSort(option),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ContentSection.group(
                  title: '顯示範圍',
                  children: [
                    SwitchListTile(
                      title: const Text('隱藏看過的番劇'),
                      value: controller.notShowWatchedBangumis,
                      onChanged: controller.setNotShowWatchedBangumis,
                    ),
                    SwitchListTile(
                      title: const Text('隱藏拋棄的番劇'),
                      value: controller.notShowAbandonedBangumis,
                      onChanged: controller.setNotShowAbandonedBangumis,
                    ),
                    SwitchListTile(
                      title: const Text('只看正在追的番劇'),
                      value: controller.onlyShowWatchingBangumis,
                      onChanged: controller.setOnlyShowWatchingBangumis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
