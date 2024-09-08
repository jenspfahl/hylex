import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'game_ground.dart';

void buildAlertDialog(NotifyType type, String text, {int seconds = 3}) {
  SmartDialog.showNotify(
    msg: text,
    clickMaskDismiss: true,
    displayTime: Duration(seconds: seconds),
    notifyType: NotifyType.error,
  );
}

void buildChoiceDialog(
    double height,
    double width,
    String text,
    String okString,
    Function() okHandler,
    String cancelString,
    Function() cancelHandler,
    [
      String? thirdString,
      Function()? thirdHandler,
      String? fourthString,
      Function()? fourthHandler,
      String? fifthString,
      Function()? fifthHandler,
    ]) {
  SmartDialog.show(builder: (_) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: okHandler,
                child: Text(okString)),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: cancelHandler,
                child: Text(cancelString)),
            if (thirdString != null && thirdHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: thirdHandler,
                  child: Text(thirdString)),
            if (fourthString != null && fourthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: fourthHandler,
                  child: Text(fourthString)),
            if (fifthString != null && fifthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: fifthHandler,
                  child: Text(fifthString)),

          ],
        ),
      ),
    );
  });
}

