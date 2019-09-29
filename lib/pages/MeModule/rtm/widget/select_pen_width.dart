import 'package:flutter/material.dart';

class SelectPenWidth extends StatelessWidget {

  static double TotalHeight = 200;
  double totalWidth = 25;
  double percentage;

  Color positiveColor;
  Color negetiveColor;

  SelectPenWidth(
      {Key key,
      @required this.percentage,
      @required this.positiveColor,
      @required this.negetiveColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: totalWidth,
      height: TotalHeight,
      decoration: BoxDecoration(
        color: negetiveColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            color: positiveColor,
            width: totalWidth,
            height: percentage / 100 * TotalHeight,
          )
        ],
      ),
    );
  }
}

/*
Widget _renderSelectPenWidth() {
  return Center(
      child: GestureDetector(
          onPanDown: (DragDownDetails details) {
            print('*** onPanDown: ${details.globalPosition.dy}, local: ${details.localPosition.dy}, percentage: ${details.localPosition.dy / SelectPenWidth.TotalHeight}');
            setState(() {
              percentage = details.localPosition.dy / SelectPenWidth.TotalHeight;
            });
          },
          onPanStart: (DragStartDetails details) {
            initial = details.localPosition.dy;
            print('%%% ${details.localPosition.dy}');
          },
          onPanUpdate: (DragUpdateDetails details) {
            double distance = details.localPosition.dy - initial;
            double percentageAddition = distance / SelectPenWidth.TotalHeight;
            setState(() {
              percentage =
                  (percentage + percentageAddition).clamp(0.0, 100.0);
            });
            print('### onPanUpdate: ${details.localPosition.dy - initial}, percentageAddition: ${distance / 200}, percentage: ${percentage}');
          },
          onPanEnd: (DragEndDetails details) {
            initial = 0;
          },
          child: SelectPenWidth(
              percentage: this.percentage,
              positiveColor: Colors.blueAccent,
              negetiveColor: Colors.grey)));
}
*/