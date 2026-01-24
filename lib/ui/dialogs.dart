import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/messaging.dart';

import '../l10n/app_localizations.dart';

const DIALOG_BG = Color(0xFF2E1B1A);


void showAlertDialog(String text,
    {
      IconData? icon = Icons.error,
      Duration? duration,
    }) {

  SmartDialog.dismiss();

  SmartDialog.showNotify(
    msg: text,
    clickMaskDismiss: true,
    notifyType: NotifyType.error,
    displayTime: duration ?? Duration(milliseconds: max(text.length * 200, 3000)),
    builder: (context) {
    return GestureDetector(
      onTap: () => SmartDialog.dismiss(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: DIALOG_BG,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, size: 22, color: Colors.white70),
          Container(
            margin: const EdgeInsets.only(top: 5),
            child: Text(text, style: TextStyle(color: Colors.white70)),
          ),
        ]),
      ),
    );
  });
  Future.delayed(Duration(seconds: text.length * 50)).then((_) => SmartDialog.dismiss());
}

void confirmOrDo(bool confirmCondition, String confirmText, MaterialLocalizations l10n, Function() doHandler) {
  if (confirmCondition) {
    confirm(confirmText, l10n, () {
      doHandler();
    });
  }
  else {
    doHandler();
  }
}

void askOrDo(bool confirmCondition, String confirmText, AppLocalizations l10n, Function() doHandler) {
  if (confirmCondition) {
    ask(confirmText, l10n, () {
      doHandler();
    });
  }
  else {
    doHandler();
  }
}

void confirm(String text, MaterialLocalizations l10n, Function() okHandler, {
  String? title,
  IconData? icon,
}) {
  showChoiceDialog(text,
      title: title,
      icon: icon,
      firstString: l10n.okButtonLabel,
      firstHandler: okHandler,
      secondString: l10n.cancelButtonLabel,
      secondHandler: () {});
}

void ask(String text, AppLocalizations l10n, Function() yesHandler, {
  IconData? icon,
  String? title,
  String? noString,
  Function()? noHandler,
}) {
  showChoiceDialog(text,
      title: title,
      icon: icon,
      firstString: l10n.yes,
      firstHandler: yesHandler,
      secondString: noString ?? l10n.no,
      secondHandler: () {
        if (noHandler != null) noHandler();
      });
}

void showChoiceDialog(
    String text,
    {
      String? title,
      IconData? icon,
      double? height,
      double? width,
      required String firstString,
      String? firstDescriptionString,
      required Function() firstHandler,
      required String secondString,
      String? secondDescriptionString,
      required Function() secondHandler,
      String? thirdString,
      String? thirdDescriptionString,
      Function()? thirdHandler,
      String? fourthString,
      String? fourthDescriptionString,
      Function()? fourthHandler,
      String? fifthString,
      String? fifthDescriptionString,
      Function()? fifthHandler,
      int? highlightButtonIndex
  }) {
  SmartDialog.dismiss();

  SmartDialog.show(tag: "CUSTOM", builder: (_) {
    var calcHeight = 180 + text.length.toDouble();
    if (title != null) calcHeight += 30;
    if (thirdString != null && thirdHandler != null) {
      calcHeight += 50;
    }
    if (fourthString != null && fourthHandler != null) {
      calcHeight += 50;
    }
    if (fifthString != null && fifthHandler != null) {
      calcHeight += 50;
    }

    if (firstDescriptionString != null) {
      calcHeight += firstDescriptionString.length.toDouble() * 2;
    }
    if (secondDescriptionString != null) {
      calcHeight += secondDescriptionString.length.toDouble() * 2;
    }
    if (thirdDescriptionString != null) {
      calcHeight += thirdDescriptionString.length.toDouble() * 2;
    }
    if (fourthDescriptionString != null) {
      calcHeight += fourthDescriptionString.length.toDouble() * 2;
    }
    if (fifthDescriptionString != null) {
      calcHeight += fifthDescriptionString.length.toDouble() * 2;
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
            if (icon != null || title != null) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) Icon(icon, color: Colors.white),
              if (icon != null && title != null) const Text(" "),
              if (title != null) Text(title, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            Text(
              text,
              style: const TextStyle(color: Colors.white),
            ),
            _buildChoiceButton(firstHandler, _emphasise(firstString, highlightButtonIndex == 0), firstDescriptionString,
                highlighted: highlightButtonIndex == 0),
            _buildChoiceButton(secondHandler, _emphasise(secondString, highlightButtonIndex == 1), secondDescriptionString,
                highlighted: highlightButtonIndex == 1),
            if (thirdString != null && thirdHandler != null)
              _buildChoiceButton(thirdHandler, _emphasise(thirdString, highlightButtonIndex == 2), thirdDescriptionString,
                  highlighted: highlightButtonIndex == 2),
            if (fourthString != null && fourthHandler != null)
              _buildChoiceButton(fourthHandler, _emphasise(fourthString, highlightButtonIndex == 3), fourthDescriptionString,
                  highlighted: highlightButtonIndex == 3),
            if (fifthString != null && fifthHandler != null)
              _buildChoiceButton(fifthHandler, _emphasise(fifthString, highlightButtonIndex == 4), fifthDescriptionString,
                  highlighted: highlightButtonIndex == 4),
          ],
        ),
      ),
    );
  });
}

_emphasise(String text, bool doIt) {
  return doIt ? "✓ $text" : text;
}

OutlinedButton _buildChoiceButton(
    Function() handler,
    String title,
    String? description,
    {
      bool highlighted = false,
    }) {
  if (description != null) {
    return OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.lightGreenAccent,
            side: highlighted ? BorderSide(width: 2.5, color: Colors.grey) : null,
        ),
        onPressed: () {
          SmartDialog.dismiss();
          handler();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
              child: Text(title.toUpperCase(), style: TextStyle(fontWeight: highlighted ? FontWeight.bold : null)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Text(description,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
            ),
          ],
        ));
  }
  else {
    return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.lightGreenAccent,
          side: highlighted ? BorderSide(width: 2.5, color: Colors.grey) : null,
        ),
        onPressed: () {
          SmartDialog.dismiss();
          handler();
        },
        child: Text(title.toUpperCase(), style: TextStyle(fontWeight: highlighted ? FontWeight.bold : null)));
  }
}

showProgressDialog(String text) async {
  SmartDialog.dismiss();

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
    MaterialLocalizations l10n,
    {
      double? height,
      double? width,
      String? prefilledText,
      bool requiresInput = false, // TODO implement this
      required Function(String) okHandler,
      Function()? cancelHandler,
      String? thirdText,
      Function(TextEditingController)? thirdHandler,
      int? maxLength,
      int? minLines,
      int? maxLines,
      String? validationMessage,
      bool Function(String)? validationHandler,
    }
    ) {
  final controller = TextEditingController(text: prefilledText);
  SmartDialog.show(builder: (_) {

    bool valid = true;
    
    return StatefulBuilder(
        builder: (BuildContext context, setState) {

          return Container(
            height: height ?? 200 + text.length.toDouble() + (thirdText != null ? 50 : 0),
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
                    maxLength: maxLength,
                    minLines: minLines,
                    maxLines: maxLines,
                    decoration: InputDecoration(
                      errorText: valid ? null : validationMessage,
                      errorMaxLines: 3,
                    ),
                    style: TextStyle(color: Colors.lightGreenAccent),
                    onChanged: (v) {
                      if (validationHandler != null) {
                        setState(() => valid = validationHandler(v));
                      }
                    },
                    cursorColor: Colors.lightGreen,
                  ),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: valid ? Colors.lightGreenAccent : Colors.grey),
                      onPressed: () {
                        if (valid) {
                          SmartDialog.dismiss();
                          okHandler(controller.text);
                        }
                      },
                      child: Text(l10n.okButtonLabel)),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.lightGreenAccent),
                      onPressed: () {
                        SmartDialog.dismiss();
                        if (cancelHandler != null) {
                          cancelHandler();
                        }
                      },
                      child: Text(l10n.cancelButtonLabel)
                  ),
                  if (thirdText != null)
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.lightGreenAccent),
                        onPressed: () {
                          if (thirdHandler != null) {
                            thirdHandler(controller);
                          }
                        },
                        child: Text(thirdText)
                    ),

                ],
              ),
            ),
          );
        }
    );
  });

}

