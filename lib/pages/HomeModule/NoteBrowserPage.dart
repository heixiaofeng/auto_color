import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drag_scale/flutter_drag_scale.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen/screen.dart';
import 'package:share_extend/share_extend.dart';
import 'package:ugee_note/manager/RealtimeManager.dart';
import 'package:ugee_note/manager/image_saver.dart';
import 'package:ugee_note/model/Note.dart';

import 'package:notepad_kit/notepad.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:ugee_note/model/NoteSkin.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/pages/HomeModule/NoteEditTagsPage.dart';
import 'package:ugee_note/pages/HomeModule/NoteReplayPage.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/DateUtils.dart';
import 'package:ugee_note/util/GestureRecognizer.dart';
import 'package:ugee_note/util/StatusStore.dart';
import 'package:ugee_note/util/permission.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'package:flutter_seekbar/flutter_seekbar.dart'
    show ProgressValue, SectionTextModel, SeekBar;
import 'package:myscript_iink/EditorView.dart';
import '../../widget/WDMAlertDialog.dart';
import 'AIAutoColorPage.dart';
import 'NoteRecognizePage.dart';

enum NoteBrowserType { browse, edit }

enum NoteRealtimeType { disconnect, noRealtime, realtime }

class NoteBrowserPage extends StatefulWidget {
  NoteBrowserPage(this.note, {this.type = NoteBrowserType.browse});

  Note note;
  NoteBrowserType type;

  @override
  _NoteBrowserPageState createState() => _NoteBrowserPageState();
}

class _NoteBrowserPageState extends State<NoteBrowserPage> {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription _noteskinSubscription;
  StreamSubscription _tagSubscription;

  NoteBrowserType _type = NoteBrowserType.browse;
  NoteRealtimeType _editType = NoteRealtimeType.realtime;

  _setEditType(NoteRealtimeType value) {
    setState(() => _editType = value);
    Screen.keepOn(_editType == NoteRealtimeType.realtime);
  }

  bool _isHiddenTopBarBottomBar = false;
  var _noteskins = List<NoteSkin>();
  var _tags = List<Tag>();

  PenStyle _penStyle;
  final _brushs = [
    MyscriptPenBrushType.FountainPen,
    MyscriptPenBrushType.CalligraphicBrush,
    MyscriptPenBrushType.Polyline
  ];

  EditorController _editorController;

  _setSkin(int skinid) async {
    if (skinid != null) {
      widget.note.skinID = skinid;
      await sNoteProvider.update(widget.note.createTime, skinID: skinid);
      Navigator.pop(context); //  TODO 隐藏背景灰色 & 更新当前note的skinid
    }
  }

  var _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    print('NoteBrowserPage initState');

    _type = widget.type;

    _textEditingController.text = widget.note.remark;

    _refreshState(sNotepadManager.notepadState);

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _noteskinSubscription =
        sNoteProvider.changeStream.listen(_onNoteSkinChange);
    _onNoteSkinChange(null);

    _setSkin(null);

    _tagSubscription = sTagProvider.changeStream.listen(_onTagChange);
    _onTagChange(null);

    sStatusStore.browsePage_createtime = widget.note.createTime;

    initEditController();
  }

  @override
  void dispose() {
    super.dispose();
    print('NoteBrowserPage dispose');
    _notepadStateSubscription.cancel();
    _noteskinSubscription.cancel();
    _tagSubscription.cancel();
    Screen.keepOn(false);
    close();
    sStatusStore.browsePage_createtime = -1;
  }

  close() async {
    if (_editorController == null) return;
    await widget.note.saveAll(_editorController);
    if (widget.note.createTime != sRealtimeManager.note.createTime)
      await _editorController.close();
  }

  _getPenStyle() async {
    if (_editorController == null) return;
    var style = await _editorController.getPenStyle();
    _penStyle = PenStyle.parse(style);
  }

  _onTagChange(DBChangeType type) async {
    sNoteProvider.queryTags(widget.note.createTime).then((tags) {
      setState(() => _tags = tags);
    });
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    _refreshState(event.state);
  }

  _onNoteSkinChange(DBChangeType type) async {
    var skins = await sNoteSkinProvider.queryAvalibleNoteSkins();
    setState(() => _noteskins
      ..clear()
      ..addAll(skins));
  }

  initEditController() async {
    if (_editorController != null) return;
    var path = (await widget.note.getNoteFile()).path;
    print('path = ${path}');
    EditorController controller;
    if (sRealtimeManager.note.createTime == widget.note.createTime) {
      controller = sRealtimeManager.realtimeEditorController;
    } else {
      controller = await EditorController.create(path);
      (await File(path).exists())
          ? await controller.openPackage(path)
          : await controller.createPackage(path);
    }
    setState(() => _editorController = controller);

    await _getPenStyle();
  }

  _refreshState(NotepadState state) async {
    if (sNotepadManager.notepadState != NotepadState.Connected) {
      _setEditType(NoteRealtimeType.disconnect);
    } else if (widget.note.createTime == sRealtimeManager.note.createTime) {
      _setEditType(NoteRealtimeType.realtime);
    } else {
      _setEditType(NoteRealtimeType.noRealtime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: color_background,
        appBar: _isHiddenTopBarBottomBar
            ? null
            : (_type == NoteBrowserType.browse
                ? _appbarBrowse(context)
                : _appbarEdit(context)),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                color: color_background,
                child: RawGestureDetector(
                  gestures: {
                    AllowMultipleGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                            AllowMultipleGestureRecognizer>(
                      () => AllowMultipleGestureRecognizer(), //构造函数
                      (instance) {
                        instance.onTap = () {
                          setState(() => _isHiddenTopBarBottomBar =
                              !_isHiddenTopBarBottomBar);
                        };
                      },
                    )
                  }, //TODO Fix：单击和双击的耦合、布局重构）
                  child: DragScaleContainer(
                    doubleTapStillScale: false,
                    child: _noteWidget(),
                  ),
                ),
              ),
            ),
            if (!_isHiddenTopBarBottomBar)
              Container(
                height: 60,
                color: Colors.white,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _type == NoteBrowserType.browse
                      ? _bottomSheetChildrenBrowse()
                      : _bottomSheetChildrenEdit(),
                ),
              ),
          ],
        ));
  }

  AppBar _appbarBrowse(BuildContext context) {
    return appbar(
      context,
      DateUtils.getDescription(widget.note.createTime, DateFormatType.yMd_dot),
      titleStyle: TextStyle(fontSize: 19, color: Colors.black87),
      actions: <Widget>[
        appbarRighItem(
            _editType == NoteRealtimeType.realtime
                ? 'icons/intoEdit_Realtime.png'
                : 'icons/intoEdit_NoRealtime.png', () {
          setState(() => _type = NoteBrowserType.edit);
        }),
        appbarRighItem('icons/share_black.png', () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (BuildContext context) {
              return shareWidget(
                context,
                exportJPG_call: () {
                  Navigator.pop(context);
                  _exportJPG();
                },
                exportPNG_call: () {
                  Navigator.pop(context);
                  _exportPNG();
                },
                exportGIF_call: () {
                  Navigator.pop(context);
                  _exportGIF();
                },
              );
            },
          );
        }),
      ],
    );
  }

  Future _exportJPG() async {
    if (_editorController == null) return;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => shareWidget_Loading(),
    );

    var b = await _ensurePermissions();
    if (!b) {
      Navigator.pop(context);
      return;
    }

    final skinByteData =
        await rootBundle.load(widget.note.getSkin().localImage);
    final skinBytes = skinByteData.buffer.asUint8List();
    final bytes = await _editorController.exportJPG(skinBytes);
    await Image_saver.saveImage(bytes);

    var documentsDir = await getApplicationDocumentsDirectory();
    var jpgFile = File("${documentsDir.path}/share_jpg.jpg");
    await jpgFile.writeAsBytesSync(bytes);

    Navigator.pop(context);
    ShareExtend.share(jpgFile.path, "image");
  }

  Future _exportPNG() async {
    if (_editorController == null) return;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => shareWidget_Loading(),
    );

    var b = await _ensurePermissions();
    if (!b) {
      Navigator.pop(context);
      return;
    }

    final skinByteData =
        await rootBundle.load(widget.note.getSkin().localImage);
    final skinBytes = skinByteData.buffer.asUint8List();
    final bytes = await _editorController.exportPNG(skinBytes);
    await Image_saver.saveImage(bytes);

    var documentsDir = await getApplicationDocumentsDirectory();
    var pngFile = File("${documentsDir.path}/share_png.png");
    await pngFile.writeAsBytesSync(bytes);

    Navigator.pop(context);
    ShareExtend.share(pngFile.path, "image");
  }

  Future _exportGIF() async {
    if (_editorController == null) return;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => shareWidget_Loading(),
    );

    var b = await _ensurePermissions();
    if (!b) {
      Navigator.pop(context);
      return;
    }

    var jiix = await _editorController.exportJIIX();
    var pointerEvents = await _editorController.parseJIIX(jiix);

    var gifNote = Note.shared.clone(createTime: 999);
    var path = (await gifNote.getNoteFile()).path;
    var gifEditorViewController = await EditorController.create(path);
    (await File(path).exists())
        ? await gifEditorViewController.openPackage(path)
        : await gifEditorViewController.createPackage(path);
    await gifEditorViewController.clear();

    final skinByteData =
        await rootBundle.load(widget.note.getSkin().localImage);
    final skinBytes = skinByteData.buffer.asUint8List();

    var documentsDir = await getApplicationDocumentsDirectory();
    final gifFilePath = await gifEditorViewController.exportGIF(
      skinBytes,
      pointerEvents,
      '${documentsDir.path}/share_gif.gif',
    );

    print('finish gifFilePath = ${gifFilePath}');

    Navigator.pop(context);
    ShareExtend.share(gifFilePath, "file");
  }

  AppBar _appbarEdit(BuildContext context) {
    return appbar(
      context,
      Translations.of(context).text('edit'),
      titleStyle: TextStyle(fontSize: 19, color: Colors.black87),
      actions: <Widget>[_editAction()],
      back: () {
        setState(() => _type = NoteBrowserType.browse);
      },
    );
  }

  Widget _editAction() {
    switch (_editType) {
      case NoteRealtimeType.disconnect:
        return _editActionItem(
            'icons/edit_disconnect.png',
            Translations.of(context).text('notify_notepad_disconnected'),
            Color(0xFF999999),
            null);
        break;
      case NoteRealtimeType.noRealtime:
        return _editActionItem(
            'icons/edit_noRealtime.png',
            Translations.of(context).text('compose_real_time'),
            Color(0xFF000000), () {
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return WDMAlertDialog(
                  title: Translations.of(context).text('editing_this_page'),
                  message: Translations.of(context).text('need_to_re-identify'),
                  cancelText: Translations.of(context).text('Cancel'),
                  confimText: Translations.of(context).text('OK'),
                  type: Operation.NOTICE,
                  confim: (value) async {
                    if (_editorController == null) return;
                    await sRealtimeManager.intoRealtime(
                        widget.note, _editorController);
                    _refreshState(sNotepadManager.notepadState);
                  },
                );
              });
        });
        break;
      case NoteRealtimeType.realtime:
        return _editActionItem(
            'icons/edit_realtime.png',
            Translations.of(context).text('compose_real_time_ing'),
            Color(0xFF0E74BB),
            null);
        break;
    }
  }

  Widget _editActionItem(
    String imageResource,
    String text,
    Color textColor,
    VoidCallback call,
  ) {
    return FlatButton(
      child: Row(
        children: <Widget>[
          Image.asset(imageResource, width: 20, height: 20),
          Container(width: 5),
          Text(text, style: TextStyle(color: textColor, fontSize: 14)),
        ],
      ),
      onPressed: call,
    );
  }

  List<Widget> _bottomSheetChildrenBrowse() {
    var note_replay = Translations.of(context).text('note_replay');
    var note_detail = Translations.of(context).text('note_detail');
    var note_recognize = Translations.of(context).text('note_recognize');
    var auto_color = '上色';
    return <Widget>[
      ImageTextFlatButton(
        'icons/note_replay.png',
        note_replay,
        () {
          pushReplay(
            _editorController,
            widget.note.getSkin().localImage,
            context,
          );
        },
      ),
      ImageTextFlatButton('icons/note_recognize.png', note_recognize, () {
        if (_editorController == null) return;
        _editorController.exportText().then((covert) {
          sNoteProvider.update(widget.note.createTime, convert: covert);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NoteRecognizePage(covert)));
        });
      }),
      ImageTextFlatButton('icons/note_detail.png', note_detail, () {
        showModalBottomSheet(
          backgroundColor: Colors.transparent,
          context: context,
          builder: (BuildContext context) {
            return _noteConfigDetail();
          },
        );
      }),
      ImageTextFlatButton(
          'icons/delete_black.png', Translations.of(context).text('delete'),
          () {
        var title = Translations.of(context).text('delete_current_page');
        var message = Translations.of(context).text('deleted_no_recover');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return WDMAlertDialog(
              title: title,
              message: message,
              cancelText: Translations.of(context).text('Cancel'),
              confimText: Translations.of(context).text('OK'),
              type: Operation.NOTICE,
              confim: (value) async {
                if (widget.note.createTime == sRealtimeManager.note.createTime)
                  sRealtimeManager.intoRealtime();
                sNoteProvider.update(widget.note.createTime,
                    state: NoteStateDescription(DBTRState.localRecyclebin));
              },
            );
          },
        );
      }),
      ImageTextFlatButton(
          'icons/auto_color_main.png',
          auto_color,
              () async {
            final skinByteData =
            await rootBundle.load(widget.note.getSkin().localImage);
            final skinBytes = skinByteData.buffer.asUint8List();
            final bytes = await _editorController.exportJPG(skinBytes);

            var documentsDir = await getApplicationDocumentsDirectory();
            var pngFile = File("${documentsDir.path}/share.png");
            await pngFile.writeAsBytesSync(bytes);

            Navigator.push(
              context, MaterialPageRoute(
              builder: (ctx) => AiAutoColorPage(
                  piclocation:
                  pngFile.path),
            ),
            );
          }
      ),
    ];
  }

  Widget _noteWidget() {
    return AspectRatio(
      aspectRatio: 157.5 / 210.0,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Image.asset(widget.note.getSkin().localImage),
          ),
          if (_editorController != null)
            Align(
              alignment: Alignment.center,
              child: Container(
                child: EditorView(
                  onCreated: _editorController.bindPlatformView,
                  onDisposed: _editorController.unbindPlatformView,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _bottomSheetChildrenEdit() {
    return <Widget>[
      ImageTextFlatButton(
        'icons/note_color.png',
        Translations.of(context).text('compose_stroke_color'),
        () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => _selectColor(),
          );
        },
      ),
      ImageTextFlatButton(
        'icons/note_penStoke.png',
        Translations.of(context).text('compose_stroke_width'),
        () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => _selectPenThinckness(),
          );
        },
      ),
      ImageTextFlatButton(
        'icons/note_penType.png',
        Translations.of(context).text('pen_type'),
        () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => _selectPenType(),
          );
        },
      ),
      ImageTextFlatButton(
        'icons/note_skin.png',
        Translations.of(context).text('paper_background'),
        () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => _selecteSkin(),
          );
        },
      ),
    ];
  }

  Widget _noteConfigDetail() {
    final style = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return normalBottomSheet(
      ScreenWidth * 0.82,
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _detailItem(<Widget>[
            Text(Translations.of(context).text('my_label'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  direction: Axis.vertical,
                  spacing: 8.0, // gap between adjacent chips
                  runSpacing: 4.0, // gap between lines
                  children: <Widget>[
                    addTagItem(
                        '+${Translations.of(context).text('add_label')}'),
                    for (final tag in _tags)
                      searchTagItem(tag.name, searchTagItemType.selected, null),
                  ],
                ),
              ),
            ),
          ], marginTop: 35, call: () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NoteEditTagsPage(widget.note)));
          }),
          _detailItem(<Widget>[
            Text(
                '${Translations.of(context).text('paper_detail_create_time')}：${DateUtils.getDescription(widget.note.createTime, DateFormatType.yMdHm_dot)}',
                style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 13)),
            Text(
                '${Translations.of(context).text('paper_detail_last_modify')}：${DateUtils.getDescription(widget.note.lastModify, DateFormatType.yMdHm_dot)}',
                style: TextStyle(color: Color(0xFF5A5A5A), fontSize: 13)),
          ]),
          Expanded(
            child: _detailItem(<Widget>[
              Text(Translations.of(context).text('remark'), style: style),
              Expanded(
                child: Container(
                  width: ScreenWidth,
                  margin: EdgeInsets.only(top: 10, bottom: 10),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: color_line, width: 1),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration.collapsed(hintText: null),
                    onSubmitted: (text) {
                      sNoteProvider.update(
                        widget.note.createTime,
                        remark: text,
                      );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(List<Widget> list,
      {double marginTop = 0, VoidCallback call}) {
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.only(top: marginTop, left: 30, right: 30),
        width: ScreenWidth,
        height: ScreenWidth * 0.82 * 0.23,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: list,
        ),
      ),
      onTap: call,
    );
  }

  Widget _selectColor() {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      color: color_background,
      height: ScreenWidth / 4.0 + 45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (final index in [0, 1, 2, 3, 4, 5]) _colorItem(index),
            ],
          ),
          Container(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (final index in [6, 7, 8, 9, 10, 11]) _colorItem(index),
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorItem(int index) {
    return Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      width: ScreenWidth / 8.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: showPenColors[index] == _penStyle.color
            ? Colors.white
            : Colors.transparent,
      ),
      child: FloatingActionButton(
        backgroundColor: Color(getColorFromHex(showPenColors[index])),
        onPressed: () {
          Navigator.pop(context); //  TODO 共享传值后不需要返回
          if (_editorController == null) return;
          _penStyle = _penStyle.clone(color: showPenColors[index]);
          _editorController.setPenStyle(_penStyle.fromat());
        },
      ),
    );
  }

  Widget _selecteSkin() {
    return Container(
      color: color_background,
      height: ScreenWidth / 2.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _noteskins.length,
        itemBuilder: (context, index) {
          return _skinItem(_noteskins[index]);
        },
      ),
    );
  }

  Widget _skinItem(NoteSkin noteskin) {
    return GestureDetector(
      child: Container(
        padding: EdgeInsets.only(top: 10, left: 5, right: 5, bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Image.asset(noteskin.localImage),
                  if (widget.note.skinID == noteskin.id)
                    Opacity(
                        opacity: 0.5,
                        child: Image.asset('icons/selected_note.png')),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Text(noteskin.name),
            )
          ],
        ),
      ),
      onTap: () {
        _setSkin(noteskin.id);
      },
    );
  }

  /// 粗细
  Widget _selectPenThinckness() {
    return normalBottomSheet(
      ScreenWidth * 0.82,
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (_penStyle != null)
            Container(
              padding: EdgeInsets.only(bottom: 50),
              child: Text(
                  '${Translations.of(context).text('compose_stroke_width')}：${_penStyle.myscriptPenWidth.toStringAsFixed(2)}px'),
            ),
          if (_penStyle != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text('0.0px'),
                Container(
                  width: ScreenWidth * 0.4,
                  child: SeekBar(
                    progresseight: 10,
                    indicatorRadius: 0.0,
                    value: (_penStyle.myscriptPenWidth / 2.5) * 100,
                    isRound: true,
                    backgroundColor: Colors.black26,
                    progressColor: ThemeColor,
                    onValueChanged: (v) {
                      setState(() {
                        if (_editorController == null) return;
                        _penStyle =
                            _penStyle.clone(myscriptPenWidth: v.progress * 2.5);
                        _editorController.setPenStyle(_penStyle.fromat());
                      });
                    },
                  ),
                ),
                Text('2.5px'),
              ],
            )
        ],
      ),
    );
  }

  /// 笔类型
  Widget _selectPenType() {
    final h = ScreenWidth * 0.82;
    return normalBottomSheet(
      h,
      Container(
        margin: EdgeInsets.only(top: 20, left: 30, right: 30, bottom: 44),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            for (final pt in _brushs)
              GestureDetector(
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'icons/penType_${MyscriptPenBrush(pt).descriptions()}.png',
                    height: pt == _penStyle.myscriptPenBrush.type
                        ? h * 0.5
                        : h * 0.3,
                  ),
                ),
                onTap: () {
                  setState(() {
                    Navigator.pop(context); //  TODO 共享传值后不需要返回
                    if (_editorController == null) return;
                    _penStyle =
                        _penStyle.clone(myscriptPenBrush: MyscriptPenBrush(pt));
                    _editorController.setPenStyle(_penStyle.fromat());
                  });
                },
              )
          ],
        ),
      ),
    );
  }

  Future<bool> _ensurePermissions() async {
    var permissions =
        Platform.isAndroid ? PermissionGroup.storage : PermissionGroup.photos;
    return await checkAndRequest(permissions);
  }
}
