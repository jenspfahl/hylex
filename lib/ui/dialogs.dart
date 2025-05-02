import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'game_ground.dart';

void buildAlertDialog(String text, {NotifyType? type, int seconds = 3}) {
  SmartDialog.showNotify(
    msg: text,
    clickMaskDismiss: true,
    displayTime: Duration(seconds: seconds),
    notifyType: type ?? NotifyType.error,
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
  buildChoiceDialog(text,
      firstString: "OK", 
      firstHandler: okHandler,
      secondString: "CANCEL",
      secondHandler: () {});
}

void ask(String text, Function() yesHandler, {String? noString, Function()? noHandler}) {
  buildChoiceDialog(text,
      firstString: "YES",
      firstHandler: yesHandler,
      secondString: noString ?? "NO",
      secondHandler: () {
        if (noHandler != null) noHandler();
      });
}

void buildChoiceDialog(
    String text,
    {
      double? height,
      double? width,
      required String firstString,
      required Function() firstHandler,
      required String secondString,
      required Function() secondHandler,
      String? thirdString,
      Function()? thirdHandler,
      String? fourthString,
      Function()? fourthHandler,
      String? fifthString,
      Function()? fifthHandler,
  }) {
  SmartDialog.show(builder: (_) {
    var calcHeight = 180 + text.length.toDouble();
    if (thirdString != null && thirdHandler != null) {
      calcHeight += 50;
    }
    if (fourthString != null && fourthHandler != null) {
      calcHeight += 50;
    }
    if (fifthString != null && fifthHandler != null) {
      calcHeight += 50;
    }

    return Container(
      height: height ?? calcHeight,
      width: width ?? 220,
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
                onPressed: () {
                  SmartDialog.dismiss();
                  firstHandler();
                },
                child: Text(firstString ?? "OK")),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () {
                  SmartDialog.dismiss();
                  secondHandler();
                },
                child: Text(secondString)),
            if (thirdString != null && thirdHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    thirdHandler();
                  },
                  child: Text(thirdString)),
            if (fourthString != null && fourthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    fourthHandler();
                  }, 
                  child: Text(fourthString)),
            if (fifthString != null && fifthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    fifthHandler();
                  },
                  child: Text(fifthString)),

          ],
        ),
      ),
    );
  });
}

void buildInputDialog(
    String text,
    {
      double? height,
      double? width,
      String? prefilledText,
      required Function(String) okHandler,
      Function()? cancelHandler,
    }
    ) {
  final controller = TextEditingController(text: prefilledText);
  SmartDialog.show(builder: (_) {
    return Container(
      height: height ?? 200 + text.length.toDouble(),
      width: width ?? 300,
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
                onPressed: () {
                  SmartDialog.dismiss();
                  okHandler(controller.text);
                },
                child: Text("OK")),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () {
                  SmartDialog.dismiss();
                  if (cancelHandler != null) {
                      cancelHandler();
                    }
                },
                child: Text("CANCEL")
            ),

          ],
        ),
      ),
    );
  });
}

