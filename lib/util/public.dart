import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/manager/DeviceManager.dart';
import 'package:ugee_note/manager/RealtimeManager.dart';
import 'package:ugee_note/manager/ServerManager.dart';
import 'package:ugee_note/model/Note.dart';
import 'package:ugee_note/model/NoteSkin.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/TagSkin.dart';

loadDeafultData() async {
  await sTagSkinProvider.queryAvalibleTagSkins(true);
  await sNoteSkinProvider.queryAvalibleNoteSkins(true);
  await sTagProvider.queryAvalible(true);
  await sNoteProvider.queryAvalible(true);

  await sServerManager.requestServer();
  await sAccountManager.refreshAccesstoken(); //  自动登录
  await sRealtimeManager.start();
  await sDeviceManager.resetAllData(); // 后台自动连接设备

  await TagSkin.defaultInit();
  await NoteSkin.defaultInit();
  await Tag.defaultInit();
  await Note.defaultInit();
}
