import 'package:flutter/material.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:screen/screen.dart';

final sStatusStore = StatusStore._();

class StatusStore with ChangeNotifier {
  int browsePage_createtime = -1;   //  正在展示的笔记的id
  String lang = '';
  BuildContext _context;

  RTMUserInfo _userInfo;

  RTMUserInfo get userInfo => _userInfo;

  BuildContext get context => _context;

  StatusStore._();

  setContext(BuildContext value) async {
    _context = value;

    var defaultLang = 'zh_CN';
    if (defaultLang != lang) {
      lang = defaultLang;
      MyscriptIink.setEngineConfiguration_Language(lang);
    }
  }

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
