import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:ugee_note/model/NormalWeb.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

import 'package:ugee_note/widget/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NormalWebPage extends StatefulWidget {
  NormalWebInfo info;

  NormalWebPage(this.info);

  @override
  _NormalWebPageState createState() => _NormalWebPageState();
}

class _NormalWebPageState extends State<NormalWebPage> {
  Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 1), () => loading(context));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(
        context,
        widget.info.title,
        titleStyle: TextStyle(fontSize: 24, color: Colors.black87),
        implyLeading: false,
        centerTitle: true,
      ),
      body: WebView(
        initialUrl: widget.info.url,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
      ),
    );
  }
}
