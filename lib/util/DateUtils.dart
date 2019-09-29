import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:quiver/time.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

const millisPerSecond = 1000;

const WEEKDAY_DESCRIPTION = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday'
];

final HH_mm = DateFormat.Hm();

enum DateFormatType {
  yMd_dot,
  yMdHm_dot
}

String FormatTypeDesc(DateFormatType type) {
  String format;
  switch (type) {
    case DateFormatType.yMd_dot:
      format = 'y.M.d';
      break;
    case DateFormatType.yMdHm_dot:
      format = 'y.M.d H:m';
      break;
    default:
      format = 'y.M.d';
      break;
  }
  return format;
}


class DateUtils {
  /// Get the start time in milliseconds of the day
  static int getByDate(int millis) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime(dateTime.year, dateTime.month, dateTime.day)
        .millisecondsSinceEpoch;
  }

  /// Get the start time in milliseconds of the week
  /// [ref link] https://api.dartlang.org/stable/2.1.0/dart-core/DateTime/weekday.html
  /// In accordance with ISO 8601 a week starts with Monday, which has the value 1.
  static int getByWeek(int millis) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    var weekStart = Clock.fixed(dateTime).daysAgo(dateTime.weekday - 1);
    return DateTime(weekStart.year, weekStart.month, weekStart.day)
        .millisecondsSinceEpoch;
  }

  /// Get the start time in milliseconds of the year
  static int getByYear(int millis) {
    var dateTime = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime(dateTime.year).millisecondsSinceEpoch;
  }

  /// Get relative description of time [millis] to now
  static String getDescriptionInDay(int millis, BuildContext context) {
    var nowClock = Clock();
    var that = DateTime.fromMillisecondsSinceEpoch(millis);
    var currentMillis = DateTime.now().millisecondsSinceEpoch;
    if (getByDate(millis) == getByDate(currentMillis)) {
      return Translations.of(context).text('Today');
    } else if (nowClock.daysAgo(1).day == that.day &&
        nowClock.daysAgo(2).isBefore(that)) {
      return Translations.of(context).text('yesterday');
    } else if (getByWeek(currentMillis) == getByWeek(millis)) {
      return Translations.of(context).text(WEEKDAY_DESCRIPTION[that.weekday - 1]);
    } else if (getByYear(currentMillis) == getByYear(millis)) {
      return DateFormat("M月d日").format(that);
    } else {
      return DateFormat("y年M月d日").format(that);
    }
  }

  /// Get relative description of time [millis] by format
  /// format: "y年M月d日"
  static String getDescription(int millis, DateFormatType type) {
    if (millis == null) return '';
    var that = DateTime.fromMillisecondsSinceEpoch(millis);
    return DateFormat(FormatTypeDesc(type)).format(that);
  }
}
