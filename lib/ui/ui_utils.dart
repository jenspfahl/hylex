
import 'package:flutter/material.dart';
import 'package:hyle_x/engine/game_engine.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../model/chip.dart';
import '../model/common.dart';
import '../model/coordinate.dart';
import '../model/messaging.dart';
import 'dialogs.dart';




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

toast(BuildContext context, String message, Color? color) {
  _calcMessageDuration(message.length, true).then((duration) {
    var messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
        SnackBar(
            duration: duration,
            showCloseIcon: true,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(5),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            elevation: 10,
            content: Text(message, style: TextStyle(color: color))));
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


Widget buildRoleIndicator(
    Role role, {
      required bool isSelected,
      PlayerType? playerType,
      GameEngine? gameEngine,
      Color? color,
      Color? backgroundColor,
      int? points,
    }) {
  final isLeftElseRight = role == Role.Chaos;

  final iconData = playerType == PlayerType.LocalAi
      ? MdiIcons.brain
      : playerType == PlayerType.RemoteUser
      ? Icons.transcribe
      : playerType == PlayerType.LocalUser
      ? MdiIcons.account
      : null;
  final icon = iconData != null
      ? Transform.flip(
        flipX: playerType == PlayerType.RemoteUser,
        child: Icon(iconData, color: color, size: 16))
      : null;

  var _points = gameEngine != null
      ? gameEngine.play.stats.getPoints(role)
      : points;

  if (gameEngine?.play.header.playMode == PlayMode.Classic && role == Role.Chaos) {
    if (gameEngine?.play.header.rolesSwapped == true) {
      // Order points of first game  for Chaos if Classic mode in second Game
      _points = gameEngine?.play.stats.classicModeFirstRoundOrderPoints;
    }
    else {
      // no points for Chaos if Classic mode in first Game
      _points = null;
    }
  }

  return Chip(
    padding: EdgeInsets.zero,
    shape: isLeftElseRight
        ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)))
        : const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
    label: isLeftElseRight
        ? Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (icon != null ) icon,
        if (icon != null ) const Text(" "),
        Text(_points != null ? "${role.name} - ${_points}" : role.name,
            style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : null)),
      ],
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(_points != null ? " ${_points} - ${role.name}" : role.name,
            style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : null)),
        if (icon != null ) const Text(" "),
        if (icon != null ) icon,
      ],
    ),
    backgroundColor: backgroundColor,
    elevation: 3,
    shadowColor: playerType == PlayerType.LocalUser || playerType == null ? Colors.black : null,
  );
}

Widget buildGameChip(
    String text,
    {
      required int dimension,
      bool showCoordinates = false,
      Color? chipColor,
      Color? backgroundColor,
      Coordinate? where,
      GestureLongPressStartCallback? onLongPressStart,
      GestureLongPressEndCallback? onLongPressEnd,
    }) {

  if (chipColor == null) {

    return Container(
      color: backgroundColor,
      child: where != null && text.isEmpty && showCoordinates
          ? Center(child: Text(_getPositionText(where, dimension),
          style: TextStyle(
              fontSize: dimension > 9 ? 10 : null,
              color: Colors.grey[400])))
          : null,
    );
  }
  return Container(
    color: backgroundColor,
    child: GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: CircleAvatar(
        backgroundColor: chipColor,
        maxRadius: 60,
        child: Text(text,
            style: TextStyle(
              fontSize: dimension > 7 ? 12 : 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
    ),
  );
}


String _getPositionText(Coordinate where, int dimension) {
  if (where.x == 0 && where.y == 0 ||
      where.x == 0 && where.y == dimension - 1 ||
      where.x == dimension - 1 && where.y == 0 ||
      where.x == dimension - 1 && where.y == dimension - 1) {
    return where.toReadableCoordinates();
  }
  else if (where.x > 0 && where.y == 0 || where.x > 0 && where.y == dimension - 1) {
    return String.fromCharCode('A'.codeUnitAt(0) + where.x);
  }
  else if (where.y > 0 && where.x == 0 || where.y > 0 && where.x == dimension - 1) {
    return (where.y + 1).toString();
  }
  else {
    return "";
  }
}



