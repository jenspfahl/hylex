
import 'package:flutter/material.dart';

import '../model/messaging.dart';




bool isDarkMode(BuildContext context) => Theme.of(context).brightness == Brightness.dark;


String truncate(String text, { required int length, omission = '...' }) {
  if (length >= text.length) {
    return text;
  }
  return text.replaceRange(length, text.length, omission);
}


Widget buildFilledButton(
    BuildContext context,
    IconData? iconData,
    String text,
    VoidCallback? onPressed,
    {bool isBold = false}) {
  return FilledButton(onPressed: onPressed, child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (iconData != null) Icon(iconData),
      if (iconData != null )const Text("  "),
      Text(text.toUpperCase(),
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
    ],
  ));
}

Widget buildOutlinedButton(
    BuildContext context,
    IconData? iconData,
    String text,
    VoidCallback? onPressed) {
  return OutlinedButton(onPressed: onPressed, child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (iconData != null) Icon(iconData),
      if (iconData != null )const Text("  "),
      Text(text.toUpperCase()),
    ],
  ));
}

toastInfo(BuildContext context, String message) {
  toast(context, message, null);
}

toastLost(BuildContext context, String message) {
  toast(context, message, Colors.redAccent);
}

toastWon(BuildContext context, String message) {
  toast(context, message, Colors.lightGreenAccent);
}

toastWonOrLost(BuildContext context, String message) {
  toast(context, message, Colors.lightBlueAccent);
}

toast(BuildContext context, String message, Color? backgroundColor) {
  _calcMessageDuration(message.length, true).then((duration) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
            backgroundColor: backgroundColor,
            duration: duration,
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            elevation: 10,
            content: Text(message)));
  });
}

Future<Duration> _calcMessageDuration(int messageLength, bool isError) async {
  return Duration(milliseconds: (messageLength * (isError ? 100 : 80)).toInt());
}

Uri? extractAppLinkFromString(String s) {
  final link = deepLinkRegExp.stringMatch(s);
  if (link == null) {
    print("No app link found in $s");
    return null;
  }
  final uri = Uri.parse(link);
  debugPrint("Extracted app link: $uri");
  return uri;
}

Color getColorFromIdx(int i) {
  /**
   *    rgb
   *  0 x
   *  1 xx
   *  2  x
   *  3  xx
   *  4   x
   *  5 x x
   *  6 xxx
   *  7 y
   *  8 yy
   *  9  y
   * 10  yy
   * 11   y
   * 12 y y
   */

  int r,g,b;
  if (i > 6) {
    r = 45;
    g = 45;
    b = 45;
  }
  else {
    r = 10;
    g = 10;
    b = 10;
  }

  if (i == 0 || i == 1 || i == 5 || i == 6) {
    r = 210;
  }
  if (i == 1 || i == 2 || i == 3 || i == 6) {
    g = 210;
  }
  if (i == 3 || i == 4 || i == 5 || i == 6) {
    b = 210;
  }

  if (i == 7 || i == 8 || i == 12) {
    r = 145;
  }
  if (i == 8 || i == 9 || i == 10) {
    g = 145;
  }
  if (i == 10 || i == 11 || i == 12) {
    b = 145;
  }

  if (i == 1) { // make yellow a bit brighter
    r = 250;
    g = 180;
    b = 0;
  }

  if (i == 6) { // make gray a bit darker
    r = 110;
    g = 110;
    b = 110;
  }

  return Color.fromARGB(
      210, r, g, b);
}

