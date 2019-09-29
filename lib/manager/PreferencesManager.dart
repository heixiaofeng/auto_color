import 'dart:typed_data';

import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugee_note/model/account.dart';

var sPreferencesManager = PreferencesManager.shared();

class PreferencesManager {
  PreferencesManager.shared() {}

  Future<SharedPreferences> get _pre async =>
      await SharedPreferences.getInstance();

  /*------------------------上次连接设备的id-------------------------------------*/
  final _lastPairDeviceID_key = 'LastPairDeviceID';

  Future<String> get lastPairDeviceID async =>
      await (await _pre).getString(_lastPairDeviceID_key);

  setLastPairDeviceID([String value]) async {
    value != null
        ? (await _pre).setString(_lastPairDeviceID_key, value)
        : (await _pre).remove(_lastPairDeviceID_key);
  }

/*------------------------上次登录账号的id-------------------------------------*/
  final _lastPairAccountID_key = 'PairAccountID';

  Future<int> get lastPairAccountID async =>
      await (await _pre).getInt(_lastPairAccountID_key);

  setLastPairAccountID([int value]) async {
    value != null
        ? (await _pre).setInt(_lastPairAccountID_key, value)
        : (await _pre).remove(_lastPairAccountID_key);
  }

/*--------------------------------------------------------------------------*/
  final _switchValue_key = 'switchValue_key';

  Future<bool> get switchValue async {
    return (await _pre).getBool(_switchValue_key) ?? false;
  }

  setSwitchValue([bool value]) async =>
      (await _pre).setBool(_switchValue_key, value ?? false);

/*--------------------------------------------------------------------------*/
  final _searchRecordKeyword_key = '_searchRecordKeyword_key';

  Future<List<String>> get searchrecord async =>
      (await _pre).getStringList(_searchRecordKeyword_key) ?? List<String>();

  setSearchrecord([List<String> value]) async => (await _pre)
      .setStringList(_searchRecordKeyword_key, value ?? List<String>());

/*--------------------------------------------------------------------------*/
  final _isOnReview_key = 'isOnReview_key';

  Future<bool> get isOnReview async =>
      (await _pre).getBool(_isOnReview_key) ?? false;

  setIsOnReview([bool value]) async =>
      (await _pre).setBool(_isOnReview_key, value ?? false);

/*--------------------------------------------------------------------------*/
  final _syncCloudDate_key = 'syncCloudDate_key';

  Future<int> get syncCloudDate async =>
      (await _pre).getInt(_syncCloudDate_key);

  setSyncCloudDate([int value]) async => (await _pre).setInt(
      _syncCloudDate_key, value ?? DateTime.now().millisecondsSinceEpoch);

  /*--------------------------------------------------------------------------*/
  final _keyLastImportTime_key = 'lastImportTime';

  Future<int> get lastImportTime async =>
      (await _pre).getInt(_keyLastImportTime_key);

  setLastImportTime([int value]) async => (await _pre).setInt(
      _keyLastImportTime_key, value ?? DateTime.now().millisecondsSinceEpoch);

/*--------------------------------------------------------------------------*/
  Future<bool> get isLoadGuidePages async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var version = 'v${packageInfo.version}_b${packageInfo.buildNumber}';
    var _isLoadGuidePages_key = 'isLoadGuidePages_key_${version}';
    return (await SharedPreferences.getInstance())
            .getBool(_isLoadGuidePages_key) ??
        false;
  }

  setIsLoadGuidePages([bool value]) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var version = 'v${packageInfo.version}_b${packageInfo.buildNumber}';
    var _isLoadGuidePages_key = 'isLoadGuidePages_key_${version}';
    (await _pre).setBool(_isLoadGuidePages_key, value ?? false);
  }

/*--------------------------------------------------------------------------*/
  final _loginState_key = 'loginState_key';
  final _loginPlatform_key = 'loginPlatform_key';
  final _uid_key = 'uid_key';
  final _showid_key = 'showid_key';
  final _nickname_key = 'nickname_key';
  final _avatar_key = 'avatar_key';
  final _gender_key = 'gender_key';
  final _accesstoken_key = 'accesstoken_key';
  final _logintoken_key = 'logintoken_key';

  Future<LoginInfo> get loginInfo async {
    var _pre = await SharedPreferences.getInstance();

    //sigout = 0；loading = 1；sigin = 2
    final loginStateIndex = _pre.getInt(_loginState_key) ?? 0;
    if (loginStateIndex != 2) return LoginInfo.sinout;

    //google = 1；facebook = 2；account_password = 3；phone = 4；wechat = 5
    final platformIndex = _pre.getInt(_loginPlatform_key) ?? 0;
    LoginPlatform platform;
    switch (platformIndex) {
      case 1:
        platform = LoginPlatform.google;
        break;
      case 2:
        platform = LoginPlatform.facebook;
        break;
      case 3:
        platform = LoginPlatform.account_password;
        break;
      case 4:
        platform = LoginPlatform.phone;
        break;
      case 5:
        platform = LoginPlatform.wechat;
        break;
      default:
        return LoginInfo.sinout;
    }

    //  UserInfo
    var aaainfo = UserInfo(0, 0, '', '', 0);
    print(aaainfo);
    var info = UserInfo(
        _pre.getInt(_uid_key) ?? 0,
        _pre.getInt(_showid_key) ?? 0,
        _pre.getString(_nickname_key) ?? '',
        _pre.getString(_avatar_key) ?? '',
        _pre.getInt(_gender_key) ?? 0);
    info.accessToken = _pre.getString(_accesstoken_key) ?? '';
    info.loginToken = _pre.getString(_logintoken_key) ?? '';

    return LoginInfo(LoginState.sigin, platform: platform, userInfo: info);
  }

  setLoginInfo([LoginInfo value]) async {
    if (value == null || value.state != LoginState.sigin) {
      (await _pre).setInt(_loginState_key, 0);
      (await _pre).remove(_loginPlatform_key);
      (await _pre).remove(_uid_key);
      (await _pre).remove(_showid_key);
      (await _pre).remove(_nickname_key);
      (await _pre).remove(_avatar_key);
      (await _pre).remove(_gender_key);
      (await _pre).remove(_accesstoken_key);
      (await _pre).remove(_logintoken_key);
    } else {
      // sigout = 0；loading = 1；sigin = 2
      (await _pre).setInt(_loginState_key, 2);

      //google = 1；facebook = 2；account_password = 3；phone = 4；wechat = 5
      int platformIndex;
      switch (value.platform) {
        case LoginPlatform.google:
          platformIndex = 1;
          break;
        case LoginPlatform.facebook:
          platformIndex = 2;
          break;
        case LoginPlatform.account_password:
          platformIndex = 3;
          break;
        case LoginPlatform.phone:
          platformIndex = 4;
          break;
        case LoginPlatform.wechat:
          platformIndex = 5;
          break;
        default:
          return null;
      }
      (await _pre).setInt(_loginPlatform_key, platformIndex);

      //  UserInfo
      (await _pre).setInt(_uid_key, value.userInfo.uid);
      (await _pre).setInt(_showid_key, value.userInfo.showid);
      (await _pre).setString(_nickname_key, value.userInfo.nickname);
      (await _pre).setString(_avatar_key, value.userInfo.avatar);
      (await _pre).setInt(_gender_key, value.userInfo.gender);
      (await _pre).setString(_accesstoken_key, value.userInfo.accessToken);
      (await _pre).setString(_logintoken_key, value.userInfo.loginToken);
    }
  }
}
