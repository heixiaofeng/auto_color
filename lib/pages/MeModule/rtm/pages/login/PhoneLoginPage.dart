import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/model/account.dart';
import 'package:ugee_note/pages/MeModule/rtm/pages/login/WoodemiService.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/api_request.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/tools.dart';
import 'package:ugee_note/pages/MeModule/rtm/widget/wdm_widget.dart';

import 'UsageProtocolPage.dart';

class PhoneLoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PhoneLoginPageState();
}

enum AuthCodeState { RequestingAuthCode, AuthCodeValid, AuthCodeInvalid }
enum LoginStateInternal { LoginFailure, LoginSuccess, LoginIng }

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int maxTime = 60;
  int _start = 60;
  Timer _timer;
  AuthCodeState _authCodeState = AuthCodeState.AuthCodeInvalid;
  LoginStateInternal _loginState = LoginStateInternal.LoginFailure;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _topImgContainer(),
                  Container(
                    height: getFreeHeight(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _textBindPhone(),
                        _inputContainer(),
                        _loginBtn(),
                        _bottomText(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 5,
              left: 3,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column _inputContainer() {
    return Column(
      children: <Widget>[
        _inputPhoneContainer(),
        _inputAuthCodeContainer(),
      ],
    );
  }

  final _phoneNumberController = TextEditingController();
  final _authCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loginInfoSubscription =
        sAccountManager.loginInfoStream.listen(_onLoginInfoChange);

    _phoneNumberController.text = '13521476058';
    _authCodeController.text = '1881';
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _authCodeController.dispose();
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  var isPop = false;
  _onLoginInfoChange(LoginInfo loginInfo) {
    if (!isPop &&
        loginInfo.state == LoginState.sigin) {
      isPop = true;
      Future.delayed(
          Duration(milliseconds: 1000), () => Navigator.pop(context));
    }
  }

  bool _phoneNumberValidator(String value) {
    RegExp exp = RegExp(
        r'^((13[0-9])|(14[0-9])|(15[0-9])|(16[0-9])|(17[0-9])|(18[0-9])|(19[0-9]))\d{8}$');
    return exp.hasMatch(value);
  }

  sendAuthCode() async {
    if (!_phoneNumberValidator(_phoneNumberController.text)) {
      _showToast("请输入有效的手机号码");
      return;
    }

    setState(() {
      _authCodeState = AuthCodeState.RequestingAuthCode;
    });

    APIRequest.request('/users/mobile/code',
        isLogin: true,
        method: APIRequest.POST,
        data: {"phone": _phoneNumberController.text},
        faildCallback: (errorMsg) {
      setState(() {
        _authCodeState = AuthCodeState.AuthCodeInvalid;
      });
      _showToast("验证码发送失败");
    }).then(
      (data) {
        if (data == null) return;

        _showToast("验证码发送成功");

        //开始倒计时
        _authCodeState = AuthCodeState.AuthCodeValid;
        startTimer();
      },
    );
  }

  goLogin() async {
    if (!_phoneNumberValidator(_phoneNumberController.text)) {
      _showToast("请输入有效的手机号码");
      return;
    }
    if (_authCodeController.text.isEmpty) {
      _showToast("请输入验证码");
      return;
    }

//    sAccountManager.login(LoginPlatform.phone,parameters: {
//      "phone": _phoneNumberController.text,
//      "code": _authCodeController.text,
//      ...await WoodemiService.systemData,
//    });

    setState(() {
      _loginState = LoginStateInternal.LoginIng;
    });

    APIRequest.request('/users/login/mobile',
        isLogin: true,
        method: APIRequest.POST,
        data: {
          "phone": _phoneNumberController.text,
          "code": _authCodeController.text,
          ...await WoodemiService.systemData,
        }, faildCallback: (errorMsg) {
      _showToast('登录失败');
    }).then(
      (data) {
        if (data == null) return;

        _showToast('登录成功');

        sAccountManager.setLoginInfo(LoginState.sigin, LoginPlatform.phone, UserInfo.fromMap(data['entities'][0]));

        setState(() => _loginState = LoginStateInternal.LoginSuccess);
      },
    );
  }

  StreamSubscription<LoginInfo> _loginInfoSubscription;

  void startTimer() {
    setState(() {
      _start--;
    });

    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        setState(() {
          if (_start < 1) {
            timer.cancel();
            //倒计时恢复为初始值 验证码失效
            _start = 60;
            _authCodeState = AuthCodeState.AuthCodeInvalid;
          } else {
            _start--;
          }
        });
      },
    );
  }

  void _showToast(String msg) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 2),
      ),
    );
  }

  _enterUsageProtocolPage() {
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext ctx) => UsageProtocolPage()));
  }

  double getFreeHeight(BuildContext context) {
    return MediaQuery.of(context).size.height -
        208 -
        MediaQuery.of(context).padding.top -
        40;
  }

  Widget _topImgContainer() {
    return Container(
      margin: EdgeInsets.only(top: 40),
      alignment: Alignment.topCenter,
      child: Image.asset(
        'icons/login_main_icon_small.png',
        width: 268,
        height: 208,
      ),
    );
  }

  Container _textBindPhone() {
    return Container(
      child: Text(
        '手机号登录',
        style: TextStyle(
          fontSize: 16,
          color: Color(0xff292929),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Container _inputPhoneContainer() {
    return Container(
      padding: EdgeInsets.only(left: 13),
      width: MediaQuery.of(context).size.width * 0.75,
      height: 48,
      decoration: BoxDecoration(
          color: Color(0xfff5f5f5),
          borderRadius: BorderRadius.circular(48 / 2)),
      child: TextField(
        keyboardType: TextInputType.number,
        cursorColor: AppColors.ThemeColor,
        controller: _phoneNumberController,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.DesTextColor,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '请输入手机号',
        ),
      ),
    );
  }

  Container _inputAuthCodeContainer() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.only(left: 13),
      width: MediaQuery.of(context).size.width * 0.75,
      height: 48,
      decoration: BoxDecoration(
          color: Color(0xfff5f5f5),
          borderRadius: BorderRadius.circular(48 / 2)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              cursorColor: AppColors.ThemeColor,
              controller: _authCodeController,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.DesTextColor,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '请输入验证码',
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(10),
            width: 76,
            height: 25,
            child: FlatButton(
              padding: EdgeInsets.all(0),
              onPressed: _authCodeState == AuthCodeState.AuthCodeInvalid
                  ? sendAuthCode
                  : null,
              child: authCodeBtnChild(),
            ),
          ),
        ],
      ),
    );
  }

  Widget authCodeBtnChild() {
    if (_authCodeState == AuthCodeState.AuthCodeInvalid) {
      return Text(
        '获取验证码',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.ThemeColor,
        ),
      );
    } else if (_authCodeState == AuthCodeState.AuthCodeValid) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: Text(
          '重新发送($_start)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
      );
    } else if (_authCodeState == AuthCodeState.RequestingAuthCode) {
      return Container(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.ThemeColor),
        ),
      );
    } else {
      return null;
    }
  }

  Widget _loginBtnChild() {
    if (_loginState == LoginStateInternal.LoginIng) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text(
            '正在登录',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      );
    } else if (_loginState == LoginStateInternal.LoginSuccess) {
      return Text(
        '登录成功 ',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      return Text(
        '登 录',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      );
    }
  }

  Widget _loginBtn() {
    return AlphaButton(
        child: _loginBtnChild(),
        width: MediaQuery.of(context).size.width * 0.75,
        onPressed:
            _loginState == LoginStateInternal.LoginFailure ? goLogin : null);
  }

  Container _bottomText() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          WDMText(
              text: '登录即代表阅读并同意', fontSize: 11, color: AppColors.DesTextColor),
          InkWell(
            onTap: _enterUsageProtocolPage,
            child: WDMText(
                text: '《36记用户使用协议》',
                fontSize: 11,
                color: AppColors.DesTextColor),
          ),
        ],
      ),
    );
  }
}
