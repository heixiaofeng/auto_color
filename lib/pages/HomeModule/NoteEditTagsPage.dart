import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/database.dart';

import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

class NoteEditTagsPage extends StatefulWidget {
  NoteEditTagsPage(this.note);

  Note note;

  @override
  _NoteEditTagsPageState createState() => _NoteEditTagsPageState();
}

class _NoteEditTagsPageState extends State<NoteEditTagsPage> {
  //  TODO listView: _searchResultTags
  //  TODO onTap: _tags(删除)
  //  TODO onTap: _allTags(选中)
  //  TODO 按键删除
  //  TODO 提示语
  //  TODO 上下两部分布局

  StreamSubscription _tagSubscription;

  var _tags = List<Tag>();
  var _allTags = List<Tag>();
  var _searchResultTags = List<Tag>();
  String _keyword = '';

  Tag highlightTag;

  _setKeyWord(String value) {
    setState(() {
      _keyword = value;
      if (controller.text != _keyword) controller.text = _keyword;
    });
    _refreshTags();
  }

  _refreshTags() {
    sNoteProvider.queryTags(widget.note.createTime).then((ts) {
      setState(() => _tags
        ..clear()
        ..addAll(ts));
    });
    if (_keyword.length > 0) {
      sTagProvider.queryByNameKeyword(_keyword).then((ts) {
        setState(() => _searchResultTags
          ..clear()
          ..addAll(ts));
      });
    } else {
      sTagProvider.queryAvalible(false).then((ts) {
        setState(() => _allTags
          ..clear()
          ..addAll(ts));
      });
    }
  }

  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    _setKeyWord(_keyword);

    _tagSubscription = sTagProvider.changeStream.listen(_onTagChange);
    _onTagChange(null);
  }

  @override
  void dispose() {
    super.dispose();
    _tagSubscription.cancel();
  }

  _onTagChange(DBChangeType type) async {
    _setKeyWord('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(context, Translations.of(context).text('label_edit_title')),
      body: Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          children: <Widget>[
            _tagsList(
              _tags,
              lastAddItem: addTagItem(
                '+${Translations.of(context).text('add_label')}',
                controller: controller,
                onChanged: (text) {
                  _setKeyWord(text);
                },
                onSubmitted: (text) async {
                  await sNoteProvider.updateTagsByName(
                      widget.note.createTime, text,
                      isAdd: true);
                  widget.note = await sNoteProvider
                      .queryByCreateTime(widget.note.createTime);
                  _refreshTags();
                },
              ),
            ),
            if (_keyword.length == 0)
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                child: Text(Translations.of(context).text('my_label')),
              ),
            if (_keyword.length > 0)
              Container(
                height: 50,
                alignment: Alignment.centerLeft,
                child: Text(Translations.of(context).text('searched_tags')),
              ),
            if (_keyword.length == 0) _alltagList(_allTags),
            if (_keyword.length > 0) _alltagList(_searchResultTags),
          ],
        ),
      ),
    );
  }

  Container _alltagList(List<Tag> list) {
    return Container(
      alignment: Alignment.topLeft,
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, // gap between lines
        children: <Widget>[
          for (final tag in list)
            searchTagItem(
                tag.name,
                _tagsContains(tag)
                    ? searchTagItemType.selected
                    : searchTagItemType.normal, () async {
              await sNoteProvider.updateTagsByName(
                  widget.note.createTime, tag.name,
                  isAdd: !_tagsContains(tag));
              widget.note =
                  await sNoteProvider.queryByCreateTime(widget.note.createTime);
              _refreshTags();
            }),
        ],
      ),
    );
  }

  Container _tagsList(List<Tag> list, {Widget lastAddItem}) {
    return Container(
      alignment: Alignment.topLeft,
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, // gap between lines
        children: <Widget>[
          for (final tag in list)
            searchTagItem(
                tag.name,
                (highlightTag == null || tag.id != highlightTag.id)
                    ? searchTagItemType.selected
                    : searchTagItemType.highlight, () async {
              if (highlightTag == null || tag.id != highlightTag.id) {
                setState(() => highlightTag = tag);
              } else {
                await sNoteProvider.updateTagsByName(
                    widget.note.createTime, tag.name,
                    isAdd: false);
                widget.note = await sNoteProvider
                    .queryByCreateTime(widget.note.createTime);
                _refreshTags();
              }
            }),
          if (lastAddItem != null) lastAddItem,
        ],
      ),
    );
  }

  bool _tagsContains(Tag tag) {
    for (final t in _tags) {
      if (t.id == tag.id) {
        return true;
      }
    }
    return false;
  }
}
