
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqlite_api.dart';

enum DBChangeType {
  insert,
  delete,
  update,
}

/*
 *  数据库表，某一条数据的状态
 * 一、取值范围如下
 * 二、目前将只有字段：1、2、3、4
 * TODO "完全不可用"和"可用"之间还有一种"状态集"，称为：处理中。
 * TODO "处理中"可能但不限于以下状态：解析失败、解析中、等状态等，需要再增加一个"processingStatus"来表示
 */
enum DBTRState {
  unavailable,            //  完全不可用
  processing,             //  处理中
  available,              //  可用
  localRecyclebin,        //  放入本地回收站：与云端交互之前（可恢复）
  recyclebin,             //  放入回收站：与云端交互后（可恢复）
//  removeLocalRecyclebin,  //  从本地回收站中移除：与云端交互之前（产品上：不可恢复）
//  removrRecyclebin,       //  从回收站中移除：与云端交互后（产品上：不可恢复）
}

///  笔记状态枚举 => int
final _NoteStateDescriptions = {DBTRState.unavailable: 1, DBTRState.available: 2, DBTRState.localRecyclebin: 3, DBTRState.recyclebin: 4};
int NoteStateDescription(DBTRState state) {
  return _NoteStateDescriptions[state] ?? 1;
}

///  标签状态枚举 => int
final _TagStateDescriptions = {DBTRState.unavailable: 1, DBTRState.available: 2, DBTRState.localRecyclebin: 3, DBTRState.recyclebin: 4};
int TagStateDescription(DBTRState state) {
  return _TagStateDescriptions[state] ?? 1;
}

///  笔记背景图状态枚举 => int
final _NoteSkinStateDescriptions = {DBTRState.unavailable: 1, DBTRState.available: 2, DBTRState.localRecyclebin: 3, DBTRState.recyclebin: 4};
int NoteSkinStateDescription(DBTRState state) {
  return _NoteSkinStateDescriptions[state] ?? 1;
}

///  标签背景图状态枚举 => int
final _TagSkinStateDescriptions = {DBTRState.unavailable: 1, DBTRState.available: 2, DBTRState.localRecyclebin: 3, DBTRState.recyclebin: 4};
int TagSkinStateDescription(DBTRState state) {
  return _TagSkinStateDescriptions[state] ?? 1;
}

class DatabaseProvider {
  Database db;
  bool isOpened = false;

  final changeStreamController = StreamController<DBChangeType>.broadcast();

  Stream<DBChangeType> get changeStream => changeStreamController.stream;
}

SQL_FromatText(String text) {
  var retText = text.replaceAll("'", "''");
  retText = retText.replaceAll('"', '""');
  return retText;
}