import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/EditorView.dart';
import 'package:myscript_iink/common.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/database.dart';

import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import '../../widget/WDMAlertDialog.dart';

pushReplay(EditorController controller, String localImageName,
    BuildContext context) async {
  var jiix = await controller.exportJIIX();
  var pointEvents = await controller.parseJIIX(jiix);
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => NoteReplayPage(pointEvents, localImageName)));
}

class NoteReplayPage extends StatefulWidget {
  NoteReplayPage(this.pointEvents, this.localImageName);

  List<IINKPointerEventFlutter> pointEvents;
  String localImageName;

  @override
  _NoteReplayPageState createState() => _NoteReplayPageState();
}

class _NoteReplayPageState extends State<NoteReplayPage> {
  var replayNote = Note.shared.clone(createTime: 111);
  EditorController replayEditorController;

  final _allSpeeds = [0.5, 1.0, 2.0, 4.0, 8.0, 16.0];
  int currentSpeedIndex = 1;

  setCurrentSpeedIndex(int value) {
    if (value < 0)
      currentSpeedIndex = 0;
    else if (value > _allSpeeds.length)
      currentSpeedIndex = _allSpeeds.length - 1;
    else
      currentSpeedIndex = value;
  }

  Timer _countdownTimer;
  bool _isPause = false;
  int currentIndex = 0;

  setCurrentIndex(int value) {
    if (value < 0)
      currentIndex = 0;
    else if (value > widget.pointEvents.length)
      currentIndex = widget.pointEvents.length - 1;
    else
      currentIndex = value;
  }

  int get _currentSpeed {
    if (currentSpeedIndex < 0)
      currentSpeedIndex = 0;
    else if (currentSpeedIndex > _allSpeeds.length)
      currentSpeedIndex = _allSpeeds.length - 1;
    return (_allSpeeds[currentSpeedIndex] * 200).toInt();
  }

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    super.dispose();
    _isPause = true;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    close();
  }

  close() async {
    if (replayEditorController == null) return;
    var path = (await replayNote.getNoteFile()).path;
    await replayEditorController.close();
  }

  _initController() async {
    await _initReplayEditorViewController();
    startPlay();
  }

  _initReplayEditorViewController() async {
    if (replayEditorController == null) {
      var path = (await replayNote.getNoteFile()).path;
      var controller = await EditorController.create(path);
      setState(() => replayEditorController = controller);

      (await File(path).exists())
          ? await replayEditorController.openPackage(path)
          : await replayEditorController.createPackage(path);
    }
    await replayEditorController.clear();
  }

  startPlay() {
    if (_countdownTimer != null) return;
    _countdownTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (currentIndex < widget.pointEvents.length - 1) {
        if (!_isPause) {
          var list = List<IINKPointerEventFlutter>();
          var currentDate = widget.pointEvents[currentIndex].t;
          var targetDate = currentDate + _currentSpeed;
          int maxNum = (_currentSpeed * 0.2).toInt();
          for (var index = currentIndex;
              index < widget.pointEvents.length;
              index++) {
            setCurrentIndex(index);
            if (widget.pointEvents[currentIndex].t > targetDate) break;
            list.add(widget.pointEvents[currentIndex]);
            if (list.length >= maxNum) break; //  按照时间回放，每秒最多200点
          }
          if (list.length == 0) {
            setState(() => _isPause = true);
            return;
          }

          if (list.first.eventType != IINKPointerEventTypeFlutter.down)
            list.insert(0,
                list.first.clone(eventType: IINKPointerEventTypeFlutter.down));
          if (list.last.eventType != IINKPointerEventTypeFlutter.up)
            list.add(
                list.last.clone(eventType: IINKPointerEventTypeFlutter.up));
          replayEditorController.syncPointerEvents(list);
        }
      } else {
        if (_isPause == false) {
          setState(() => _isPause = true);
          Navigator.pop(context);
        }
        print('播放结束');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(
        context,
        Translations.of(context).text('creative_playback'),
        actions: <Widget>[
          appbarRighItem(
            _isPause ? 'icons/split_black.png' : 'icons/split_gray.png',
            () {
              if (_isPause) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return WDMAlertDialog(
                      title:
                          Translations.of(context).text('split_into_two_pages'),
                      message: Translations.of(context)
                          .text('recombined_after_splitting'),
                      cancelText: Translations.of(context).text('Cancel'),
                      confimText: Translations.of(context).text('OK'),
                      type: Operation.NOTICE,
                      confim: (value) {
                        splite();
                      },
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              color: color_background,
              child: _noteWidget(),
            ),
          ),
          Container(
            height: 60,
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _bottomSheetChildren(),
            ),
          )
        ],
      ),
    );
  }

  Widget _noteWidget() {
    return AspectRatio(
      aspectRatio: 157.5 / 210.0,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: Image.asset(widget.localImageName),
          ),
          if (replayEditorController != null)
            Align(
              alignment: Alignment.center,
              child: Container(
                child: EditorView(
                  onCreated: replayEditorController.bindPlatformView,
                  onDisposed: replayEditorController.unbindPlatformView,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _bottomSheetChildren() {
    return <Widget>[
      ImageTextFlatButton('icons/play_rewind.png', null, () {
        setCurrentSpeedIndex(currentSpeedIndex - 1);
      }),
      ImageTextFlatButton(
          _isPause ? 'icons/play_start.png' : 'icons/play_pause.png', null, () {
        setState(() => _isPause = !_isPause);
      }),
      ImageTextFlatButton('icons/play_fastforward.png', null, () {
        setCurrentSpeedIndex(currentSpeedIndex + 1);
      }),
    ];
  }

  splite() async {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => shareWidget_Loading(),
    );
    await _spliteNote(widget.pointEvents.sublist(0, currentIndex));
    await _spliteNote(widget.pointEvents.sublist(currentIndex));

    Navigator.pop(context);
  }

  _spliteNote(List<IINKPointerEventFlutter> list) async {
    print('_spliteNote = ${list.length}');
    if (list == null || list.length == 0) return;
    if (list.first.eventType != IINKPointerEventTypeFlutter.down)
      list.insert(
          0, list.first.clone(eventType: IINKPointerEventTypeFlutter.down));
    if (list.last.eventType != IINKPointerEventTypeFlutter.up)
      list.add(list.last.clone(eventType: IINKPointerEventTypeFlutter.up));

    var splitNote = await Note.init_InDB();
    await sNoteProvider.update(splitNote.createTime,
        state: NoteStateDescription(DBTRState.available));
    var path = (await splitNote.getNoteFile()).path;
    var splitEditorViewController = await EditorController.create(path);
    await splitEditorViewController.createPackage(path);
    await splitEditorViewController.syncPointerEvents(list);
    await splitNote.saveAll(splitEditorViewController);
    await splitEditorViewController.close();
  }
}
