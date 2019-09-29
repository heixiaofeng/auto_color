import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ugee_note/manager/image_saver.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/util/permission.dart';
import 'package:ugee_note/widget/widgets.dart';

class ColorImage extends StatefulWidget {
  Uint8List imageBytes;
  double screenPixelRatio;
  ColorImage({this.imageBytes,this.screenPixelRatio});
  @override
  _ColorImageState createState() => _ColorImageState();
}

class _ColorImageState extends State<ColorImage> {
  GlobalKey _repaintBoun = GlobalKey();
  _ColorImageState();
  @override
  Widget build(BuildContext context) {
    print('color image: ${widget.imageBytes}');
    AppBar appBar = appbar(
      context,
      'AI上色',
      titleStyle: TextStyle(fontSize: 19, color: Colors.black87),
      actions: <Widget>[
        appbarRighItem('icons/auto_color_share.png', () {
          share();
        }),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _repaintBoun,
                  child: Image.memory(
                    widget.imageBytes,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width * 4 / 3,
                  ),
                ),
              ),
            ),
            Container(
                height: 80,
                color: Colors.white,
                child: Center(
                    child: FlatButton(
                      color: Colors.blueAccent,
                      child: Text('重新上色', style: TextStyle(color: Colors.white),),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )))
          ],
        ),
      ),
    );
  }

  share(){
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => normalBottomSheet(
            ScreenWidth * 0.6,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ImageTextFlatButton('icons/auto_color_square.png', '广场',
                        () {
                      Navigator.pop(context);
                      // 分享
                    }, imageSize: 40, textFontSize: 12),
                ImageTextFlatButton('icons/auto_color_save.png', '保存',
                        () async {
                      Navigator.pop(context);
                      var b = await _ensurePermissions();
                      if (!b) return;
                      RenderRepaintBoundary boundary =
                      _repaintBoun.currentContext.findRenderObject();
                      ui.Image image = await boundary.toImage(pixelRatio: widget.screenPixelRatio);
                      ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                      Uint8List pngBytes = byteData.buffer.asUint8List();
                      await Image_saver.saveImage(pngBytes);
                    }, imageSize: 40, textFontSize: 12),
              ],
            )));
  }

  Future<bool> _ensurePermissions() async {
    var permissions =
    Platform.isAndroid ? PermissionGroup.storage : PermissionGroup.photos;
    return await checkAndRequest(permissions);
  }
}
