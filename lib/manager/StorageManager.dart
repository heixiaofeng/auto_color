import 'dart:convert';
import 'dart:io';

import 'package:aliyun_oss/OSSClient.dart';
import 'package:logging/logging.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:woodemi_service/StorageService.dart';
import 'package:woodemi_service/common.dart';
import 'package:woodemi_service/storage.dart';

import '../manager/AccountManager.dart';
import '../util/Lazy.dart';

final _logger = Logger("StorageManager");

class StorageManager {
  static Lazy _lazyStorageConfig = Lazy(() => _fetchConfig());

  static Future<StorageConfig> get storageConfig => _lazyStorageConfig.call();

  static Lazy _lazyOssClient = Lazy(() =>
      storageConfig.then((config) {
        return OSSClient(config.endpoint, storageService);
      }));

  static Future<OSSClient> get _ossClient => _lazyOssClient.call();

  static Future<StorageConfig> _fetchConfig() async {
    _logger.info('下载Aliyun-OSS配置信息');
    await sAccountManager.refreshAccesstoken();
    storageService.uid = sAccountManager.loginInfo.userInfo.uid;
    storageService.accessToken = sAccountManager.loginInfo.userInfo.accessToken;
    storageService.init();

    return storageService.privateConfig;
  }

  static Future<void> uploadLocalNoteFile(int createTime) async {
    _logger.info("上传笔记文件");

    var localNote = await sNoteProvider.queryByCreateTime(createTime);
    var config = await storageConfig;

    var fileContent = (await localNote.getNoteFile()).readAsBytesSync();
    var extCallbackVars = {
      'noteid': '${localNote.cloudID}',
      'filetype': '${storageService.noteFileTypes.points}',
      'picName': '${config.prefix}${localNote.thumbName}',
      'content': localNote.convert,
      'lastModify': '${localNote.lastModify}',
      'cfg': jsonEncode({
        'background': localNote.skinID,
        'lastModify': localNote.configLastModify,
      }),
    };
    try {
      var result = await storageService.uploadObject(
          config, localNote.fileName, fileContent, extCallbackVars);
      _logger.info('上传笔记文件--完成：${result}');
    } catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  static Future<void> downloadCloudNoteFile(NoteInfo cloudNote,
      File localNoteFile) async {
    _logger.info('下载笔记文件');
    try {
      var noteBytes = await (await _ossClient)
          .getObject((await storageConfig).bucket, cloudNote.name);
      await localNoteFile.writeAsBytes(noteBytes);
      _logger.info('下载笔记文件--完成');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
    return true;
  }

  static Future<void> uploadLocalNotePic(int createTime) async {
    _logger.info('上传笔记的图片');

    var localNote = await sNoteProvider.queryByCreateTime(createTime);
    var config = await storageConfig;

    var fileContent = (await localNote.getThumbFile()).readAsBytesSync();
    var extCallbackVars = {
      'noteid': '${localNote.cloudID}',
      'filetype': '${storageService.noteFileTypes.outlinedrawing}',
    };

    try {
      var result = await storageService.uploadObject(
          config, localNote.thumbName, fileContent, extCallbackVars);
      _logger.info('上传笔记的图片--完成：${result}');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }

  static Future<void> downloadCloudNotePic(NoteInfo cloudNote,
      File localPicFile) async {
    _logger.info('下载笔记的图片');
    try {
      var picBytes = await (await _ossClient)
          .getObject((await storageConfig).bucket, cloudNote.picName);
      await localPicFile.writeAsBytes(picBytes);
      _logger.info('下载笔记的图片--完成');
    } on WoodemiException catch (e) {
      _logger.severe('Error: ${e.message}');
    }
  }
}
