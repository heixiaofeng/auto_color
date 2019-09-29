import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:date_utils/date_utils.dart';
import 'package:ugee_note/res/sizes.dart';
import 'package:ugee_note/tanslations/tanslations.dart';

typedef DayBuilder(BuildContext context, DateTime day);

class PickerCalendar extends StatefulWidget {
  final DateTime initialCalendarDateOverride;
  final List<DateTime> dateTimes;
  final VoidCallback dismiss;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<Tuple2<DateTime, DateTime>> onSelectedRangeChange;

  PickerCalendar({
    this.initialCalendarDateOverride,
    this.dateTimes,
    this.dismiss,
    this.onDateSelected,
    this.onSelectedRangeChange,
  });

  @override
  _PickerCalendarState createState() => _PickerCalendarState();
}

class _PickerCalendarState extends State<PickerCalendar> {
  List<DateTime> _currentMonthDays;

  DateTime _currentDate = DateTime.now();
  String _displayTop = '';

  void initState() {
    super.initState();

    final datetime = widget.initialCalendarDateOverride != null
        ? widget.initialCalendarDateOverride
        : DateTime.now();
    resetToDatetime(dateTime: datetime);
  }

  @override
  Widget build(BuildContext context) {
    final top = 80.0;
    final spacing = 40.0;
    final partWidth = (ScreenWidth - spacing * 2.0) / 7.0;
    return GestureDetector(
      child: Container(
        color: Colors.black38,
        child: Container(
          margin: EdgeInsets.only(
              top: top,
              left: spacing,
              right: spacing,
              bottom: ScreenHeight - top - 7.0 * partWidth),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _topYearAndMonth(),
              _buildFlexible(_calendarGridView, _calendarGridView)
            ],
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
      onTap: widget.dismiss,
    );
  }

  Flexible _buildFlexible(Widget first, Widget second) {
    return Flexible(
      child: AnimatedCrossFade(
        firstChild: first,
        secondChild: second,
        firstCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        secondCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        sizeCurve: Curves.decelerate,
        crossFadeState: CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _topYearAndMonth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FlatButton(
          child: Image.asset('icons/month_previous.png', width: 15, height: 15),
          onPressed: previousMonth,
        ),
        Container(
          width: 80,
          child: Text(
            _displayTop,
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.black,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        FlatButton(
          child: Image.asset('icons/month_next.png', width: 15, height: 15),
          onPressed: nextMonth,
        ),
      ],
    );
  }

  Widget get _calendarGridView {
    return Container(
      child: GestureDetector(
        onHorizontalDragStart: (gestureDetails) => beginSwipe(gestureDetails),
        onHorizontalDragUpdate: (gestureDetails) =>
            getDirection(gestureDetails),
        onHorizontalDragEnd: (gestureDetails) => endSwipe(gestureDetails),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          padding: EdgeInsets.only(bottom: 0.0),
          children: _calendarBuilder(),
        ),
      ),
    );
  }

  List<Widget> _calendarBuilder() {
    List<Widget> dayWidgets = [];
    List<DateTime> calendarDays = _currentMonthDays;

    [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ].forEach(
      (week) {
        dayWidgets.add(
          _weekTitle(Translations.of(context).text(week)),
        );
      },
    );

    bool monthStarted = false;
    bool monthEnded = false;

    calendarDays.forEach(
      (day) {
        if (monthStarted && day.day == 1) monthEnded = true;

        if (Utils.isFirstDayOfMonth(day)) monthStarted = true;

        var hadIcon = false;
        for (final datetime in widget.dateTimes) {
          if (datetime.year == day.year &&
              datetime.month == day.month &&
              datetime.day == day.day) {
            hadIcon = true;
            break;
          }
        }
        dayWidgets.add(
          _dayTitle(
            day,
            monthStarted && !monthEnded,
            isSelected: Utils.isSameDay(day, DateTime.now()),
            haveIcon: hadIcon,
            onDateSelected: () {
              resetToDatetime(dateTime: day, call: widget.onDateSelected);
            },
          ),
        );
      },
    );
    return dayWidgets;
  }

  Widget _weekTitle(String week) {
    return GestureDetector(
      child: Container(
        alignment: Alignment.center,
        child: Text(
          week,
          style: TextStyle(
            color: (week == Translations.of(context).text('Sunday') ||
                    week == Translations.of(context).text('Saturday'))
                ? Colors.red
                : Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _dayTitle(DateTime day, bool isInMonth,
      {bool isSelected = false,
      bool haveIcon = false,
      VoidCallback onDateSelected = null}) {
    return GestureDetector(
      onTap: onDateSelected,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: isSelected
                  ? BoxDecoration(shape: BoxShape.circle, color: Colors.black)
                  : BoxDecoration(),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isInMonth ? Colors.black : Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            if (haveIcon)
              Image.asset('icons/note_icon.png', width: 10, height: 10),
          ],
        ),
      ),
    );
  }

  void resetToDatetime(
      {DateTime dateTime = null, ValueChanged<DateTime> call = null}) {
    setState(() {
      _currentDate = dateTime != null ? dateTime : DateTime.now();
      _refreshBySelectedDate();
    });

    if (call != null) call(_currentDate);
  }

  void nextMonth() {
    setState(() {
      _currentDate = Utils.nextMonth(_currentDate);
      _refreshBySelectedDate();
    });
  }

  void previousMonth() {
    setState(() {
      _currentDate = Utils.previousMonth(_currentDate);
      _refreshBySelectedDate();
    });
  }

  void nextWeek() {
    setState(() {
      _currentDate = Utils.nextWeek(_currentDate);
      _refreshBySelectedDate();
    });
  }

  void previousWeek() {
    setState(() {
      _currentDate = Utils.previousWeek(_currentDate);
      _refreshBySelectedDate();
    });
  }

  void _refreshBySelectedDate() {
    var firstDateOfNewMonth = Utils.firstDayOfMonth(_currentDate);
    var lastDateOfNewMonth = Utils.lastDayOfMonth(_currentDate);
    updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
    _currentMonthDays = Utils.daysInMonth(_currentDate);
    if (_currentMonthDays.length == 42) {
      if (_currentMonthDays.first == firstDateOfNewMonth) {
        _currentMonthDays = _currentMonthDays.sublist(0, 34);
      } else {
        _currentMonthDays = _currentMonthDays.sublist(7, 41);
      }
    }
    _displayTop = '${_currentDate.year}.${_currentDate.month}';
  }

  void updateSelectedRange(DateTime start, DateTime end) {
    var selectedRange = Tuple2<DateTime, DateTime>(start, end);
    if (widget.onSelectedRangeChange != null) {
      widget.onSelectedRangeChange(selectedRange);
    }
  }

  var gestureStart;
  var gestureDirection;

  void beginSwipe(DragStartDetails gestureDetails) {
    gestureStart = gestureDetails.globalPosition.dx;
  }

  void getDirection(DragUpdateDetails gestureDetails) {
    gestureDirection = gestureDetails.globalPosition.dx < gestureStart
        ? 'rightToLeft'
        : 'leftToRight';
  }

  void endSwipe(DragEndDetails gestureDetails) {
    gestureDirection == 'rightToLeft' ? nextMonth() : previousMonth();
  }
}
