import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kazumi/bean/widget/error_widget.dart';
import 'package:kazumi/bean/widget/loading_indicator.dart';
import 'package:kazumi/bean/widget/state_presentation.dart';

class StorageErrorPage extends StatelessWidget {
  const StorageErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('內部錯誤'),
      ),
      body: FutureBuilder<Directory>(
        future: getApplicationSupportDirectory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final path = snapshot.data?.path ?? '未知路徑';
            return GeneralErrorWidget(
              title: '無法初始化本地儲存',
              icon: Icons.storage_rounded,
              errMsg: '當前儲存位置：\n$path\n\n可在退出後刪除該目錄以重置本地儲存，此操作會清除本地資料。',
              actions: [
                StateActionButton(
                  onPressed: () {
                    exit(0);
                  },
                  text: '退出程式',
                  icon: Icons.close_rounded,
                ),
              ],
            );
          } else {
            return const Center(child: LoadingIndicator());
          }
        },
      ),
    );
  }
}
