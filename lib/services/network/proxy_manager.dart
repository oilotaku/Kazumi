import 'package:cached_network_image/cached_network_image.dart';
import 'package:kazumi/request/core/dio_factory.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/network/proxy_aware_image_cache_manager.dart';

// WebView proxies are configured separately by their platform controllers.
class ProxyManager {
  ProxyManager._();

  static void applyProxy() {
    DioFactory.reset();
    _applyImageCacheManager();
    KazumiLogger().i('Proxy: 網路客戶端配置已重新整理');
  }

  static void clearProxy() {
    DioFactory.reset();
    _applyImageCacheManager();
    KazumiLogger().i('Proxy: 網路客戶端代理已清除');
  }

  static void _applyImageCacheManager() {
    ProxyAwareImageCacheManager.instance.resetNetworkClients();
    CachedNetworkImageProvider.defaultCacheManager =
        ProxyAwareImageCacheManager.instance;
  }
}
