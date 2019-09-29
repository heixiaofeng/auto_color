import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class UsageProtocolPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('用户使用协议'),
        centerTitle: true,
      ),
      body: WebView(
        initialUrl: "http://www.woodemi.com/html/userAgreement.html",
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
