import 'dart:async';

import 'package:flutter/material.dart';

import 'package:notepad_kit/notepad.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import '../../widget/WDMAlertDialog.dart';

class NotepadConfirmPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotepadConfirmPageState();
}

class _NotepadConfirmPageState extends State<NotepadConfirmPage> {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  @override
  void initState() {
    super.initState();
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);

    // 倒计时说明：
    // 因：发出连接的请求后：设备已不在范围内或设备已关闭或者设备未响应或者SDK未有效响应等，
    // 而导致：当前页面一直未返回，
    // _setKowUnconfirmed有且仅处理一次：
//    Future.delayed(Duration(milliseconds: 12000), () => _setKnownUnconfirmed());
  }

  @override
  void dispose() {
    super.dispose();
    _notepadStateSubscription.cancel();
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    if (event.state == NotepadState.Connected) {
      setState(() => _confirmed = true);
      Navigator.pop(context);
    } else if (event.state == NotepadState.Disconnected) {
      switch (event.cause) {
        case 'Unconfirmed':
          _setKnownUnconfirmed();
          break;
        case '': //  TODO 设备已被其他人绑定，提示后，再返回(需改SDK)
          break;
        case '': //  TODO 设备直接拒绝连接(需改SDK)
          break;
        default: //  TODO  default未直接返回原因：连接请求发出后，SDK会受到多次disconnect。在将disconnect每一种case需单独处理。
          break;
      }
    }
  }

  var _knowUnconfirmed = false;

  _setKnownUnconfirmed({bool nowKnowUnconfirmed = true}) {
    if (_knowUnconfirmed == false && nowKnowUnconfirmed) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WDMAlertDialog(
            title: Translations.of(context).text('notify_notepad_unconfirmed'),
            message:
                Translations.of(context).text('connecting_device_instruction'),
            cancelText: Translations.of(context).text('Cancel'),
            type: Operation.NOTICE,
          );
        },
      );
    }
    _knowUnconfirmed = nowKnowUnconfirmed;
  }

  var _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(
          context, Translations.of(context).text('paired_smart_notebook'),
          implyLeading: true),
      body: Row(
        children: <Widget>[
          Expanded(
            child: _confirmed ? _confirmedBody() : _awaitBody(),
          ),
        ],
      ),
    );
  }

  Widget _awaitBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'gifs/notepad_await_confirm.gif',
          width: 0.66 * ScreenWidth,
          height: 0.66 * ScreenWidth / 238 * 203,
        ),
        Image.asset(
          'images/notepad_scan_indicator.png',
          width: 62,
          height: 104,
        ),
        Text(Translations.of(context).text('connecting_device_instruction'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xff191919), fontSize: 13)),
      ],
    );
  }

  Widget _confirmedBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Image.asset(
          'graphics/notepad_confirm_phone.png',
          width: 0.66 * ScreenWidth,
          height: 0.66 * ScreenWidth / 239 * 255,
        ),
        Text(
          Translations.of(context).text('connection_confirmed'),
          textAlign: TextAlign.center,
        ),
        Image.asset(
          'gifs/common_completed.gif',
          width: 28,
          height: 19,
        ),
      ],
    );
  }
}
