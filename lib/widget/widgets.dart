import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ugee_note/model/EmptyInfo.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

import '../res/colors.dart';
import '../res/sizes.dart';

typedef StringCallback = void Function(String);
typedef BoolCallback = void Function(bool);

Widget appbar(BuildContext context, String title,
    {back(),
    bool implyLeading = false,
    List<Widget> actions = null,
    TextStyle titleStyle = null,
    bool centerTitle = true}) {
  return AppBar(
    backgroundColor: color_background,
    centerTitle: centerTitle,
    title: Text(title,
        style: titleStyle != null
            ? titleStyle
            : TextStyle(fontSize: 19, color: Colors.black87)),
    elevation: 0,
    brightness: Brightness.light,
    automaticallyImplyLeading: false,
    leading: implyLeading
        ? null
        : IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              back == null ? Navigator.pop(context) : back();
            },
            color: Colors.black87,
          ),
    actions: actions,
  );
}

Widget appbarSearch(BuildContext context, TextEditingController controller,
    StringCallback onChanged, StringCallback onSubmitted, List<Widget> actions,
    {Widget firstWidget}) {
  return AppBar(
    backgroundColor: color_background,
    title: Container(
      width: ScreenWidth * 0.77,
      height: 33,
      alignment: Alignment.center,
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: <Widget>[
          Image.asset('icons/search_gray.png', width: 10, height: 10),
          Container(width: 5),
          if (firstWidget != null) firstWidget,
          if (firstWidget != null) Container(width: 5),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(top: 0.0),
                hintText: Translations.of(context).text('search_tags_or_notes'),
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFD8D8D8), width: 1),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.5),
      ),
    ),
    centerTitle: true,
    elevation: 0,
    brightness: Brightness.light,
    automaticallyImplyLeading: false,
    leading: null,
    actions: actions,
  );
}

Widget appbarRighItem(String imageResouce, VoidCallback call) {
  return Container(
    width: 52,
    child: FlatButton(
      child: Image.asset(
        imageResouce,
        width: 30,
        height: 30,
      ),
      onPressed: call,
    ),
  );
}

/*
 *  横线·item间横线
 */
Widget line({double height = 2.0}) {
  return Divider(
    height: height,
    color: color_divider,
  );
}

/*
 *  弹框card
 */
Widget dialogCard({
  Widget child,
  Color color,
  double width,
  double height,
  double radius,
  Clip behavior,
}) {
  final paddingTop = (ScreenHeight - (height ?? DialogHeight)) / 2.0;
  final paddingBottom = paddingTop;
  final paddingLeft = (ScreenWidth - (width ?? DialogWidth)) / 2.0;
  final paddingRight = paddingLeft;

  return Card(
    color: color ?? Colors.white,
    margin: EdgeInsets.only(
        top: paddingTop,
        left: paddingLeft,
        bottom: paddingBottom,
        right: paddingRight),
    clipBehavior: behavior ?? Clip.hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? 15.0),
    ),
    child: child,
  );
}

/*
 *  通用型Card
 *  "我的"及其子页面，wrapRoundedCard可作为包裹，便于统一修改样式
 */
Widget wrapRoundedCard({
  List<Widget> items,
  double radius,
  Clip behavior,
  EdgeInsets outterPadding,
  EdgeInsets innerPadding,
  Colors color,
  BorderRadius borderRadius,
  Border border,
}) {
  return Card(
    color: color ?? Colors.white,
    margin: outterPadding ??
        EdgeInsets.only(top: 0, left: 15, bottom: 0, right: 15),
    clipBehavior: behavior ?? Clip.hardEdge,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius ?? 15.0),
    ),
    child: Container(
      padding: (innerPadding != null)
          ? innerPadding
          : EdgeInsets.only(top: 0, left: 10, bottom: 0, right: 10),
      decoration: BoxDecoration(
        color: (color != null) ? color : Colors.white,
        borderRadius:
            (borderRadius != null) ? borderRadius : BorderRadius.circular(10),
      ),
      child: Wrap(
        children: items,
      ),
    ),
  );
}

/*
 * 列表item
 */
Widget entryItem(String iconResource, String title, String subTitle,
    {VoidCallback onTap = null,
    bool loadSwitch = false,
    bool switchValue = false,
    BoolCallback switchCall = null}) {
  return GestureDetector(
    onTap: () {
      if (onTap != null) onTap();
    },
    child: Container(
      height: 45,
      color: Colors.white,
      padding: EdgeInsets.only(
        top: 0,
        left: 5.0,
        bottom: 0,
        right: 5.0,
      ),
      child: Row(
        children: <Widget>[
          if (iconResource != null)
            Image.asset(
              iconResource,
              width: 20.0,
              height: 20.0,
            ),
          Container(
            width: 10.0,
          ),
          Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              subTitle,
              textAlign: TextAlign.right,
              maxLines: 2,
              style: TextStyle(
                color: Colors.black38,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            child: onTap != null ? Icon(Icons.keyboard_arrow_right) : null,
          ),
          if (loadSwitch)
            Switch(
              value: switchValue,
              onChanged: switchCall,
            ),
        ],
      ),
    ),
  );
}

//  Text
Widget WDMText(
    {String text,
    double fontSize = 18,
    Color color = Colors.black,
    Color backgroundColor = Colors.transparent,
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    bool isBold = false}) {
  return Container(
    color: backgroundColor,
    margin: EdgeInsets.only(left: left, top: top, right: right, bottom: bottom),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      ),
    ),
  );
}

//  TextField
Widget WDMTextField(
    {String text,
    TextEditingController controller,
    double width = 230,
    double height = 38,
    EdgeInsetsGeometry margin,
    double radius = 19,
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
        border: Border.all(color: DividerColor, width: LineThickness),
        borderRadius: BorderRadius.circular(radius)),
    child: Material(
      color: Colors.transparent,
      child: TextFormField(
        enabled: isNull,
        textAlign: isNull ? TextAlign.start : TextAlign.center,
        cursorColor: ThemeColor,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: onFieldSubmitted,
        controller: controller,
        decoration: InputDecoration.collapsed(hintText: null),
        style: TextStyle(
          fontSize: isNull ? 16 : 18,
          fontWeight: isNull ? FontWeight.w400 : FontWeight.w600,
          color: ThemeColor,
        ),
      ),
    ),
  );
}

/// 上图片+下文字
Widget ImageTextFlatButton(String imageResource, String text, VoidCallback call,
    {double imageSize = 20, double textFontSize = 13, double opacity = null}) {
  return opacity == null
      ? _NormalImageTextWidget(
          imageResource,
          text,
          call,
          imageSize: imageSize,
          textFontSize: textFontSize,
        )
      : Opacity(
          opacity: opacity,
          child: _NormalImageTextWidget(
            imageResource,
            text,
            call,
            imageSize: imageSize,
            textFontSize: textFontSize,
          ),
        );
}

Widget _NormalImageTextWidget(
    String imageResource, String text, VoidCallback call,
    {double imageSize = 20, double textFontSize = 13}) {
  return GestureDetector(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (imageResource != null)
          Image.asset(
            imageResource,
            width: imageSize,
            height: imageSize,
          ),
        if (text != null) Container(height: 5),
        if (text != null)
          Text(
            text,
            style: TextStyle(
              fontSize: textFontSize,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    ),
    onTap: call,
  );
}

enum searchTagItemType {
  normal,
  selected,
  highlight,
}

Widget searchTagItem(String name, searchTagItemType type, VoidCallback call) {
  return GestureDetector(
    child: Container(
      height: 30,
      padding: EdgeInsets.only(left: 15, right: 15),
      decoration: BoxDecoration(
        color: type == searchTagItemType.highlight
            ? Color(0xff0E74BB)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: type == searchTagItemType.normal
                ? color_line
                : Color(0xff0E74BB),
            width: 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              color: type == searchTagItemType.highlight
                  ? Colors.white
                  : type == searchTagItemType.normal
                      ? color_line
                      : Color(0xff0E74BB),
            ),
          ),
        ],
      ),
    ),
    onTap: call,
  );
}

Widget addTagItem(
  String name, {
  TextEditingController controller,
  StringCallback onChanged,
  StringCallback onSubmitted,
}) {
  return Container(
    padding: EdgeInsets.only(left: 5, right: 5),
    child: Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image.asset('icons/add_tag.png', height: 30, width: 90),
        Container(
          alignment: Alignment.center,
          width: 85,
          height: 30,
          child: TextField(
            enabled: controller != null,
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(top: 0.0),
              hintText: name,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget searchTagWidget() {
  return Container(
    alignment: Alignment.centerLeft,
    child: Wrap(
      spacing: 8.0, // gap between adjacent chips
      runSpacing: 4.0, // gap between lines
      children: <Widget>[
        searchTagItem('', searchTagItemType.normal, null),
        searchTagItem('', searchTagItemType.selected, null),
        searchTagItem('', searchTagItemType.highlight, null),
      ],
    ),
  );
}

/// empty view
enum EmptyViewType {
  noNote,
  noTag,
  noKeyword,
  noSearchNote,
  noNet,
}

Widget emptyView(EmptyViewType type, BuildContext context) {
  final _allImageResource = {
    EmptyViewType.noNote: EmptyInfo.init('images/empty_noNote.png',
        Translations.of(context).text('note_list_empty_hint')),
    EmptyViewType.noTag: EmptyInfo.init('images/empty_noSearchResult.png',
        Translations.of(context).text('no_tag')),
    EmptyViewType.noKeyword: EmptyInfo.init('images/empty_noSearchResult.png',
        Translations.of(context).text('please_enter_keyword_search')),
    EmptyViewType.noSearchNote: EmptyInfo.init(
        'images/empty_noSearchResult.png',
        Translations.of(context).text('no_related_content_found')),
    EmptyViewType.noNet: EmptyInfo.init('images/empty_noNet.png',
        Translations.of(context).text('no_network_found_please_try_again')),
  };
  final emptyInfo =
      _allImageResource[type] ?? EmptyInfo.init('images/empty_noNote.png', '');
  return Container(
    alignment: Alignment.center,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Image.asset(emptyInfo.imageResource,
            width: ScreenWidth, height: ScreenHeight * 0.2),
        Container(height: ScreenHeight * 0.11),
        Text(emptyInfo.description,
            style: TextStyle(color: Color(0xFF6F6F6F), fontSize: 14)),
        Container(height: ScreenHeight * 0.11),
      ],
    ),
  );
}

///  顶部带圆角
Widget normalBottomSheet(double height, Widget child,
    {Color bgColor = Colors.white}) {
  return Stack(
    children: <Widget>[
      Container(
        height: height,
        width: ScreenWidth,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(35),
            topRight: Radius.circular(35),
          ),
        ),
        child: child,
      ),
    ],
  );
}

Widget shareWidget_Loading() {
  return normalBottomSheet(
    ScreenWidth * 0.82,
    Center(
      child: Image.asset(
        'gifs/loading.gif',
        width: 80,
        height: 80,
      ),
    ),
  );
}

Widget shareWidget(BuildContext context,
    {VoidCallback exportJPG_call,
    VoidCallback exportPNG_call,
    VoidCallback exportGIF_call}) {
  return normalBottomSheet(
    ScreenWidth * 0.82,
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(bottom: 30),
            height: 40,
            alignment: Alignment.topCenter,
            child: Column(
              children: <Widget>[
                Container(
                  child: Text(Translations.of(context).text('image'),
                      style: TextStyle(
                          color: Color(0xFF0E74BB),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    color: Color(0xFF0E74BB),
                    width: 60,
                    height: 2),
              ],
            )),
        Container(
          height: 100,
          color: Colors.white,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ImageTextFlatButton('icons/export_JPG.png', 'JPG', exportJPG_call,
                  imageSize: 40, textFontSize: 12),
              ImageTextFlatButton('icons/export_PNG.png', 'PNG', exportPNG_call,
                  imageSize: 40, textFontSize: 12),
              ImageTextFlatButton('icons/export_GIF.png', 'GIF', exportGIF_call,
                  imageSize: 44, textFontSize: 12),
            ],
          ),
        )
      ],
    ),
  );
}

Widget bottomDialog({
  @required String title,
  @required String imageResource,
  @required String bottomText,
  String battery,
}) {
  final style = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  return normalBottomSheet(
    ScreenWidth * 0.82,
    Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (title != null) Text(title),
        Image.asset(imageResource,
            width: 100, height: ScreenWidth * 0.82 * 0.5),
        if (battery != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(battery),
              Container(width: 5),
              Image.asset('icons/battery_icon_H.png', width: 20, height: 20),
            ],
          ),
        Text(bottomText),
      ],
    ),
  );
}

loading(
  BuildContext context, {
  VoidCallback popCall,
  String text,
  Duration duration = const Duration(milliseconds: 2000),
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
              ),
              Text(text ?? Translations.of(context).text('loading')),
            ],
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
    },
  );
  if (popCall == null) Future.delayed(duration, () => Navigator.pop(context));
}
