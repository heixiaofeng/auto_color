import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/pages/MeModule/rtm/pages/rtc_note_screen.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/rtc_status.dart';
import 'package:ugee_note/util/StatusStore.dart';
import 'dart:async';

import '../widget/wdm_widget.dart';
import '../utils/api_request.dart';
import '../utils/tools.dart';
import 'rtc_waiting_connect.dart';
import '../model/room_model.dart';

class RTCNoteInfo extends StatefulWidget {
  final isBroadcast;

  RoomModel roomModel;

  RTCNoteInfo({Key key, this.isBroadcast = true, this.roomModel})
      : super(key: key);

  @override
  _RTCNoteInfoState createState() => new _RTCNoteInfoState();
}

class _RTCNoteInfoState extends State<RTCNoteInfo> {
  String _roomNumber = '';

  String _roomURL = '';

  Timer _timer;

  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    remoteShowId = ''; // reset remoteShowId

    LiveStatus.value = LiveStatus.unknow;

    OnlineStatus.value = OnlineStatus.android;

    SmartChannel.setMethodCallHandler(_handler);

    if (widget.isBroadcast) {
      _createRoom();
    } else {
      _addHeartBeat();

      SmartChannel.invokeMethod(RTCMethodName.rtm_channel, [
        widget.roomModel.roomId,
        widget.roomModel.showId,
        widget.roomModel.channel,
        widget.roomModel.sysChannel,
        sAccountManager.loginInfo.userInfo.accessToken
      ]);
      setState(() {
        _roomNumber = widget.roomModel.roomId;
        _roomURL = widget.roomModel.webUrl;
      });
    }

    sStatusStore.screenKeepOn(isOn: true);
  }

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
    sStatusStore.screenKeepOn(isOn: false);
  }

  Future<dynamic> _handler(MethodCall methodCall) {
    print('*** >>> fank flutter 0');
    switch (methodCall.method) {
      case RTCMethodName.sys_msg:

        var dict = json.decode(methodCall.arguments);
        print('*** >>> fank flutter 1: $dict');
        print('*** >>> fank flutter 2: $dict, subtype: ${dict['subtype'].runtimeType}, value: ${dict['subtype']}');

        if (widget.roomModel.roomId.toString() != dict['roomid'].toString()) return null;

        final liveStatus = LiveStatus.value == LiveStatus.unknow;

        if (liveStatus && dict['type'] == SysChannelMsg.room && dict['subtype'] == SysChannelMsg.room_kick) {}
        else if (liveStatus) return null;

        final isCurrent = dict['uid'] == sAccountManager.loginInfo.userInfo.uid;

        switch (dict['type']) {
          case SysChannelMsg.room:
            switch (dict['subtype']) {
              case SysChannelMsg.room_join:
                if (!isCurrent) sStatusStore.updateRTMUserInfo(RTMUserInfo.fromMap(dict['userInfo']));
                break;
              case SysChannelMsg.room_leave:
                break;
              case SysChannelMsg.room_kick:
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (BuildContext ctx) => RTCNoteScreen()),
                        (route) => route == null);
                break;
            }
            break;
          case SysChannelMsg.status:
            switch (dict['roomStatus']) {
              case SysChannelMsg.status_notready: // 未准备
                break;
              case SysChannelMsg.status_already: // 已准备
                if (!isCurrent) sStatusStore.updateRTMUserInfo(RTMUserInfo.fromMap(dict['userInfo']));
                break;
              case SysChannelMsg.status_starting: // 开播中
                break;
            }

            switch (dict['onlineStatus']) {
              case OnlineStatus.web:
                OnlineStatus.value = OnlineStatus.web;
                break;
              case OnlineStatus.iOS:
                OnlineStatus.value = OnlineStatus.iOS;
                break;
              case OnlineStatus.android:
                OnlineStatus.value = OnlineStatus.android;
                break;
            }
            break;
        }
        break;
       case RTCMethodName.remote_show_id:
         remoteShowId = methodCall.arguments as String;
         break;
    }
  }

  _addHeartBeat() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _heartRequest();
    });
  }

  _heartRequest() async {
    print('*** >>> hearbeat: ${'在线：${LiveStatus.value}, 设备：${DeviceStatus.value}, roomModel：${widget.roomModel}, roomId：${widget.roomModel == null ? _roomNumber : widget.roomModel.roomId}'}');
    APIRequest.request(
        '/rooms/${widget.roomModel == null ? _roomNumber : widget.roomModel.roomId}/heartbeat',
        method: APIRequest.PUT,
        data: {
          'liveStatus': LiveStatus.value,
          'deviceStatus': DeviceStatus.value
        }).then((data) {
      if (data == null) return;
      SmartChannel.invokeMethod(RTCMethodName.hud_info,
          '在线：${LiveStatus.value}, 设备：${DeviceStatus.value}, roomModel：${widget.roomModel}, roomId：${widget.roomModel == null ? _roomNumber : widget.roomModel.roomId}');
    });
  }

  _createRoom() async {
    APIRequest.request('/rooms/apply', method: APIRequest.POST,
        faildCallback: (errorMsg) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
    }).then((data) {

      if (data == null) return;

      var rtm = data['rtm'];

      print('*** widget.isBroadcast 1 ${widget.isBroadcast}');

      widget.roomModel = RoomModel(
          roomId: data['roomid'].toString(),
          channel: rtm['channel'],
          sysChannel: rtm['sysChannel'],
          webUrl: data['webUrl'],
          showId: sAccountManager.loginInfo.userInfo.showid.toString(),
          isBroadcast: widget.isBroadcast,
          hasMember: false);

      setState(() {
        _roomNumber = data['roomid'].toString();
        _roomURL = data['webUrl'];
      });

      _addHeartBeat();

      SmartChannel.invokeMethod(RTCMethodName.rtm_channel, [
        widget.roomModel.roomId,
        widget.roomModel.showId,
        widget.roomModel.channel,
        widget.roomModel.sysChannel,
        sAccountManager.loginInfo.userInfo.accessToken
      ]);
    });
  }

  _leaveRoom(BuildContext context) async {
    if (widget.roomModel == null) Navigator.pop(context);

    APIRequest.request('/rooms/${widget.roomModel.roomId}/join',
        method: APIRequest.DELETE, faildCallback: (errorMsg) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
    }).then((data) {
      SmartChannel.invokeMethod(RTCMethodName.leave_rtm_channel);
      OnlineStatus.value = OnlineStatus.android;
      LiveStatus.value = LiveStatus.unknow;
    });

    Navigator.pop(context);
  }

  _roomNumberCopy() {
    Clipboard.setData(ClipboardData(text: _roomNumber));
  }

  _urlNumberCopy() {
    Clipboard.setData(ClipboardData(text: _textEditingController.text));
  }

  _joinBtnClick(BuildContext context) async {

    if (OnlineStatus.value == 0) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, '已在PC端开播');
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext ctx) =>
                  RTCWaitingConnect(isBroadcast: widget.isBroadcast,
                      channelId: _roomNumber)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WDMAppBar(context, '房间信息', void_callback, true),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(AppColors.BackgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 100,
              height: 100,
              margin: EdgeInsets.only(top: 30, bottom: 30),
              child: CircleAvatar(
                radius: 45,
                backgroundImage: sAccountManager.loginInfo.userInfo.avatar !=
                        null
                    ? NetworkImage(sAccountManager.loginInfo.userInfo.avatar)
                    : ExactAssetImage("images/default_avatar.jpg"),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                WDMText(text: '您的房间号是：', fontSize: 16, isBold: true),
                WDMText(
                    text: _roomNumber,
                    isBold: true,
                    color: AppColors.ThemeColor,
                    fontSize: 17),
                WDMButton(
                    text: '复制',
                    margin: EdgeInsets.only(left: 8),
                    width: 58,
                    height: 24,
                    fontSize: 12,
                    onPressed: () {
                      _roomNumberCopy();
                    }),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  WDMTextField(
                      text: _roomURL,
                      controller: _textEditingController,
                      margin: EdgeInsets.only(right: 8)),
                  WDMButton(
                      text: '复制',
                      width: 58,
                      height: 24,
                      fontSize: 12,
                      onPressed: () {
                        _urlNumberCopy();
                      }),
                ],
              ),
            ),
            WDMText(text: '您的投屏链接已生成', fontSize: 16, top: 25),
            WDMText(text: '复制上方链接在电脑端打开即可进行体验', fontSize: 16, top: 2),
            WDMButton(
                text: '退出投屏房间',
                width: 135,
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.29),
                onPressed: () {
                  _leaveRoom(context);
                }),
            WDMButton(
                text: '使用手机端访问',
                width: 150,
                margin: EdgeInsets.only(top: 5),
                textColor: Colors.black,
                backgroundColor: Color(AppColors.BackgroundColor),
                fontSize: 15,
                onPressed: () {
                  _joinBtnClick(context);
                }),
          ],
        ),
      ),
    );
  }
}
