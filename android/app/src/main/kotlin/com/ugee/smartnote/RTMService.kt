package com.ugee.smartnote

import android.util.Log
import io.agora.rtm.*

internal fun MainActivity.sendChannelMessage(msg: String) {
    val message = rtmClient.createMessage()
    message.text = msg

    rtmChannel.sendMessage(message, object : ResultCallback<Void> {
        override fun onSuccess(p0: Void?) {
            Log.d(TAG, "join success!")
        }

        override fun onFailure(p0: ErrorInfo?) {
            Log.d(TAG, "join failure!")
        }
    })
}

internal fun MainActivity.leave() {
    rtmChannel.leave(object : ResultCallback<Void> {
        override fun onSuccess(p0: Void?) {
            Log.d(TAG, "leave success!")
        }

        override fun onFailure(p0: ErrorInfo?) {
            Log.d(TAG, "leave failure!")
        }
    })
}

private fun MainActivity.createChannel(channel: String) {
    rtmChannel = rtmClient.createChannel(channel, mRtmChannelListener)
    rtmChannel.join(object : ResultCallback<Void> {
        override fun onSuccess(p0: Void?) {
            Log.d(TAG, "join success!")
        }

        override fun onFailure(p0: ErrorInfo?) {
            Log.d(TAG, "join failure!")
        }
    })
}

internal fun MainActivity.rtmLogout() {
    rtmClient.logout(object : ResultCallback<Void> {
        override fun onSuccess(p0: Void?) {
            Log.d(TAG, "logout success!")
            socketIODisconnect()
        }

        override fun onFailure(p0: ErrorInfo?) {
            Log.d(TAG, "logout failure!")
        }
    })
}

internal fun MainActivity.rtmLogin(showId: String, channel: String) {
    rtmClient.login(null, showId, object : ResultCallback<Void> {
        override fun onSuccess(p0: Void?) {
            Log.d(TAG, "login success!")
            socketIOConnect()
            createChannel(channel)
        }

        override fun onFailure(p0: ErrorInfo?) {
            Log.d(TAG, "login failure!")
        }
    })
}

internal fun MainActivity.rtmInit() {
    try {
        rtmClient = RtmClient.createInstance(this, AppId,
                object : RtmClientListener {
                    override fun onConnectionStateChanged(state: Int, reason: Int) {
                        Log.d(TAG, "Connection state changes to "
                                + state + " reason: " + reason)
                    }

                    override fun onMessageReceived(rtmMessage: RtmMessage, peerId: String) {
                        val msg = rtmMessage.text
                        Log.d(TAG, "Message received  from $peerId$msg"
                        )
                    }

                    override fun onTokenExpired() {}
                })
    } catch (e: Exception) {
        Log.d(TAG, "RTM SDK init fatal error!")
        throw RuntimeException("You need to check the RTM init process.")
    }
}