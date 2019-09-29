import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/iterables.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/pages/TagModule/TagDetailPage.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'package:ugee_note/pages/HomeModule/SearchPage.dart';
import 'TagSettingPage.dart';

class TagPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TagPageState();
  }
}

class _TagPageState extends State<TagPage> {
  StreamSubscription _tagSubscription;

  var _sections = List<Tag>();

  @override
  void initState() {
    super.initState();
    print('TagPage initState');

    _tagSubscription = sTagProvider.changeStream.listen(_onNoteChange);
    _onNoteChange(null);
  }

  @override
  void dispose() {
    super.dispose();
    print('TagPage dispose');
    _tagSubscription.cancel();
    _tagSubscription = null;
  }

  _onNoteChange(DBChangeType type) async {
    var tags = await sTagProvider.queryAvalible();
    setState(() => _sections
      ..clear()
      ..addAll(tags));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(
        context,
        Translations.of(context).text('tab_text_2'),
        titleStyle: TextStyle(fontSize: 24, color: Colors.black87),
        implyLeading: true,
        centerTitle: false,
        actions: <Widget>[
          appbarRighItem('icons/note_search.png', () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SearchPage()));
          }),
        ],
      ),
      body: _sections.length > 0 ? _buildListView() :emptyView(EmptyViewType.noTag, context),
    );
  }

  ListView _buildListView() {
    return ListView.builder(
      itemCount: 1,
      padding: EdgeInsets.symmetric(vertical: 21.0, horizontal: 18.0),
      itemBuilder: (BuildContext context, int index) {
        return Column(
          children: <Widget>[
            Table(
              children: partition(_sections, 2).map((items) {
                var itemWidgets = items.cast<Tag>().map(_buildItem).toList();
                var dummyWidgets =
                List.generate(items.length % 2, (index) => Container());
                return TableRow(children: itemWidgets..addAll(dummyWidgets));
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItem(Tag tag) => Container(
        margin: EdgeInsets.all(13),
        child: AspectRatio(
          aspectRatio: 136.0 / 181.0,
          child: GestureDetector(
            child: Stack(
              children: <Widget>[
                Align(
                  child: Image.asset(tag.getSkin().localImage),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 50,
                    height: 50,
                    child: FlatButton(
                      child: Image.asset('icons/setting.png',
                          width: 25, height: 25),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TagSettingPage(tag)));
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Container(
                      height: 40,
                      color: Colors.black26,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 30.0, horizontal: 9.0),
                    child: Text(tag.name,
                        style: TextStyle(color: Colors.white, fontSize: 13.5)),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 9.0),
                    child: Text(Translations.of(context).text('notes_less', '${tag.noteNums}'),
                        style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TagDetailPage(tag)));
            },
          ),
        ),
      );
}
