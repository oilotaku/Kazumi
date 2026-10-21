import 'dart:io';

import 'package:kazumi/request/clients/trace_client.dart';
import 'package:kazumi/modules/search/image_search_module.dart';
import 'package:kazumi/request/config/api_endpoints.dart';

class TraceApi {
  static final TraceClient _client = TraceClient.instance;

  ///根據圖片搜尋番劇資訊
  static Future<ImageSearchItem> searchAnimeByImageFile(File imageFile,
      {int anilistInfo = 2}) async {
    final bytes = await imageFile.readAsBytes();

    final data = await _client.post(
      ApiEndpoints.traceApi,
      queryParameters: {
        'anilistInfo': anilistInfo,
      },
      data: bytes,
      headers: {'Content-Type': 'image/jpeg'},
    );
    return ImageSearchItem.fromJson(data as Map<String, dynamic>);
  }

  ///根據圖片URL搜尋番劇資訊
  static Future<ImageSearchItem> searchAnimeByImageUrl(String imageUrl,
      {int anilistInfo = 2}) async {
    final data = await _client.post(
      ApiEndpoints.traceApi,
      queryParameters: {
        'anilistInfo': anilistInfo,
        'url': imageUrl,
      },
    );
    return ImageSearchItem.fromJson(data as Map<String, dynamic>);
  }
}
