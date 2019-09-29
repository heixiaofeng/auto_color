import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:fluwx/fluwx.dart' as fluwx;
import 'package:fluwx/fluwx.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/model/account.dart';
import 'package:woodemi_service/StorageService.dart';
import 'package:woodemi_service/UserService.dart' as WS;
import 'package:woodemi_service/common.dart';
import 'package:woodemi_service/user.dart' as user;

final sAccountManager = AccountManager._internal();

class AccountManager {
  LoginInfo _loginInfo = LoginInfo(LoginState.sigout);

  LoginInfo get loginInfo => _loginInfo;

  _setLoginInfoState(LoginState state) {
    setLoginInfo(state, _loginInfo.platform, _loginInfo.userInfo);
  }

  setLoginInfo(
      LoginState state, LoginPlatform platform, UserInfo userInfo) async {
    final oldState = _loginInfo.state;
    _loginInfo.state = (state != null) ? state : LoginState.sigout;
    if (_loginInfo.state != LoginState.sigout) {
      _loginInfo.platform = platform;
      _loginInfo.userInfo = userInfo;
    } else {
      _loginInfo.platform = null;
      _loginInfo.userInfo = null;
    }

    await sPreferencesManager.setLoginInfo(loginInfo);

    if (oldState != state) _loginInfoStreamController.add(_loginInfo);
  }

  final _loginInfoStreamController = StreamController<LoginInfo>.broadcast();

  Stream<LoginInfo> get loginInfoStream => _loginInfoStreamController.stream;

  AccountManager._internal() {
    initWX();
  }

  initWX() async {
    await fluwx.register(
      appId: "wx25d5fcaddc2b73a9",
      doOnAndroid: true,
      doOnIOS: true,
      enableMTA: false,
    );
    fluwx.responseFromAuth.listen(_handWXLogin);
  }

  FacebookLogin _facebookLogin = FacebookLogin();
  GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly']);

  void accountLogin(String username, String password) async {
    print(LoginPlatform.account_password.toString());
    var info = await WS.userService.login(username, password);

    final userInfo = UserInfo.fromMap({
      ...info.toJson(),
      ...info.credentialInfo.toJson(),
    });
    setLoginInfo(LoginState.sigin, LoginPlatform.account_password, userInfo);
  }

  void authLogin(LoginPlatform platform) async {
    print(platform.toString());

    user.UserInfo info;
    switch (platform) {
      case LoginPlatform.facebook:
        var code = await _signInWithFacebook();
        info = await WS.userService.authLogin(user.AuthPlatform.facebook, code);
        break;
      case LoginPlatform.google:
        var code = await _signInWithGoogle();
        info = await WS.userService.authLogin(user.AuthPlatform.google, code);
        break;
      case LoginPlatform.wechat:
        var result = await fluwx.isWeChatInstalled();
        if (!result) {
          return;
        }
        await fluwx.sendAuth(scope: "snsapi_userinfo");
        return;
      default:
        return;
    }

    final userInfo = UserInfo.fromMap({
      ...info.toJson(),
      ...info.credentialInfo.toJson(),
    });
    setLoginInfo(LoginState.sigin, platform, userInfo);
  }

  _handWXLogin(WeChatAuthResponse resp) async {
    if (resp.errCode != 0) return;
    try {
      var info =
      await WS.userService.authLogin(user.AuthPlatform.wechat, resp.code);
      final userInfo = UserInfo.fromMap({
        ...info.toJson(),
        ...info.credentialInfo.toJson(),
      });
      setLoginInfo(LoginState.sigin, LoginPlatform.wechat, userInfo);
    } on WoodemiException catch (e) {
      print('error = ${e.message}');
    }
  }

  /// TODO Update [StorageService.uid], [StorageService.accessToken]
  Future<void> refreshAccesstoken() async {
    final userInfo = await _getAccesstoken();
    if (userInfo != null && userInfo.loginToken != null) {
      setLoginInfo(LoginState.sigin, _loginInfo.platform, userInfo);
    } else {
      _setLoginInfoState(LoginState.sigout);
    }
  }

  void logOut() {
    print(loginInfo.state);
    if (loginInfo.state == LoginState.sigin) {
      switch (loginInfo.platform) {
        case LoginPlatform.facebook:
          _facebookLogin.logOut();
          break;
        case LoginPlatform.google:
          _googleSignIn.signOut();
          break;
        default:
          break;
      }
    }
    _setLoginInfoState(LoginState.sigout);
  }

  void removeAccount() async {
    if (loginInfo.state == LoginState.sigin) {
      try {
        await WS.userService.deleteAccount(
            loginInfo.userInfo.uid, loginInfo.userInfo.accessToken);
        // TODO 提示注销账号成功
      } catch (e) {
        // TODO
      }
    }
    _setLoginInfoState(LoginState.sigout);
  }

  Future<String> _signInWithFacebook() async {
    var result = await _facebookLogin.logInWithReadPermissions(['email']);
    if (result.status != FacebookLoginStatus.loggedIn) {
      if (result.status == FacebookLoginStatus.cancelledByUser) {
        print('Facebook: cancelledByUser');
      } else if (result.status == FacebookLoginStatus.error) {
        print('Facebook: ${result.errorMessage}');
      }
      return null;
    }
    return result.accessToken.token;
  }

  Future<String> _signInWithGoogle() async {
    GoogleSignInAuthentication authentication;
    try {
      var account = await _googleSignIn.signIn();
      authentication = await account.authentication;
    } catch (e) {
      if (e is PlatformException) {
        if (e.code == GoogleSignIn.kSignInCanceledError) {
          print('Google: cancelledByUser');
        } else if (e.code == GoogleSignIn.kSignInFailedError) {
          print('Google: ${e.message}');
        }
      }
      print('Google ${e.toString()}');
      return null;
    }
    return authentication.idToken;
  }

  Future<UserInfo> _getAccesstoken() async {
    final userInfo = (await sPreferencesManager.loginInfo).userInfo;
    if (userInfo == null ||
        userInfo.uid == null ||
        userInfo.loginToken == null ||
        userInfo.accessToken == null) return null;

    try {
      var credentialInfo = await WS.userService
          .refreshAccessToken(userInfo.uid, userInfo.loginToken);
      return UserInfo.fromMap({
        ...userInfo.toMap(),
        ...credentialInfo.toJson(),
      });
    } on WoodemiException catch (e) {
      if (e.statuscode == WoodemiStatus.accessInvalid) return null;
    }
  }
}
