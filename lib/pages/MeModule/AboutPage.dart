import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ugee_note/model/NormalWeb.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'NormalWebPage.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar: appbar(context, Translations.of(context).text('setting_item_about')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) => Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1.0 / 0.5,
            child: Container(
              padding: const EdgeInsets.only(
                top: 40,
                left: 20,
                bottom: 0,
                right: 20,
              ),
              child: Image.asset('graphics/about_36notes.png',
                  width: 20.0, height: 20.0),
            ),
          ),
          Container(height: 20),
          wrapRoundedCard(items: [
            entryItem("icons/about_privacyAgreement.png", Translations.of(context).text('privacy_agreement'), '', onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => NormalWebPage(NormalWebInfo.init(Translations.of(context).text('privacy_agreement'), 'https://www.36notes.com/html/privacyAgreement.html'))));
            }),
            line(),
          ]),
        ],
      );
}
