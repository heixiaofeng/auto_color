import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';

const IMAGE_SAVER_SERVERS_CHANNEL = 'image_saver_servers_channel';

class Image_saver {
  static const MethodChannel _channel = const MethodChannel(IMAGE_SAVER_SERVERS_CHANNEL);

  static Future<bool> saveImage(Uint8List imageBytes) async {
    return await _channel.invokeMethod('saveImage', {'imageBytes': imageBytes});
  }
}
