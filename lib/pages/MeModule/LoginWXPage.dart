import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/model/account.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

class LoginItem {
  LoginPlatform platform;
  String name;
  String icon;

  LoginItem._(LoginPlatform platform, String name, String icon)
      : this.platform = platform,
        this.name = name,
        this.icon = icon;
}

class LoginWXPage extends StatefulWidget {
  @override
  _LoginWXPageState createState() => _LoginWXPageState();
}

class _LoginWXPageState extends State<LoginWXPage> {
  StreamSubscription<LoginInfo> _loginInfoSubscription;
  LoginPlatform _currentPlatform = sAccountManager.loginInfo.platform;

  var isAgree = true;

  @override
  void initState() {
    super.initState();
    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);
  }

  @override
  void dispose() {
    super.dispose();
    print("LoginPage dispose");
    _loginInfoSubscription.cancel();
  }

  _onLoginInfoChange(LoginInfo loginInfo) {
    setState(() => _currentPlatform = loginInfo.platform);
    if (loginInfo.state == LoginState.sigin) {
      Future.delayed(
          Duration(milliseconds: 2000), () => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(context, ''),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          topContent(),
          bottomContent(),
        ],
      ),
    );
  }

  Container topContent() {
    var imageProvider = (sAccountManager.loginInfo.userInfo != null &&
            sAccountManager.loginInfo.userInfo.avatar != null)
        ? NetworkImage(sAccountManager.loginInfo.userInfo.avatar)
        : ExactAssetImage("images/default_avatar.jpg");
    return Container(
      alignment: Alignment.center,
      height: ScreenHeight * 0.5,
      child: Column(
        children: <Widget>[
          CircleAvatar(
            backgroundImage: imageProvider,
            radius: 40.0,
          ),
          Container(height: 10),
          Text(
              sAccountManager.loginInfo.state == LoginState.sigin
                  ? '${Translations.of(context).text('welcom_back')}, ${sAccountManager.loginInfo.userInfo?.nickname}'
                  : Translations.of(context).text('welcom_to_smartnote'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff0E74BB), fontSize: 15))
        ],
      ),
    );
  }

  Widget bottomContent() {
    var item =
        LoginItem._(LoginPlatform.wechat, '验证登录', 'icons/icon_wechat.png');
    return Column(
      children: <Widget>[
        Container(
          width: ScreenWidth * 0.65,
          height: 40,
          child: RaisedButton(
            padding: EdgeInsets.fromLTRB(0, 10.0, 0, 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            color: ThemeColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(item.icon, width: 25, height: 25),
                Container(width: 10),
                Text(item.name, style: TextStyle(color: Colors.white)),
              ],
            ),
            onPressed: () async {
              if (sNotepadManager.notepadState == NotepadState.Connected)
                await sNotepadManager.disconnect();
              await sAccountManager.authLogin(item.platform);
            },
          ),
        ),
        Container(height: 20),
        Container(
          alignment: Alignment.center,
          height: 30,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                isAgree ? 'icons/selected.png' : 'icons/no_selected.png',
                width: 10,
                height: 10,
              ),
              Container(width: 5),
              GestureDetector(
                child: Text(
                  '我已阅读并同意',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                onTap: () {
                  setState(() => isAgree = !isAgree);
                },
              ),
              GestureDetector(
                child: Text(
                  '《36记用户使用协议》',
                  style: TextStyle(color: ThemeColor, fontSize: 12),
                ),
                onTap: () {
                  //  TODO 进入用户使用协议
                  print('TODO 进入用户使用协议');
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}
