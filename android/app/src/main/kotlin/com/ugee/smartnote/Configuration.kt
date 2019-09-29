package com.ugee.smartnote

val ChannelName = "com.woodemi.smartnote.light"

val EventName = "com.woodemi.smartnote.light/event"

val AppId = "c8d9c58ab1744ff1a5197aec24afa1c0"

enum class RTMMsgType {
    points, color, width, create, paper
}

enum class RTCMethodName {

    sys_msg,

    hud_info,
    hud_loading,
    hud_finish,
    rtm_channel,
    leave_rtm_channel,
    rtc_connected,
    set_liveStatus,
    liveStatus,
    onlineStatus,
    deviceStatus,
    screenConstant,
    allowCreatePaper,
    refreshAccessToken,
    allowRotation,

    rtc_leave,
    remote_ready,

    remote_show_id,

    join_rtc_channel,
    remote_joined_room,
    leave_rtc_channel,
    send_rtm_message,
    modify_pen_color,
    modify_pen_width,
    local_name_avatar,
    rtc_local_delay,
    rtc_remote_delay,
    rtc_mute,
    rtc_mic,
}

//var liveStatus = LiveStatus.unknown
//
//enum class LiveStatus(val type : Int) {
//    unknown(-1), notStart(0), haveReady(1), starting(2)
//}
//
//var onlineStatus = OnlineStatus.android
//
//enum class OnlineStatus(val type : Int) {
//    web(0), iOS(1), android(2)
//}
//
//var deviceStatus = DeviceStatus.disconnected
//
//enum class DeviceStatus(val type : Int) {
//    disconnected(0), connected(1)
//}
//
//enum class SysChannelMsg(val type : Int) {
//    room(1), status(2), device(3)
//}
//
//enum class RoomMsg(val type : Int) {
//    join(1), leave(2), kick(3)
//}