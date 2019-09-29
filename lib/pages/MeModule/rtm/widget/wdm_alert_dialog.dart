import 'package:flutter/material.dart';

import 'wdm_widget.dart';
import '../utils/tools.dart';

class WDMAlertDialog extends Dialog {
  final String title;
  final String message;

  final bool isLandscape;

  final VoidCallback cancel;
  final VoidCallback confim;

  final alertDialogHeight = 180.0;

  WDMAlertDialog(
      {Key key,
      @required this.title,
      this.message,
      this.isLandscape = false,
      this.cancel,
      this.confim})
      : super(key: key);

  @override
  Widget build(BuildContext context) {

    final width = isLandscape ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.width;
    final height = isLandscape ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height;

    final padding = (width - alertDialogHeight) / 2;

    return Padding(
      padding: EdgeInsets.only(
          left: height * 0.3,
          right: height * 0.3,
          top: padding - 10,
          bottom: padding + 10),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: alertDialogHeight,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              WDMText(
                  text: title, isBold: true, color: Colors.black, fontSize: 20),
              WDMText(
                  text: message,
                  isBold: false,
                  color: Colors.black87,
                  fontSize: 16,
                  top: 18,
                  left: 10,
                  right: 10,
                  bottom: 30),
              Container(
                height: Constants.DividerWidth,
                color: Colors.black12,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            if (cancel != null) cancel();
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            color: Colors.transparent,
                            child: Center(
                                child: WDMText(
                                    text: '取消',
                                    isBold: true,
                                    fontSize: 18,
                                    color: AppColors.ThemeColor)),
                          ))),
                  Container(
                    height: 50,
                    width: Constants.DividerWidth,
                    color: Colors.black12,
                  ),
                  Expanded(
                      child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            if (confim != null) confim();
                          },
                          child: Container(
                            height: 50,
                            color: Colors.transparent,
                            child: Center(
                                child: WDMText(
                                    text: '确定',
                                    isBold: true,
                                    fontSize: 18,
                                    color: AppColors.ThemeColor)),
                          ))),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
