import 'package:flutter/material.dart';

class RoomModel {

  final roomId;

  final channel;
  final sysChannel;
  final webUrl;

  final showId;

  final isBroadcast;
  final hasMember;

  RoomModel(
      {@required this.roomId,
      @required this.channel,
      @required this.sysChannel,
      @required this.webUrl,
      @required this.showId,
      @required this.isBroadcast,
      @required this.hasMember});
}
