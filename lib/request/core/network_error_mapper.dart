import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:kazumi/request/core/network_exception.dart';

class NetworkErrorMapper {
  const NetworkErrorMapper._();

  static Future<NetworkException> mapException(DioException error) async {
    switch (error.type) {
      case DioExceptionType.badCertificate:
        return NetworkException(
          type: NetworkExceptionType.badCertificate,
          message: '證書有誤！',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return NetworkException(
          type: NetworkExceptionType.badResponse,
          message: '伺服器異常，請稍後重試！',
          statusCode: statusCode,
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          type: NetworkExceptionType.cancel,
          message: '請求已被取消，請重新請求',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          type: NetworkExceptionType.connectionError,
          message: '連線錯誤，請檢查網路設定',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.connectionTimeout:
        return NetworkException(
          type: NetworkExceptionType.connectionTimeout,
          message: '網路連線超時，請檢查網路設定',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          type: NetworkExceptionType.receiveTimeout,
          message: '響應超時，請稍後重試！',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.sendTimeout:
        return NetworkException(
          type: NetworkExceptionType.sendTimeout,
          message: '傳送請求超時，請檢查網路設定',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.transformTimeout:
        return NetworkException(
          type: NetworkExceptionType.parseError,
          message: '響應解析超時，請稍後重試！',
          rawError: error,
          stackTrace: error.stackTrace,
        );
      case DioExceptionType.unknown:
        var connection = '';
        try {
          connection = await _connectionLabel().timeout(
            const Duration(seconds: 1),
          );
        } catch (_) {}
        return NetworkException(
          type: NetworkExceptionType.unknown,
          message: '$connection 網路異常'.trimLeft(),
          rawError: error,
          stackTrace: error.stackTrace,
        );
    }
  }

  static NetworkException parse(Object error, StackTrace stackTrace) {
    return NetworkException(
      type: NetworkExceptionType.parseError,
      message: '響應解析失敗',
      rawError: error,
      stackTrace: stackTrace,
    );
  }

  static Future<String> _connectionLabel() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return '正在使用行動資料';
    }
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return '正在使用wifi';
    }
    if (connectivityResult.contains(ConnectivityResult.ethernet)) {
      return '正在使用區域網';
    }
    if (connectivityResult.contains(ConnectivityResult.vpn)) {
      return '正在使用代理網路';
    }
    if (connectivityResult.contains(ConnectivityResult.other)) {
      return '正在使用其他網路';
    }
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return '未連線到任何網路';
    }
    return '';
  }
}
