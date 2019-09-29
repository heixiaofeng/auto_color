import 'dart:async';
import 'dart:io';

import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:myscript_iink/DeviceSize.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/util/StatusStore.dart';

final sRealtimeManager = RealtimeManager._init();

class RealtimeManager {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription<NotePenPointer> _notepadSyncPointerSubscription;
  NotepadState _state = sNotepadManager.notepadState;

  Note note = Note.shared;

  EditorController realtimeEditorController;

  RealtimeManager._init() {
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _notepadSyncPointerSubscription =
        sNotepadManager.syncPointerStream.listen(_onSyncPointerEvent);
  }

  start() {
    print('RealtimeManager start');
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    _state = event.state;

    switch (_state) {
      case NotepadState.Connected:
        intoRealtime(null);
        break;
      default:
        finishRealtime();
        break;
    }
  }

  IINKPointerEventFlutter _prePointer = IINKPointerEventFlutter.shared;

  _onSyncPointerEvent(NotePenPointer pointer) {
    if (note.state != NoteStateDescription(DBTRState.available)) {
      note.state = NoteStateDescription(DBTRState.available);
      sNoteProvider.update(
        note.createTime,
        state: NoteStateDescription(DBTRState.available),
      );
    }
    IINKPointerEventTypeFlutter eventType;
    switch (_prePointer.eventType) {
      case IINKPointerEventTypeFlutter.down:
        eventType = pointer.p > 0
            ? IINKPointerEventTypeFlutter.move
            : IINKPointerEventTypeFlutter.up;
        break;
      case IINKPointerEventTypeFlutter.move:
        eventType = pointer.p > 0
            ? IINKPointerEventTypeFlutter.move
            : IINKPointerEventTypeFlutter.up;
        break;
      case IINKPointerEventTypeFlutter.up:
        if (pointer.p > 0) eventType = IINKPointerEventTypeFlutter.down;
        break;
      default:
        break;
    }

    if (eventType != null) {
      final pointerEventFlutter = IINKPointerEventFlutter(
        eventType: eventType,
        x: pointer.x.toDouble() * viewScale,
        y: pointer.y.toDouble() * viewScale,
        t: -1,
        f: pointer.p.toDouble() / 512.0,
        pointerType: IINKPointerTypeFlutter.pen,
        pointerId: -1,
      );
      _prePointer = pointerEventFlutter;
      realtimeEditorController.syncPointerEvent(pointerEventFlutter);
    }
  }

  /*
   * 新建一个实时笔记
   */
  Future<void> intoRealtime([Note newNote, EditorController controller]) async {
    await finishRealtime();

    note = (newNote != null) ? newNote : await Note.init_InDB();
    var path = (await note.getNoteFile()).path;
    realtimeEditorController =
        (controller != null) ? controller : await EditorController.create(path);

    await Future.delayed(Duration(milliseconds: 100), () {});
    (await File(path).exists())
        ? await realtimeEditorController.openPackage(path)
        : await realtimeEditorController.createPackage(path);
    await note.saveAll(realtimeEditorController);

    await Future.delayed(Duration(milliseconds: 100), () {});
    lastKeyupTime = note.createTime;
  }

  /*
   * 结束当前实时
   */
  var lastKeyupTime = 0;

  Future<void> finishRealtime() async {
    if (note != Note.shared) {
      if (_prePointer.eventType != IINKPointerEventTypeFlutter.up) {
        final pointerEventFlutter_up =
            _prePointer.clone(eventType: IINKPointerEventTypeFlutter.up);
        await realtimeEditorController
            ?.syncPointerEvent(pointerEventFlutter_up);
      }
      await note.saveAll(realtimeEditorController);

      if (sStatusStore.browsePage_createtime != note.createTime)
        await realtimeEditorController.close();

      note = Note.shared;
      _prePointer = IINKPointerEventFlutter.shared;
    }
  }
}
