import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:ugee_note/model/database.dart';

class TagSkin {
  static const _TABLE_NAME = "TagSkin";
  static const ID = "id";
  static const STATE = "state";
  static const NAME = "name";
  static const LOCAL_IMAGE = "localImage";

  int id;
  int state;
  String name;
  String localImage;

  static int defaultSkinid = 1;
  static final shared = TagSkin(
    id: defaultSkinid,
    state: TagSkinStateDescription(DBTRState.available),
    name: '戴耳环的女人',
    localImage: 'images/tagskin1.png',
  );

  TagSkin clone({
    int id,
    int state,
    String name,
    String localImage,
  }) =>
      TagSkin(
        id: id ?? this.id,
        state: state ?? this.state,
        name: name ?? this.name,
        localImage: localImage ?? this.localImage,
      );

  TagSkin({
    int id,
    int state,
    String name,
    String localImage,
  })  : id = id,
        state = state,
        name = name,
        localImage = localImage;

  TagSkin._fromMap(Map<String, dynamic> map)
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

  //  加载默认的标签-背景图
  static void defaultInit() async {
    if ((await sTagSkinProvider.queryAvalibleTagSkins(true)).length == 0) {
      final name = [
        '戴耳环的女人',
        '迷宫',
        '初恋物语',
        '抽象人物',
        '猫和鱼',
        '海洋世界',
        '喵星人',
        '雨中漫步'
      ];
      for (final i in [0, 1, 2, 3, 4, 5, 6, 7]) {
        final tagskin = TagSkin.shared.clone(
            id: i + 1, name: name[i], localImage: 'images/tagskin${i + 1}.png');
        await sTagSkinProvider.insert(tagskin);
      }
    }
  }
}

final sTagSkinProvider = TagSkinProvider._internal();

class TagSkinProvider extends DatabaseProvider {
  TagSkinProvider._internal() {
    open();
  }

  open() async {
    var path = join(await getDatabasesPath(), "tagskin.db");
    db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('CREATE TABLE IF NOT EXISTS ${TagSkin._TABLE_NAME} ('
          '${TagSkin.ID} INTEGER,'
          '${TagSkin.STATE} INTEGER,'
          '${TagSkin.NAME} TEXT,'
          '${TagSkin.LOCAL_IMAGE} TEXT'
          ')');
    });
    isOpened = true;
  }

  //  暂时用不到
  close() async => await db.close();

  Future<int> insert(TagSkin skin) async {
    await openDB();
    var s = await queryByID(skin.id);
    if (s == null) {
      final length = db.insert(TagSkin._TABLE_NAME, skin._toMap());
      changeStreamController.add(DBChangeType.insert);
      _addDBChangeType(DBChangeType.insert);
      return length;
    }
    return 0;
  }

  Future<int> batchInsert(List<TagSkin> skins) async {
    await openDB();
    var batch = db.batch();
    skins.forEach((t) => batch.insert(TagSkin._TABLE_NAME, t._toMap()));
    final length = (await batch.commit()).length;
    _addDBChangeType(DBChangeType.insert);
    return length;
  }

  Future<int> delete(TagSkin skin) async {
    await openDB();
    final length = db.rawDelete(
        'DELETE FROM ${TagSkin._TABLE_NAME} WHERE ${TagSkin.ID} = ${skin.id}',
        []);
    _addDBChangeType(DBChangeType.delete);
    return length;
  }

  Future<int> updateState(TagSkin skin, [String name, int state]) async {
    await openDB();
    final length = db.rawUpdate(
        'UPDATE ${TagSkin._TABLE_NAME} SET ${TagSkin.STATE} = ${state} WHERE ${TagSkin.ID} = ${skin.id}',
        []);
    _addDBChangeType(DBChangeType.update);
    return length;
  }

  Future<TagSkin> queryByID(int skinid) async {
    await openDB();
    var queryResultSet = await db.rawQuery(
        'SELECT * FROM ${TagSkin._TABLE_NAME} WHERE ${TagSkin.ID} = ${skinid}');
    final getTags = queryResultSet.map((map) => TagSkin._fromMap(map)).toList();
    if (getTags.length != 0) return getTags.first;
    return null;
  }

  var _allTagSkins = List<TagSkin>();

  List<TagSkin> get allTagSkins => _allTagSkins;

  Future<List<TagSkin>> queryAvalibleTagSkins([bool forceQuery = false]) async {
    await openDB();
    if (forceQuery) {
      var queryResultSet = await db.query(TagSkin._TABLE_NAME);
      _allTagSkins =
          queryResultSet.map((map) => TagSkin._fromMap(map)).toList();
    }
    return _allTagSkins;
  }

  _addDBChangeType(DBChangeType type) async {
    await queryAvalibleTagSkins(true);
    changeStreamController.add(type);
  }

  Future<void> openDB() async {
    if (!isOpened) await open();
  }
}

///  tagskin mock data
void tagskinMockData() async {
  final all = await sTagSkinProvider.queryAvalibleTagSkins(true);
  if (all.length == 0) {
    //  Add mock data
  }
}
