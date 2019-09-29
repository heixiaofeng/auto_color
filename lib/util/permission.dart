import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ugee_note/pages/MeModule/NotepadScanPage.dart';

Future<bool> checkAndRequest(PermissionGroup permissionGroup) async {
  var permissionHandler = PermissionHandler();
  var permissionStatus =
      await permissionHandler.checkPermissionStatus(permissionGroup);
  if (permissionStatus == PermissionStatus.granted) return true;

  var requestResults =
      await permissionHandler.requestPermissions([permissionGroup]);

  if (requestResults[permissionGroup] == PermissionStatus.granted) return true;
  return false;
}

//  进入扫描页
pushNotepadScanpage(BuildContext context) async {
  var b = Platform.isAndroid
      ? await checkAndRequest(PermissionGroup.location)
      : true;

  if (b)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotepadScanPage()),
    );
}
