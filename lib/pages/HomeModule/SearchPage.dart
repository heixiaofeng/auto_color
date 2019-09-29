import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/DateUtils.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'package:ugee_note/pages/HomeModule/NoteBrowserPage.dart';

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage> {
  var _searchResultNote = List<Note>();
  var _searchResultTag = List<Tag>();
  var _allTags = List<Tag>();

  final _controller = TextEditingController();

  Tag _selectedTag;

  var _recordKWList = List<String>();

  String _keyword = '';

  _refreshKeyword(String value) {
    if (_controller.text != value) _controller.text = value;
    setState(() => _keyword = value);
    _refresh();
  }

  _refreshSelectedTag(Tag value) {
    setState(() => _selectedTag = value);
    _refresh();
  }

  _refresh() async {
    if (_keyword.length == 0 && _selectedTag == null) {
      var list = await sPreferencesManager.searchrecord;
      setState(() => _searchResultTag..clear());
      setState(() => _searchResultNote..clear());
      setState(() => _recordKWList
        ..clear()
        ..addAll(list));
      print(
          'refresh _recordKWList.length = ${_recordKWList.length} _keyword.lenght = ${_keyword.length}');
    } else {
      sNoteProvider
          .queryByTag_ConvertKeyword(
              tagid: _selectedTag != null ? _selectedTag.id : null,
              keyword: _keyword)
          .then((notes) {
        setState(() => _searchResultNote
          ..clear()
          ..addAll(notes));
      });
    }
  }

  @override
  void initState() {
    super.initState();

    print('SearchPage initState');

    sTagProvider.queryAvalible(false).then((tags) {
      setState(() => _allTags
        ..clear()
        ..addAll(tags));
    });
    _refreshKeyword('');
  }

  @override
  void dispose() {
    super.dispose();
    print('SearchPage dispose');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarSearch(
        context,
        _controller,
        (text) {
          print('changed ${text}');
          _refreshKeyword(text);
        },
        (text) {
          print('submmit ${text}');
          _refreshKeyword(text);
        },
        <Widget>[
          FlatButton(
            child: Text(Translations.of(context).text('Cancel'),
                style: TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 17,
                    fontWeight: FontWeight.w400)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        firstWidget: _selectedTag != null
            ? searchTagItem(
                _selectedTag.name, searchTagItemType.selected, () {})
            : null,
      ),
      body: Column(
        children: <Widget>[
          if (_selectedTag == null &&
              _keyword.length == 0 &&
              _allTags.length > 0)
            subTitle(Translations.of(context).text('all_labels')),
          if (_selectedTag == null &&
              _keyword.length == 0 &&
              _allTags.length > 0)
            tagList(_allTags),
          if (_selectedTag == null &&
              _keyword.length > 0 &&
              _searchResultTag.length > 0)
            subTitle(Translations.of(context).text('searched_tags')),
          if (_selectedTag == null &&
              _keyword.length > 0 &&
              _searchResultTag.length > 0)
            tagList(_searchResultTag),
          if (_selectedTag == null &&
              _recordKWList.length > 0 &&
              _keyword.length == 0)
            _recordList(),
          if (_searchResultNote.length > 0) _noteList(),
          if (_keyword.length == 0 &&
              _allTags.length == 0 &&
              _recordKWList.length == 0)
            Expanded(child: emptyView(EmptyViewType.noKeyword, context)),
          if (_keyword.length > 0 &&
              _searchResultTag.length == 0 &&
              _searchResultNote.length == 0)
            Expanded(child: emptyView(EmptyViewType.noSearchNote, context)),
        ],
      ),
    );
  }

  Container subTitle(String title) {
    return Container(
      padding: EdgeInsets.only(top: 10, left: 15, bottom: 10),
      alignment: Alignment.centerLeft,
      child: Text(title),
    );
  }

  Container tagList(List<Tag> list) {
    return Container(
      padding: EdgeInsets.only(left: 15, bottom: 10),
      alignment: Alignment.topLeft,
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 8.0, // gap between adjacent chips
        runSpacing: 4.0, // gap between lines
        children: <Widget>[
          for (final tag in list)
            searchTagItem(tag.name, searchTagItemType.selected, () {
              _refreshSelectedTag(tag);
            }),
        ],
      ),
    );
  }

  Widget _recordList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _recordKWList.length,
        itemBuilder: (context, index) {
          return _recordItem(_recordKWList[index], () {
            _refreshKeyword(_recordKWList[index]);
          }, () {
            _recordKWList.remove(_recordKWList[index]);
            sPreferencesManager.setSearchrecord(_recordKWList);
            _refreshKeyword(_keyword);
          });
        },
      ),
    );
  }

  Widget _recordItem(
      String keyword, VoidCallback selectCall, VoidCallback clearCall) {
    return GestureDetector(
      child: Container(
        width: ScreenWidth,
        height: 35,
        padding: EdgeInsets.only(left: 25, right: 25),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'icons/record_icon.png',
                  width: 20.0,
                  height: 20.0,
                ),
                Container(width: 10),
                Expanded(
                  child: Text(
                    keyword,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color(0xFF5A5A5A),
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  child: GestureDetector(
                    child: Icon(Icons.clear),
                    onTap: clearCall,
                  ),
                ),
              ],
            ),
            line(),
          ],
        ),
      ),
      onTap: selectCall,
    );
  }

  Widget _noteList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _searchResultNote.length,
        itemBuilder: (context, index) {
          return _noteItem(_searchResultNote[index]);
        },
      ),
    );
  }

  Widget _noteItem(Note note) {
    return GestureDetector(
      child: AspectRatio(
        aspectRatio: 307 / 84,
        child: Container(
          margin: EdgeInsets.only(top: 4, left: 25, bottom: 4, right: 25),
          padding: EdgeInsets.only(top: 10, left: 10, bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(2.5),
                child: note.getThumbImage(),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26, width: 0.5),
                  borderRadius: BorderRadius.circular(5.0),
                ),
              ),
              Container(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(height: 10),
                  Text(
                      "${HH_mm.format(DateTime.fromMillisecondsSinceEpoch(note.createTime))}",
                      style: TextStyle(fontSize: 13)),
                  Container(height: 5),
                  Text(
                    note.convert,
                    style: TextStyle(fontSize: 9),
                    maxLines: 2,
                  )
                ],
              ),
            ],
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1),
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => NoteBrowserPage(note)));
        if (_keyword.length > 0) {
          if (_recordKWList.contains(_keyword)) _recordKWList.remove(_keyword);
          _recordKWList.insert(0, _keyword);
          sPreferencesManager.setSearchrecord(_recordKWList);
          _refreshKeyword(_keyword);
        }
      },
    );
  }
}
