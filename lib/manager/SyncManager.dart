import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:myscript_iink/EditorController.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/database.dart';
import 'package:woodemi_service/StorageService.dart';
import 'package:woodemi_service/common.dart';
import 'package:woodemi_service/storage.dart';

import 'AccountManager.dart';
import 'StorageManager.dart';

final _logger = Logger("SyncManager");

class SyncManager {
  static Future<List<NoteInfo>> fetchCloudNotes() async {
    try {
      _logger.info('云同步前先：下载Aliyun-OSS配置信息');
      await sAccountManager.refreshAccesstoken();
      storageService.uid = sAccountManager.loginInfo.userInfo.uid;
      storageService.accessToken =
          sAccountManager.loginInfo.userInfo.accessToken;
      storageService.init();

      _logger.info('拉取云端所有笔记');
      await sAccountManager.refreshAccesstoken();
      storageService.accessToken =
          sAccountManager.loginInfo.userInfo.accessToken;
      var noteInfos = await storageService.listNotes(0, 0, 1000);
      return noteInfos;
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  static Future<int> createCloudNote(int createTime) async {
    _logger.info('创建云端笔记');
    var cloudNote = await storageService.createNote(createTime);
    await sNoteProvider.update(createTime, cloudID: cloudNote.id);
    return cloudNote.id;
  }

  static Future<void> uploadLocalNoteConfig(int localCreateTime) async {
    var localNote = await sNoteProvider.queryByCreateTime(localCreateTime);
    _logger.info('上传笔记的配置信息');
    try {
      storageService.putNoteConfig(localNote.cloudID, {
        'lastModify': localNote.configLastModify,
        'background': localNote.skinID,
      });
      _logger.info('上传笔记的配置信息--完成');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  static Future<void> downloadCloudConfig(
      NoteInfo cloudNote, int localCreateTime) async {
    var localNote = await sNoteProvider.queryByCreateTime(localCreateTime);
    _logger.info('下载笔记的配置信息');
    try {
      var noteInfo = await storageService.getNoteInfo(localNote.cloudID);
      await sNoteProvider.update(localNote.createTime,
          configLastModify: noteInfo.config['lastModify'],
          skinID: int.parse(noteInfo.config['background']));
      _logger.info('下载笔记的配置信息--完成');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  static Future<void> deleteCloudNote(NoteInfo note) async {
    _logger.info('删除云端笔记');
    try {
      await storageService.deleteNote(note.id);
      _logger.info('删除云端笔记--完成');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  /// local
  static deleteLocalNote(int localCreateTime) async {
    var localNote = await sNoteProvider.queryByCreateTime(localCreateTime);
    _logger.info('删除本地笔记');
    // 标记为彻底删除，但未真删除
    await sNoteProvider.update(localNote.createTime,
        state: NoteStateDescription(DBTRState.recyclebin));
  }

  /// local： 依据file、config生成最新的图片等
  static createPicCovert(int localCreateTime) async {
    var localNote = await sNoteProvider.queryByCreateTime(localCreateTime);
    _logger.info('生成笔记的图片等');
    try {
      var path = (await localNote.getNoteFile()).path;
      final realtimeEditorController = await EditorController.create(path);
      await realtimeEditorController.openPackage(path);
      await localNote.saveAll(realtimeEditorController);

      if (localNote.state == NoteStateDescription(DBTRState.unavailable))
        await sNoteProvider.update(localNote.createTime,
            state: NoteStateDescription(DBTRState.available));
      await realtimeEditorController.close();
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  /**************************************************云同步**************************************************/
  static startCloudSync() async {
    print('--------------startCloudSync--------------');
    try {
      ///  cloud to dic
      var cloudNotes = await fetchCloudNotes();
      var cloudNotes_dic = HashMap<int, NoteInfo>();
      cloudNotes.map((cloudNote) {
        cloudNotes_dic[cloudNote.createTime] = cloudNote;
      });

      ///  local to dic
      var localAllNotes = await sNoteProvider.queryAll();
      var localAllNotes_dic = HashMap<int, Note>();
      localAllNotes.map((note) {
        localAllNotes_dic[note.createTime] = note;
      });

      print('cloudNotes==== ${cloudNotes.length}');
      print('localAllNotes==== ${localAllNotes.length}');

      /*
       *  case1：云端没有，本地有；因本地有cloudID，-》云端原来有，现在已删除
       *  case2：云端没有，本地有；因本地没有cloudID，-》本地是新建，从未上传过
       *  case3：云端有，本地有；-》本地已删除
       *  case4：云端有，本地有；-》本地lastModify新，本地configLastModify不旧
       *  case5：云端有，本地有；-》本地lastModify新，本地configLastModify旧
       *  case6：云端有，本地有；-》本地云端lastModify同，本地configLastModify新
       *  case7：云端有，本地有；-》本地 == 云端
       *  case8：云端有，本地有；-》本地云端lastModify同，本地configLastModify旧
       *  case9：云端有，本地有；-》本地lastModify旧，本地configLastModify不新
       *  case10：云端有，本地有；-》本地lastModify旧，本地configLastModify新
       *  case11：云端有，本地没有；-》云端新建，本地无。
       */

      ///  以本地所有的notes为基础进行遍历
      var futures1 = localAllNotes.map((localNote) async {
        var localCreateTime = localNote.createTime;
        final cloudNote = cloudNotes_dic[localCreateTime];
        if (cloudNote == null) {
          //  云端没有
          if (localNote.state == NoteStateDescription(DBTRState.recyclebin)) {
            //  case1：云端没有，本地有；因本地有cloudID，-》云端原来有，现在已删除
            await deleteLocalNote(localCreateTime);
          } else {
            //  case2：云端没有，本地有；因本地没有cloudID，-》本地是新建，从未上传过
            if (localNote.cloudID == -1)
              localNote.cloudID = await createCloudNote(localCreateTime);
            await uploadLocalNoteConfig(localCreateTime);
            await StorageManager.uploadLocalNotePic(localCreateTime);
            await StorageManager.uploadLocalNoteFile(localCreateTime);
          }
        } else {
          ///  云端有id，本地无id，需绑定
          if (localNote.cloudID == -1)
            await sNoteProvider.update(localCreateTime, cloudID: cloudNote.id);

          if (localNote.state ==
              NoteStateDescription(DBTRState.localRecyclebin)) {
            //  case3：云端有，本地有；-》本地已删除
            await deleteCloudNote(cloudNote);
            await deleteLocalNote(localCreateTime);
          } else {
            if (localNote.lastModify > cloudNote.lastModify) {
              if (localNote.configLastModify >=
                  cloudNote.config['lastModify']) {
                //  case4：云端有，本地有；-》本地lastModify新，本地configLastModify不旧
                await StorageManager.uploadLocalNotePic(localCreateTime);
                await uploadLocalNoteConfig(localCreateTime);
                await StorageManager.uploadLocalNoteFile(localCreateTime);
              } else {
                //  case5：云端有，本地有；-》本地lastModify新，本地configLastModify旧
                await downloadCloudConfig(cloudNote, localCreateTime);
                await createPicCovert(localCreateTime);
                await StorageManager.uploadLocalNotePic(localCreateTime);
                await StorageManager.uploadLocalNoteFile(localCreateTime);
              }
            } else if (localNote.lastModify == cloudNote.lastModify) {
              if (localNote.configLastModify > cloudNote.config['lastModify']) {
                //  case6：云端有，本地有；-》本地云端lastModify同，本地configLastModify新
                await StorageManager.uploadLocalNotePic(localCreateTime);
                await uploadLocalNoteConfig(localCreateTime);
              } else if (localNote.configLastModify ==
                  cloudNote.config['lastModify']) {
                //  case7：云端有，本地有；-》本地 == 云端 the same as that, nothing to do.
              } else {
                //  case8：云端有，本地有；-》本地云端lastModify同，本地configLastModify旧
                await downloadCloudConfig(cloudNote, localCreateTime);
                await createPicCovert(localCreateTime);
              }
            } else if (localNote.lastModify < cloudNote.lastModify) {
              if (localNote.configLastModify <=
                  cloudNote.config['lastModify']) {
                //  case9：云端有，本地有；-》本地lastModify旧，本地configLastModify不新
                await downloadCloudConfig(cloudNote, localCreateTime);
                await StorageManager.downloadCloudNoteFile(
                    cloudNote, await localNote.getNoteFile());
                await createPicCovert(localCreateTime);
              } else {
                //  case10：云端有，本地有；-》本地lastModify旧，本地configLastModify新
                await uploadLocalNoteConfig(localCreateTime);
                await StorageManager.downloadCloudNoteFile(
                    cloudNote, await localNote.getNoteFile());
                await createPicCovert(localCreateTime);
                await StorageManager.uploadLocalNotePic(localCreateTime);
              }
            }
          }
        }
      });
      await Future.wait(futures1);

      ///  以云端所有的notes为基础，且减去本地所有的笔记，进行遍历
      var futures = cloudNotes.map((cloudNote) async {
        if (localAllNotes_dic[cloudNote.createTime] == null) {
          //  case11  云端有，本地没有；-》云端新建，本地无。
          var newLocalCreateTime = cloudNote.createTime;
          var newLocalnote = Note.shared.clone(createTime: newLocalCreateTime);
          await sNoteProvider.insert(newLocalnote);
          await sNoteProvider.update(newLocalCreateTime, cloudID: cloudNote.id);
          await StorageManager.downloadCloudNoteFile(
              cloudNote, await newLocalnote.getNoteFile());
          await downloadCloudConfig(cloudNote, newLocalCreateTime);
          await createPicCovert(newLocalCreateTime);
        }
      });
      await Future.wait(futures);
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    } finally {
      _logger.finest('同步完成');
    }
  }
}
