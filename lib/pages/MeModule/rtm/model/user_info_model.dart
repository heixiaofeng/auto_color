
class UserInfoModel {

  String anchorUid;
  String anchorNickName;
  String anchorAvatar;
  String anchorGender;
  String anchorOnlineStatus;
  String anchorLiveStatus;
  String anchorDeviceStatus;

  String studentUid;
  String studentNickName;
  String studentAvatar;
  String studentGender;
  String studentOnlineStatus;
  String studentLiveStatus;
  String studentDeviceStatus;

  UserInfoModel.modelFromMap(Map map) {

    var anchor = map['anchorInfo'];

    var students = (map['students'] as List);

    var isEmpty = students.length <= 0;

    this.anchorUid = (anchor['uid'] ?? 0).toString();
    this.anchorNickName = anchor['nickname'] ?? '';
    this.anchorAvatar = anchor['avatar'] ?? '';
    this.anchorGender = (anchor['gender'] ?? 0).toString();
    this.anchorOnlineStatus = (anchor['onlineStatus'] ?? 0).toString();
    this.anchorLiveStatus = (anchor['liveStatus'] ?? 0).toString();
    this.anchorDeviceStatus = (anchor['deviceStatus'] ?? 0).toString();

    this.studentUid = isEmpty ? '' : students.first['uid'].toString();
    this.studentNickName = isEmpty ? '' : students.first['nickname'];
    this.studentAvatar = isEmpty ? '' : students.first['avatar'];
    this.studentGender = isEmpty ? '' : students.first['gender'].toString();
    this.studentOnlineStatus =
    isEmpty ? '' : students.first['onlineStatus'].toString();
    this.studentLiveStatus =
    isEmpty ? '' : students.first['liveStatus'].toString();
    this.studentDeviceStatus =
    isEmpty ? '' : students.first['deviceStatus'].toString();
  }
}

