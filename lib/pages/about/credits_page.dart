import 'package:flutter/material.dart';

import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/widget/content_section.dart';
import 'package:kazumi/pages/about/about_widgets.dart';
import 'package:kazumi/request/config/api_endpoints.dart';

class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) => SettingsDetailScaffold(
        title: const Text('致謝'),
        body: AboutContent(
          children: [
            ContentSection.group(
              title: '貢獻',
              children: const [
                AboutLinkTile(
                  icon: Icons.people_outline_rounded,
                  title: '貢獻者',
                  url: '${ApiEndpoints.sourceUrl}/graphs/contributors',
                ),
                AboutLinkTile(
                  icon: Icons.brush_rounded,
                  title: '圖示作者',
                  subtitle: 'Pixiv',
                  url: ApiEndpoints.iconUrl,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ContentSection.group(
              title: '服務',
              children: const [
                AboutLinkTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Bangumi',
                  subtitle: '番劇資訊',
                  url: ApiEndpoints.bangumiIndex,
                ),
                AboutLinkTile(
                  icon: Icons.subtitles_rounded,
                  title: '彈彈play',
                  subtitle: '彈幕',
                  url: ApiEndpoints.dandanIndex,
                ),
                AboutLinkTile(
                  icon: Icons.image_search_rounded,
                  title: 'trace.moe',
                  subtitle: '以圖搜番',
                  url: 'https://trace.moe',
                ),
              ],
            ),
            const SizedBox(height: 24),
            ContentSection.group(
              title: '開源專案',
              children: const [
                AboutLinkTile(
                  icon: Icons.flutter_dash_rounded,
                  title: 'Flutter',
                  subtitle: '應用框架',
                  url: 'https://flutter.dev',
                ),
                AboutLinkTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'media-kit',
                  subtitle: '影片播放',
                  url: 'https://github.com/media-kit/media-kit',
                ),
                AboutLinkTile(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Anime4K',
                  subtitle: '實時超解析度',
                  url: 'https://github.com/bloc97/Anime4K',
                ),
                AboutLinkTile(
                  icon: Icons.sync_rounded,
                  title: 'Syncplay',
                  subtitle: '播放同步',
                  url: 'https://github.com/Syncplay/syncplay',
                ),
                AboutLinkTile(
                  icon: Icons.account_tree_rounded,
                  title: 'XpathSelector',
                  subtitle: 'XPath 解析',
                  url: 'https://github.com/simonkimi/xpath_selector',
                ),
                AboutLinkTile(
                  icon: Icons.video_settings_rounded,
                  title: 'avbuild',
                  subtitle: '非標準影片流支援',
                  url: 'https://github.com/wang-bin/avbuild',
                ),
                AboutLinkTile(
                  icon: Icons.storage_rounded,
                  title: 'Hive CE',
                  subtitle: '本地儲存',
                  url: 'https://github.com/IO-Design-Team/hive_ce',
                ),
              ],
            ),
          ],
        ),
      );
}
