import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

class LoginAccountPage extends StatefulWidget {
  @override
  _LoginAccountPageState createState() => _LoginAccountPageState();
}

class _LoginAccountPageState extends State<LoginAccountPage> {
  StreamSubscription<LoginInfo> _loginInfoSubscription;

  final accountController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);
  }

  @override
  void dispose() {
    super.dispose();
    print("LoginAccountPage dispose");
    _loginInfoSubscription.cancel();
  }

  _onLoginInfoChange(LoginInfo loginInfo) {
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
        centerContent(),
        bottomCentent(),
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

  Container centerContent() {
    return Container(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Account:',
                  style: TextStyle(fontSize: 18),
                ),
                line(height: 20),
                Text(
                  'Password:',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            Container(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                normalTextfield(accountController, 'input account'),
                line(height: 20),
                normalTextfield(passwordController, 'input password'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Container normalTextfield(TextEditingController controller, String hintText) {
    return Container(
      width: ScreenWidth * 0.5,
      height: 33,
      padding: EdgeInsets.only(left: 10, right: 10),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: (value) {},
        onSubmitted: (value) {},
        decoration: InputDecoration(
          contentPadding: EdgeInsets.only(top: 0.0),
          hintText: hintText,
          border: InputBorder.none,
        ),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFD8D8D8), width: 1),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.5),
      ),
    );
  }

  Widget bottomCentent() {
    return Container(
      alignment: Alignment.center,
      width: ScreenWidth / 2.0,
      child: RaisedButton(
        padding: EdgeInsets.fromLTRB(20, 10.0, 20.0, 10.0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        disabledTextColor: Colors.red,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text('Login', style: TextStyle(color: ThemeColor)),
          ],
        ),
        onPressed: () {
          if (accountController.text.length > 0 &&
              passwordController.text.length > 0) {
            sAccountManager.accountLogin(
              accountController.text,
              passwordController.text,
            );
          }
        },
      ),
    );
  }
}
