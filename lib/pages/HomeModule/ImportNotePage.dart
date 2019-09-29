import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/manager/ImportMemoManager.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

class ImportNotePage extends StatefulWidget {
  @override
  _ImportNotePageState createState() => _ImportNotePageState();
}

class _ImportNotePageState extends State<ImportNotePage> {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription<ImportProgress> _progressSubscription;

  String _imageName = "";
  String _centerText = "";

  @override
  void initState() {
    super.initState();
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _progressSubscription =
        sImportMemoManager.progressStream.listen(_onProgress);

    Future.delayed(Duration(milliseconds: 100),
        () => refreshState(state: sNotepadManager.notepadState));
  }

  @override
  void dispose() {
    super.dispose();
    _notepadStateSubscription.cancel();
    _progressSubscription.cancel();
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    refreshState(state: event.state);
  }

  _onProgress(ImportProgress progress) {
    setState(() {
      if (sImportMemoManager.memoSummary.memoCount == 0) {
        _imageName = 'images/import_note_empty.png';
        _centerText = Translations.of(context).text('no_offline_import');
      } else {
        if (sImportMemoManager.isImporting) {
          if (progress.importCount < progress.memoCount) {
            _imageName = 'images/import_note_circle.png'; //  TODO 同步中的动画
            _centerText =
            '${Translations.of(context).text('offline_importing')}：${progress.importCount}/${progress.memoCount}';
          } else {
            _imageName = 'images/import_note_circle.png';
            _centerText =
                Translations.of(context).text('notify_offline_import_success');
          }
        } else {
          _imageName = 'images/import_note_circle.png';
          _centerText = Translations.of(context).text('have_offline_import');
        }
      }
    });
  }

  refreshState({NotepadState state}) async {
    if ((state ?? sNotepadManager.notepadState) == NotepadState.Connected) {
      if (sImportMemoManager.memoSummary == null &&
          sNotepadManager.notepadState == NotepadState.Connected) {
        await sImportMemoManager.resetData();
      }
      _onProgress(sImportMemoManager.progress);
    } else {
      setState(() {
        _imageName = "images/import_note_empty.png";
        _centerText =
            Translations.of(context).text('please_connect_device_first');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          child: Container(
            margin: EdgeInsets.only(top: ScreenHeight * 0.2),
            alignment: Alignment.center,
            child: Image.asset(_imageName, width: 150, height: 150),
          ),
          onTap: () {
            sImportMemoManager.startImport();
          },
        ),
        Container(
          margin: EdgeInsets.only(top: 40),
          child: Text(_centerText,
              style: TextStyle(color: Colors.black54, fontSize: 13.5)),
        ),
        Expanded(
          child: GestureDetector(
            child: Container(
              color: color_background,
              width: ScreenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 10),
                    child:
                        Image.asset('icons/pullup.png', width: 15, height: 15),
                  ),
                  Container(
                    margin: EdgeInsets.only(bottom: 25),
                    child: Text(
                        Translations.of(context)
                            .text('pull_up_return_homepage'),
                        style:
                            TextStyle(color: Colors.black54, fontSize: 13.5)),
                  ),
                ],
              ),
            ),
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100)
                Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
