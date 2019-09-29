import 'dart:core';

import 'package:flutter/material.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/TagSkin.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/pages/HomeModule/NoteBrowserPage.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/widget/widgets.dart';

class TagDetailPage extends StatefulWidget {
  TagDetailPage(this.tag);

  Tag tag;

  @override
  _TagDetailPageState createState() => _TagDetailPageState();
}

class _TagDetailPageState extends State<TagDetailPage> {
  var _notes = List<Note>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _onNoteChange(null);
  }

  _onNoteChange(DBChangeType type) async {
    var papers = await sTagProvider.queryNotesByTagID(widget.tag.id);
    _notes
      ..clear()
      ..addAll(papers);
    setState(() {
      _notes.insert(0, Note.shared);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(context, widget.tag.name),
      body: Container(
        color: color_background,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.0 / 1.2,
            child: GestureDetector (
              child: Container(
                margin: const EdgeInsets.only(
                  top: 20,
                  left: 20,
                  bottom: 20,
                  right: 20,
                ),
                child: FlatButton(
                  child: (_selectedIndex == 0)
                      ? Image.asset(widget.tag.getSkin().localImage)
                      : _notes[_selectedIndex].getThumbImage(),
                  onPressed: () {
                    if (_selectedIndex > 0) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NoteBrowserPage(_notes[_selectedIndex])));
                    }
                  },
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dy < -100) {
                  if (_selectedIndex > 0)
                    setState(() => _selectedIndex -= 1);
                } else if (details.velocity.pixelsPerSecond.dy > 100) {
                  if (_selectedIndex < _notes.length - 1)
                    setState(() => _selectedIndex += 1);
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                return _buildItem(index);
              },
            ),
          )
        ]);
  }

  Widget _buildItem(int index) {
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.only(top: 10, left: 10, bottom: 30, right: 10),
        child: Stack(
          children: <Widget>[
            (index == 0)
                ? Image.asset(widget.tag.getSkin().localImage)
                : _notes[index].getThumbImage(),
            if (_selectedIndex == index)
              Opacity(
                  opacity: 0.5, child: Image.asset('icons/selected_note.png')),
          ],
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
      },
    );
  }
}
