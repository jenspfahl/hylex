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

void confirmOrDo(bool confirmCondition, String confirmText, Function() doHandler) {
  if (confirmCondition) {
    confirm(confirmText, () {
      doHandler();
    });
  }
  else {
    doHandler();
  }
}

void askOrDo(bool confirmCondition, String confirmText, Function() doHandler) {
  if (confirmCondition) {
    ask(confirmText, () {
      doHandler();
    });
  }
  else {
    doHandler();
  }
}

void confirm(String text, Function() okHandler) {
  buildChoiceDialog(180 + text.length.toDouble(), 180, text,
      "OK", () {
        SmartDialog.dismiss();
        okHandler();
      },
      "CANCEL", () {
        SmartDialog.dismiss();
      });
}

void ask(String text, Function() okHandler) {
  buildChoiceDialog(180 + text.length.toDouble(), 180, text,
      "YES", () {
        SmartDialog.dismiss();
        okHandler();
      },
      "NO", () {
        SmartDialog.dismiss();
      });
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

void buildInputDialog(
    double height,
    double width,
    String text,
    String? prefilledText,
    Function(String) okHandler,
    Function() cancelHandler,
    ) {
  final controller = TextEditingController(text: prefilledText);
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
            TextField(
              controller: controller,
              style: TextStyle(color: Colors.lightGreenAccent),
              cursorColor: Colors.lightGreen,
            ),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () => okHandler(controller.text),
                child: Text("OK")),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: cancelHandler,
                child: Text("CANCEL")),

          ],
        ),
      ),
    );
  });
}

