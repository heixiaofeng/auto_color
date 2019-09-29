import 'package:flutter/material.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/widget/widgets.dart';

enum Operation { NOTICE, EDIT }

class WDMAlertDialog extends Dialog {
  final String title;
  final String message;

  final Operation type;

  final bool isLandscape;

  final String cancelText;
  final String confimText;

  final VoidCallback cancel;
  final StringCallback confim;

  final alertDialogHeight = 265.0;

  final TextEditingController textEditingController;

  WDMAlertDialog(
      {Key key,
      @required this.title,
      this.message,
      this.isLandscape = false,
      this.cancelText = '取消',
      this.confimText = '确定',
      this.type = Operation.NOTICE,
      this.textEditingController,
      this.cancel,
      this.confim})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding =
        (MediaQuery.of(context).size.height - alertDialogHeight) / 2;
    return Padding(
      padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width / (isLandscape ? 1.88 : 8.5),
          right: MediaQuery.of(context).size.width / (isLandscape ? 1.88 : 8.5),
          top: padding - 30,
          bottom: padding + 30),
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _renderContent(context),
            ),
            Container(
              margin: EdgeInsets.only(top: 5, left: 30, right: 30),
              child: AspectRatio(
                aspectRatio: 254 / 78,
                child: Image.asset('icons/alert_top.png'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _renderContent(BuildContext context) {
    return Container(
      height: alertDialogHeight - 75,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          WDMText(text: title, isBold: true, color: Colors.black, fontSize: 17),
          type == Operation.NOTICE
              ? WDMText(
                  text: message,
                  isBold: false,
                  color: Colors.black87,
                  fontSize: 14,
                  top: 15,
                  left: 10,
                  right: 10,
                  bottom: 30)
              : WDMTextField(
                  margin: EdgeInsets.only(top: 18, bottom: 25),
                  controller: textEditingController),
          Container(
            height: LineThickness,
            color: DividerColor,
          ),
          Row(
            children: <Widget>[
              Expanded(
                  child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (cancel != null) cancel();
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12))),
                        child: Center(
                            child: WDMText(
                          text: cancelText,
                          isBold: true,
                          fontSize: 14,
                          color: Colors.black,
                        )),
                      ))),
              Container(
                height: 50,
                width: LineThickness,
                color: DividerColor,
              ),
              Expanded(
                  child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (confim != null) confim(textEditingController?.text);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(12))),
                        child: Center(
                            child: WDMText(
                          text: confimText,
                          isBold: true,
                          fontSize: 14,
                          color: Colors.black,
                        )),
                      ))),
            ],
          )
        ],
      ),
    );
  }
}
