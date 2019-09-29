package com.ugee.smartnote

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

internal fun MainActivity.registerImageSaver() {
    val registrar = this.registrarFor("image_saver_flutter")
    MethodChannel(registrar.messenger(), "image_saver_servers_channel").setMethodCallHandler { call, result ->
        println("setMethodCallHandler")
        when (call.method) {
            "saveImage" -> {
                val bytes = call.argument<ByteArray>("imageBytes")
                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes!!.size)
                saveImageToGallery(bitmap)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}

//保存文件到指定路径
internal fun MainActivity.saveImageToGallery(bmp: Bitmap): Boolean {
    // 首先保存图片
    val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator
    val appDir = File(storePath)
    if (!appDir.exists()) {
        appDir.mkdir()
    }
    val fileName = System.currentTimeMillis().toString() + ".jpg"
    val file = File(appDir, fileName)
    try {
        val fos = FileOutputStream(file)
        //通过io流的方式来压缩保存图片
        val isSuccess = bmp.compress(Bitmap.CompressFormat.JPEG, 60, fos)
        fos.flush()
        fos.close()

        //把文件插入到系统图库
        //MediaStore.Images.Media.insertImage(context.getContentResolver(), file.getAbsolutePath(), fileName, null);

        //保存图片后发送广播通知更新数据库
        val uri = Uri.fromFile(file)
        this.baseContext.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
        return isSuccess
    } catch (e: IOException) {
        e.printStackTrace()
    }

    return false
}