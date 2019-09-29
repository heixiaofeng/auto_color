import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/util/FileImageEx.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'ColorImage.dart';


class AiAutoColorPage extends StatefulWidget {
  String piclocation;
  AiAutoColorPage({this.piclocation});
  @override
  _AiAutoColorPageState createState() => _AiAutoColorPageState();
}

GlobalKey _repaintBoud = GlobalKey();
final double screenDevicePixelRatio = ui.window.devicePixelRatio;
final defaultPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..color = Colors.red;

class _AiAutoColorPageState extends State<AiAutoColorPage> {

  requestPermission() async {
    var permissionHandler = PermissionHandler();
    PermissionGroup storage = PermissionGroup.storage;
    var storagePermissionStatus =
    await permissionHandler.checkPermissionStatus(storage);
    if (storagePermissionStatus != PermissionStatus.granted) {
      var requestResults =
      await permissionHandler.requestPermissions([storage]);
      if (requestResults[storage] != PermissionStatus.granted) {
        throw Exception('Permission denied: $storage');
      }
    }
  }

  @override
  void initState() {
    print('init state.......');
    super.initState();
    paint = defaultPaint;
    requestPermission();
  }

  @override
  void dispose(){
    super.dispose();
    strokeList.clear();
  }


  ImagePainter imagePainter = ImagePainter();
  var screenWidth;
  var screenHeight;
  Paint paint;
  bool selectStatus = true;
  Color selectColor = Colors.red;
  bool flag = true;
  String ref;
  String line;
  var httpUtil = HttpUtil.getInstance();
  String imageName;

  @override
  Widget build(BuildContext context) {
    print('build.....');
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.width * 4 / 3;
    AppBar appBar = appbar(
      context,
      'AI上色',
      titleStyle: TextStyle(fontSize: 19, color: Colors.black87),
      actions: <Widget>[
        appbarRighItem('icons/item_active_indicator.png', () async {
          flag = true;
          await submit();
          ref = (await _getCapturePngFile()).path;
          line = widget.piclocation;
          uploadImage(ref, line);
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
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: renderContent(),
                ),
              ),
            ),
            Container(
              height: 50,
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  iconState(
                      img: selectStatus
                          ? 'icons/auto_color_selected_pen.png'
                          : 'icons/auto_color_pen.png',
                      name: '画笔',
                      onTap: () async {
                        paint = defaultPaint;
                        setState(() => {
                          selectStatus = !selectStatus,
                          selectColor = Colors.red,
                        });
                      }),
                  iconState(
                      img: !selectStatus
                          ? 'icons/auto_color_selected_eraser.png'
                          : 'icons/auto_color_eraser.png',
                      name: '橡皮',
                      onTap: () async {
                        paint = Paint()
                          ..blendMode = BlendMode.clear
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 15;
                        setState(() => {
                          selectStatus = !selectStatus,
                          selectColor = Colors.red,
                        });
                      }),
                  iconState(
                      color: selectColor,
                      name: '色板',
                      onTap: () async {
                        showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            context: context,
                            builder: (context) => _selectColor());
                      }),
                  iconState(
                      img: 'icons/auto_color_clear.png',
                      name: '清空',
                      onTap: () async {
                        strokeList.clear();
                        imagePainter.notifyPainter();
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget iconState(
      {String img = '', String name, Function onTap, Color color}) {
    return GestureDetector(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          img == ''
              ? Container(
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(10))),
            width: 20,
            height: 20,
          )
              : Image.asset(
            img,
            height: 20,
            width: 20,
          ),
          WDMText(text: name, fontSize: 13),
        ],
      ),
      onTap: onTap,
    );
  }

  renderContent() => Column(
    children: <Widget>[
      Expanded(
        child: Center(
          child: Stack(
            children: <Widget>[
                getThumbImage(),
             gesturePaintArea(screenWidth, screenHeight, paint, imagePainter),
            ],
          ),
        ),
      ),
    ],
  );

  Widget getThumbImage(
      {String placeholder = 'icons/paper_thumb_placeholder.png'}) {
    return FutureBuilder(
      future: Future.value(File(widget.piclocation)),
      builder: (context, file) {
        if (file.data != null) {
          final img = Image(
            image: FileImageEx(file.data as File),
            width: screenWidth,
            height: screenHeight,
          );
          if (img != null) return img;
        }
        return Image.asset(placeholder);
      },
    );
  }

  Widget _selectColor() {
    return Container(
      color: color_background,
      height: ScreenWidth / 2.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          selectColorRow([0, 1, 2, 3, 4, 5]),
          selectColorRow([6, 7, 8, 9, 10, 11]),
        ],
      ),
    );
  }

  Row selectColorRow(List<int> list ) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (final index in list) Expanded(child: _colorItem(index)),
        ],
      );

  Widget _colorItem(int index) {
    return Container(
      padding: EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: FloatingActionButton(
        backgroundColor: Color(getColorFromHex(showPenColors[index])),
        onPressed: () {
          Navigator.pop(context);
          print(index);
          var color = Color(getColorFromHex(showPenColors[index]));
          print('color: $color');
          setState(() => {
            selectColor = color,
            selectStatus = true,
          });
          paint = Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3;
        },
      ),
    );
  }

  submit() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => normalBottomSheet(
            ScreenWidth * 0.6,
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text('AI正在为您上色中'),
                Image.asset(
                  'gifs/loading.gif',
                  width: 80,
                  height: 80,
                ),
                FlatButton(
                  color: Colors.blueAccent,
                  child: Text('取消',style: TextStyle(color: Colors.white),),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  onPressed: () {
                    flag = false;
                    httpUtil.cancelRequests(CancelToken());
                    Navigator.pop(context);
                  },
                )
              ],
            )
        )
    );
  }

  void uploadImage(String refImage, String lineImage) async {
    String ref_image = path.basename(refImage);
    String line_image = path.basename(lineImage);
    print('line原图路径：$lineImage');
    FormData formData = new FormData.from({
      "ref": UploadFileInfo(File(refImage), ref_image),
      "line": UploadFileInfo(File(lineImage), line_image)
    });
    var responseData = await httpUtil
        .post("http://10.0.0.202:5000/api/v1/colorize", data: formData);
    print('response.........${responseData.runtimeType}');
    var outputAsUint8List = new Uint8List.fromList(responseData);
    if (flag) {
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (ctx) => ColorImage(
                imageBytes: outputAsUint8List,
                screenPixelRatio: screenDevicePixelRatio,
              )));
    }
  }

  Future<File> _getCapturePngFile() async {
    RenderRepaintBoundary boundary =
    _repaintBoud.currentContext.findRenderObject();
    ui.Image image =
    await boundary.toImage(pixelRatio: screenDevicePixelRatio);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();

    final directory = (await getApplicationDocumentsDirectory()).path;
    debugPrint("ref图片路径 $directory");
    File imageFile = File("$directory/$imageName" + " ref.png");
    await imageFile.writeAsBytes(pngBytes);

    return imageFile;
  }
}

List<PointAndPaint> strokeList = List();

class ImagePainter extends CustomPainter with ChangeNotifier {
  ImagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    print('paint............');
    canvas.saveLayer(Offset.zero & size, Paint());
    for (int i = 0; i < strokeList.length - 1; i++) {
      if (strokeList[i] == null || strokeList[i + 1] == null) {
        continue;
      }
      if (strokeList[i] != null && strokeList[i] != null) {
        Path path = Path();
        path.relativeMoveTo(
            strokeList[i].offset.dx, strokeList[i].offset.dy);
        path.lineTo(strokeList[i + 1].offset.dx,
            strokeList[i + 1].offset.dy);
        canvas.drawPath(path, strokeList[i].paint);
      }
    }
    canvas.restore();
  }

  void notifyPainter() {
    notifyListeners();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PointAndPaint {
  Paint paint;
  Offset offset;
  PointAndPaint({this.offset, this.paint});
}

GestureDetector gesturePaintArea(double screenWidth, double screenHeight, Paint paint, ImagePainter imagePainter){
  return  GestureDetector(
    onPanStart: (details) {
      print('start..............');
      var point = details.localPosition;
      PointAndPaint pointPaint =
      PointAndPaint(paint: paint, offset: point);
      strokeList.add(pointPaint);
      imagePainter.notifyPainter();
    },
    onPanUpdate: (details) {
      print('update.........');
      var point = details.localPosition;
      PointAndPaint pointPaint =
      PointAndPaint(paint: paint, offset: point);
      strokeList.add(pointPaint);
      imagePainter.notifyPainter();
    },
    onPanEnd: (details) {
      print('end..........');
      strokeList.add(null);
      imagePainter.notifyPainter();
    },
    child: Container(
      width: screenWidth,
      height: screenHeight,
      child: RepaintBoundary(
        key: _repaintBoud,
        child: CustomPaint(
          painter: imagePainter,
        )),
    ),
  );
}

// dio classutil
class HttpUtil {
  static HttpUtil instance;
  Dio dio;
  BaseOptions options;

  CancelToken cancelToken = new CancelToken();

  static HttpUtil getInstance() {
    if (null == instance) instance = new HttpUtil();
    return instance;
  }
  /*
   * config it and create
   */
  HttpUtil() {
    //BaseOptions、Options、RequestOptions 都可以配置参数，优先级别依次递增，且可以根据优先级别覆盖参数
    options = new BaseOptions(
      //连接服务器超时时间，单位是毫秒.
      connectTimeout: 5000,
      //响应流上前后两次接受到数据的间隔，单位为毫秒。
      receiveTimeout: 10000,
      //表示期望以那种格式(方式)接受响应数据。接受4种类型 `json`, `stream`, `plain`, `bytes`. 默认值是 `json`,
      responseType: ResponseType.bytes,
    );

    dio = new Dio(options);
  }
  /*
   * post请求
   */
  post(url, {data, options, cancelToken}) async {
    print('-------------------------data = ${data == null}');
    Response response;
    try {
      response = await dio.post(url,
          data: data, options: options, cancelToken: cancelToken);
      print('post success---------${response.data}');
    } on DioError catch (e) {
      print('post error---------$e');
    }
    return response.data;
  }
  /*
   * 取消请求
   *
   * 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。
   * 所以参数可选
   */
  void cancelRequests(CancelToken token) {
    token.cancel("cancelled");
  }
}

