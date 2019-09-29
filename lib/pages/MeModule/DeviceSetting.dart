import 'dart:async';

import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:notepad_kit/notepad.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/DateUtils.dart';
import 'package:ugee_note/util/permission.dart';
import 'package:ugee_note/widget/AutoLockTime.dart';
import 'package:ugee_note/widget/WDMAlertDialog.dart';
import 'package:ugee_note/widget/widgets.dart';

class DeviceSetting extends StatefulWidget {
  @override
  _DeviceSettingState createState() => _DeviceSettingState();
}

class _DeviceSettingState extends State<DeviceSetting> {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;

  int _devicePercent = 0;
  String _deviceName = "";
  String _deviceMemo = "";
  String _deviceSyncDate = "";
  String _deviceId = "";
  String _deviceVersion = "";
  String _deviceAutolockTime = "";

  var _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('DeviceSetting initState');

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _refreshState(sNotepadManager.notepadState);
  }

  @override
  void dispose() {
    super.dispose();
    print('DeviceSetting dispose');

    _notepadStateSubscription.cancel();
    _notepadStateSubscription = null;
  }

  _onNotepadStateEvent(NotepadStateEvent event) {
    _refreshState(event.state);
  }

  _refreshState(NotepadState state) {
    state == NotepadState.Connected
        ? handleConnected()
        : Navigator.pop(context);
  }

  handleConnected() async {
    var batteryInfo = await sNotepadManager.getBatteryInfo();
    var deviceName = await sNotepadManager.getDeviceName();
    var memoSummary = await sNotepadManager.getMemoSummary();
    var versionInfo = await sNotepadManager.getVersionInfo();
    var autoLockTime = await sNotepadManager.getAutoLockTime();
    var lastImportTime = await sPreferencesManager.lastImportTime;
    var used = NumUtil.getNumByValueDouble(memoSummary.usedCapacityInMegas, 2);
    var total =
        NumUtil.getNumByValueDouble(memoSummary.totalCapacityInMegas, 2);
    setState(() {
      _devicePercent = batteryInfo.percent;
      _deviceName = deviceName;
      _deviceSyncDate = lastImportTime != null
          ? DateUtils.getDescription(lastImportTime, DateFormatType.yMd_dot)
          : '';
      _deviceId = sNotepadManager.connectedDevice.deviceId;
      _deviceMemo = "${used}M/${total}M";
      _deviceVersion = versionInfo.software.description;
      _deviceAutolockTime = formatLockTime(autoLockTime, context);
    });
  }

  _updateDeviceName(String name) async {
    await sNotepadManager.setDeviceName(name);
    var deviceName = await sNotepadManager.getDeviceName();
    setState(() {
      _deviceName = deviceName;
    });
  }

  _updateDeviceAutoLuckTime(int time) async {
    await sNotepadManager.setAutoLockTime(time);
    var autoLockTime = await sNotepadManager.getAutoLockTime();
    setState(() {
      _deviceAutolockTime = formatLockTime(autoLockTime, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(
          context, Translations.of(context).text('setting_item_notepad')),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      children: <Widget>[
        CircularPercentIndicator(
          radius: 120,
          lineWidth: 6,
          startAngle: 90,
          animation: true,
          percent: _devicePercent / 100,
          center: WDMText(text: '${_devicePercent}%', fontSize: 14),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: ThemeColor,
          backgroundColor: Color(0xFFE2E2E2),
        ),
        Container(height: 20),
        wrapRoundedCard(items: [
          entryItem(
            "icons/device_name.png",
            Translations.of(context).text('setting_notepad_name'),
            _deviceName,
            onTap: () {
              _textEditingController.text = _deviceName;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return WDMAlertDialog(
                    cancelText: Translations.of(context).text('Cancel'),
                    confimText: Translations.of(context).text('OK'),
                    type: Operation.EDIT,
                    textEditingController: _textEditingController,
                    title: Translations.of(context).text('change_notepad_name'),
                    confim: (value) {
                      //  TODO 校验设备名称的长度（1-15个字节）
                      _updateDeviceName(value);
                    },
                  );
                },
              );
            },
          ),
          line(),
          entryItem(
              "icons/device_name.png",
              Translations.of(context).text('setting_notepad_storage'),
              _deviceMemo),
          line(),
          entryItem(
              "icons/device_sync_icon.png",
              Translations.of(context).text('setting_notepad_last_import'),
              _deviceSyncDate),
          line(),
          entryItem(
              "icons/device_number.png",
              Translations.of(context).text('setting_notepad_sn_code'),
              _deviceId),
          line(),
          entryItem(
              "icons/device_version.png",
              Translations.of(context).text('setting_notepad_firmware'),
              _deviceVersion),
          line(),
          entryItem(
              "icons/device_sleeptime.png",
              Translations.of(context).text('device_sleep_time'),
              _deviceAutolockTime, onTap: () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) => AutoLockTime(
                confim: (value) => _updateDeviceAutoLuckTime(value),
              ),
            );
          }),
          line(),
          entryItem(
            "icons/device_list.png",
            Translations.of(context).text('device_list'),
            '',
            onTap: () => pushNotepadScanpage(context),
          ),
        ]),
      ],
    );
  }
}
