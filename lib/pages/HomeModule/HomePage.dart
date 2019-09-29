import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:myscript_iink/common.dart';
import 'package:myscript_iink/myscript_iink.dart';
import 'package:quiver/iterables.dart';

import 'package:flutter/widgets.dart';
import 'package:ugee_note/main.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/DateUtils.dart';
import 'package:ugee_note/widget/CustomRouteSlide.dart';
import 'package:ugee_note/widget/PickerCalendar.dart';
import 'package:ugee_note/widget/widgets.dart';
import 'package:ugee_note/manager/RealtimeManager.dart';

import 'package:ugee_note/widget/WDMAlertDialog.dart';
import 'ImportNotePage.dart';
import 'NoteBrowserPage.dart';
import 'SearchPage.dart';

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  StreamSubscription _noteSubscription;

  var _sections = Map<int, List<Note>>();

  var _editing = false;

  _setEditing(bool value) {
    _selectedNotes.clear();
    setState(() => _editing = value);
    BottomNavigationBarStreamController.add(_editing);
  }

  var _selectedNotes = List<Note>();

  final _scrollController = ScrollController();

  var _firstLoad = true;
  OverlayEntry _overlayEntry;

  @override
  void initState() {
    super.initState();
    print('HomePage initState');

    _firstLoad = true;

    _noteSubscription = sNoteProvider.changeStream.listen(_onNoteChange);
    _onNoteChange(null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState.show();
    });
  }

  @override
  void dispose() {
    super.dispose();
    print('HomePage dispose');
    _noteSubscription.cancel();
  }

  _onNoteChange(DBChangeType type) async {
    var papers = await sNoteProvider.queryAvalible();
    papers.sort((left, right) => right.lastModify.compareTo(left.lastModify));
    setState(() => _sections
      ..clear()
      ..addAll(groupBy(papers, _getSectionKey)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _editing ? _buildAppBarEditing(context) : _buildAppBar(context),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        color: color_background,
        child: _sections.length > 0
            ? _child()
            : emptyView(EmptyViewType.noNote, context),
        onRefresh: () async {
          if (!_firstLoad)
            Navigator.push(context, CustomRouteSlide(ImportNotePage()));
          _firstLoad = false;
        },
      ),
    );
  }

  Widget _child() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _sections.length,
            padding: EdgeInsets.symmetric(vertical: 21.0, horizontal: 18.0),
            itemBuilder: (BuildContext context, int index) =>
                _buildSectionView(_sections.entries.toList()[index]),
          ),
        ),
        if (_editing) _bottomSheet(),
      ],
    );
  }

  Widget _bottomSheet() {
    return Container(
      height: 80,
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ImageTextFlatButton(
            'icons/merge_black.png',
            Translations.of(context).text('merge'),
            () {
              if (_selectedNotes.length > 1)
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return WDMAlertDialog(
                      title: Translations.of(context)
                          .text('merge_selected_notes_less')
                          .replaceAll('{n}', '${_selectedNotes.length}'),
                      message:
                          Translations.of(context).text('merged_can_break'),
                      cancelText: Translations.of(context).text('Cancel'),
                      confimText: Translations.of(context).text('OK'),
                      type: Operation.NOTICE,
                      confim: (value) async {
                        await _mergeNote(_selectedNotes);
                        _setEditing(false);
                      },
                    );
                  },
                );
            },
            opacity: _selectedNotes.length > 1 ? 1 : 0.5,
          ),
          ImageTextFlatButton(
            'icons/delete_black.png',
            Translations.of(context).text('delete'),
            () {
              if (_selectedNotes.length > 0)
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) {
                    return WDMAlertDialog(
                      title: Translations.of(context)
                          .text('merge_selected_notes_less')
                          .replaceAll('{n}', '${_selectedNotes.length}'),
                      message:
                          Translations.of(context).text('deleted_no_recover'),
                      cancelText: Translations.of(context).text('Cancel'),
                      confimText: Translations.of(context).text('OK'),
                      type: Operation.NOTICE,
                      confim: (value) async {
                        for (final note in _selectedNotes) {
                          if (note.createTime ==
                              sRealtimeManager.note.createTime)
                            await sRealtimeManager.intoRealtime();
                          await sNoteProvider.update(note.createTime,
                              state: NoteStateDescription(
                                  DBTRState.localRecyclebin));
                        }
                        _setEditing(false);
                      },
                    );
                  },
                );
            },
            opacity: _selectedNotes.length > 0 ? 1 : 0.5,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return appbar(
      context,
      Translations.of(context).text('tab_text_1'),
      implyLeading: true,
      centerTitle: false,
      titleStyle: TextStyle(fontSize: 24, color: Colors.black87),
      actions: <Widget>[
        appbarRighItem('icons/note_search.png', () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => SearchPage()));
        }),
        appbarRighItem('icons/note_date.png', () {
          _overlayEntry = OverlayEntry(builder: (context) {
            var dateTimes = Map<int, DateTime>();
            _sections.keys.forEach((millis) {
              dateTimes[millis] = DateTime.fromMillisecondsSinceEpoch(millis);
            });
            return PickerCalendar(
              dateTimes: dateTimes.values.toList(),
              dismiss: () {
                _overlayEntry?.remove();
              },
              onDateSelected: (date) {
                _overlayEntry?.remove();
                for (final key in dateTimes.keys) {
                  final datetime = dateTimes[key];
                  if (datetime.year == date.year &&
                      datetime.month == date.month &&
                      datetime.day == date.day) {
                    double offset = 0.0;
                    double headerH = 20.0;
                    double itemH =
                        (ScreenWidth - 40 * 3) * 0.5 / (136.0 / 181.0);
                    for (final oldKey in _sections.keys) {
                      if (oldKey != key) {
                        offset += headerH;
                        offset += (_sections[oldKey].length / 2 +
                                _sections[oldKey].length % 2) *
                            itemH;
                      }
                    }
                    _scrollController.animateTo(offset,
                        duration: Duration(seconds: 1), curve: Curves.ease);
                    break;
                  }
                }
              },
            );
          });
          Overlay.of(context).insert(_overlayEntry);
        }),
        appbarRighItem('icons/note_import.png', () {
          Navigator.push(context, CustomRouteSlide(ImportNotePage()));
        }),
      ],
    );
  }

  AppBar _buildAppBarEditing(BuildContext context) {
    return appbar(
      context,
      Translations.of(context)
          .text('selected_notes', '${_selectedNotes.length}'),
      implyLeading: true,
      centerTitle: true,
      titleStyle: TextStyle(fontSize: 19, color: Colors.black87),
      actions: <Widget>[
        Container(
          width: 100,
          child: FlatButton(
            child: Text(Translations.of(context).text('Cancel'),
                style: TextStyle(
                    color: Color(0xFF3A3A3A),
                    fontSize: 17,
                    fontWeight: FontWeight.w400)),
            onPressed: () {
              setState(() => _setEditing(false));
            },
          ),
        )
      ],
    );
  }

  int _getSectionKey(Note paper) => DateUtils.getByDate(paper.createTime);

  Widget _buildSectionView(MapEntry<int, List<Note>> entry) => Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 20.0),
            child: Text(
              DateUtils.getDescriptionInDay(entry.key, context),
              style: TextStyle(fontSize: 16.0),
            ),
          ),
          Table(
            children: partition(entry.value, 2).map((items) {
              var itemWidgets = items.cast<Note>().map(_buildItem).toList();
              var dummyWidgets =
                  List.generate(items.length % 2, (index) => Container());
              return TableRow(children: itemWidgets..addAll(dummyWidgets));
            }).toList(),
          )
        ],
      );

  Widget _buildItem(Note note) {
    return Container(
      margin: EdgeInsets.all(13),
      child: AspectRatio(
        aspectRatio: 136.0 / 181.0,
        child: GestureDetector(
          child: Stack(
            children: <Widget>[
              Align(
                child: note.getThumbImage(),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 9.0),
                  child: Text(
                      "${HH_mm.format(DateTime.fromMillisecondsSinceEpoch(note.createTime))}"),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 9.0),
                    child: _editing
                        ? Image.asset(
                            _selectedNotes.contains(note)
                                ? 'icons/dot_selected.png'
                                : 'icons/dot_normal.png',
                            width: 10,
                            height: 10)
                        : (sRealtimeManager.note != null &&
                                note.createTime ==
                                    sRealtimeManager.note.createTime)
                            ? Image.asset('icons/intoEdit_Realtime.png',
                                width: 10, height: 10)
                            : null),
              ),
            ],
          ),
          onTap: () {
            if (_editing) {
              print(_selectedNotes.contains(note));
              setState(() {
                _selectedNotes.contains(note)
                    ? _selectedNotes.remove(note)
                    : _selectedNotes.add(note);
              });
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NoteBrowserPage(note)));
            }
          },
          onLongPress: () {
            if (!_editing) _setEditing(true);
          },
        ),
      ),
    );
  }

  _mergeNote(List<Note> notes) async {
    var mergePointEvents = List<IINKPointerEventFlutter>();

    for (var note in notes) {
      var isRealtime = sRealtimeManager.note.createTime == note.createTime;
      var path = (await note.getNoteFile()).path;
      var editorController = isRealtime
          ? sRealtimeManager.realtimeEditorController
          : await EditorController.create(path);
      if (!isRealtime)
        (await File(path).exists())
            ? await editorController.openPackage(path)
            : await editorController.createPackage(path);

      var _jiix = await editorController.exportJIIX();
      var _pointEvents = await editorController.parseJIIX(_jiix);
      print('_pointEvents = ${_pointEvents.length}');
      mergePointEvents.addAll(_pointEvents);
      await editorController.close();
    }

    print('mergePointEvents = ${mergePointEvents.length}');
    if (mergePointEvents.length > 0) {
      var mergeNote = await Note.init_InDB();
      sNoteProvider.update(mergeNote.createTime,
          state: NoteStateDescription(DBTRState.available));
      var path = (await mergeNote.getNoteFile()).path;
      var mergeEditorViewController = await EditorController.create(path);
      mergeEditorViewController.createPackage(path);
      await mergeEditorViewController.syncPointerEvents(mergePointEvents);
      await mergeNote.saveAll(mergeEditorViewController);
      await mergeEditorViewController.close();
    }
  }
}
