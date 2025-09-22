import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

const DIALOG_BG = Color(0xFF2E1B1A);


void showAlertDialog(String text) {


  SmartDialog.showNotify(
    msg: text,
    clickMaskDismiss: true,
    notifyType: NotifyType.error,
    builder: (context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: DIALOG_BG,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error, size: 22, color: Colors.white70),
        Container(
          margin: const EdgeInsets.only(top: 5),
          child: Text(text, style: TextStyle(color: Colors.white70)),
        ),
      ]),
    );
  });
  Future.delayed(Duration(seconds: text.length * 50)).then((_) => SmartDialog.dismiss());
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
  showChoiceDialog(text,
      firstString: "OK", 
      firstHandler: okHandler,
      secondString: "CANCEL",
      secondHandler: () {});
}

void ask(String text, Function() yesHandler, {String? noString, Function()? noHandler}) {
  showChoiceDialog(text,
      firstString: "YES",
      firstHandler: yesHandler,
      secondString: noString ?? "NO",
      secondHandler: () {
        if (noHandler != null) noHandler();
      });
}

void showChoiceDialog(
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
        color: DIALOG_BG,
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
                child: Text(firstString.toUpperCase())),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () {
                  SmartDialog.dismiss();
                  secondHandler();
                },
                child: Text(secondString.toUpperCase())),
            if (thirdString != null && thirdHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    thirdHandler();
                  },
                  child: Text(thirdString.toUpperCase())),
            if (fourthString != null && fourthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    fourthHandler();
                  }, 
                  child: Text(fourthString.toUpperCase())),
            if (fifthString != null && fifthHandler != null)
              OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.lightGreenAccent),
                  onPressed: () {
                    SmartDialog.dismiss();
                    fifthHandler();
                  },
                  child: Text(fifthString.toUpperCase())),

          ],
        ),
      ),
    );
  });
}

showShowLoading(String text) async {
  SmartDialog.showLoading(msg: text, builder: (_) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: DIALOG_BG,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        //loading animation
        CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(Colors.white70),
        ),

        //msg
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: Text(text, style: TextStyle(color: Colors.white70)),
        ),
      ]),
    );
  });
  await Future.delayed(const Duration(seconds: 1));
}

void showInputDialog(
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
        color: DIALOG_BG,
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

