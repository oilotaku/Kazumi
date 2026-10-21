import 'dart:io';

import 'package:flutter/material.dart';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/services/download/download_directory_service.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/file_system.dart';

class DownloadSettingsPage extends StatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  State<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends State<DownloadSettingsPage> {
  final _directoryService = DownloadDirectoryService();
  late int parallelEpisodes;
  late int parallelSegments;
  late bool downloadDanmaku;
  String downloadDirectory = '';
  String defaultDownloadDirectory = '';
  bool isSelectingDirectory = false;

  @override
  void initState() {
    super.initState();
    parallelEpisodes =
        GStorage.getSetting(SettingsKeys.downloadParallelEpisodes);
    parallelSegments =
        GStorage.getSetting(SettingsKeys.downloadParallelSegments);
    downloadDanmaku = GStorage.getSetting(SettingsKeys.downloadDanmaku);
    downloadDirectory = _directoryService.customDirectory;
    _loadDefaultDownloadDirectory();
  }

  bool get _hasCustomDirectory => downloadDirectory.isNotEmpty;

  String get _effectiveDownloadDirectory =>
      _hasCustomDirectory ? downloadDirectory : defaultDownloadDirectory;

  Future<void> _loadDefaultDownloadDirectory() async {
    final directory = await getDefaultDownloadDirectory();
    if (!mounted) return;
    setState(() {
      defaultDownloadDirectory = directory;
    });
  }

  Future<void> _selectDownloadDirectory() async {
    if (isSelectingDirectory) return;

    setState(() => isSelectingDirectory = true);
    try {
      final selectedPath = await _directoryService.selectDirectory();
      if (selectedPath == null) return;
      if (mounted) {
        setState(() => downloadDirectory = selectedPath);
      }
      KazumiDialog.showToast(message: '下載位置已更新，僅對新下載生效');
    } on DownloadDirectoryException catch (e) {
      KazumiDialog.showToast(message: e.message);
    } on FileSystemException catch (e) {
      KazumiDialog.showToast(message: '無法寫入該目錄: ${e.message}');
    } catch (e) {
      KazumiDialog.showToast(message: '選擇下載位置失敗: $e');
    } finally {
      if (mounted) {
        setState(() => isSelectingDirectory = false);
      }
    }
  }

  Future<void> _resetDownloadDirectory() async {
    await _directoryService.resetDirectory();
    if (mounted) {
      setState(() => downloadDirectory = '');
    }
    KazumiDialog.showToast(message: '已恢復預設下載位置，僅對新下載生效');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('下載設定'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('併發設定'),
            tiles: [
              SettingsSliderTile(
                leading: Icons.video_library_rounded,
                title: Text('同時下載集數'),
                description: Text('並行下載的劇集數量'),
                value: parallelEpisodes.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                valueLabel: '$parallelEpisodes 集',
                onChanged: (value) {
                  setState(() => parallelEpisodes = value.toInt());
                  GStorage.putSetting(
                    SettingsKeys.downloadParallelEpisodes,
                    parallelEpisodes,
                  );
                },
              ),
              SettingsSliderTile(
                leading: Icons.call_split_rounded,
                title: Text('分片併發數'),
                description: Text('每集同時下載的分片數量'),
                value: parallelSegments.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                valueLabel: '$parallelSegments 個',
                onChanged: (value) {
                  setState(() => parallelSegments = value.toInt());
                  GStorage.putSetting(
                    SettingsKeys.downloadParallelSegments,
                    parallelSegments,
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('快取設定'),
            tiles: [
              SettingsTile(
                leading: Icons.folder_rounded,
                title: Text('下載位置'),
                description: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveDownloadDirectory.isEmpty
                          ? '正在讀取預設位置...'
                          : _effectiveDownloadDirectory,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasCustomDirectory
                          ? '當前使用自定義下載位置，修改後僅對新下載生效'
                          : '當前使用預設下載位置，修改後僅對新下載生效',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                trailing: isSelectingDirectory
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingIndicator(),
                      )
                    : _hasCustomDirectory
                        ? IconButton(
                            tooltip: '恢復預設',
                            icon: const Icon(Icons.restore_rounded),
                            onPressed: _resetDownloadDirectory,
                          )
                        : null,
                onPressed: (_) => _selectDownloadDirectory(),
              ),
              SettingsTile.switchTile(
                leading: Icons.subtitles_rounded,
                onToggle: (value) {
                  setState(() => downloadDanmaku = value ?? !downloadDanmaku);
                  GStorage.putSetting(
                      SettingsKeys.downloadDanmaku, downloadDanmaku);
                },
                title: Text('快取彈幕'),
                description: Text(
                  '下載影片時同時快取彈幕資料',
                ),
                initialValue: downloadDanmaku,
              ),
            ],
          ),
          SettingsSection(
            title: Text('說明'),
            tiles: [
              SettingsTile(
                leading: Icons.info_outline_rounded,
                title: Text('關於併發設定'),
                description: Text(
                  '• 集數併發：同時下載多少集影片\n'
                  '• 分片併發：每集內同時下載多少個影片片段\n'
                  '• 較高的併發可提升速度，但可能被伺服器限制\n'
                  '• 修改後對新開始的下載生效',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
