import 'package:flutter/material.dart';

toast(GlobalKey<ScaffoldState> scaffoldKey, String text, [int milliseconds = 1000]) {
  scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(text), duration: Duration(milliseconds: milliseconds),));
}