import 'dart:async';
import 'dart:io';

import 'package:myscript_iink/DeviceSize.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:myscript_iink/common.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/database.dart';

final sImportMemoManager = ImportMemoManager();

class ImportProgress {
  int memoCount;
  int importCount;

  ImportProgress clone({
    int memoCount,
    int importCount,
  }) =>
      ImportProgress.internal(
        memoCount ?? this.memoCount,
        importCount ?? this.importCount,
      );

  ImportProgress.internal(int memoCount, int importCount) {
    this.memoCount = memoCount;
    this.importCount = importCount;
  }
}

class ImportMemoManager {
  final _progressStreamController =
      StreamController<ImportProgress>.broadcast();

  Stream<ImportProgress> get progressStream => _progressStreamController.stream;

  MemoSummary memoSummary;
  ImportProgress progress = ImportProgress.internal(0, 0);

  bool get isImporting =>
      (progress.memoCount != 0 && progress.memoCount != progress.importCount);

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  ImportMemoManager() {
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
  }

  resetData() async {
    progress = ImportProgress.internal(0, 0);
    memoSummary = await sNotepadManager.getMemoSummary();
    _progressStreamController.add(progress);
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    switch (event.state) {
      case NotepadState.Connected:
        sNotepadManager.getMemoSummary().then((memo) {
          memoSummary = memo;
        });
        break;
      default:
        break;
    }
  }

  startImport() async {
    if (isImporting || memoSummary.memoCount == 0) return;

    progress = progress.clone(memoCount: memoSummary.memoCount);
    _progressStreamController.add(progress);

    await sPreferencesManager.setLastImportTime();

    do {
      //  TODO 同步方法，可能失败（修改SDK）
      MemoData memoData = await sNotepadManager.importMemo();
      await handleSaveMemoData(memoData);
      await sNotepadManager.deleteMemo();
      progress = progress.clone(
        importCount: progress.importCount + 1,
      );
      _progressStreamController.add(progress);
    } while (progress.importCount < progress.memoCount);

    print('------import finish');
    await resetData();
  }

  Future<List<IINKPointerEventFlutter>> handleSaveMemoData(
      MemoData memoData) async {
    print('handleSaveMemoData');

    var pointerEvents = List<IINKPointerEventFlutter>();

    IINKPointerEventFlutter _prePointer = IINKPointerEventFlutter.shared;
    for (var pointer in memoData.pointers) {
      var pe = await handlePointerEvent(_prePointer.eventType, pointer);
      if (pe != null) {
        pointerEvents.add(pe);
        _prePointer = pe;
      }
    }

    if (pointerEvents.length > 0) {
      if (pointerEvents.last.eventType != IINKPointerEventTypeFlutter.up) {
        pointerEvents.add(pointerEvents.last
            .clone(eventType: IINKPointerEventTypeFlutter.up));
      }

      //  2000年前的笔记，证明设备未校准时间，按当前时间存储(设备m级，笔记ms级)
      var importNoteCreatetime = (memoData.memoInfo.createdAt * 1000) >
              DateTime.utc(2000).millisecondsSinceEpoch
          ? memoData.memoInfo.createdAt * 1000
          : DateTime.now().millisecondsSinceEpoch;
      final importNote = await Note.init_InDB(importNoteCreatetime);
      await sNoteProvider.update(importNote.createTime,
          state: NoteStateDescription(DBTRState.available));
      var path = (await importNote.getNoteFile()).path;
      var importEditorController = await EditorController.create(path);
      (await File(path).exists())
          ? await importEditorController.openPackage(path)
          : await importEditorController.createPackage(path);
      await importEditorController.syncPointerEvents(pointerEvents);
      await importNote.saveAll(importEditorController);
      await importEditorController.close();
    }
  }

  //  TODO 拿出
  Future<IINKPointerEventFlutter> handlePointerEvent(
      IINKPointerEventTypeFlutter _preEventType, NotePenPointer pointer) async {
    IINKPointerEventTypeFlutter eventType;
    switch (_preEventType) {
      case IINKPointerEventTypeFlutter.down:
        if (pointer.p > 0) {
          eventType = IINKPointerEventTypeFlutter.move;
        } else {
          eventType = IINKPointerEventTypeFlutter.up;
        }
        break;
      case IINKPointerEventTypeFlutter.move:
        if (pointer.p > 0) {
          eventType = IINKPointerEventTypeFlutter.move;
        } else {
          eventType = IINKPointerEventTypeFlutter.up;
        }
        break;
      case IINKPointerEventTypeFlutter.up:
        if (pointer.p > 0) {
          eventType = IINKPointerEventTypeFlutter.down;
        }
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
      return pointerEventFlutter;
    }
    return null;
  }
}
