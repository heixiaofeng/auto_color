import 'dart:convert';

enum LoginState {
  sigout,
  loading,
  sigin,
}

enum LoginPlatform {
  google,
  facebook,
  account_password,
  phone,
  wechat,
}

class CredentialInfo {
  String accessToken;
  int accessTokenTTL; // seconds
  String loginToken;
  int loginTokenTTL; // seconds

  CredentialInfo({
    String accessToken,
    int accessTokenTTL,
    String loginToken,
    int loginTokenTTL,
  })  : this.accessToken = accessToken,
        this.accessTokenTTL = accessTokenTTL,
        this.loginToken = loginToken,
        this.loginTokenTTL = loginTokenTTL;

  CredentialInfo.fromMap(Map json) {
    accessToken = json['accessToken'];
    accessTokenTTL = json['accessTokenTTL'];
    loginToken = json['loginToken'];
    loginTokenTTL = json['loginTokenTTL'];
  }

  Map toMap() {
    var json = Map<String, dynamic>();
    json['accessToken'] = accessToken;
    json['accessTokenTTL'] = accessTokenTTL;
    json['loginToken'] = loginToken;
    return json;
  }
}

class UserInfo extends CredentialInfo {
  int uid;
  int showid;
  String nickname;
  String avatar;
  int gender;

  UserInfo(int uid, int showid, String nickname, String avatar, int gender)
      : this.uid = uid,
        this.showid = showid,
        this.nickname = nickname,
        this.avatar = avatar,
        this.gender = gender,
        super();

  UserInfo.fromMap(Map json) : super.fromMap(json) {
    uid = json['uid'];
    showid = json['showid'];
    nickname = json['nickname'];
    avatar = json['avatar'];
    gender = json['gender'];
  }

  Map toMap() {
    var json = Map<String, dynamic>();
    json['uid'] = uid;
    json['showid'] = showid;
    json['nickname'] = nickname;
    json['avatar'] = avatar;
    json['gender'] = gender;
    return json..addAll(super.toMap());
  }

  factory UserInfo.fromJson(String json) => UserInfo.fromMap(jsonDecode(json));

  String toJson() => jsonEncode(toMap());
}

class LoginInfo {
  LoginState state;
  LoginPlatform platform;
  UserInfo userInfo;

  static final sinout = LoginInfo(LoginState.sigout);

  LoginInfo(LoginState state, {LoginPlatform platform, UserInfo userInfo})
      : this.state = state,
        this.platform = platform,
        this.userInfo = userInfo;
}
