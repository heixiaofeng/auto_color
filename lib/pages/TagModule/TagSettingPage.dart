import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';
import 'package:ugee_note/model/Tag.dart';
import 'package:ugee_note/model/TagSkin.dart';
import 'package:ugee_note/model/database.dart';
import 'package:ugee_note/res/colors.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/NormalDialog.dart';
import 'package:ugee_note/widget/WDMAlertDialog.dart';
import 'package:ugee_note/widget/widgets.dart';

class TagSettingPage extends StatefulWidget {
  TagSettingPage(this.tag);

  Tag tag;

  @override
  _TagSettingPageState createState() => _TagSettingPageState();
}

class _TagSettingPageState extends State<TagSettingPage> {
  StreamSubscription _tagskinSubscription;
  var _noteskins = List<TagSkin>();

  TagSkin _skin;

  _setSkin(int skinid) async {
    if (skinid != null) {
      await sTagProvider.update(widget.tag.id, skinID: skinid);
      widget.tag.skinID = skinid;
      Navigator.pop(context); //  TODO 隐藏背景灰色 & 更新当前note的skinid
    }
    final skin = await sTagSkinProvider.queryByID(widget.tag.skinID);
    setState(() => _skin = skin);
  }

  _setName(String name) async {
    if (name != null) {
      final length = await sTagProvider.update(widget.tag.id, name: name);
      if (length != 1) {
        showDialog(
          // 设置点击 dialog 外部不取消 dialog，默认能够取消
          barrierDismissible: false,
          context: context,
          builder: (context) => NormalDialog(message: '标签名已存在'),
        );
        return;
      }
      setState(() => widget.tag.name = name);
    }
  }

  var _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tagskinSubscription = sTagProvider.changeStream.listen(_onNoteSkinChange);
    _onNoteSkinChange(null);
    _setSkin(null);
  }

  @override
  void dispose() {
    super.dispose();
    _tagskinSubscription.cancel();
  }

  _onNoteSkinChange(DBChangeType type) async {
    var skins = await sTagSkinProvider.queryAvalibleTagSkins();
    setState(() => _noteskins
      ..clear()
      ..addAll(skins));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(
        context,
        Translations.of(context).text('label_setting'),
        actions: <Widget>[
          appbarRighItem('icons/delete_black.png', () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return WDMAlertDialog(
                  title: Translations.of(context).text('delete_current_label'),
                  message: Translations.of(context)
                      .text('notes_within_the_tag_will_not_be_deleted'),
                  cancelText: Translations.of(context).text('Cancel'),
                  confimText: Translations.of(context).text('OK'),
                  type: Operation.NOTICE,
                  confim: (value) async {
                    sTagProvider.delete(widget.tag);
                    Navigator.pop(context);
                  },
                );
              },
            );
          }),
        ],
      ),
      body: Container(
        color: color_background,
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return Column(children: <Widget>[
      AspectRatio(
        aspectRatio: 1.0 / 0.72,
        child: Container(
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            bottom: 20,
            right: 20,
          ),
          child:
              Image.asset(_skin?.localImage ?? '', width: 20.0, height: 20.0),
        ),
      ),
      wrapRoundedCard(items: [
        entryItem(
            null, Translations.of(context).text('label_name'), widget.tag.name,
            onTap: () {
          _textEditingController.text = widget.tag.name;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return WDMAlertDialog(
                cancelText: Translations.of(context).text('Cancel'),
                confimText: Translations.of(context).text('OK'),
                type: Operation.EDIT,
                textEditingController: _textEditingController,
                title: Translations.of(context).text('label_name'),
                confim: (value) {
                  _setName(value);
                },
              );
            },
          );
        }),
        line(),
        entryItem(null, Translations.of(context).text('label_cover'), _skin.name,
            onTap: () {
          showModalBottomSheet(
            backgroundColor: Colors.transparent,
            context: context,
            builder: (BuildContext context) {
              return _selectSkin();
            },
          );
        }),
      ])
    ]);
  }

  Widget _selectSkin() {
    return normalBottomSheet(
      ScreenWidth * 0.88,
      Container(
        margin: EdgeInsets.only(top: 35),
        height: ScreenWidth / 2.0,
        child: ListView.builder(
          itemCount: 1,
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
          itemBuilder: (context, index) => _buildSectionView(_noteskins),
        ),
      ),
    );
  }

  Widget _buildSectionView(List<TagSkin> entry) {
    return Table(
      children: partition(entry, 4).map((items) {
        var itemWidgets = items.cast<TagSkin>().map(_skinItem).toList();
        var dummyWidgets =
            List.generate(items.length % 4, (index) => Container());
        return TableRow(children: itemWidgets..addAll(dummyWidgets));
      }).toList(),
    );
  }

  Widget _skinItem(TagSkin tagskin) {
    return Container(
      color: Colors.white,
      width: ScreenWidth / 6.0,
      padding: EdgeInsets.only(top: 10, bottom: 20),
      child: GestureDetector(
        child: AspectRatio(
          aspectRatio: 136.0 / 181.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Image.asset(tagskin.localImage),
                    if (widget.tag.skinID == tagskin.id)
                      Opacity(
                          opacity: 0.5,
                          child: Image.asset('icons/selected_note.png')),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Text(tagskin.name),
              )
            ],
          ),
        ),
        onTap: () {
          setState(() {
            _setSkin(tagskin.id);
          });
        },
      ),
    );
  }
}
