import 'package:flutter/material.dart';



bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;


String truncate(String text, { required int length, omission = '...' }) {
  if (length >= text.length) {
    return text;
  }
  return text.replaceRange(length, text.length, omission);
}


toastInfo(BuildContext context, String message) {
  _calcMessageDuration(message, false).then((duration) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
            duration: duration,
            content: Text(message)));
  });
}

toastError(BuildContext context, String message) {
  _calcMessageDuration(message, true).then((duration) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            duration: duration,
            content: Text(message)));
  });
}

Future<Duration> _calcMessageDuration(String message, bool isError) async {
  return Duration(milliseconds: (message.length * (isError ? 100 : 80)).toInt());
}


bool isTooClose(Color color, Color otherColor, int radix) {
  debugPrint("${color.red}/${round(color.red, radix)} == ${otherColor.red}/${round(otherColor.red, radix)}");
  return round(color.red, radix) == round(otherColor.red, radix)
      && round(color.green, radix) == round(otherColor.green, radix)
      && round(color.blue, radix) == round(otherColor.blue, radix);
}

int round(int value, int radix) => (value ~/ radix) * radix;

bool tooDark(Color color) => color.red < 50 && color.green < 50 && color.blue < 50;

bool tooLight(Color color) => color.red > 200 && color.green > 180 && color.blue > 200;


