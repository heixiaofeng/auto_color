import 'dart:ui';

final ThemeBackgroundColor = Color(0xffF6F6F6);
final ThemeColor = Color(0xff115EAD);
final DividerColor = Color(0xffd9d9d9);

final color_background = Color(0xFFF5F4F4);
final color_divider = Color(0xFFE5E5E5);
final color_line = Color(0xFFBFBFBF);

final showPenColors = [
  '#FFFFFF',
  '#FFE82A',
  '#2E48FF',
  '#7BFF16',
  '#F836FF',
  '#32397E',
  '#BAC290',
  '#492C4F',
  '#FFAAAA',
  '#FFBE79',
  '#FF0000',
  '#000000'
];

//  '#FFE82A'   ->   0xFFFFE82A
getColorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) hexColor = "FF" + hexColor;
  return int.parse(hexColor, radix: 16);
}
