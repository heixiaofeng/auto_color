import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ble/flutter_ble.dart';

import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/manager/DeviceManager.dart';
import 'package:ugee_note/pages/MeModule/NotepadConfirmPage.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import '../../widget/WDMAlertDialog.dart';

class NotepadScanPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _NotepadScanPageState();
}

class _NotepadScanPageState extends State<NotepadScanPage> {
  var _scanResults = new List<NotepadScanResult>();

  StreamSubscription<NotepadScanResult> _scanResultSubscription;

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  NotepadScanResult _selectedScanResult;

  @override
  void initState() {
    super.initState();
    print("_NotepadScanPageState initState");
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _scanResultSubscription = sNotepadManager.scanResultStream.listen((result) {
      if (!_scanResults.any((r) => r.deviceId == result.deviceId)) {
        setState(() => _scanResults.add(result));
      }
    });
    sDeviceManager.startScan();
    if (sNotepadManager.notepadState == NotepadState.Connected &&
        sNotepadManager.connectedDevice != null) {
      _scanResults.add(sNotepadManager.connectedDevice);
    }

    _ensureBleState();
  }

  @override
  void dispose() {
    super.dispose();
    print("_NotepadScanPageState dispose");
    _scanResultSubscription.cancel();
    _notepadStateSubscription.cancel();
    sDeviceManager.stopScan();
  }

  _ensureBleState() async {
    FlutterBle flutterBlue = FlutterBle.instance;
    var state = await flutterBlue.state;
    if (state != BluetoothState.on) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WDMAlertDialog(
            title: Translations.of(context).text('request_bluetooth'),
            message: Translations.of(context)
                .text('please_turn_on_bluetooth_service'),
            confimText: Translations.of(context).text('OK'),
            type: Operation.NOTICE,
          );
        },
      );
    }
  }

  NotepadState _state = sNotepadManager.notepadState;

  _onNotepadStateEvent(NotepadStateEvent event) {
    setState(() => _state = event.state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(
          context, Translations.of(context).text('searched_following_devices')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Image.asset(
          'images/notepad_scan_indicator.png',
          width: 150,
          height: 150,
        ),
        wrapRoundedCard(
          outterPadding: EdgeInsets.all(0),
          radius: 0,
          items: [
            Container(
              height: 205,
              child: ListView.separated(
                itemBuilder: _itemBuilder,
                separatorBuilder: (context, index) => line(),
                itemCount: _scanResults.length,
              ),
            )
          ],
        ),
        buildButton(),
      ],
    );
  }

  Widget _itemBuilder(context, index) {
    var scanResult = _scanResults[index];
    var selected = scanResult.deviceId == _selectedScanResult?.deviceId;
    var connected =
        scanResult.deviceId == sNotepadManager.connectedDevice?.deviceId;
    var connectedIndicator = Image.asset(
      'icons/item_active_indicator.png',
      width: 20.0,
      height: 20.0,
    );
    return ListTile(
      title: Text('${scanResult.name}'),
      subtitle: Text(scanResult.deviceId),
      onTap: () {
        setState(() => _selectedScanResult = selected ? null : scanResult);
      },
      trailing: connected ? connectedIndicator : null,
      selected: selected,
    );
  }

  Widget buildButton() {
    switch (_state) {
      case NotepadState.Connecting:
        return actionButton("连接中");
      case NotepadState.AwaitConfirm:
        return actionButton("等待确认连接");
      case NotepadState.Connected: //  断开：1、断开；2、更换
        if (_selectedScanResult == null)
          return actionButton(
              Translations.of(context).text('notify_notepad_connected'));
        if (_selectedScanResult.deviceId ==
            sNotepadManager.connectedDevice.deviceId) {
          return actionButton(
            Translations.of(context).text('action_disconnect_selected'),
            () async {
              await sDeviceManager.disconnectUnbindDevice();
              setState(() => _selectedScanResult = null);
            },
          );
        }
        return actionButton(
          Translations.of(context).text('action_switch_selected'),
          () async {
            await sDeviceManager.disconnectUnbindDevice();
            await sDeviceManager.connectDevice(_selectedScanResult);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotepadConfirmPage()));
          },
        );
      case NotepadState.Disconnected: //  开始连接
        if (_selectedScanResult == null)
          return actionButton(
              Translations.of(context).text('notify_notepad_disconnected'));
        return actionButton(
          Translations.of(context).text('connecting_device_title'),
          () async {
            sDeviceManager.connectDevice(_selectedScanResult);
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NotepadConfirmPage()));
          },
        );
    }
  }

  Widget actionButton(String text, [VoidCallback onPressed]) {
    return RaisedButton(
      padding: EdgeInsets.fromLTRB(20, 10.0, 20.0, 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      textColor: Colors.white,
      disabledTextColor: Colors.red,
      color: ThemeColor,
      disabledColor: ThemeBackgroundColor,
      disabledElevation: 0,
      child: Text(text),
      onPressed: onPressed,
    );
  }
}
