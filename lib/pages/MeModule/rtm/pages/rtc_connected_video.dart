//import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'dart:async';
//
//import 'package:agora_rtc_engine/agora_rtc_engine.dart';
//
//import '../utils/bottom_alert_dialog.dart';
//import '../utils/wdm_alert_dialog.dart';
//import '../utils/wdm_widget.dart';
//import 'rtc_note_screen.dart';
//import '../utils/tools.dart';
//
//class NoteModel {
//  final bool showBroadcast;
//  final bool showAudience;
//
//  NoteModel({@required this.showBroadcast, @required this.showAudience});
//}
//
//class VideoSession {
//
//  int viewId;
//  final int uId;
//  final Widget view;
//
//  VideoSession(this.uId, this.view);
//}
//
//class RTCVideoConnected extends StatefulWidget {
//  final String channelName;
//
//  RTCVideoConnected({Key key, this.channelName = '2017'}) : super(key: key);
//
//  @override
//  _RTCVideoConnectedState createState() => new _RTCVideoConnectedState();
//}
//
//class _RTCVideoConnectedState extends State<RTCVideoConnected> {
//  var dataArray = [];
//
//  final BottomWidgetHeight = 55.0;
//
//  var listViewItemHeight = 0.0;
//  final ListViewBottomPadding = 3.0;
//
//  bool isMic = true;
//  bool isVolume = true;
//
//  bool isBroadcastBg = false;
//  bool isAudienceBg = false;
//
//  bool isBroadcast = true;
//
//  TextEditingController urlController = TextEditingController();
//  TextEditingController numberController = TextEditingController();
//
//  static final _sessions = List<VideoSession>();
//
//  @override
//  void initState() {
//    super.initState();
//
//    _initData();
//
//    Timer(Duration(milliseconds: 250), () {
//      SystemChrome.setEnabledSystemUIOverlays([]);
//    });
//
////    _handleCameraAndMic();
//
//    _initAgoraSDK();
//  }
//
//  @override
//  void dispose() {
//    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
//
//    _sessions
//        .forEach((session) => AgoraRtcEngine.removeNativeView(session.viewId));
//
//    _sessions.clear();
//
//    _leaveChannel();
//
//    super.dispose();
//  }
//
////  _handleCameraAndMic() async {
////    await PermissionHandler().requestPermissions(
////        [PermissionGroup.camera, PermissionGroup.microphone]);
////  }
//
//  _initAgoraSDK() {
//    assert(!APP_ID.isEmpty);
//
//    _initAgoraRtcEngine();
//    _addAgoraEventHandlers();
//    // use _addRenderView everytime a native video view is needed
//    _addRenderView(0, (viewId) {
//      AgoraRtcEngine.setupLocalVideo(viewId, VideoRenderMode.Hidden);
//      AgoraRtcEngine.startPreview();
//
//      var config = VideoEncoderConfiguration();
//      config.dimensions = Size(720, 960);
//      AgoraRtcEngine.setVideoEncoderConfiguration(config);
//
//      // state can access widget directly
//      AgoraRtcEngine.joinChannel(null, widget.channelName, null, 30);
//    });
//  }
//
//  /// Create agora sdk instance and initialze
//  Future<void> _initAgoraRtcEngine() async {
//    AgoraRtcEngine.create(APP_ID);
//    AgoraRtcEngine.enableVideo();
//  }
//
//  /// Add agora event handlers
//  void _addAgoraEventHandlers() {
//    AgoraRtcEngine.onError = (int code) {
//      print('onError $code');
//    };
//
//    AgoraRtcEngine.onJoinChannelSuccess =
//        (String channel, int uid, int elapsed) {
//      print('onJoinChannel: ' + channel + ', uid: ' + uid.toString());
//    };
//
//    AgoraRtcEngine.onLeaveChannel = () {
//      print('onLeaveChannel success');
//    };
//
//    AgoraRtcEngine.onUserJoined = (int uid, int elapsed) {
//      setState(() {
//        print('userJoined: ' + uid.toString());
//        _addRenderView(uid, (viewId) {
//          AgoraRtcEngine.setupRemoteVideo(viewId, VideoRenderMode.Hidden, uid);
//        });
//      });
//    };
//
//    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
//      setState(() {
//        print('userOffline: ' + uid.toString());
//        _removeRenderView(uid);
//      });
//    };
//
//    AgoraRtcEngine.onFirstLocalVideoFrame =
//        (int width, int height, int elapsed) {
//      print('*** >> onFirstLocalVideoFrame');
//    };
//
//    AgoraRtcEngine.onFirstRemoteVideoFrame =
//        (int uid, int width, int height, int elapsed) {
//      print('*** >> onFirstRemoteVideoFrame');
//    };
//  }
//
//  /// Create a native view and add a new video session object
//  /// The native viewId can be used to set up local/remote view
//  _addRenderView(int uid, Function(int viewId) finished) {
//    Widget view = AgoraRtcEngine.createNativeView(uid, (viewId) {
//      setState(() {
//        _getVideoSession(uid).viewId = viewId;
//        if (finished != null) {
//          finished(viewId);
//        }
//      });
//    });
//    VideoSession session = VideoSession(uid, view);
//    _sessions.add(session);
//  }
//
//  /// Remove a native view and remove an existing video session object
//  _removeRenderView(int uid) {
//    VideoSession session = _getVideoSession(uid);
//    if (session != null) {
//      _sessions.remove(session);
//    }
//    AgoraRtcEngine.removeNativeView(session.viewId);
//  }
//
//  /// Helper function to filter video session with uid
//  VideoSession _getVideoSession(int uId) {
//    return _sessions.firstWhere((session) {
//      return session.uId == uId;
//    });
//  }
//
//  /// Helper function to get list of native views
//  List<Widget> _getRenderViews() {
//    return _sessions.map((session) => session.view).toList();
//  }
//
//  _initData() {
//    dataArray.add(NoteModel(showBroadcast: true, showAudience: true));
//    dataArray.add(NoteModel(showBroadcast: false, showAudience: true));
//    dataArray.add(NoteModel(showBroadcast: true, showAudience: false));
//  }
//
//  /// 根据自己的身份决定下两个方法的操作对象
//  _mute(bool isMute) {
//    print('*** >>> isMute ${isMute}');
//    AgoraRtcEngine.muteAllRemoteAudioStreams(!isMute);
//  }
//
//  _mic(bool isMic) {
//  print('*** >>> isMic ${isMic}');
//    AgoraRtcEngine.muteLocalAudioStream(!isMic);
//  }
//
//  _switchCamera() {
//    AgoraRtcEngine.switchCamera();
//  }
//
//  _leaveChannel() {
//    AgoraRtcEngine.leaveChannel();
//  }
//
//  _addNote() {
//    /// TODO: 发消息给原生，新建一页笔记
//    setState(() {
//      dataArray.add(NoteModel(showBroadcast: false, showAudience: true));
//    });
//  }
//
//  _leaveRoom(BuildContext context) {
//    showDialog(
//        context: context,
//        barrierDismissible: true,
//        builder: (BuildContext context) {
//          return WDMAlertDialog(
//              title: '退出房间',
//              message: '若您退出房间，房间将被立即解散',
//              isBgClose: true,
//              confim: () {
//                _leaveChannel();
//                Navigator.pushAndRemoveUntil(
//                    context,
//                    MaterialPageRoute(
//                        builder: (BuildContext ctx) => RTCNoteScreen()),
//                    (route) => route == null);
//              });
//        });
//  }
//
//  _roomBtnClick() {
//    showDialog(
//        context: context,
//        barrierDismissible: true,
//        builder: (BuildContext context) =>
//            BottomAlertDialog(widget: _initiativeLeaveRoomWidget()));
//  }
//
//  _selPenColorClick() {
//    print('>>> 选择颜色');
//    _leaveChannel();
//  }
//
//  _selPenWidthClick() {
//    print('>>> 选择宽度');
//  }
//
////  _toolBtnClick() {
////    showDialog(
////        context: context,
////        barrierDismissible: true,
////        builder: (BuildContext context) =>
////            BottomAlertDialog(widget: _toolWidget()));
////  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: Container(
//        color: Color(AppColors.BackgroundColor),
//        child: Column(
//          children: <Widget>[
//            _topWidget(),
//            _centerWidget(),
//            _bottomWidget(),
//          ],
//        ),
//      ),
//    );
//  }
//
//  Widget _topWidget() {
//    final renderViews = _getRenderViews();
//    return Container(
//      height: ScreenWidth / 2,
//      color: Colors.grey,
//      child: Row(
//        children: <Widget>[
//          Expanded(
//              child: Container(
//            color: Colors.lightBlueAccent,
//            child: Stack(
//              children: <Widget>[
//                if (renderViews.length > 0) renderViews.first,
//                GestureDetector(
//                    onTap: () {
//                      setState(() {
//                        isBroadcastBg = !isBroadcastBg;
//                      });
//                    },
//                    child: AnimatedOpacity(
//                      opacity: isBroadcastBg ? 1 : 0,
//                      duration: Duration(milliseconds: 150),
//                      child: Container(
//                        width: double.infinity,
//                        height: double.infinity,
//                        color: Color(AppColors.AlphaColor),
//                        child: Column(
//                          mainAxisAlignment: MainAxisAlignment.center,
//                          children: <Widget>[
//                            Container(
//                              width: 60,
//                              height: 60,
//                              child: CircleAvatar(
//                                /// 网络图片用 NetworkImage
//                                backgroundImage:
//                                    AssetImage('assets/images/monkey.png'),
//                              ),
//                              decoration: BoxDecoration(
//                                  border: Border.all(
//                                      color: Colors.transparent, width: 0),
//                                  borderRadius:
//                                      BorderRadius.all(Radius.circular(30))),
//                            ),
//                            WDMText(
//                                text: 'locke',
//                                fontSize: 18,
//                                isBold: false,
//                                top: 12,
//                                bottom: 8,
//                                color: Colors.white),
//                            isBroadcast
//                                ? Row(
//                                    mainAxisAlignment: MainAxisAlignment.center,
//                                    children: <Widget>[
//                                      IconButton(
//                                        icon: Icon(
//  isMic
//                                                ? Icons.mic
//                                                : Icons.mic_off,
//                                            color: Colors.white,
//                                            size: 33),
//                                        onPressed: () {
//                                          setState(() {
//                                            this.isMic =
//                                                !this.isMic;
//                                            this._mic(isMic);
//                                          });
//                                        },
//                                      ),
//                                      IconButton(
//                                        icon: Icon(
//                                            isVolume
//                                                ? Icons.volume_up
//                                                : Icons.volume_off,
//                                            color: Colors.white,
//                                            size: 33),
//                                        onPressed: () {
//                                          setState(() {
//                                            this.isVolume =
//                                                !this.isVolume;
//                                            this._mute(isVolume);
//                                          });
//                                        },
//                                      ),
//                                    ],
//                                  )
//                                : Container(),
//                          ],
//                        ),
//                      ),
//                    ))
//              ],
//            ),
//          )),
//          Expanded(
//              child: Container(
//            color: Colors.lightGreenAccent,
//            child: Stack(
//              children: <Widget>[
//                if (renderViews.length > 1) renderViews.last,
//                GestureDetector(
//                    onTap: () {
//                      setState(() {
//                        isAudienceBg = !isAudienceBg;
//                      });
//                    },
//                    child: AnimatedOpacity(
//                      opacity: isAudienceBg ? 1 : 0,
//                      duration: Duration(milliseconds: 150),
//                      child: Container(
//                        width: double.infinity,
//                        height: double.infinity,
//                        color: Color(AppColors.AlphaColor),
//                        child: Column(
//                          mainAxisAlignment: MainAxisAlignment.center,
//                          children: <Widget>[
//                            Container(
//                              width: 60,
//                              height: 60,
//                              child: CircleAvatar(
//                                /// 网络图片用 NetworkImage
//                                backgroundImage:
//                                    AssetImage('assets/images/holla.png'),
//                              ),
//                              decoration: BoxDecoration(
//                                  border: Border.all(
//                                      color: Colors.transparent, width: 0),
//                                  borderRadius:
//                                      BorderRadius.all(Radius.circular(30))),
//                            ),
//                            WDMText(
//                                text: '洛曜生',
//                                fontSize: 18,
//                                isBold: false,
//                                top: 12,
//                                bottom: 8,
//                                color: Colors.white),
//                            isBroadcast
//                                ? Container()
//                                : Row(
//                                    mainAxisAlignment: MainAxisAlignment.center,
//                                    children: <Widget>[
//                                      IconButton(
//                                        icon: Icon(
//                                            isMic
//                                                ? Icons.mic
//                                                : Icons.mic_off,
//                                            color: Colors.white,
//                                            size: 33),
//                                        onPressed: () {
//                                          setState(() {
//                                            this.isMic =
//                                                !this.isMic;
//                                            this._mic(isMic);
//                                          });
//                                        },
//                                      ),
//                                      IconButton(
//                                        icon: Icon(
//  isVolume
//                                                ? Icons.volume_up
//                                                : Icons.volume_off,
//                                            color: Colors.white,
//                                            size: 33),
//                                        onPressed: () {
//                                          setState(() {
//                                            this.isVolume =
//                                                !this.isVolume;
//                                            this._mute(isVolume);
//                                          });
//                                        },
//                                      ),
//                                    ],
//                                  )
//                          ],
//                        ),
//                      ),
//                    ))
//              ],
//            ),
//          )),
//        ],
//      ),
//    );
//  }
//
//  Widget _centerWidget() {
//    final addBtnHeight = 55.0;
//    final contentHeight =
//        ScreenHeight - BottomWidgetHeight - ScreenWidth / 2 - 10;
//    final rightViewWidth = ScreenWidth - contentHeight * 0.75;
//
//    listViewItemHeight = rightViewWidth * 1.333;
//
//    /// listview 也保持3:4
//
//    final lvRealHeight = dataArray.length * listViewItemHeight;
//    final lvMaxHeight = contentHeight - 3 - addBtnHeight;
//
//    print(
//        '** >>> 屏幕宽：${ScreenWidth}，屏幕高：${ScreenHeight}，右边宽：${rightViewWidth}');
//    print(
//        '** >>> 中部高：${contentHeight}，4比3左边：${contentHeight * 0.75}，右边宽：${ScreenWidth - contentHeight * 0.75}');
//
//    final listViewHeight =
//        lvRealHeight >= lvMaxHeight ? lvMaxHeight : lvRealHeight;
//    return Expanded(
//        child: Container(
//      color: Colors.lightBlue,
//      margin: EdgeInsets.only(left: ScreenWidth - rightViewWidth, bottom: 10),
//      child: Column(
//        children: <Widget>[
//          Container(
//            margin: EdgeInsets.only(bottom: 3),
//            height: listViewHeight,
//            child: _noteListView(),
//          ),
//          Container(
//            margin: EdgeInsets.only(left: 3),
//            height: addBtnHeight,
//            width: rightViewWidth,
//            color: Colors.white,
//            child: IconButton(
//              icon: Image.asset(
//                'assets/images/add_note.png',
//                width: 20,
//              ),
//              onPressed: _addNote,
//            ),
//          )
//        ],
//      ),
//    ));
//  }
//
//  Widget _bottomWidget() {
//    return Container(
//        height: BottomWidgetHeight,
//        child: Column(
//          children: <Widget>[
//            Divider(
//              color: Color(AppColors.DividerColor),
//              height: Constants.DividerWidth,
//            ),
//            Expanded(
//              child: Row(
//                mainAxisAlignment: MainAxisAlignment.center,
//                crossAxisAlignment: CrossAxisAlignment.center,
//                children: <Widget>[
//                  Expanded(
//                      child: GestureDetector(
//                          onTap: _selPenColorClick,
//                          child: Container(
//                            color: Colors.transparent,
//                            padding: EdgeInsets.only(right: 20),
//                            child: Column(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              crossAxisAlignment: CrossAxisAlignment.end,
//                              children: <Widget>[
//                                Container(
//                                  width: 23,
//                                  height: 23,
//                                  margin: EdgeInsets.only(right: 8, top: 3),
//                                  decoration: BoxDecoration(
//                                      color: Color(AppColors.TitleTextColor),
//                                      borderRadius: BorderRadius.all(
//                                          Radius.circular(15))),
//                                ),
//                                WDMText(text: '画笔颜色', top: 5, fontSize: 11)
//                              ],
//                            ),
//                          ))),
//                  Expanded(
//                      child: GestureDetector(
//                          onTap: _selPenWidthClick,
//                          child: Container(
//                            color: Colors.transparent,
//                            child: Column(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              crossAxisAlignment: CrossAxisAlignment.center,
//                              children: <Widget>[
//                                Container(
//                                  width: 23,
//                                  height: 23,
//                                  margin: EdgeInsets.only(top: 3),
//                                  child: Image.asset(
//                                      'assets/images/sel_pen_width.png'),
//                                ),
//                                WDMText(text: '画笔粗细', top: 5, fontSize: 11)
//                              ],
//                            ),
//                          ))),
//                  Expanded(
//                      child: GestureDetector(
//                          onTap: _roomBtnClick,
//                          child: Container(
//                            color: Colors.transparent,
//                            padding: EdgeInsets.only(left: 20),
//                            child: Column(
//                              mainAxisAlignment: MainAxisAlignment.center,
//                              crossAxisAlignment: CrossAxisAlignment.start,
//                              children: <Widget>[
//                                Container(
//                                  width: 23,
//                                  height: 23,
//                                  margin: EdgeInsets.only(left: 6, top: 3),
//                                  child: Image.asset(
//                                      'assets/images/room_info.png'),
//                                ),
//                                WDMText(text: '画笔粗细', top: 5, fontSize: 11)
//                              ],
//                            ),
//                          ))),
//                ],
//              ),
//            )
//          ],
//        ));
//  }
//
//  ListView _noteListView() {
//    return ListView.builder(
//      itemCount: dataArray.length,
//      itemBuilder: (ctx, index) => _createItem(ctx, dataArray[index]),
//    );
//  }
//
//  Widget _createItem(BuildContext ctx, NoteModel model) {
//    return GestureDetector(
//      onTap: () {
//        print('>>> model');
//      },
//      child: Column(
//        children: <Widget>[
//          Container(
//            height: listViewItemHeight - ListViewBottomPadding,
//            margin: EdgeInsets.only(left: 3, right: 2),
//            color: Colors.white,
//            child: Stack(
//              children: <Widget>[
//                /// TODO: 不会放笔记缩略图吧？
//                Positioned(
//                    right: 6,
//                    bottom: 5,
//                    child: Container(
//                      width: 20,
//                      height: 20,
//                      child: CircleAvatar(
//                        // 网络图片用 NetworkImage
//                        backgroundImage: AssetImage('assets/images/monkey.png'),
//                      ),
//                    )),
//                Positioned(
//                    right: 6,
//                    bottom: 28,
//                    child: Container(
//                      width: 20,
//                      height: 20,
//                      child: CircleAvatar(
//                        // 网络图片用 NetworkImage
//                        backgroundImage: AssetImage('assets/images/holla.png'),
//                      ),
//                    )),
//              ],
//            ),
//          ),
//          Container(
//            height: ListViewBottomPadding,
//            color: Color(AppColors.BackgroundColor),
//          ),
//        ],
//      ),
//    );
//  }
//
//  Widget _initiativeLeaveRoomWidget() {
//    return Container(
//      margin: EdgeInsets.only(top: 40, left: 50, right: 50, bottom: 40),
//      child: Column(
//        mainAxisAlignment: MainAxisAlignment.center,
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: <Widget>[
//          WDMText(text: '房间号', fontSize: 15, left: 5, bottom: 8),
//          Container(
//            margin: EdgeInsets.only(bottom: 30),
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: <Widget>[
//                WDMTextField(
//                    text: '908989898909',
//                    controller: numberController,
//                    margin: EdgeInsets.only(right: 8)),
//                WDMButton(
//                    text: '复制',
//                    width: 55,
//                    height: 24,
//                    fontSize: 13,
//                    onPressed: () {
//                      _roomNumberCopy();
//                    }),
//              ],
//            ),
//          ),
//          WDMText(text: '房间地址', fontSize: 15, left: 5, bottom: 8),
//          Container(
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: <Widget>[
//                WDMTextField(
//                    text: 'www.36notes.com/room',
//                    controller: urlController,
//                    margin: EdgeInsets.only(right: 8)),
//                WDMButton(
//                    text: '复制',
//                    width: 55,
//                    height: 24,
//                    fontSize: 13,
//                    onPressed: () {
//                      _urlNumberCopy();
//                    }),
//              ],
//            ),
//          ),
//          Center(
//              child: WDMButton(
//                  text: '退出房间',
//                  width: 130,
//                  margin: EdgeInsets.only(top: 45),
//                  onPressed: () {
//                    _leaveRoom(context);
//                  }))
//        ],
//      ),
//    );
//  }
//
//  // TODO: 收到对方退出房间消息时弹出
//  Widget _passivenessLeaveRoomWidget() {
//    return Center(
//      child: Column(
//        mainAxisAlignment: MainAxisAlignment.center,
//        children: <Widget>[
//          WDMText(text: '房间已解散', isBold: true, fontSize: 19),
//          WDMButton(
//              text: '退出房间',
//              width: 130,
//              margin: EdgeInsets.only(top: 35),
//              onPressed: () {
//                Navigator.pushAndRemoveUntil(
//                    context,
//                    MaterialPageRoute(
//                        builder: (BuildContext ctx) => RTCNoteScreen()),
//                    (route) => route == null);
//                ;
//              })
//        ],
//      ),
//    );
//  }
//
//  Widget _toolWidget() {
//    return Center(
//        child: Row(
//      mainAxisAlignment: MainAxisAlignment.center,
//      children: <Widget>[
//        Expanded(
//            child: GestureDetector(
//          onTap: () {
//            print('>>> 画笔颜色');
//          },
//          child: Container(
//            margin: EdgeInsets.only(top: 30, bottom: 30),
//            padding: EdgeInsets.only(left: 55),
//            color: Colors.white,
//            child: Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: <Widget>[
//                Container(
//                    width: 38, child: Image.asset('assets/images/monkey.png')),
//                WDMText(text: '画笔颜色', fontSize: 16, top: 16),
//              ],
//            ),
//          ),
//        )),
//        Expanded(
//            child: GestureDetector(
//          onTap: () {
//            print('>>> 画笔粗细');
//          },
//          child: Container(
//            margin: EdgeInsets.only(top: 30, bottom: 30),
//            padding: EdgeInsets.only(right: 55),
//            color: Colors.white,
//            child: Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              children: <Widget>[
//                Container(
//                    width: 38, child: Image.asset('assets/images/holla.png')),
//                WDMText(text: '画笔粗细', fontSize: 16, top: 16),
//              ],
//            ),
//          ),
//        ))
//      ],
//    ));
//  }
//
//  _roomNumberCopy() {
//    Clipboard.setData(ClipboardData(text: numberController.text));
//  }
//
//  _urlNumberCopy() {
//    Clipboard.setData(ClipboardData(text: urlController.text));
//  }
//}
