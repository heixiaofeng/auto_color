package com.ugee.smartnote

import android.os.Bundle
import android.util.Log
import com.myscript.woodemi.MyCertificate
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.woodemi.iink.MyscriptIinkPlugin
import io.agora.rtm.*
import io.flutter.plugin.common.EventChannel
import io.socket.client.IO
import io.socket.client.Socket

const val TAG = "MainActivity"

class MainActivity : FlutterActivity() {

    lateinit var roomId : String
    lateinit var showId : String
    lateinit var channelId : String
    lateinit var sysChannelId : String

    lateinit var socketIO : Socket

    lateinit var rtmClient : RtmClient

    lateinit var rtmChannel : RtmChannel

    lateinit var msgChannel : MethodChannel

    var eventSink : EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        MyscriptIinkPlugin.initWithCertificate(this, MyCertificate.getBytes())
        GeneratedPluginRegistrant.registerWith(this)
        registerImageSaver()

        initFlutterMethodChannel()

        initFlutterEventChannel()

        rtmInit()
    }

    private fun initFlutterEventChannel() {

        EventChannel(this.flutterView, EventName).setStreamHandler (object : EventChannel.StreamHandler {

            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun initFlutterMethodChannel() {

        msgChannel = MethodChannel(this.flutterView, ChannelName)

        msgChannel.setMethodCallHandler { call, _ ->

            print("*** call.method = ${call.method}, call.arguments = ${call.arguments}")

            when (call.method) {
                RTCMethodName.rtm_channel.name -> {
                    val args = call.arguments as List<String>
                    this.roomId = args.first()
                    this.showId = args[1]
                    this.channelId = args[2]
                    this.sysChannelId = args[3]

                    this.socketIO = IO.socket("http://39.106.100.225:8090?accessToken=${args.last()}")

                    this.rtmLogin(showId, channelId)
                }
                RTCMethodName.leave_rtm_channel.name -> rtmLogout()
                RTCMethodName.send_rtm_message.name -> sendChannelMessage(call.arguments as String)
                RTCMethodName.modify_pen_color.name -> rtmParamsMsg(RTMMsgType.color.name, call.arguments as String)
                RTCMethodName.modify_pen_width.name -> rtmParamsMsg(RTMMsgType.width.name, call.arguments as String)

                RTCMethodName.rtc_mute.name -> print("rtc_mute")
                RTCMethodName.rtc_mic.name -> print("rtc_mic")
            }
        }
    }

    internal val mRtmChannelListener = object : RtmChannelListener {
        override fun onMessageReceived(message: RtmMessage, fromMember: RtmChannelMember) {
            Log.d(TAG, "*** >>> message.text: ${message.text}, fromMember: ${fromMember.userId}")
            mainThreadHandler.post { eventSink?.success(message.text) }
        }

        override fun onMemberJoined(member: RtmChannelMember) {
            mainThreadHandler.post { msgChannel.invokeMethod(RTCMethodName.remote_show_id.name, member.userId) }
        }

        override fun onMemberLeft(member: RtmChannelMember) {
            mainThreadHandler.post { msgChannel.invokeMethod(RTCMethodName.remote_show_id.name, "") }
        }
    }

    private fun rtmParamsMsg(type: String, args: String) {
        this.sendChannelMessage("{\"type\":\"$type\", \"$type\":\"$args\"}")
    }
}
