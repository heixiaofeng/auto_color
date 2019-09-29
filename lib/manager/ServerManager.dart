import 'dart:io';

import 'package:logging/logging.dart';
import 'package:package_info/package_info.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/util/DeviceInfo.dart';
import 'package:woodemi_service/ConfigService.dart';
import 'package:woodemi_service/WoodemiService.dart';
import 'package:woodemi_service/common.dart';
import 'package:woodemi_service/model.dart';

final _logger = Logger("ServerManager");

final sServerManager = ServerManager._init();

class ServerManager {
  String _objectStorageUrl;

  get objectStorageUrl {
    if (_objectStorageUrl == null) requestServer();
    return _objectStorageUrl ?? '';
  }

  ServerManager._init() {
    WoodemiService.clientAgent =
        Platform.isAndroid ? ClientAgent.aSmartnoteLight : ClientAgent.iSmartnoteLight;
    DeviceInfo().model.then((value) => WoodemiService.operationSystem = value);
    DeviceInfo()
        .system
        .then((value) => WoodemiService.operatingSystemVersion = value);
    configService.environment = Environment.pSmartnote;
    requestServer();
  }

  requestServer() async {
    _logger.info("fetchConfig");
    await configService.fetchConfig();
    _objectStorageUrl = configService.objectStorageUrl;

    if (Platform.isIOS) {
      _logger.info("fetchReview");
      try {
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        var version = 'v${packageInfo.version}_b${packageInfo.buildNumber}';

        var isReview = await configService.fetchReview(version);
        await sPreferencesManager.setIsOnReview(isReview);
      } on WoodemiException catch (e) {
        _logger.severe('Error: ${e.message}');
      }
    }
  }
}
