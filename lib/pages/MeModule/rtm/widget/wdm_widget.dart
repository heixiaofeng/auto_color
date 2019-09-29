import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../utils/tools.dart' show AppColors, Constants;

Widget WDMAppBar(BuildContext context, String title,
    [back(), bool hiddenLeading = false]) {
  return PreferredSize(
      child: AppBar(
        title:
            Text(title, style: TextStyle(fontSize: 20, color: Colors.black87)),
        elevation: 0,
        centerTitle: true,
        brightness: Brightness.light,
        backgroundColor: Color(AppColors.BackgroundColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (!hiddenLeading) back == null ? Navigator.pop(context) : back();
          },
          color: hiddenLeading ? Colors.transparent : Colors.black87,
        ),
      ),
      preferredSize: Size.fromHeight(44));
}

Widget WDMText(
    {String text,
      double fontSize = 18,
      Color color = Colors.black87,
      Color backgroundColor = Colors.transparent,
      TextAlign textAlign = TextAlign.start,
      int maxLines,
      double left = 0,
      double top = 0,
      double right = 0,
      double bottom = 0,
      TextOverflow overflow,
      bool isBold = false}) {
  return Container(
    color: backgroundColor,
    margin: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
    child: Text(text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: Constants.IconFontFamily,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400)),
  );
}

Widget WDMButton(
    {String text = '加入房间',
      double width = 115,
      double height = 40,
      double fontSize = 16,
      EdgeInsetsGeometry margin,
      double radius = 20,
      bool isBold = false,
      Color textColor = Colors.white,
      Color backgroundColor,
      @required Function onPressed}) {
  if (backgroundColor == null) backgroundColor = AppColors.ThemeColor;
  return Container(
      width: width,
      height: height,
      margin: margin,
      child: FlatButton(
        child: WDMText(
            text: text,
            bottom: 2,
            color: textColor,
            fontSize: fontSize,
            isBold: isBold),
        color: backgroundColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius))),
        onPressed: onPressed,
      ));
}

Widget WDMTextField(
    {String text,
    TextEditingController controller,
    double width = 230,
    double height = 38,
    EdgeInsetsGeometry margin,
    double radius = 19,
    FocusNode focusNode,
    TextInputType type = TextInputType.text,
    onFieldSubmitted(String value)}) {
  controller.text = text;
  var isNull = text == null;
  return Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 0, left: 10, right: 9, bottom: 2),
    margin: margin == null ? EdgeInsets.only(top: 30) : margin,
    decoration: BoxDecoration(
        border: Border.all(
            color: Color(AppColors.DividerColor),
            width: Constants.DividerWidth),
        borderRadius: BorderRadius.circular(radius)),
    child: TextFormField(
      enabled: isNull,
      focusNode: focusNode,
      textAlign: isNull ? TextAlign.start : TextAlign.center,
      cursorColor: AppColors.ThemeColor,
      textInputAction: defaultTargetPlatform == TargetPlatform.iOS
          ? TextInputAction.join
          : TextInputAction.done,
      onFieldSubmitted: onFieldSubmitted,
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration.collapsed(hintText: null),
      style: TextStyle(
        fontSize: 16,
        fontFamily: Constants.IconFontFamily,
        fontWeight: isNull ? FontWeight.w400 : FontWeight.w600,
        color: AppColors.ThemeColor,
      ),
    ),
  );
}

Widget AlphaButton(
    {String text = '',
      String leftIcon,
      double left,
      double right,
      double top,
      double bottom,
      double width,
      double height = 45,
      double fontSize = 15,
      bool isBold = false,
      bool showShadow = true,
      Widget child,
      Color textColor = Colors.white,
      Color backgroundColor = AppColors.ThemeColor,
      @required Function onPressed}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: width ?? 313,
      height: height,
      alignment: child == null ? null : Alignment.center,
      margin: EdgeInsets.only(
          left: left ?? 0,
          top: top ?? 0,
          right: right ?? 0,
          bottom: bottom ?? 0),
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(height / 2)),
          boxShadow: [
            BoxShadow(
                offset: Offset(0, 0),
                color: showShadow ? Colors.black12 : Colors.transparent,
                blurRadius: 10,
                spreadRadius: 1)
          ]),
      child: child ??
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (leftIcon != null)
                Positioned(
                  left: 10,
                  child: Image.asset(
                    leftIcon,
                    width: 25,
                    height: 25,
                  ),
                ),
              WDMText(
                  text: text,
                  bottom: 2,
                  color: textColor,
                  fontSize: fontSize,
                  isBold: isBold),
            ],
          ),
    ),
  );
}