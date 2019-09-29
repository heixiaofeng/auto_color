import 'dart:async';
import 'dart:typed_data';

import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:ugee_note/model/account.dart';

import 'AccountManager.dart';
import 'PreferencesManager.dart';

Future<Uint8List> accountID_Bytes(int accountID) async {
  if (accountID == null) return null;
  var list = Uint32List.fromList([accountID]);
  return Uint8List.view(list.buffer);
}

final sDeviceManager = DeviceManager._internal();

class DeviceManager {
  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription<NotepadScanResult> _scanResultSubscription;

  StreamSubscription<LoginInfo> _loginInfoSubscription;

  LoginInfo _loginInfo = LoginInfo.sinout;
  String _lastPairDeviceID;
  int _lastPairAccountID;
  Uint8List _lastPairAccountID_Bytes;

  int _countdownIndex;
  Timer _countdownTimer;

  DeviceManager._internal() {
    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);
    _scanResultSubscription =
        sNotepadManager.scanResultStream.listen(_onScanResultChange);
  }

  //  调用场景：初始化、绑定成功后、解除绑定后
  resetAllData() async {
    print('resetAllData');
    stopAutoConnect();

    _loginInfo = await sPreferencesManager.loginInfo;
    _lastPairAccountID = await sPreferencesManager.lastPairAccountID;
    _lastPairDeviceID = await sPreferencesManager.lastPairDeviceID;
    _lastPairAccountID_Bytes =
        await accountID_Bytes(await sPreferencesManager.lastPairAccountID);

    print('当前存储的"账号绑定"相关数据');
    print(_loginInfo);
    print(_lastPairAccountID);
    print(_lastPairDeviceID);
    print(_lastPairAccountID_Bytes);

    tryAutoConnect();
  }

  _onLoginInfoChange(LoginInfo value) async {
    var oldLoginInfo = _loginInfo;
    _loginInfo = value;

    //  账号 已登录
    if (value.state == LoginState.sigin) {
      _loginInfo = await sPreferencesManager.loginInfo;
      tryAutoConnect();
      return;
    }

    //  账号绑定设备后，退出账号
    if (oldLoginInfo.state == LoginState.sigin &&
        value.state == LoginState.sigout) {
      await resetAllData();
      return;
    }
  }

  _onNotepadStateEvent(NotepadStateEvent event) async {
    if (event.state == NotepadState.Connected) {
      _cancelConnectCountdownTimer();
      _tryAccountBindDevice();
    } else if (event.state == NotepadState.Disconnected) {
      await resetAllData();
      tryAutoConnect();
    } else {}
  }

  _onScanResultChange(NotepadScanResult result) {
    if (!checkAutoConnect) return;
    if (result.deviceId == _lastPairDeviceID) _connect(result);
  }

  //  是否 满足自动连接条件
  bool get checkAutoConnect {
    //  以前未绑定
    if (_lastPairAccountID == null) return false;
    if (_lastPairDeviceID == null) return false;

    //  未登录账号
    if (_loginInfo == null) return false;
    if (_loginInfo.state != LoginState.sigin) return false;

    //  登录账号，但不匹配
    if (_lastPairAccountID != _loginInfo.userInfo.uid) return false;
    if (_lastPairAccountID_Bytes == null) return false;

    return true;
  }

  tryAutoConnect() {
    if (!checkAutoConnect) return;
    if (isScaning) return;
    startScan();
  }

  stopAutoConnect() {
    stopScan();
    _cancelConnectCountdownTimer();
  }

  var isScaning = false;

  startScan() {
    print('开始扫描');
    sNotepadManager.startScan();
    isScaning = true;
  }

  stopScan() {
    sNotepadManager.stopScan();
    isScaning = false;
    if (checkAutoConnect) startScan();
  }

  _connect(NotepadScanResult result) {
    if (_countdownTimer != null) return;
    if (!checkAutoConnect) return;
    print('开始自动连接');
    _startConnectCountdownTimer();
    connectDevice(result);
  }

  _tryAccountBindDevice() async {
    print('开始绑定');
    if (sNotepadManager.notepadState != NotepadState.Connected) return;
    if (sAccountManager.loginInfo.state != LoginState.sigin) return;

    await sNotepadManager.claimAuth();
    await sPreferencesManager
        .setLastPairAccountID(sAccountManager.loginInfo.userInfo.uid);
    await sPreferencesManager
        .setLastPairDeviceID(sNotepadManager.connectedDevice.deviceId);
    await resetAllData();
  }

  disconnectUnbindDevice() async {
    await _unBindDevice();
    await sNotepadManager.disconnect();
    await resetAllData();
  }

  _unBindDevice() async {
    print('开始解绑');
    await sPreferencesManager.setLastPairAccountID();
    await sPreferencesManager.setLastPairDeviceID();
    await sNotepadManager.disclaimAuth();
    await resetAllData();
  }

  //  连接中 定时器
  _startConnectCountdownTimer() {
    if (_countdownTimer == null) {
      _countdownTimer = Timer.periodic(Duration(minutes: 1), (timer) {
        _countdownIndex++;
        if (_countdownTimer == 8) _cancelConnectCountdownTimer();
      });
    }
  }

  _cancelConnectCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownIndex = 0;
  }

  //  正常连接（绑定当前账号）
  connectDevice(NotepadScanResult result) async {
    var accountIDBytes = (sAccountManager.loginInfo.state == LoginState.sigin)
        ? await accountID_Bytes(sAccountManager.loginInfo.userInfo.uid)
        : null;
    print('连接设备（绑定当前登录的账号）');
    print(result.deviceId);
    print(accountIDBytes);
    await sNotepadManager.connect(result, accountIDBytes);
    await resetAllData();
  }
}
