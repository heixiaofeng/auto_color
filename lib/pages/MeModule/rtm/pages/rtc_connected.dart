import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:orientation/orientation.dart';
import 'package:stylus_paint/LineStrokePainter.dart';
import 'package:stylus_paint/LayerView.dart';
import 'package:stylus_paint/StylusPointer.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/rtc_status.dart';
import 'package:ugee_note/util/StatusStore.dart';

import '../widget/wdm_alert_dialog.dart';
import '../widget/wdm_widget.dart';
import '../utils/api_request.dart';
import '../utils/tools.dart';

class VideoSession {
  int viewId;
  final int uId;
  final Widget view;

  VideoSession(this.uId, this.view);
}

class RTCConnected extends StatefulWidget {
  final String channelId;
  final bool isBroadcast;

  RTCConnected({Key key, @required this.isBroadcast, @required this.channelId})
      : super(key: key);

  @override
  _RTCConnectedState createState() => new _RTCConnectedState();
}

class _RTCConnectedState extends State<RTCConnected> {
  List<String> dataArray = [
    '0xFFED5564',
    '0xFFAC92ED',
    '0xFF4B89DE',
    '0xFF4EBFE8',
    '0xFFA1D367',
    '0xFFFB6F53',
    '0xFFFFCA28',
    '0xFF48CFAD',
    '0xFF8C6450',
    '0xFF313638'
  ];

  double initial = 0;

  double percentage = 20;

  double _MuteSize = 23;

  bool _isMic = true;
  bool _isVolume = true;

  bool _isSelWidth = false;
  bool _isSelColor = false;

  bool _isBroadcastBg = true;
  bool _isAudienceBg = true;

  int _selectedColorIndex = 0;

  String _broadcastText = '';
  String _broadcastImg = '';

  String _audienceText = '';
  String _audienceImg = '';

  String _broadcastDelayText = '0ms';
  String _audienceDelayText = '0ms';

  Color _broadcastDelayColor = Colors.lightGreenAccent;
  Color _audienceDelayColor = Colors.lightGreenAccent;

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      SmartChannel.invokeMethod(RTCMethodName.allowRotation, true);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    }

    Timer(Duration(milliseconds: 250), () {
      SystemChrome.setEnabledSystemUIOverlays([]);
    });

    _setupLocalNameAvatar();

    _joinRoomAndStart();

    _updateRemoteUserInfo();

    addLimitTimer();

//    SmartChannel.invokeMethod(RTCMethodName.join_rtc_channel, widget.channelId);
    LiveStatus.value = LiveStatus.starting;

    SmartChannel.setMethodCallHandler(_handler);

    SmartEventChannel.receiveBroadcastStream().listen((item) {
      print('*** >>> receive item: $item');
    });
  }

  @override
  void dispose() {
    super.dispose();

    _timer.cancel();
  }

  _updateRemoteUserInfo() {
    print('*** >>> sStatusStore.userInfo: ${sStatusStore.userInfo}');
    if (sStatusStore.userInfo == null) return;
    setState(() {
      if (widget.isBroadcast) {
        _audienceText = sStatusStore.userInfo.nickname;
        _audienceImg = sStatusStore.userInfo.avatar;
      } else {
        _broadcastText = sStatusStore.userInfo.nickname;
        _broadcastImg = sStatusStore.userInfo.avatar;
      }
    });
  }

  Future<bool> _onWillPop() {
    _exitRtcConfiguration();
    Navigator.pop(context);
    return Future.value(false);
  }

  _setupLocalNameAvatar() async {
    final userInfo = sAccountManager.loginInfo.userInfo;
    setState(() {
      if (widget.isBroadcast) {
        _broadcastText = userInfo.nickname;
        _broadcastImg = userInfo.avatar;
      } else {
        _audienceText = userInfo.nickname;
        _audienceImg = userInfo.avatar;
      }
    });
  }

  Future<dynamic> _handler(MethodCall methodCall) {
    switch (methodCall.method) {
      case RTCMethodName.leave_rtc_channel:
        return _leaveRoomAlert(isAccord: false);
      case RTCMethodName.rtc_local_delay:
        var delay = methodCall.arguments as int;
        setState(() {
          if (widget.isBroadcast) {
            _broadcastDelayText = delay.toString() + 'ms';
            _broadcastDelayColor = _renderColorWithDelay(delay);
          } else {
            _audienceDelayText = delay.toString() + 'ms';
            _audienceDelayColor = _renderColorWithDelay(delay);
          }
        });
        break;
      case RTCMethodName.rtc_remote_delay:
        var delay = methodCall.arguments as int;
        setState(() {
          if (widget.isBroadcast) {
            _audienceDelayText = delay.toString() + 'ms';
            _audienceDelayColor = _renderColorWithDelay(delay);
          } else {
            _broadcastDelayText = delay.toString() + 'ms';
            _broadcastDelayColor = _renderColorWithDelay(delay);
          }
        });
        break;
    }
  }

  _joinRoomAndStart() async {
    APIRequest.request('/rooms/${widget.channelId}/members',
        method: APIRequest.POST, faildCallback: (errorMsg) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
    }).then((data) {
      APIRequest.request('/rooms/${widget.channelId}/show',
          method: APIRequest.POST, faildCallback: (errorMsg) {
        SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
      });
    });
  }

  _leaveRoomAndStop() async {
    APIRequest.request('/rooms/${widget.channelId}/show',
        method: APIRequest.DELETE, faildCallback: (errorMsg) {
      SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
    }).then((data) {
      APIRequest.request('/rooms/${widget.channelId}/members',
          method: APIRequest.DELETE, faildCallback: (errorMsg) {
        SmartChannel.invokeMethod(RTCMethodName.hud_info, errorMsg);
      });
    });
  }

  Color _renderColorWithDelay(int delay) {
    return delay <= 55
        ? Colors.lightGreenAccent
        : (delay >= 180 ? Colors.redAccent : Colors.orangeAccent);
  }

  _exitRtcConfiguration() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
    if (Platform.isIOS) {
      SmartChannel.invokeMethod(RTCMethodName.allowRotation, false);
    } else {
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    }
  }

  _mute(bool isMute) {
//    AgoraRtcEngine.muteAllRemoteAudioStreams(!isMute);
//    SmartChannel.invokeMethod(RTCMethodName.rtc_mute, !isMute);
  }

  _mic(bool isMic) {
//    AgoraRtcEngine.muteLocalAudioStream(!isMic);
//    SmartChannel.invokeMethod(RTCMethodName.rtc_mic, !isMic);
  }

  _leaveRoomAlert({isAccord = true}) {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return WDMAlertDialog(
              title: isAccord ? '退出房间' : '房间已解散',
              message: isAccord ? '若您退出房间，房间将被立即解散' : '确认退出房间',
              isLandscape: true,
              confim: () {
                _leaveRoomAndStop();
                _exitRtcConfiguration();
                Navigator.popUntil(
                    context, ModalRoute.withName('rtc_note_screen'));
              });
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          body: SafeArea(
              child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Row(
              children: <Widget>[
                _renderToolBarWidget(),
                _renderContentWidget(),
                _renderInfoWidget(),
              ],
            ),
          )),
        ),
        onWillPop: _onWillPop);
  }

  Widget _renderInfoWidget() {
    return Expanded(
        child: Container(
      child: Column(
        children: <Widget>[
          Expanded(
              child: Container(
            color: Color(0xFF353535),
            child: Stack(
              children: <Widget>[
                GestureDetector(
//                    onTap: () {
//                      setState(() {
//                        _isBroadcastBg = !_isBroadcastBg;
//                      });
//                    },
                    child: AnimatedOpacity(
                  opacity: _isBroadcastBg ? 1 : 0,
                  duration: Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Color(AppColors.AlphaColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 55,
                          height: 55,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(_broadcastImg),
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.transparent, width: 0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                        ),
                        WDMText(
                            text: _broadcastText,
                            fontSize: 16,
                            isBold: false,
                            top: 12,
                            bottom: 0.5,
                            color: Colors.white),
//                        Row(
//                          mainAxisAlignment: MainAxisAlignment.center,
//                          children: <Widget>[
//                            Container(
//                                width: 8,
//                                height: 8,
//                                decoration: BoxDecoration(
//                                    color: _broadcastDelayColor,
//                                    borderRadius:
//                                        BorderRadius.all(Radius.circular(5)))),
//                            WDMText(
//                                text: _broadcastDelayText,
//                                fontSize: 10,
//                                left: 4,
//                                bottom: 1.8,
//                                color: Colors.white),
//                          ],
//                        ),
//                        widget.isBroadcast
//                            ? Row(
//                                mainAxisAlignment: MainAxisAlignment.center,
//                                children: <Widget>[
//                                  Container(
//                                    width: ScreenWidth / 7,
//                                    child: IconButton(
//                                      alignment: Alignment.centerRight,
//                                      icon: Icon(
//                                          _isMic ? Icons.mic : Icons.mic_off,
//                                          color: Colors.white,
//                                          size: _MuteSize),
//                                      onPressed: () {
//                                        setState(() {
//                                          this._isMic = !this._isMic;
//                                          this._mic(_isMic);
//                                        });
//                                      },
//                                    ),
//                                  ),
//                                  Container(
//                                    width: ScreenWidth / 7,
//                                    child: IconButton(
//                                      alignment: Alignment.centerLeft,
//                                      icon: Icon(
//                                          _isVolume
//                                              ? Icons.volume_up
//                                              : Icons.volume_off,
//                                          color: Colors.white,
//                                          size: _MuteSize),
//                                      onPressed: () {
//                                        setState(() {
//                                          this._isVolume = !this._isVolume;
//                                          this._mute(_isVolume);
//                                        });
//                                      },
//                                    ),
//                                  ),
//                                ],
//                              )
//                            : Container(),
                      ],
                    ),
                  ),
                ))
              ],
            ),
          )),
          Container(
            height: 2,
            color: Colors.white70,
          ),
          Expanded(
              child: Container(
            color: Color(0xFF353535),
            child: Stack(
              children: <Widget>[
                GestureDetector(
//                    onTap: () {
//                      setState(() {
//                        _isAudienceBg = !_isAudienceBg;
//                      });
//                    },
                    child: AnimatedOpacity(
                  opacity: _isAudienceBg ? 1 : 0,
                  duration: Duration(milliseconds: 150),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Color(AppColors.AlphaColor),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 55,
                          height: 55,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(_audienceImg),
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.transparent, width: 0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30))),
                        ),
                        WDMText(
                            text: _audienceText,
                            fontSize: 16,
                            isBold: false,
                            top: 12,
                            bottom: 0.5,
                            color: Colors.white),
//                        Row(
//                          mainAxisAlignment: MainAxisAlignment.center,
//                          children: <Widget>[
//                            Container(
//                                width: 8,
//                                height: 8,
//                                decoration: BoxDecoration(
//                                    color: _audienceDelayColor,
//                                    borderRadius:
//                                        BorderRadius.all(Radius.circular(5)))),
//                            WDMText(
//                                text: _audienceDelayText,
//                                fontSize: 10,
//                                left: 4,
//                                bottom: 1.8,
//                                color: Colors.white),
//                          ],
//                        ),
//                        widget.isBroadcast
//                            ? Container()
//                            : Row(
//                                mainAxisAlignment: MainAxisAlignment.center,
//                                children: <Widget>[
//                                  Container(
//                                    width: ScreenWidth / 7,
//                                    child: IconButton(
//                                      alignment: Alignment.centerRight,
//                                      icon: Icon(
//                                          _isMic ? Icons.mic : Icons.mic_off,
//                                          color: Colors.white,
//                                          size: _MuteSize),
//                                      onPressed: () {
//                                        setState(() {
//                                          this._isMic = !this._isMic;
//                                          this._mic(_isMic);
//                                        });
//                                      },
//                                    ),
//                                  ),
//                                  Container(
//                                    width: ScreenWidth / 7,
//                                    child: IconButton(
//                                      alignment: Alignment.centerLeft,
//                                      icon: Icon(
//                                          _isVolume
//                                              ? Icons.volume_up
//                                              : Icons.volume_off,
//                                          color: Colors.white,
//                                          size: _MuteSize),
//                                      onPressed: () {
//                                        setState(() {
//                                          this._isVolume = !this._isVolume;
//                                          this._mute(_isVolume);
//                                        });
//                                      },
//                                    ),
//                                  ),
//                                ],
//                              )
                      ],
                    ),
                  ),
                ))
              ],
            ),
          )),
        ],
      ),
    ));
  }

  Widget _createItem(BuildContext ctx, int index) {
    return GestureDetector(
        onTap: () {
          SmartChannel.invokeMethod(
              RTCMethodName.modify_pen_color, dataArray[index]);
          setState(() {
            this._selectedColorIndex = index;
          });
        },
        child: Container(
            height: 47,
            padding: EdgeInsets.all(5),
            margin: EdgeInsets.only(top: 5, left: 4, right: 4, bottom: 5),
            child: Container(
                decoration: BoxDecoration(
              color: Color(int.parse(dataArray[index])),
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.all(Radius.circular(21)),
            )),
            decoration: BoxDecoration(
                image: _selectedColorIndex == index
                    ? DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage('images/color_sel_bg.png'))
                    : null)));
  }

  ListView _renderColorListView() {
    return ListView.builder(
        itemCount: this.dataArray.length,
        itemBuilder: (ctx, index) => _createItem(ctx, index));
  }

  Widget _renderSelectPenWidth() {
    return Container(
      padding: EdgeInsets.only(top: 55, bottom: 55),
      alignment: Alignment.centerLeft,
      child: FlutterSlider(
        axis: Axis.vertical,
        handlerHeight: 25,
        handlerWidth: 25,
        rtl: true,
        values: [20],
        max: 100,
        min: 0,
        trackBar: FlutterSliderTrackBar(
          activeTrackBarHeight: 8,
          inactiveTrackBarHeight: 11,
          inactiveTrackBar: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black12,
            border: Border.all(width: 2, color: Colors.white),
          ),
          activeTrackBar: BoxDecoration(
              borderRadius: BorderRadius.circular(4), color: Colors.white),
        ),
        handler: FlutterSliderHandler(
            child: Icon(
              Icons.drag_handle,
              color: Colors.white,
              size: 15,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 3),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            )),
        onDragging: (handlerIndex, lowerValue, upperValue) {
          SmartChannel.invokeMethod(
              RTCMethodName.modify_pen_width, lowerValue.toString());
        },
      ),
    );
  }

  final Stream<StylusPointer> syncPointerStream =
  SmartEventChannel.receiveBroadcastStream().expand((item) sync* {

    String points = json.decode(item)[describeEnum(RTMMsgType.points)];
    for (var i = 0; i < points.length / 12; i++) {
      String point = points.substring(i * 12, (i + 1) * 12);
      print("*** point: $point");
      var list = List<int>();
      for (var j = 0; j < point.length / 4; j++) {
        String result = point.substring(j * 4, (j + 1) * 4);
        list.add(int.parse(result, radix: 16));
        print("*** result: $result, hex: ${int.parse(result, radix: 16)}");
      }
      final ps = {'x':list.first,'y':list[1],'t':-1,'p':list.last,};

      print("*** result: ps $ps, StylusPointer: ${StylusPointer.fromMap(ps)}");
      yield StylusPointer.fromMap(ps);
    }
  });

  Widget _renderContentWidget() {
    var pixels = Size(14800, 21000);
    var mediaQueryData = MediaQuery.of(context);
    var parentSize = mediaQueryData.size;
    var screenPixelRatio = mediaQueryData.devicePixelRatio;
    var paintScale = min(parentSize.width * screenPixelRatio / pixels.width,
        parentSize.height * screenPixelRatio / pixels.height);
    double scaleRatio = paintScale / screenPixelRatio;
    Size paintSize =
        Size(pixels.width * scaleRatio, pixels.height * scaleRatio);

    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.height * 4 / 3,
          decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('images/rtc_note_bg.png'))),
          child: Stack(children: <Widget>[
            scaleRatio == null
                ? null
                : LayerView(LineStrokePainter(scaleRatio), paintSize,
                sNotepadManager.syncPointerStream.map((p) {
                  final pointer = StylusPointer.fromMap(p.toMap());
                  didReceivePointer(pointer);
                  return pointer;
                })),
            scaleRatio == null
                ? null
                : LayerView(LineStrokePainter(scaleRatio), paintSize, syncPointerStream)
          ],),
        ),
        AnimatedOpacity(
            curve: Curves.easeInToLinear,
            opacity: _isSelWidth ? 1 : _isSelColor ? 1 : 0,
            duration: Duration(milliseconds: 150),
            child: Container(
                width: 55,
                height: double.infinity,
                color: Color(0xbb000000),
                child: _isSelWidth
                    ? _renderSelectPenWidth()
                    : _isSelColor ? _renderColorListView() : null)),
      ],
    );
  }

  Widget _renderToolBarWidget() {
    return Container(
      width: 48,
      color: Color(0xFF353535),
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 32),
            child: IconButton(
              icon: Image.asset(_isSelWidth
                  ? 'images/pen_width_sel.png'
                  : 'images/pen_width_def.png'),
              onPressed: () {
                setState(() {
                  if (_isSelColor) _isSelColor = false;
                  this._isSelWidth = !this._isSelWidth;
                });
              },
            ),
          ),
          GestureDetector(
            child: Container(
                width: 34,
                height: 34,
                padding: EdgeInsets.all(4),
                margin: EdgeInsets.only(top: 15),
                child: Container(
                    decoration: BoxDecoration(
                  color: Color(int.parse(dataArray[_selectedColorIndex])),
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                )),
                decoration: BoxDecoration(
                    image: _isSelColor
                        ? DecorationImage(
                            fit: BoxFit.cover,
                            image: AssetImage('images/tool_sel_bg.png'))
                        : null)),
            onTap: () {
              setState(() {
                if (_isSelWidth) _isSelWidth = false;
                this._isSelColor = !this._isSelColor;
              });
            },
          ),
          Container(
            margin: EdgeInsets.only(top: 15),
            child: IconButton(
              icon: Image.asset('images/clear_note.png', width: 22, height: 22),
              onPressed: () {
                showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return WDMAlertDialog(
                          title: '清空笔记内容',
                          message: '笔记清除后不可恢复',
                          isLandscape: true,
                          confim: () {});
                    });
              },
            ),
          ),
          Expanded(
              child: Container(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height / 8),
            child: IconButton(
              icon: Image.asset('images/exit_rtc.png', width: 22, height: 22),
              onPressed: () {
                _leaveRoomAlert();
              },
            ),
          ))
        ],
      ),
    );
  }

  Timer _timer;

  var limitTimes = 0;

  final LimitCount = 9;

  addLimitTimer() => _timer = Timer.periodic(
        Duration(milliseconds: 10),
        (timer) {
          this.limitTimes += 1;
        },
      );

  var pointsList = List<String>();

  didReceivePointer(StylusPointer pointer) {
    final hex =
        convertHEX(pointer.x) + convertHEX(pointer.y) + convertHEX(pointer.p);
    pointsList.add(hex);

    // 点到9个，且点的时间乘以10毫秒后抛点
    if (this.limitTimes >= LimitCount || this.pointsList.length >= LimitCount) {
      final collaborator = remoteShowId == ''
          ? sAccountManager.loginInfo.userInfo.showid
          : remoteShowId;

      final msg = '{"type":"${describeEnum(RTMMsgType.points)}", "collaborator":"$collaborator", "${describeEnum(RTMMsgType.points)}":"${pointsList.join()}", "${describeEnum(RTMMsgType.paper)}":"0"}';
      SmartChannel.invokeMethod(RTCMethodName.send_rtm_message, msg);

      this.pointsList.clear();
      this.limitTimes = 0;
    }
  }
}

enum RTMMsgType { points, color, width, create, paper }

String convertHEX(int value) {
  var hex = value.toRadixString(16);
  switch (hex.length) {
    case 1:
      hex = '000$hex';
      break;
    case 2:
      hex = '00$hex';
      break;
    case 3:
      hex = '0$hex';
      break;
  }
  return hex;
}

//import 'package:agora_rtc_engine/agora_rtc_engine.dart';

//_initAgoraSDK() {
//  assert(!APP_ID.isEmpty);
//
//  _initAgoraRtcEngine();
//
//  _addAgoraEventHandlers();
//
//  Timer(Duration(milliseconds: 1000), () {
//    if (Platform.isIOS) AgoraRtcEngine.setDefaultAudioRouteToSpeaker(true);
//    _joinChannel(widget.channelName);
//  });
//}
//
//Future<void> _initAgoraRtcEngine() async {
//  await AgoraRtcEngine.create(APP_ID);
//}
//
//_addAgoraEventHandlers() {
//  AgoraRtcEngine.onError = (int code) {
//    print('onError $code');
//  };
//
//  AgoraRtcEngine.onJoinChannelSuccess = (String channel, int uid, int elapsed) {
//    print('*** onJoinChannel: ' + channel + ', uid: ' + uid.toString());
//  };
//
//  AgoraRtcEngine.onLeaveChannel = () {
//    print('*** onLeaveChannel success');
//  };
//
//  AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
//    print('*** onUserJoined: ' + uid.toString());
//  };
//
//  AgoraRtcEngine.onUserOffline = (int uid, int reason) {
//    print('*** onUserOffline: ' + uid.toString());
//  };
//
//  AgoraRtcEngine.onRemoteAudioTransportStats =
//      (int uid, int delay, int lost, int rxKBitRate) {
//    print(
//        '*** onRemoteAudioTransportStats: uid: ${uid}, delay: ${delay}, lost: ${lost}, rxKBitRate: ${rxKBitRate}');
//
//    setState(() {
//      _broadcastDelayText = delay.toString() + 'ms';
//      _broadcastDelayColor = _renderColorWithDelay(delay);
//    });
//  };
//}
