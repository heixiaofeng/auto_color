
var remoteShowId = '';

var remotePenColor = '';
var remotePenWidth = '';

class LiveStatus {
  static const unknow = -1;
  static const notStart = 0;
  static const haveReady = 1;
  static const starting = 2;

  static int value = unknow;
}

class OnlineStatus {
  static const web = 0;
  static const iOS = 1;
  static const android = 2;

  static int value = android;
}

class DeviceStatus {
  static const disconnected = 0;
  static const connected = 1;

  static int value = disconnected;
}

class SysChannelMsg {
  static const room = 1;
  static const status = 2;
  static const device = 3;

  static const room_join = 1;
  static const room_leave = 2;
  static const room_kick = 3;

  static const status_notready = 0;
  static const status_already = 1;
  static const status_starting = 2;

  // online、device的状态上面都有
}