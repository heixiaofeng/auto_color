import 'dart:io';

import 'package:ugee_note/pages/MeModule/rtm/pages/login/AppUtils.dart';

const ALPHA_NOTE_ANDROID = 1;
const ALPHA_NOTE_IOS = 2;

class WoodemiService {
  static Future<Map> get systemData async {
    return {
      "appId": appId,
      ...await AppUtils.deviceInfo,
    };
  }

  static int get appId {
    if (Platform.isIOS) {
      return ALPHA_NOTE_IOS;
    } else if (Platform.isAndroid) {
      return ALPHA_NOTE_ANDROID;
    }
    throw UnimplementedError();
  }
}