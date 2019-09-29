import 'package:flutter/material.dart';
import 'package:ugee_note/manager/AccountManager.dart';

import '../widget/wdm_widget.dart';
import '../utils/api_request.dart';
import '../utils/tools.dart';

import 'rtc_note_info.dart';
import '../model/room_model.dart';

class RTCNoteJoin extends StatefulWidget {
  @override
  _RTCNoteJoinState createState() => new _RTCNoteJoinState();
}

class _RTCNoteJoinState extends State<RTCNoteJoin> {
  BuildContext _context;

  String _errorString = '';

  FocusNode _focusNode = FocusNode();

  TextEditingController _textEditingController = TextEditingController();

  _joinBtnClick(String value) async {
    if (_textEditingController.text.isNotEmpty) {
      APIRequest.request('/rooms/$value/join', method: APIRequest.POST,
          faildCallback: (errorMsg) {
        setState(() {
          this._errorString = errorMsg;
        });
      }).then(
        (data) {
          if (data == null) return;

          setState(() {
            this._errorString = '';
          });

          var rtm = data['rtm'];

          RoomModel roomModel = RoomModel(
              roomId: data['roomid'].toString(),
              channel: rtm['channel'],
              sysChannel: rtm['sysChannel'],
              webUrl: data['webUrl'],
              showId: sAccountManager.loginInfo.userInfo.showid.toString(),
              isBroadcast: false,
              hasMember: false);

          Navigator.push(
            _context,
            MaterialPageRoute(
              builder: (BuildContext ctx) =>
                  RTCNoteInfo(isBroadcast: false, roomModel: roomModel),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
//    FocusScope.of(context).requestFocus(_focusNode);
    this._context = context;
    return Scaffold(
      appBar: WDMAppBar(context, '加入白板', () {
        _focusNode.unfocus();
        Navigator.pop(context);
      }, false),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Color(AppColors.BackgroundColor),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 200.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 30, bottom: 30),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundImage:
                        sAccountManager.loginInfo.userInfo.avatar != null && sAccountManager.loginInfo.userInfo.avatar.isNotEmpty
                            ? NetworkImage(sAccountManager.loginInfo.userInfo.avatar)
                            : ExactAssetImage("images/default_avatar.jpg"),
                  ),
                ),
                WDMText(text: '输入您要加入的房间号'),
                WDMTextField(
                    controller: _textEditingController,
                    onFieldSubmitted: _joinBtnClick,
                    type: TextInputType.number,
                    focusNode: _focusNode),
                WDMText(
                    text: _errorString,
                    fontSize: 15,
                    isBold: true,
                    top: 15,
                    color: Colors.red),
                WDMButton(
                  margin: EdgeInsets.only(top: 100),
                  onPressed: () {
                    _joinBtnClick(_textEditingController.text);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
