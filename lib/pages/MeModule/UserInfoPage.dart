import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/manager/DeviceManager.dart';
import 'package:ugee_note/model/account.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import '../../widget/WDMAlertDialog.dart';

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  @override
  StreamSubscription<LoginInfo> _loginInfoSubscription;

  void initState() {
    super.initState();
    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);
  }

  @override
  void dispose() {
    super.dispose();
    _loginInfoSubscription.cancel();
  }

  _onLoginInfoChange(LoginInfo loginInfo) {
    if (loginInfo.state != LoginState.sigin) {
      Future.delayed(
          Duration(milliseconds: 2000), () => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(
          context, Translations.of(context).text('personal_information')),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 30),
          child: wrapRoundedCard(items: [_info()]),
        ),
        Expanded(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                FlatButton(
                  padding: EdgeInsets.fromLTRB(20, 10.0, 20.0, 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  textColor: Colors.white,
                  disabledTextColor: Colors.red,
                  color: ThemeColor,
                  disabledColor: ThemeBackgroundColor,
                  child: Text(Translations.of(context).text('account_logout')),
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return WDMAlertDialog(
                          title:
                              Translations.of(context).text('account_logout'),
                          message: Translations.of(context)
                              .text('account_changed_affect_connection'),
                          cancelText:
                              Translations.of(context).text('do_not_quit'),
                          confimText:
                              Translations.of(context).text('want_to_quit'),
                          type: Operation.NOTICE,
                          confim: (value) async {
                            //  断开
                            if (sNotepadManager.notepadState ==
                                NotepadState.Connected) {
                              await sNotepadManager.disconnect();
                            }
                            sAccountManager.logOut();
                          },
                        );
                      },
                    );
                  },
                ),
                Container(
                  margin: EdgeInsets.only(top: 15, bottom: 30),
                  child: FlatButton(
                    child: Text(Translations.of(context).text('logout')),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return WDMAlertDialog(
                            title: Translations.of(context).text('logout'),
                            message: Translations.of(context)
                                .text('will_delete_all_information_account'),
                            cancelText: Translations.of(context).text('Cancel'),
                            confimText: Translations.of(context).text('OK'),
                            type: Operation.NOTICE,
                            confim: (value) async {
                              //  解绑、断开
                              if (sNotepadManager.notepadState ==
                                  NotepadState.Connected) {
                                await sDeviceManager.disconnectUnbindDevice();
                              }
                              sAccountManager.removeAccount();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _info() {
    var showid = sAccountManager.loginInfo.userInfo?.showid ?? 0;
    var imageProvider = sAccountManager.loginInfo.state == LoginState.sigin
        ? ((sAccountManager.loginInfo.userInfo.avatar != null)
            ? NetworkImage(sAccountManager.loginInfo.userInfo.avatar)
            : ExactAssetImage("images/default_avatar.jpg"))
        : ExactAssetImage("images/share_wechat.png");
    final w = ScreenWidth * 0.80;
    final h = ScreenWidth * 0.80;
    return Container(
      width: w,
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(bottom: 15),
            child:
                CircleAvatar(backgroundImage: imageProvider, radius: w * 0.1),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 15),
            child: Text(
              'ID：$showid',
              style: TextStyle(color: Color(0xff6D6D6D), fontSize: 14),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 20),
            height: 1.0,
            width: w * 0.85,
            color: color_line,
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: _item(),
          ),
        ],
      ),
    );
  }

  Widget _item() {
    var nickname = sAccountManager.loginInfo.userInfo?.nickname ?? 'okokok';
    var gender = Translations.of(context).text(
        (sAccountManager.loginInfo.userInfo?.gender ?? 0) == 1
            ? 'personal_sex_male'
            : 'personal_sex_female');
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              _icon('icons/user_info.png'),
              line(height: 10),
              _icon('icons/gender.png'),
            ],
          ),
          Container(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _name(Translations.of(context).text('personal_name')),
              line(height: 10),
              _name(Translations.of(context).text('personal_sex')),
            ],
          ),
          Container(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _content(nickname),
              line(height: 10),
              _content(gender),
            ],
          ),
        ],
      ),
    );
  }

  Text _content(String nickname) {
    return Text(nickname,
        style: TextStyle(
            fontSize: 16,
            color: Color(0xff313638),
            fontWeight: FontWeight.w600));
  }

  Text _name(String name) =>
      Text(name, style: TextStyle(fontSize: 12, color: Color(0xff3B3B3B)));

  Image _icon(String icon) => Image.asset(
        icon,
        width: 15.0,
        height: 15.0,
      );
}
