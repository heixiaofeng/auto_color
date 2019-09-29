import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:notepad_kit/NotepadManager.dart';
import 'package:notepad_kit/notepad.dart';
import 'package:provider/provider.dart';
import 'package:ugee_note/SplashScreen.dart';
import 'package:ugee_note/pages/HomeModule/NoteBrowserPage.dart';
import 'package:ugee_note/pages/MeModule/rtm/pages/rtc_note_screen.dart';
import 'package:ugee_note/pages/MeModule/rtm/utils/tools.dart';
import 'package:ugee_note/tanslations/locale_util.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/util/StatusStore.dart';
import 'package:ugee_note/util/permission.dart';
import 'package:ugee_note/util/public.dart';
import 'package:ugee_note/widget/widgets.dart';

import 'manager/RealtimeManager.dart';
import 'package:ugee_note/pages/HomeModule/HomePage.dart';
import 'package:ugee_note/pages/MeModule/MePage.dart';
import 'package:ugee_note/pages/TagModule/TagPage.dart';
import 'res/colors.dart';

void main() => runApp(ChangeNotifierProvider(builder: (context) => sStatusStore, child: App()));

//  全局的~
final BottomNavigationBarStreamController = StreamController<bool>.broadcast();

Stream<bool> get BottomNavigationBarStream =>
    BottomNavigationBarStreamController.stream;

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    loadDeafultData();
    return MaterialApp(
      title: '36记',
      localizationsDelegates: [
        const TranslationsDelegate(), // 指向默认的处理翻译逻辑的库
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: localeUtil.supportedLocales(),
      home: SplashScreen(),
      routes: <String, WidgetBuilder>{
        'rtc_note_screen': (ctx) => RTCNoteScreen()
      },
    );
  }
}

class MainPage extends StatefulWidget {
  setHiddenBottomNavigationBar(bool value) {}

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var _navigationIndex = 0;
  var _navigationPages = <Widget>[HomePage(), TagPage(), MePage()];
  var _isHiddenBottomNavigationBar = false;

  StreamSubscription<NotepadStateEvent> _notepadStateSubscription;
  StreamSubscription<bool> _bottomNavigationBarSubscription;
  StreamSubscription<String> _eventMessageSubscription;

  var isConnected = false;

  double iconSize = 25.0;

  @override
  void initState() {
    super.initState();

    _notepadStateSubscription =
        sNotepadManager.notepadStateStream.listen(_onNotepadStateEvent);
    _bottomNavigationBarSubscription =
        BottomNavigationBarStream.listen(_onBottomNavigationBar);
    _eventMessageSubscription =
        sNotepadManager.eventMessageStream.listen(_onEventMessage);
  }

  @override
  void dispose() {
    super.dispose();
    _notepadStateSubscription.cancel();
    _bottomNavigationBarSubscription.cancel();
    _eventMessageSubscription.cancel();
  }

  String deviceName = '';

  _onNotepadStateEvent(NotepadStateEvent event) async {
    final oldIsConnected = isConnected;
    setState(() => isConnected = event.state == NotepadState.Connected);
    await Future.delayed(Duration(milliseconds: 1000), null); // TODO fix
    if (!oldIsConnected && event.state == NotepadState.Connected) {
      deviceName = await sNotepadManager.getDeviceName();
      var memoSummary = await sNotepadManager.getMemoSummary();
      var deviceBattery = await sNotepadManager.getBatteryInfo();
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return bottomDialog(
              title: deviceName,
              imageResource: 'icons/note_covert2.png',
              bottomText: Translations.of(context).text(
                  'paper_recorded_in_device_less').replaceAll(
                  '{n}', '${memoSummary.memoCount}'),
              battery: '${deviceBattery.percent}%');
        },
      );
    }
    
    if (oldIsConnected && event.state == NotepadState.Disconnected) {
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return bottomDialog(
              title: deviceName,
              imageResource: 'icons/note_covert1.png',
              bottomText:
                  Translations.of(context).text('action_disconnect_selected'));
        },
      );
    }
  }

  _onBottomNavigationBar(bool value) {
    setState(() => _isHiddenBottomNavigationBar = value);
  }

  _onEventMessage(String type) async {
    if (type == 'keyup') {
      var current = DateTime.now().millisecondsSinceEpoch;
      if (current - sRealtimeManager.lastKeyupTime <= 2000) return; //  防抖动处理

      if (sStatusStore.browsePage_createtime != -1)
        await Navigator.pop(context);

      await sRealtimeManager.intoRealtime();
      await Future.delayed(Duration(milliseconds: 200), () {});
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoteBrowserPage(sRealtimeManager.note,
              type: NoteBrowserType.edit),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    sStatusStore.setContext(context);

    return Scaffold(
      body: _navigationPages[_navigationIndex],
      floatingActionButton: _isHiddenBottomNavigationBar
          ? null
          : realtimeFloatingActionButton(context),
      bottomNavigationBar:
          _isHiddenBottomNavigationBar ? null : _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _navigationIndex,
      onTap: (i) => setState(() => _navigationIndex = i),
      items: [
        BottomNavigationBarItem(
            title: Text(Translations.of(context).text('tab_text_1')),
            icon: Image.asset('icons/nav_home.png',
                width: iconSize, height: iconSize),
            activeIcon: Image.asset('icons/nav_home_active.png',
                width: iconSize, height: iconSize)),
        BottomNavigationBarItem(
            title: Text(Translations.of(context).text('tab_text_2')),
            icon: Image.asset('icons/nav_tag.png',
                width: iconSize, height: iconSize),
            activeIcon: Image.asset('icons/nav_tag_active.png',
                width: iconSize, height: iconSize)),
        BottomNavigationBarItem(
            title: Text(Translations.of(context).text('tab_text_4')),
            icon: Image.asset('icons/nav_me.png',
                width: iconSize, height: iconSize),
            activeIcon: Image.asset('icons/nav_me_active.png',
                width: iconSize, height: iconSize))
      ],
    );
  }

  FloatingActionButton realtimeFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      child: Image.asset(isConnected
          ? 'icons/fab_compose_active.png'
          : 'icons/fab_compose.png'),
      backgroundColor: Colors.transparent,
      onPressed: () {
        if (isConnected) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      NoteBrowserPage(sRealtimeManager.note)));
        } else {
          pushNotepadScanpage(context);
        }
      },
    );
  }
}
