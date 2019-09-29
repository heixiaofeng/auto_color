import 'dart:async';
import 'dart:core';

import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/model/account.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/pages/MeModule/AboutPage.dart';
import 'package:ugee_note/pages/MeModule/AppSetting.dart';
import 'package:ugee_note/pages/MeModule/DeviceSetting.dart';
import 'package:ugee_note/pages/MeModule/LoginAccountPage.dart';
import 'package:ugee_note/pages/MeModule/LoginWXPage.dart';
import 'package:ugee_note/pages/MeModule/UserInfoPage.dart';

import 'package:notepad_kit/notepad.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:ugee_note/pages/MeModule/rtm/pages/login/PhoneLoginPage.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/permission.dart';
import 'package:ugee_note/widget/NormalDialog.dart';
import 'package:ugee_note/widget/widgets.dart';

class MePage extends StatefulWidget {
  @override
  _MePageState createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription _noteSubscription;
  StreamSubscription<LoginInfo> _loginInfoSubscription;

  LoginInfo _loginInfo = sAccountManager.loginInfo;
  String _deviceConnect = "";
  String _totalNotes = '0';
  String _version = '';

  @override
  void initState() {
    super.initState();
    print('MePage initState');
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);

    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);

    _onNoteChange(null);
    _noteSubscription = sNoteProvider.changeStream.listen(_onNoteChange);

    _getVersion();

    _getIsOnReview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _refreshState(sNotepadManager.notepadState);
  }

  @override
  void dispose() {
    super.dispose();
    print('MePage dispose');
    _loginInfoSubscription.cancel();
    _notepadStateSubscription.cancel();
    _noteSubscription.cancel();
  }

  _onNoteChange(DBChangeType type) async {
    var papers = await sNoteProvider.queryAvalible();
    setState(() => _totalNotes = '${papers.length}');
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    _refreshState(event.state);
  }

  _refreshState(NotepadState state) {
    setState(() => _deviceConnect = (state == NotepadState.Connected)
        ? Translations.of(context).text('notify_notepad_connected')
        : "");
  }

  _onLoginInfoChange(LoginInfo loginInfo) {
    setState(() => _loginInfo = loginInfo);
  }

  _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() => _version = 'v${packageInfo.version}');
  }

  var _isOnReview = false;

  _getIsOnReview() async => _isOnReview = await sPreferencesManager.isOnReview;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(
        context,
        Translations.of(context).text('tab_text_4'),
        titleStyle: TextStyle(fontSize: 24, color: Colors.black87),
        implyLeading: true,
        centerTitle: false,
      ),
      body: Container(
        color: color_background,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(children: <Widget>[
      wrapRoundedCard(items: [meUserItem()]),
      Container(height: 20),
      wrapRoundedCard(items: [
        entryItem(
            "icons/me_device_setting.png",
            Translations.of(context).text('setting_item_notepad'),
            _deviceConnect, onTap: () {
          if (sNotepadManager.notepadState == NotepadState.Connected) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => DeviceSetting()));
          } else {
            pushNotepadScanpage(context);
          }
        }),
        line(),
        entryItem("icons/me_app_setting.png",
            Translations.of(context).text('setting_item_app'), '', onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AppSetting()));
        }),
        line(),
        entryItem(
            "icons/me_about.png",
            Translations.of(context).text('setting_item_about'),
            _version, onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AboutPage()));
        }),
        line(),
        entryItem("icons/me_about.png", 'RTM', '', onTap: () {
          Navigator.pushNamed(context, 'rtc_note_screen');
//          Navigator.push(context, MaterialPageRoute(builder: (context) => RTCNoteScreen()));
        }),
      ])
    ]);
  }

  Widget meUserItem() => GestureDetector(
        onTap: () async {
          var isSigin = sAccountManager.loginInfo.state == LoginState.sigin;

          //  弹框提示（账号变化会断开设备连接）
          if (!isSigin &&
              sNotepadManager.notepadState == NotepadState.Connected) {
            var str = Translations.of(context)
                .text('account_changed_affect_connection');
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => NormalDialog(message: str, duration: 0),
            );

            await Future.delayed(Duration(milliseconds: 1500), () {
              Navigator.pop(context);
            });
            await sNotepadManager.disconnect();
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => isSigin ? UserInfoPage() : LoginWXPage(),
            ),
          );
        },
        child: Container(
          height: 90,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              loginView(), //  已登录
              Container(
                alignment: Alignment.centerRight,
                child: Icon(Icons.keyboard_arrow_right),
              ),
            ],
          ),
        ),
      );

  Widget loginView() {
    var imageProvider = _loginInfo.state == LoginState.sigin
        ? ((_loginInfo.userInfo.avatar != null)
            ? NetworkImage(_loginInfo.userInfo.avatar)
            : ExactAssetImage("images/default_avatar.jpg"))
        : ExactAssetImage("icons/no_login.png");
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        top: 0,
        left: 10,
        bottom: 0,
        right: 10,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: <Widget>[
          Container(
            width: 56.0,
            height: 56.0,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: imageProvider,
                  radius: 28.0,
                ),
                AnimatedOpacity(
                  opacity: _loginInfo.state == LoginState.sigin ? 1 : 0,
                  duration: Duration(milliseconds: 0),
                  child: (_loginInfo.state == LoginState.sigin)
                      ? Image.asset(
                          (_loginInfo.userInfo.gender == 1)
                              ? "icons/gender_male.png"
                              : "icons/gender_female.png",
                          width: 10.0,
                          height: 10.0,
                        )
                      : null,
                ),
              ],
            ),
          ),
          Container(
            width: 17.0,
          ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  (_loginInfo.state == LoginState.sigin)
                      ? (_loginInfo.userInfo?.nickname ?? '')
                      : Translations.of(context).text('singout'),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 19.0,
                  ),
                ),
                Text(
                  Translations.of(context)
                      .text('paper_recorded_less', '${_totalNotes}'),
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
