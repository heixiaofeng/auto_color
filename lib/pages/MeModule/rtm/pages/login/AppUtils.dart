import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';

final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

class AppUtils {
  static Future<Map> get deviceInfo async => {
        ...await getSystemInfo(),
        'appVer': (await PackageInfo.fromPlatform()).version,
      };

  static Future<Map<String, String>> getSystemInfo() async {
    if (Platform.isAndroid) {
      var androidDeviceInfo = await _deviceInfo.androidInfo;
      return {
        'deviceToken': androidDeviceInfo.model,
        'sysVer': 'Android ${androidDeviceInfo.version.release}',
      };
    } else if (Platform.isIOS) {
      var iosInfo = await _deviceInfo.iosInfo;
      return {
        'deviceToken': iosInfo.model,
        'sysVer': '${iosInfo.systemName} ${iosInfo.systemVersion}',
      };
    }
    throw UnimplementedError();
  }
}
