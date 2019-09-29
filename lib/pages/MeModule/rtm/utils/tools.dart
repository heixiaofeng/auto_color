import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

//import 'package:shared_preferences/shared_preferences.dart';

//const APP_ID = 'c8d9c58ab1744ff1a5197aec24afa1c0'; // 公司
//const APP_ID = 'a878650d6d244948bca12bcf67ea74b4'; // 个人

final void_callback = () {};

const SmartChannel = const MethodChannel('com.woodemi.smartnote.light');
const SmartEventChannel = const EventChannel('com.woodemi.smartnote.light/event');

class AppColors {
  static const BackgroundColor = 0xfff6f6f6;
  static const ThemeColor = Color(0xff115EAD);
  static const MainThemeColor = Color(0XFF6885C9);
  static const TitleTextColor = Colors.black87;
  static const TABTEXTCOLOR = 0XFF6885C9;
  static const DesTextColor = Colors.black54;
  static const DividerColor = 0xffd9d9d9;
  static const AlphaColor = 0x88111111;
}

class AppStyles {
  static const TitleStyle = TextStyle(
    fontSize: 14.0,
    color: AppColors.TitleTextColor,
  );

  static const DesStyle = TextStyle(
    fontSize: 12.0,
    color: AppColors.DesTextColor,
  );
}

class Constants {
  static const IconFontFamily = 'appIconFont';
  static const ConversationAvatarSize = 48.0;
  static const DividerWidth = 0.5;
  static const UnReadMsgNotifyDotSize = 20.0;
  static const ConversationMuteIconSize = 18.0;
}

class RTCMethodName {
  
  static const sys_msg = 'sys_msg';
  
  static const get_url = 'get_url';
  static const get_avatar = 'get_avatar';
  static const pop = 'pop';
  static const hud_info = 'hud_info';
  static const hud_loading = 'hud_loading';
  static const hud_finish = 'hud_finish';
  static const rtm_channel = 'rtm_channel';
  static const leave_rtm_channel = 'leave_rtm_channel';
  static const rtc_connected = 'rtc_connected';
  static const set_liveStatus = 'set_liveStatus';
  static const liveStatus = 'liveStatus';
  static const onlineStatus = 'onlineStatus';
  static const deviceStatus = 'deviceStatus';
  static const screenConstant = 'screenConstant';
  static const allowCreatePaper = 'allowCreatePaper';
  static const refreshAccessToken = 'refreshAccessToken';
  static const allowRotation = 'allowRotation';

  static const rtc_leave = 'rtc_leave';
  static const remote_ready = 'remote_ready';

  static const remote_show_id = 'remote_show_id';

  static const join_rtc_channel = 'join_rtc_channel';
  static const remote_joined_room = 'remote_joined_room';
  static const leave_rtc_channel = 'leave_rtc_channel';
  static const send_rtm_message = 'send_rtm_message';
  static const modify_pen_color = 'modify_pen_color';
  static const modify_pen_width = 'modify_pen_width';
  static const local_name_avatar = 'local_name_avatar';
  static const rtc_local_delay = 'rtc_local_delay';
  static const rtc_remote_delay = 'rtc_remote_delay';
  static const rtc_mute = 'rtc_mute';
  static const rtc_mic = 'rtc_mic';
}