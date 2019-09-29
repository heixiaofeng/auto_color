import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ugee_note/model/database.dart';

class NoteSkin {
  static const _TABLE_NAME = "NoteSkin";
  static const ID = "id";
  static const STATE = "state";
  static const NAME = "name";
  static const LOCAL_IMAGE = "localImage";

  int id;
  int state;
  String name;
  String localImage;

  static int defaultSkinid = 1;
  static final shared = NoteSkin(
    id: defaultSkinid,
    state: NoteSkinStateDescription(DBTRState.available),
    name: '本白纸',
    localImage: 'images/noteskin1.png',
  );

  NoteSkin clone({
    int id,
    int state,
    String name,
    String localImage,
  }) =>
      NoteSkin(
        id: id ?? this.id,
        state: state ?? this.state,
        name: name ?? this.name,
        localImage: localImage ?? this.localImage,
      );

  NoteSkin({
    int id,
    int state,
    String name,
    String localImage,
  })  : id = id,
        state = state,
        name = name,
        localImage = localImage;

  NoteSkin._fromMap(Map<String, dynamic> map)
      : id = map[ID],
        state = map[STATE],
        name = map[NAME],
        localImage = map[LOCAL_IMAGE];

  Map<String, dynamic> _toMap() => {
        ID: id,
        STATE: state,
        NAME: name,
        LOCAL_IMAGE: localImage,
      };

  //  TODO 简称名字合法性（单独的方法、检查重复）

  //  加载默认的笔记-背景图
  static void defaultInit() async {
    if ((await sNoteSkinProvider.queryAvalibleNoteSkins(true)).length == 0) {
      final name = ['本白纸', '点阵纸', '方格纸', '英文'];
      for (final i in [0, 1, 2, 3]) {
        final noteskin = NoteSkin.shared.clone(
            id: i + defaultSkinid,
            name: name[i],
            localImage: 'images/noteskin${i + 1}.png');
        await sNoteSkinProvider.insert(noteskin);
      }
    }
  }
}

final sNoteSkinProvider = NoteSkinProvider._internal();

class NoteSkinProvider extends DatabaseProvider {
  NoteSkinProvider._internal() {
    open();
  }

  open() async {
    var path = join(await getDatabasesPath(), "noteskin.db");
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS ${NoteSkin._TABLE_NAME} ('
          '${NoteSkin.ID} INTEGER,'
          '${NoteSkin.STATE} INTEGER,'
          '${NoteSkin.NAME} TEXT,'
          '${NoteSkin.LOCAL_IMAGE} TEXT'
          ')');
    });
    isOpened = true;
  }

  //  暂时用不到
  close() async => await db.close();

  Future<int> insert(NoteSkin skin) async {
    await openDB();
    var s = await queryByID(skin.id);
    if (s == null) {
      final length = db.insert(NoteSkin._TABLE_NAME, skin._toMap());
      changeStreamController.add(DBChangeType.insert);
      _addDBChangeType(DBChangeType.insert);
      return length;
    }
    return 0;
  }

  Future<int> batchInsert(List<NoteSkin> skins) async {
    await openDB();
    var batch = db.batch();
    skins.forEach((t) => batch.insert(NoteSkin._TABLE_NAME, t._toMap()));
    final length = (await batch.commit()).length;
    _addDBChangeType(DBChangeType.insert);
    return length;
  }

  Future<int> updateState(NoteSkin skin, [String name, int state]) async {
    await openDB();
    final length = db.rawUpdate(
        'UPDATE ${NoteSkin._TABLE_NAME} SET ${NoteSkin.STATE} = ${state} WHERE ${NoteSkin.ID} = ${skin.id}',
        []);
    _addDBChangeType(DBChangeType.update);
    return length;
  }

  Future<int> delete(NoteSkin skin) async {
    await openDB();
    final length = db.rawDelete(
        'DELETE FROM ${NoteSkin._TABLE_NAME} WHERE ${NoteSkin.ID} = ${skin.id}',
        []);
    _addDBChangeType(DBChangeType.delete);
    return length;
  }

  var _allNoteSkins = List<NoteSkin>();

  List<NoteSkin> get allNoteSkins => _allNoteSkins;

  Future<List<NoteSkin>> queryAvalibleNoteSkins(
      [bool forceQuery = false]) async {
    await openDB();
    if (forceQuery) {
      var queryResultSet = await db.query(NoteSkin._TABLE_NAME);
      _allNoteSkins =
          queryResultSet.map((map) => NoteSkin._fromMap(map)).toList();
    }
    return _allNoteSkins;
  }

  Future<NoteSkin> queryByID(int skinid) async {
    await openDB();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${NoteSkin._TABLE_NAME} WHERE ${NoteSkin.ID} = ${skinid}');
    final getTags =
        queryResultSet.map((map) => NoteSkin._fromMap(map)).toList();
    if (getTags.length > 0) return getTags.first;
    return null;
  }

  _addDBChangeType(DBChangeType type) async {
    await queryAvalibleNoteSkins(true);
    changeStreamController.add(type);
  }

  Future<void> openDB() async {
    if (!isOpened) await open();
  }
}

///  noteskin mock data
void noteskinMockData() async {
  //  Add mock data
}
