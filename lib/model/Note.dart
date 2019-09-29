import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ugee_note/model/NoteSkin.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/util/FileImageEx.dart';

import 'database.dart';
import 'package:http/http.dart' as http;

class Note {
  static const _TABLE_NAME = "Note";

  static const CREATE_TIME = "createTime";
  static const STATE = "state";
  static const CLOUD_ID = "cloudID";
  static const FILE_NAME = "fileName";
  static const THUMB_NAME = "thumbName";
  static const CONVERT = "convert";
  static const SKIN_ID = "skinID";
  static const TAGS = "tags";
  static const LAST_MODIFY = "lastModify";
  static const CONFIG_LAST_MODIFY = "configLastModify";
  static const REMARK = "remark";

  int createTime;
  int state;
  int cloudID;
  String fileName;
  String thumbName;
  String convert;
  int skinID;
  String tags;
  int lastModify;
  int configLastModify;
  String remark;

  static final shared = Note(
    createTime: 0,
    state: NoteStateDescription(DBTRState.unavailable),
    cloudID: -1,
    convert: '',
    skinID: NoteSkin.defaultSkinid,
    tags: '',
    remark: '',
  );

  Note clone({
    @required int createTime,
    int state,
    int cloudID,
    String convert,
    int skinID,
    String tags,
    int lastModify,
    int configLastModify,
    String remark,
  }) =>
      Note(
        createTime: createTime ?? this.createTime,
        state: state ?? this.state,
        cloudID: cloudID ?? this.cloudID,
        fileName: '${createTime ?? this.createTime}.pts',
        thumbName: '${createTime ?? this.createTime}.jpg',
        convert: convert ?? this.convert,
        skinID: skinID ?? this.skinID,
        tags: tags ?? this.tags,
        lastModify: lastModify ?? this.lastModify,
        configLastModify: configLastModify ?? this.configLastModify,
        remark: remark ?? this.remark,
      );

  Note({
    @required int createTime,
    int state,
    int cloudID,
    String fileName,
    String thumbName,
    String convert,
    int skinID,
    String tags,
    int lastModify,
    int configLastModify,
    String remark,
  })
      : createTime = createTime,
        state = state,
        cloudID = cloudID,
        fileName = '${createTime}.pts',
        thumbName = '${createTime}.jpg',
        convert = convert ?? '',
        skinID = skinID,
        tags = tags ?? '',
        lastModify = lastModify ?? createTime,
        configLastModify = configLastModify ?? createTime,
        remark = remark ?? '';

  Note._fromMap(Map<String, dynamic> map)
      : createTime = map[CREATE_TIME],
        state = map[STATE],
        cloudID = map[CLOUD_ID],
        fileName = map[FILE_NAME],
        thumbName = map[THUMB_NAME],
        convert = map[CONVERT],
        skinID = map[SKIN_ID],
        tags = map[TAGS],
        lastModify = map[LAST_MODIFY],
        configLastModify = map[CONFIG_LAST_MODIFY],
        remark = map[REMARK];

  Map<String, dynamic> _toMap() =>
      {
        CREATE_TIME: createTime,
        STATE: state,
        CLOUD_ID: cloudID,
        FILE_NAME: fileName,
        THUMB_NAME: thumbName,
        CONVERT: convert,
        SKIN_ID: skinID,
        TAGS: tags,
        LAST_MODIFY: lastModify,
        CONFIG_LAST_MODIFY: configLastModify,
        REMARK: remark,
      };

  Future<File> getNoteFile() async {
    var documentsDir = await getApplicationDocumentsDirectory();
    return File("${documentsDir.path}/$fileName");
  }

  Future<File> getThumbFile() async {
    var documentsDir = await getApplicationDocumentsDirectory();
    return File("${documentsDir.path}/$thumbName");
  }

  Widget getThumbImage(
      {String placeholder = 'icons/paper_thumb_placeholder.png'}) {
    return FutureBuilder(
      future: getThumbFile(),
      builder: (context, file) {
        if (file.data != null) {
          final img = Image(image: FileImageEx(file.data as File));
          if (img != null) return img;
        }
        return Image.asset(placeholder);
      },
    );
  }

  /*
   *  唯一：初始化一条note，添加到数据库
   */
  static Future<Note> init_InDB([int newCreateTime]) async {
    //  TODO 先查询，再增加（单独的方法、检查重复）
    final createTime = (newCreateTime != null)
        ? newCreateTime
        : DateTime
        .now()
        .millisecondsSinceEpoch;
    final note = Note.shared.clone(createTime: createTime);
    await sNoteProvider.insert(note);
    return note;
  }

  //  加载默认的笔记(没有笔记时)
  static void defaultInit() async {
    if ((await sNoteProvider.queryAll()).length == 0) {
      await createNote('https://shnote.woodemi.com/b8aa/100007862/59.pts', '1');
      await createNote('https://shnote.woodemi.com/b8aa/100007862/1157.pts', '1,2');
    }
  }

  static void createNote(String url, String tags) async {
    final note = await init_InDB();
    var response = await http.get(url);
    await (await note.getNoteFile()).writeAsBytesSync(response.bodyBytes);
    await sNoteProvider.update(note.createTime, tags: tags,
        state: NoteSkinStateDescription(DBTRState.available));
    var path = (await note.getNoteFile()).path;
    var controller = await EditorController.create(path);
    await controller.openPackage(path);
    await note.saveAll(controller);
  }

  NoteSkin getSkin() {
    for (final skin in sNoteSkinProvider.allNoteSkins)
      if (skinID == skin.id) return skin;
    return NoteSkin.shared;
  }

  //  保存所有
  saveAll(EditorController controller) async {
    if (controller != null) {
      await saveThumb(controller);
      await saveConvert(controller);
    }
  }

  //  save image
  Future<Uint8List> saveThumb(EditorController controller) async {
    final ByteData skinByteData = await rootBundle.load(getSkin().localImage);
    final Uint8List skinBytes = skinByteData.buffer.asUint8List();
    final imageBytes = await controller.exportJPG(skinBytes);
    final thumbFile = await getThumbFile();
    try {
      thumbFile.writeAsBytesSync(imageBytes);
    } catch (e) {
      print(e);
    }

    await sNoteProvider.update(createTime);
    return imageBytes;
  }

  //  save convert
  saveConvert(EditorController controller) async {
    final convert = await controller.exportText();
    await sNoteProvider.update(createTime, convert: convert);
  }
}

final sNoteProvider = NoteProvider._internal();

class NoteProvider extends DatabaseProvider {
  NoteProvider._internal() {
    open();
  }

  open() async {
    var path = join(await getDatabasesPath(), "note.db");
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS ${Note._TABLE_NAME} ('
          '${Note.CREATE_TIME} INTEGER PRIMARY KEY,'
          '${Note.STATE} INTEGER,'
          '${Note.CLOUD_ID} INTEGER,'
          '${Note.FILE_NAME} TEXT,'
          '${Note.THUMB_NAME} TEXT,'
          '${Note.CONVERT} TEXT,'
          '${Note.SKIN_ID} INTEGER,'
          '${Note.TAGS} TEXT,'
          '${Note.LAST_MODIFY} INTEGER,'
          '${Note.CONFIG_LAST_MODIFY} INTEGER,'
          '${Note.REMARK} TEXT'
          ')');
    });
    isOpened = true;

    await queryAvalible(true);
  }

  //  暂时用不到
  close() async => await db.close();

  Future<int> insert(Note note) async {
    if (!isOpened) await open();
    if ((await queryByCreateTime(note.createTime)) == null) {
      await (await note.getThumbFile()).createSync(recursive: true);
      final length = db.insert(Note._TABLE_NAME, note._toMap());
      _addDBChangeType(DBChangeType.insert);
      return length;
    }
    return 0;
  }

  Future<int> batchInsert(List<Note> notes) async {
    if (!isOpened) await open();
    var batch = db.batch();
    notes.forEach((p) => batch.insert(Note._TABLE_NAME, p._toMap()));
    final length = (await batch.commit()).length;
    _addDBChangeType(DBChangeType.insert);
    return length;
  }

  Future<int> delete(Note note) async {
    if (!isOpened) await open();
    final length = db.rawDelete(
        'DELETE FROM ${Note._TABLE_NAME} WHERE ${Note.CREATE_TIME} = ${note
            .createTime}',
        []);
    _addDBChangeType(DBChangeType.delete);
    return length;
  }

  Future<int> updateTagsByName(int createTime, String tagName,
      {bool isAdd = true}) async {
    await sTagProvider.insert(tagName);
    final note = await sNoteProvider.queryByCreateTime(createTime);
    final tag = await sTagProvider.queryByName(tagName);
    if (tag != null) {
      var newList = note.tags.split(',');
      String newTags = isAdd ? '${tag.id}' : '';
      newList.forEach((tagid) {
        if (tagid != null &&
            tagid.length > 0 &&
            tagid != 'null' &&
            tagid != '${tag.id}') {
          if (newTags.length > 0) newTags += ',';
          newTags += '${tagid}';
        }
      });
      return sNoteProvider.update(createTime, tags: newTags);
    }
    return 0;
  }

  Future<int> updateTags(int createTime, String tags,
      {bool isAdd = true}) async {
    final note = await queryByCreateTime(createTime);
    if (note == null) return 0;
    var oldTagsStr = note.tags.split(',');
    var tagsStr = tags.split(',');
    var newTagsStr = List<String>();
    newTagsStr.addAll(oldTagsStr);

    for (String tagStr in tagsStr) {
      if (isAdd) {
        if (!oldTagsStr.contains(tagsStr)) {
          newTagsStr.add(tagStr);
        }
      } else {
        if (oldTagsStr.contains(tagsStr)) {
          newTagsStr.remove(tagStr);
        }
      }
    }
    if (newTagsStr.length != oldTagsStr.length) {
      final tags = newTagsStr.reduce((a, b) => a + b);
      update(createTime, tags: tags);
    }
  }

  Future<int> update(int createTime, {
    int state = null,
    int cloudID = null,
    String convert = null,
    int skinID = null,
    String tags = null,
    int lastModify = null,
    int configLastModify = null,
    String remark = null,
  }) async {
    if (!isOpened) await open();
    var formater = '';
    var isUpdateLastModify = false;
    var isUpdateConfigLastModify = false;

    if (state != null) {
      isUpdateLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.STATE} = ${state}';
    }
    if (cloudID != null) {
      isUpdateLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.CLOUD_ID} = ${cloudID}';
    }
    if (convert != null) {
      isUpdateLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.CONVERT} = \'${SQL_FromatText(convert)}\'';
    }
    if (tags != null) {
      isUpdateLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.TAGS} = \'${tags}\'';
    }
    if (remark != null) {
      isUpdateLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.REMARK} = \'${SQL_FromatText(remark)}\'';
    }
    if (skinID != null) {
      isUpdateConfigLastModify = true;
      if (formater.length > 0) formater += ' ,';
      formater += '${Note.SKIN_ID} = ${skinID}';
    }
    if (lastModify != null || isUpdateLastModify) {
      if (formater.length > 0) formater += ' ,';
      formater +=
      '${Note.LAST_MODIFY} = ${lastModify != null ? lastModify : DateTime
          .now()
          .millisecondsSinceEpoch}';
    }
    if (configLastModify != null || isUpdateConfigLastModify) {
      if (formater.length > 0) formater += ' ,';
      formater +=
      '${Note.CONFIG_LAST_MODIFY} = ${configLastModify != null
          ? configLastModify
          : DateTime
          .now()
          .millisecondsSinceEpoch}';
    }

    if (formater.length == 0) return 0;

    final updateStr =
        'UPDATE ${Note._TABLE_NAME} SET ${formater} WHERE ${Note
        .CREATE_TIME} = ${createTime}';
    print('updateStr为： ${updateStr}');

    final length = await db.rawUpdate(updateStr, []);
    await _addDBChangeType(DBChangeType.update);
    if (tags != null) await sTagProvider.updateAllNoteNums();
    print('finish update db');
    return length;
  }

  var _allAvalibleNotes = List<Note>();

  Future<List<Note>> queryAvalible([bool forceQuery = false]) async {
    if (!isOpened) await open();
    if (forceQuery) {
      var queryResultSet = await db.rawQuery(
          'SELECT * FROM ${Note._TABLE_NAME} WHERE ${Note
              .STATE} = ${NoteStateDescription(DBTRState.available)}');
      _allAvalibleNotes =
          queryResultSet.map((map) => Note._fromMap(map)).toList();
    }
    return _allAvalibleNotes;
  }

  Future<List<Note>> queryAll() async {
    if (!isOpened) await open();
    var queryResultSet = await db.query(Note._TABLE_NAME);
    return queryResultSet.map((map) => Note._fromMap(map)).toList();
  }

  Future<List<Note>> queryByTag_ConvertKeyword(
      {int tagid, String keyword}) async {
    if (!isOpened) await open();
    var list = List<Note>();
    if (tagid != null) {
      list = await sTagProvider.queryNotesByTagID(tagid);
    } else {
      var queryResultSet = await db.rawQuery(
          'SELECT * FROM ${Note._TABLE_NAME} WHERE ${Note
              .CONVERT} LIKE \'%${keyword}%\'');
      list = queryResultSet.map((map) => Note._fromMap(map)).toList();
    }
    print('list.length-------------${list.length}');
    var notes = List<Note>();
    if (keyword != null && keyword.length > 0) {
      list.forEach((note) {
        if (note.convert.contains(keyword)) notes.add(note);
      });
    } else {
      return list;
    }
    print('notes.length-------------${notes.length}');
    return notes;
  }

  Future<List<Note>> queryByConvertKeyword(String keyword) async {
    if (!isOpened) await open();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${Note._TABLE_NAME} WHERE ${Note
            .CONVERT} LIKE \'%${keyword}%\'');
    final getNotes = queryResultSet.map((map) => Note._fromMap(map)).toList();
    return getNotes;
  }

  Future<Note> queryByCreateTime(int createTime) async {
    if (!isOpened) await open();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${Note._TABLE_NAME} WHERE ${Note
            .CREATE_TIME} = ${createTime}');
    final getNotes = queryResultSet.map((map) => Note._fromMap(map)).toList();
    if (getNotes.length > 0) {
      return getNotes.first;
    }
    return null;
  }

  Future<List<Tag>> queryTags(int createTime) async {
    final allTags = await sTagProvider.queryAvalible();
    final note = await queryByCreateTime(createTime);
    var listTag = List<Tag>();
    if (note != null) {
      if (note.tags.length == 0) return listTag;
      final tagsStr = note.tags.split(',');
      for (final tagStr in tagsStr) {
        if (tagStr != null && tagStr.length > 0 && tagStr != 'null') {
          final tagID = int.parse(tagStr);
          allTags.forEach((t) {
            if (t.id == tagID) listTag.add(t);
          });
        }
      }
    }
    return listTag;
  }

  _addDBChangeType(DBChangeType type) async {
    await queryAvalible(true);
    changeStreamController.add(type);
  }
}

///  note mock data
void noteMockData() async {
  final all = await sTagProvider.queryAvalible(true);
  if (all.length == 0) {
    final note = await Note.init_InDB(1564061914190);
    var path = (await note.getNoteFile()).path;
    note.saveAll(await EditorController.create(path));
    sNoteProvider.update(note.createTime,
        state: NoteStateDescription(DBTRState.available));
  }
}
