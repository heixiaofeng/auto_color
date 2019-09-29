import 'package:flutter/material.dart';

import '../utils/tools.dart';
import '../widget/wdm_widget.dart';
import 'rtc_note_join.dart';
import 'rtc_note_info.dart';
import 'rtc_connected.dart';

enum Operation { CREATE, JOIN }

class OperationModel {
  final String image;
  final String title;
  final Operation type;
  final bool showDivider;

  OperationModel(
      {@required this.image,
      @required this.title,
      @required this.type,
      this.showDivider: true});
}

class RTCNoteScreen extends StatelessWidget {
  var _dataArray = [
    OperationModel(
        image: 'create_screen', title: '创建白板', type: Operation.CREATE),
    OperationModel(
        image: 'join_screen',
        title: '加入白板',
        type: Operation.JOIN,
        showDivider: false)
  ];

  final RowHeight = 50.0;

  BuildContext _context;

  _popVC() async {
    Navigator.pop(_context);
    await SmartChannel.invokeMethod(RTCMethodName.pop);
  }

  @override
  Widget build(BuildContext context) {
    this._context = context;
    return Scaffold(
      appBar: WDMAppBar(context, '笔记白板', () {
        _popVC();
      }),
      body: Container(
        color: Color(AppColors.BackgroundColor),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 50, top: 20, right: 50),
              child: Image.asset(
                'images/note_screen.png',
                fit: BoxFit.cover,
              ),
            ),
            Container(
              width: double.infinity,
              height: RowHeight * _dataArray.length,
              margin: EdgeInsets.only(left: 15, top: 12, right: 15),
              padding: EdgeInsets.only(left: 20, right: 10),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(9))),
              child: ListView.builder(
                  itemCount: this._dataArray.length,
                  itemBuilder: (ctx, index) =>
                      _createItem(ctx, _dataArray[index])),
            ),
            WDMText(
                text: '若您想创建一个房间，等待另一个人加入，请选择"创建白板"。若您想加入别人的房间，请选择"加入白板"。',
                fontSize: 15,
                top: 15,
                left: 30,
                right: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext ctx) =>
                      RTCConnected(isBroadcast: true, channelId: '60011')));
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  /// 重构设置模块再抽离
  Widget _createItem(BuildContext ctx, OperationModel model) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (BuildContext ctx) {
              switch (model.type) {
                case Operation.CREATE:
                  return RTCNoteInfo();
                case Operation.JOIN:
                  return RTCNoteJoin();
                default:
                  return Container();
              }
            },
          ),
        );
      },
      child: Container(
        height: RowHeight,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 20,
                    height: 16,
                    margin: EdgeInsets.only(right: 8),
                    child: Image.asset('images/${model.image}.png'),
                  ),
                  Expanded(
                    child: Text(
                      model.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontFamily: Constants.IconFontFamily,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_right)
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 30, right: 10),
              child: Divider(
                color: model.showDivider
                    ? Color(AppColors.DividerColor)
                    : Colors.white,
                height: Constants.DividerWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
