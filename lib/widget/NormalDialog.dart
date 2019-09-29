import 'package:flutter/material.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/widget/widgets.dart';

class NormalDialog extends Dialog {
  final String message;
  final int duration;

  NormalDialog({
    Key key,
    @required this.message,
    this.duration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final padding = (ScreenHeight - 180.0) / 2;
    if (duration != 0)
      Future.delayed(Duration(milliseconds: duration != null ? duration : 1500),
          () => Navigator.pop(context));
    return Padding(
      padding: EdgeInsets.only(
          left: ScreenWidth / 8.5,
          right: ScreenWidth / 8.5,
          top: padding - 10,
          bottom: padding + 10),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(15),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: WDMText(
              text: message, isBold: false, color: Colors.black, fontSize: 16),
        ),
      ),
    );
  }
}
