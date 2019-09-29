import 'dart:io';

import 'package:device_info/device_info.dart';

final deviceInfo = DeviceInfo();

class DeviceInfo {
  final plugin = DeviceInfoPlugin();

  Future<String> get model async {
    if (Platform.isAndroid) {
      return (await plugin.androidInfo).model;
    } else if (Platform.isIOS) {
      return (await plugin.iosInfo).model;
    }
    // TODO throw UnimplementedError();
    return Platform.operatingSystem;
  }

  Future<String> get system async {
    if (Platform.isAndroid) {
      var info = await plugin.androidInfo;
      return 'Android ${info.version.release}';
    } else if (Platform.isIOS) {
      var info = await plugin.iosInfo;
      return '${info.systemVersion} ${info.systemVersion}';
    }
    // TODO throw UnimplementedError();
    return Platform.operatingSystemVersion;
  }
}