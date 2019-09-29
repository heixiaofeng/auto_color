import 'package:flutter/material.dart';
import 'package:ugee_note/tanslations/tanslations.dart';
import 'package:ugee_note/widget/widgets.dart';

final _allOptionalTimes = [15, 30, 45, 60, 0];

String formatLockTime(int _minutes, BuildContext context) {
  final duration = Duration(minutes: _minutes);
  if (duration.inSeconds == 0) return Translations.of(context).text('Never');

  if (duration.inHours >= 1) {
    var desc = "${duration.inHours}${Translations.of(context).text('hour')}";
    final m = duration.inMinutes % Duration.minutesPerHour;
    if (m >= 1) desc += "${m}${Translations.of(context).text('minute')}";
    return desc;
  }
  return "${duration.inMinutes}${Translations.of(context).text('minute')}";
}

class AutoLockTime extends Dialog {
  final VoidCallback cancel;
  final Function(int value) confim;

  AutoLockTime({
    Key key,
    this.cancel,
    this.confim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return dialogCard(
      child: Container(
        color: Colors.white,
        margin: EdgeInsets.all(0),
        child: ListView.separated(
          itemCount: _allOptionalTimes.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              dense: true,
              title: Text(
                formatLockTime(_allOptionalTimes[index], context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15.5,
                  decorationColor: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              onTap: () {
                if (confim != null) confim(_allOptionalTimes[index]);
                Navigator.pop(context);
              },
            );
          },
          separatorBuilder: (context, index) => line(),
        ),
      ),
    );
  }
}
