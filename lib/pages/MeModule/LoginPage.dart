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

final loginItems = [
  LoginItem._(
      LoginPlatform.facebook, 'Facebook login', 'icons/icon_facebook.png'),
  LoginItem._(LoginPlatform.google, 'Google login', 'icons/icon_google.png'),
];

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamSubscription<LoginInfo> _loginInfoSubscription;
  LoginPlatform _currentPlatform = sAccountManager.loginInfo.platform;

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
    setState(() {
      _currentPlatform = loginInfo.platform;
    });
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
      body: Row(
        children: <Widget>[
          Expanded(
            child: _body(),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        topContent(),
        bottomLoginItems(),
      ],
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

  Widget bottomLoginItems() {
    return Container(
      alignment: Alignment.center,
      width: _currentPlatform != null ? ScreenWidth / 2.0 : ScreenWidth,
      child: _currentPlatform != null
          ? _loginItemsSelected()
          : _loginItemsUnselected(),
    );
  }

  Widget _loginItemsSelected() {
    return Column(
      children: <Widget>[
        _loginItemSelected(
            loginItems[_currentPlatform == LoginPlatform.facebook ? 0 : 1]),
        Container(height: 20),
        _loginItemUnSelected(
            loginItems[_currentPlatform == LoginPlatform.facebook ? 1 : 0]),
      ],
    );
  }

  Widget _loginItemsUnselected() {
    return Column(
      children: <Widget>[
        Container(width: ScreenWidth * 0.66, height: 2, color: color_divider),
        Container(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (var item in loginItems) _loginItemNormal(item),
          ],
        ),
      ],
    );
  }

  Widget _loginItemNormal(LoginItem item) {
    return FlatButton(
      child: Column(
        children: <Widget>[
          Image.asset(item.icon, width: 25, height: 25),
          Container(
            height: 5,
          ),
          Text(item.name),
        ],
      ),
      onPressed: () {
        setState(() {
          _currentPlatform = item.platform;
        });
      },
    );
  }

  Widget _loginItemSelected(LoginItem item) {
    return RaisedButton(
      padding: EdgeInsets.fromLTRB(20, 10.0, 20.0, 10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      disabledTextColor: Colors.red,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Image.asset(item.icon, width: 25, height: 25),
          Container(width: 10),
          Text(item.name, style: TextStyle(color: ThemeColor)),
        ],
      ),
      onPressed: () async {
        if (sNotepadManager.notepadState == NotepadState.Connected)
          await sNotepadManager.disconnect();

        await sAccountManager.authLogin(item.platform);
      },
    );
  }

  Widget _loginItemUnSelected(LoginItem item) {
    return FlatButton(
      child: Text(item.name),
      onPressed: () {
        setState(() {
          _currentPlatform = item.platform;
        });
      },
    );
  }
}
