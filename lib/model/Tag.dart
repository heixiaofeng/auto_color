import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ugee_note/model/NoteSkin.dart';
import 'package:ugee_note/model/TagSkin.dart';
import 'package:ugee_note/model/database.dart';

import 'Note.dart';

class Tag {
  static const _TABLE_NAME = "Tag";
  static const ID = "id";
  static const STATE = "state";
  static const NAME = "name";
  static const SKIN_ID = "skinID";
  static const NOTE_NUMS = "noteNums";

  int id;
  int state;
  String name;
  int skinID;
  int noteNums;

  static final shared = Tag(
    state: TagStateDescription(DBTRState.available),
    name: '',
    skinID: TagSkin.defaultSkinid,
    noteNums: 0,
  );

  Tag clone({
    int id,
    int state,
    String name,
    int skinID,
    int noteNums,
  }) =>
      Tag(
        id: id ?? this.id,
        state: state ?? this.state,
        name: name ?? this.name,
        skinID: skinID ?? this.skinID,
        noteNums: noteNums ?? this.noteNums,
      );

  Tag({
    @required int id,
    int state,
    String name,
    int skinID,
    int noteNums,
  })  : id = id,
        state = state,
        name = name,
        skinID = skinID,
        noteNums = noteNums;

  Tag._fromMap(Map<String, dynamic> map)
      : id = map[ID],
        state = map[STATE],
        name = map[NAME],
        skinID = map[SKIN_ID],
        noteNums = map[NOTE_NUMS];

  Map<String, dynamic> _toMap() => {
        ID: id,
        STATE: state,
        NAME: name,
        SKIN_ID: skinID,
        NOTE_NUMS: noteNums,
      };

  /*
   *  唯一：初始化一条tag，添加到数据库
   */
  static Future<Tag> init_InDB(String name) async {
    //  TODO 简称名字合法性（单独的方法、检查重复）
    final tag = Tag(
      state: TagStateDescription(DBTRState.available),
      name: '${name}',
      skinID: TagSkin.defaultSkinid,
      noteNums: 0,
    );
    await sTagProvider.insertTag(tag);
    return tag;
  }

  //  加载默认的标签
  static void defaultInit() async {
    if ((await sTagProvider.queryAll(true)).length == 0) {
      await init_InDB('Exercise Book');
      await init_InDB('Painting');
    }
  }

  TagSkin getSkin() {
    for (final skin in sTagSkinProvider.allTagSkins) {
      if (skinID == skin.id) return skin;
    }
    return TagSkin.shared;
  }
}

final sTagProvider = TagProvider._internal();

class TagProvider extends DatabaseProvider {
  TagProvider._internal() {
    open();
  }

  open() async {
    var path = join(await getDatabasesPath(), "tag.db");
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS ${Tag._TABLE_NAME} ('
          '${Tag.ID} INTEGER PRIMARY KEY AUTOINCREMENT,'
          '${Tag.STATE} INTEGER,'
          '${Tag.NAME} TEXT,'
          '${Tag.SKIN_ID} INTEGER,'
          '${Tag.NOTE_NUMS} INTEGER'
          ')');
    });
    isOpened = true;
  }

  //  暂时用不到
  close() async => await db.close();

  Future<int> insertTag(Tag tag) async {
    return await insert(tag.name);
  }

  Future<int> insert(String name) async {
    if (!isOpened) await open();
    await queryAvalible();
    final t = await queryByName(name);
    if (t == null) {
      final tag = Tag.shared.clone(name: name);
      final length = await db.insert(Tag._TABLE_NAME, tag._toMap());
      changeStreamController.add(DBChangeType.insert);
      _addDBChangeType(DBChangeType.insert);
      return length;
    }
    return 1;
  }

  Future<int> batchInsert(List<Tag> tags) async {
    if (!isOpened) await open();
    var batch = db.batch();
    tags.forEach((t) => batch.insert(Tag._TABLE_NAME, t._toMap()));
    final length = (await batch.commit()).length;
    _addDBChangeType(DBChangeType.insert);
    return length;
  }

  Future<int> delete(Tag tag) async {
    if (!isOpened) await open();
    final length = db.rawDelete(
        'DELETE FROM ${Tag._TABLE_NAME} WHERE ${Tag.ID} = ${tag.id}', []);
    _addDBChangeType(DBChangeType.delete);
    return length;
  }

  Future<int> update(int tagID,
      {int state = null,
      String name = null,
      int skinID = null,
      int noteNums = null}) async {
    if (!isOpened) await open();
    var formater = '';
    if (state != null) {
      if (formater.length > 0) formater += ' ,';
      formater += '${Tag.STATE} = ${state}';
    }
    if (name != null) {
      final t = await queryByName(name);
      if (t != null) return 0;
      if (formater.length > 0) formater += ' ,';
      formater += '${Tag.NAME} = \'${SQL_FromatText(name)}\'';
    }
    if (skinID != null) {
      if (formater.length > 0) formater += ' ,';
      formater += '${Tag.SKIN_ID} = \'${skinID}\'';
    }
    if (noteNums != null) {
      if (formater.length > 0) formater += ' ,';
      formater += '${Tag.NOTE_NUMS} = \'${noteNums}\'';
    }
    if (formater.length == 0) return 0;

    final length = await db.rawUpdate(
        'UPDATE ${Tag._TABLE_NAME} SET ${formater} WHERE ${Tag.ID} = ${tagID}',
        []);
    _addDBChangeType(DBChangeType.update);
    return length;
  }

  Future<void> updateAllNoteNums() async {
    if (!isOpened) await open();
    final _allTags = await queryAll(true);
    for (final tag in _allTags) await queryNotesByTagID(tag.id);
    _addDBChangeType(DBChangeType.update);
  }

  Future<int> updateNoteNums(int tagID, int noteNums) async {
    if (!isOpened) await open();
    if (noteNums == null) return 0;
    final length = await db.rawUpdate(
        'UPDATE ${Tag._TABLE_NAME} SET ${Tag.NOTE_NUMS} = \'${noteNums}\' WHERE ${Tag.ID} = ${tagID}',
        []);
    return length;
  }

  var _allAvalibaleTags = List<Tag>();

  Future<List<Tag>> queryAll([bool forceQuery = false]) async {
    if (!isOpened) await open();
    if (forceQuery) {
      var queryResultSet = await db.query(Tag._TABLE_NAME);
      _allAvalibaleTags =
          queryResultSet.map((map) => Tag._fromMap(map)).toList();
    }
    return _allAvalibaleTags;
  }

  Future<List<Tag>> queryAvalible([bool forceQuery = false]) async {
    if (!isOpened) await open();
    if (forceQuery) {
      var queryResultSet = await db.rawQuery(
          'SELECT * FROM ${Tag._TABLE_NAME} WHERE ${Tag.NOTE_NUMS} > 0');
      _allAvalibaleTags =
          queryResultSet.map((map) => Tag._fromMap(map)).toList();
    }
    return _allAvalibaleTags;
  }

  Future<List<Note>> queryNotesByTagID(int tagID) async {
    if (!isOpened) await open();
    final _allAvalibleNotes = await sNoteProvider.queryAvalible();
    var notes = List<Note>();
    for (final note in _allAvalibleNotes) {
      final tagsStr = note.tags.split(',');
      if (tagsStr.contains('${tagID}')) notes.add(note);
    }
    await sTagProvider.updateNoteNums(tagID, notes.length);
    return notes;
  }

  Future<Tag> queryByID(int tagID) async {
    if (!isOpened) await open();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${Tag._TABLE_NAME} WHERE ${Tag.ID} = ${tagID}');
    final getTags = queryResultSet.map((map) => Tag._fromMap(map)).toList();
    if (getTags.length > 0) return getTags.first;
    return null;
  }

  Future<Tag> queryByName(String name) async {
    if (!isOpened) await open();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${Tag._TABLE_NAME} WHERE ${Tag.NAME} = \'${name}\'');
    final getTags = queryResultSet.map((map) => Tag._fromMap(map)).toList();
    if (getTags.length > 0) return getTags.first;
    return null;
  }

  Future<List<Tag>> queryByNameKeyword(String keyword) async {
    if (!isOpened) await open();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${Tag._TABLE_NAME} WHERE ${Tag.NAME} LIKE \'%${keyword}%\'');
    final getTags = queryResultSet.map((map) => Tag._fromMap(map)).toList();
    return getTags;
  }

  _addDBChangeType(DBChangeType type) async {
    await queryAvalible(true);
    changeStreamController.add(type);
  }
}

///  tag mock data
void tagMockData() async {
  final all = await sTagProvider.queryAvalible(true);
  if (all.length == 0) {
    await Tag.init_InDB('练习册');
  }
}
