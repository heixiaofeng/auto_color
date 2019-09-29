import 'package:flutter/material.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/rtc_status.dart';
import 'package:ugee_note/util/StatusStore.dart';
import 'dart:async';

import '../widget/wdm_widget.dart';
import '../utils/api_request.dart';
import '../utils/tools.dart';

import '../model/room_model.dart';
import '../model/user_info_model.dart';
import 'rtc_note_screen.dart';
import 'rtc_connected.dart';

class RTCWaitingConnect extends StatefulWidget {
  final String channelId;
  final bool isBroadcast;

  RTCWaitingConnect({Key key, @required this.isBroadcast, @required this.channelId}) : super(key: key);

  @override
  _RTCWaitingConnectState createState() => new _RTCWaitingConnectState();
}

class _RTCWaitingConnectState extends State<RTCWaitingConnect> {
  Timer _waitingTimer;

  UserInfoModel _userInfoModel;

  int _remoteLiveStatus = 0;

  bool _preConnectTag = false;

  bool _isRequestTag = false;

  String _waitingText = '等待用户加入...';
  String _timerText = '30:00';

  String _broadcastText = '';
  String _audienceText = '';

  String _broadcastImg = '';
  String _audienceImg = '';

  @override
  void initState() {
    super.initState();

    _updateRoomStatus();

    _updateLiveStatus();

//    SmartChannel.setMethodCallHandler(_handler);

    sStatusStore.addListener(_statusStoreListener);
  }

  @override
  void dispose() {
    super.dispose();

    if (_waitingTimer != null) {
      _waitingTimer.cancel();
    }

    sStatusStore.removeListener(_statusStoreListener);
  }

  _updateLiveStatus({int value = 1}) => LiveStatus.value = value;

  _statusStoreListener() {

    if (!_preConnectTag && _isRequestTag) _preConnect();

    setState(() {
      print('*** >>> _statusStoreListener 1: ${widget.isBroadcast}, ${sStatusStore.userInfo.nickname}');
      this._remoteLiveStatus = 1;
      if (widget.isBroadcast) {
        _audienceText = sStatusStore.userInfo.nickname;
        _audienceImg = sStatusStore.userInfo.avatar;
      } else {
        _broadcastText = sStatusStore.userInfo.nickname;
        _broadcastImg = sStatusStore.userInfo.avatar;
      }
    });
  }

//  Future<dynamic> _handler(MethodCall methodCall) {
//    switch (methodCall.method) {
//      case RTCMethodName.rtc_leave:
//        return Navigator.pushAndRemoveUntil(
//            context,
//            MaterialPageRoute(builder: (BuildContext ctx) => RTCNoteScreen()),
//            (route) => route == null);
//    }
//  }

  _updateRoomStatus({isJoin = true}) async {

    APIRequest.request('/rooms/${widget.channelId}/show',
        method: APIRequest.PUT,
        data: {'liveStatus': isJoin ? 1 : 0}, faildCallback: (errorMsg) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
    }).then((data) {

      if (data == null) return;

      if (!isJoin) return;

      this._isRequestTag = true;

      _userInfoModel = UserInfoModel.modelFromMap(data);

      if (widget.isBroadcast) {
        if (_userInfoModel.studentLiveStatus == '1') {
          _preConnect();
          setState(() {
            this._remoteLiveStatus = 1;
          });
        } else {
          _addTimer();
        }
      } else {
        if (_userInfoModel.anchorLiveStatus == '1') {
          _preConnect();
          setState(() {
            this._remoteLiveStatus = 1;
          });
        } else {
          _addTimer();
        }
      }

      setState(() {
        if (_userInfoModel.anchorLiveStatus == '1') {
          _broadcastImg = _userInfoModel.anchorAvatar;
          _broadcastText = _userInfoModel.anchorNickName;
        }

        if (_userInfoModel.studentLiveStatus == '1') {
          _audienceImg = _userInfoModel.studentAvatar;
          _audienceText = _userInfoModel.studentNickName;
        }
      });
    });
  }

  _addTimer() {
    _waitingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      var result = _timerText.split(':');

      if (result.last == '00' || result.last == '0') {
        result.first = (int.parse(result.first) - 1).toString();
        result.last = '59';
      } else {
        var secString = '';
        var sec = int.parse(result.last) - 1;
        secString = sec < 10 ? '0$sec' : '$sec';
        result.last = secString;
      }

      if (result.first == '0' && result.last == '00') {
        timer.cancel();
        Navigator.pop(context);
      }

      setState(() {
        _timerText = result.join(':');
      });
    });
  }

  _preConnect() {
    this._preConnectTag = true;

    if (_waitingTimer != null) {
      _waitingTimer.cancel();
    }
    setState(() {
      _waitingText = '匹配成功，即将进入房间';
      _timerText = '5';
//      _audienceText = '';
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (timer.tick == 5) {
        timer.cancel();

//        SmartChannel.invokeMethod(RTCMethodName.rtc_connected, [
//          widget.roomModel.roomId,
//          widget.roomModel.showId,
//          widget.roomModel.webUrl,
//          widget.roomModel.isBroadcast ? '1' : '0'
//        ]);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext ctx) => RTCConnected(
                    isBroadcast: widget.isBroadcast,
                    channelId: widget.channelId)));
      }

      setState(() {
        _timerText = (5 - timer.tick).toString();
      });
    });
  }

  _cancelMatch() {
    _updateRoomStatus(isJoin: false);

    _updateLiveStatus(value: -1);

    Navigator.pop(context);
//    Navigator.push(context, MaterialPageRoute(builder: (BuildContext ctx) => RTCConnected()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(AppColors.BackgroundColor),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                WDMText(text: '房间号：', fontSize: 18, isBold: true),
                WDMText(
                    text: widget.channelId,
                    isBold: true,
                    color: AppColors.ThemeColor,
                    fontSize: 18),
              ],
            ),
            Container(
              width: 100,
              height: 100,
              margin: EdgeInsets.only(top: 38),
              child: CircleAvatar(
                backgroundImage: _broadcastImg == ''
                    ? AssetImage('images/placeholder_img.png')
                    : NetworkImage(_broadcastImg),
              ),
            ),
            WDMText(text: _broadcastText, fontSize: 16, isBold: true, top: 10),
            WDMText(
                text: _waitingText,
                isBold: true,
                color: AppColors.ThemeColor,
                fontSize: 18,
                top: 35),
            WDMText(
                text: _timerText,
                isBold: true,
                color: AppColors.ThemeColor,
                fontSize: 18,
                top: 10),
            Container(
              width: 100,
              height: 100,
              margin: EdgeInsets.only(top: 38),
              child: CircleAvatar(
                // 网络图片用 NetworkImage
                backgroundImage: _audienceImg == ''
                    ? AssetImage('images/placeholder_img.png')
                    : NetworkImage(_audienceImg),
              ),
            ),
            WDMText(text: _audienceText, fontSize: 16, isBold: true, top: 10),
            AnimatedOpacity(
                opacity: this._remoteLiveStatus == 0 ? 1 : 0,
                duration: Duration(milliseconds: 150),
                child: WDMButton(
                    text: '取消匹配',
                    width: 130,
                    margin: EdgeInsets.only(top: 45),
                    onPressed: () {
                      _cancelMatch();
                    })),
          ],
        ),
      ),
    );
  }
}
