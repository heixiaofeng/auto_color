import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

import 'main.dart';
import 'manager/PreferencesManager.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  List<Widget> list = List();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    initData();
  }

  initData() async {
    var isLoadGuidePages = await sPreferencesManager.isLoadGuidePages;
    isLoadGuidePages ? _navigateToHomeScreen() : loadGuidePages();
  }

  loadGuidePages() {
    for (var i = 1; i < 5; i++) list.add(_item(i));
  }

  /// Navigate to Home screen.
  _navigateToHomeScreen() async {
    await sPreferencesManager.setIsLoadGuidePages(true);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MainPage()));
  }

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty)
      return Image.asset('images/launchImage.png', fit: BoxFit.contain);

    return Stack(
      children: <Widget>[
        Container(
          color: color_background,
          width: ScreenWidth,
          height: ScreenHeight,
          child: Swiper(
            itemCount: list.length,
            itemBuilder: (context, index) => list[index],
            loop: false,
            onIndexChanged: (index) {
              setState(() => currentIndex = index);
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: currentIndex < list.length - 1
              ? _itemPage(currentIndex, list.length)
              : RaisedButton(
                  padding: EdgeInsets.fromLTRB(20, 10.0, 20.0, 10.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  color: ThemeColor,
                  child: Text(
                    Translations.of(context).text('splash_complete'),
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  onPressed: () => _navigateToHomeScreen(),
                ),
        )
      ],
    );
  }

  Widget _item(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _itemImage('images/guidePages${index}.png'),
        _itemTitle(
          Translations.of(context).text('splash_title_${index}'),
          Translations.of(context).text('splash_content_${index}'),
        ),
      ],
    );
  }

  Widget _itemImage(String imgResource) {
    return AspectRatio(
      aspectRatio: 1.0 / 1.0,
      child: Container(
        padding: EdgeInsets.only(top: 40, left: 20, bottom: 0, right: 20),
        child: Image.asset(imgResource),
      ),
    );
  }

  Widget _itemTitle(String title, String subTitle) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        children: <Widget>[
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              decoration: TextDecoration.none,
            ),
          ),
          Container(height: 15),
          Text(
            subTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black38,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemPage(int index, int max) {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < max; i++) _itemPageControl(i == index),
        ],
      ),
    );
  }

  Widget _itemPageControl(bool active) {
    var r = 8.0;
    var maxR = 16.0;
    return Container(
      width: active ? maxR : r,
      height: r,
      margin: EdgeInsets.only(left: r * 0.5, right: r * 0.5, bottom: 30),
      decoration: BoxDecoration(
        color: active ? ThemeColor : Colors.black38,
        borderRadius: BorderRadius.circular(r * 0.5),
      ),
    );
  }
}
