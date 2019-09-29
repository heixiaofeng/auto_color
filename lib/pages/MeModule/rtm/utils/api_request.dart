import 'package:dio/dio.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'tools.dart';

const _UGEE_ServerUrl = 'http://39.106.100.225/';

class APIRequest {

  static Dio _dio;

  static const String GET = 'get';
  static const String POST = 'post';
  static const String PUT = 'put';
  static const String PATCH = 'patch';
  static const String DELETE = 'delete';

  static Dio shared() {
    if (_dio == null) {
      BaseOptions options = BaseOptions(
        baseUrl: _UGEE_ServerUrl,
        connectTimeout: 10000,
        receiveTimeout: 3000,
      );

      _dio = Dio(options);
    }

    return _dio;
  }

  static Future<Map> request (
      String url,
      { method, data, bool isLogin = false, Function faildCallback }) async {

    data = data ?? {};
    method = method ?? GET;

    data.forEach((key, value) {
      if (url.indexOf(key) != -1) {
        url = url.replaceAll(':$key', value.toString());
      }
    });

    try {
//      SmartChannel.invokeMethod(RTCMethodName.hud_loading, '请稍后');
      var path = '${isLogin ? 'v2' : 'applets/v2'}' + url + (isLogin ? '' : '?accessToken=' + sAccountManager.loginInfo.userInfo.accessToken);
      print('*** >>> fank path $path, method: $method, params: ${data.toString()}');
      Response response = await shared().request(path, data: data, options: Options(method: method));
//      SmartChannel.invokeMethod(RTCMethodName.hud_finish);
      var result = response.data;
      switch(result['status']['statuscode']) {
        case '0':
          return result['data'] as Map;
        case '-998':
          SmartChannel.invokeMethod(RTCMethodName.refreshAccessToken);
          return null;
        default:
          if(faildCallback != null) faildCallback(result['status']['message']);
          return null;
      }
    } on DioError catch (error) {
      print('DioError：' + error.toString());
    }

    return null;
  }

  static clear() {
    _dio = null;
  }
}