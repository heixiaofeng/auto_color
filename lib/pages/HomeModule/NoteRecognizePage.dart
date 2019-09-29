import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ugee_note/model/Note.dart';

import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/NormalDialog.dart';
import 'package:ugee_note/widget/widgets.dart';

class NoteRecognizePage extends StatefulWidget {
  NoteRecognizePage(this.covert);

  String covert;

  @override
  _NoteRecognizePageState createState() => _NoteRecognizePageState();
}

class _NoteRecognizePageState extends State<NoteRecognizePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(context, Translations.of(context).text('recognition_result')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              width: ScreenWidth,
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1),
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.covert),
            ),
          ),
          Container(
            height: 60,
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                ImageTextFlatButton('icons/note_copy.png', Translations.of(context).text('copy'), () {
                  Clipboard.setData(ClipboardData(text: widget.covert));
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => NormalDialog(message: Translations.of(context).text('copied')),
                  );
                }),
              ],
            ),
          )
        ],
      ),
    );
  }
}
