import 'package:flutter/material.dart';
import 'package:screen/screen.dart';

final rtcSysMsg = RTCSysMsg._();

class RTCSysMsg with ChangeNotifier {

  RTMUserInfo _userInfo;

  RTMUserInfo get userInfo => _userInfo;

  RTCSysMsg._();

  updateRTMUserInfo(RTMUserInfo info) {
    _userInfo = info;
    notifyListeners();
  }

  screenKeepOn({bool isOn = false}) {
    Screen.keepOn(isOn);
  }
}

class RTMUserInfo {
  final nickname;
  final avatar;
  RTMUserInfo.fromMap(Map map)
      : this.nickname = map['nickname'],
        this.avatar = map['avatar'];
}