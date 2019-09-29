package com.ugee.smartnote

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.socket.client.Socket
import io.socket.emitter.Emitter

val mainThreadHandler = Handler(Looper.getMainLooper())

internal fun MainActivity.socketIOConnect() {
    this.socketIO.on(Socket.EVENT_CONNECT, Emitter.Listener {
        Log.e(TAG, "EVENT_CONNECT")
    }).on("chatevent") { value ->

        Log.e(TAG, "socketIOConnect: ${value.last()}")

        mainThreadHandler.post { msgChannel.invokeMethod(RTCMethodName.sys_msg.name, value.last()) }

    }.on(Socket.EVENT_DISCONNECT,  Emitter.Listener {
        Log.e(TAG, "EVENT_DISCONNECT")
    })
    this.socketIO.connect()
}

internal fun MainActivity.socketIODisconnect() {
    this.socketIO.disconnect()
}