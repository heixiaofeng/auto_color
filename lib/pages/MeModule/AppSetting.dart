import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:ugee_note/manager/PreferencesManager.dart';
import 'package:ugee_note/model/account.dart';
import 'package:ugee_note/manager/AccountManager.dart';
import 'package:ugee_note/manager/SyncManager.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/DateUtils.dart';
import 'package:ugee_note/widget/NormalDialog.dart';
import 'package:ugee_note/widget/widgets.dart';

final _logger = Logger("AppSetting");
final switchValue = 'switchValue';

class AppSetting extends StatefulWidget {
  @override
  _AppSettingState createState() => _AppSettingState();
}

class _AppSettingState extends State<AppSetting> {
  bool _switch = false;
  String _syncDate = '';

  _onSwichChanged({bool value}) async {
    if (value != null) await sPreferencesManager.setSwitchValue(value);
    var b = await sPreferencesManager.switchValue;
    setState(() => _switch = b);
  }

  _getSyncDate() async {
    final t = await sPreferencesManager.syncCloudDate;
    setState(() {
      _syncDate =
          t != null ? DateUtils.getDescription(t, DateFormatType.yMd_dot) : "";
    });
  }

  @override
  void initState() {
    super.initState();
    _onSwichChanged();
    _getSyncDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color_background,
      appBar:
          appbar(context, Translations.of(context).text('setting_item_app')),
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
              child: Image.asset(
                'graphics/app_setting.png',
              ),
            ),
          ),
          Container(height: 20),
          wrapRoundedCard(items: [
            entryItem("icons/app_syncCloud.png",
                Translations.of(context).text('splash_title_2'), '',
                loadSwitch: true, switchValue: _switch, switchCall: (value) {
              _onSwichChanged(value: value);
            }),
            if (_switch) line(),
            if (_switch)
              entryItem(
                  "icons/app_immediatelyCloudSync.png",
                  Translations.of(context).text('start_cloud_backup'),
                  _syncDate, onTap: () {
                if (sAccountManager.loginInfo.state != LoginState.sigin) {
                  showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) => NormalDialog(
                        message: Translations.of(context)
                            .text('please_log_in_first')),
                  );
                  return;
                }
                _syncNotes(context);
              }),
            line(),
            entryItem(
                "icons/app_firstLanguage.png",
                Translations.of(context).text('default_recognition_language'),
                Translations.of(context).text('covert_language_name')),
          ]),
        ],
      );

  _syncNotes(BuildContext context) async {
    loading(context,
        text: Translations.of(context).text('cloud_syncing'), popCall: () {});

    await SyncManager.startCloudSync();
    await sPreferencesManager.setSyncCloudDate();
    _getSyncDate();

    Navigator.pop(context);
  }
}
