
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../model/messaging.dart';
import '../model/move.dart';
import '../model/play.dart';
import '../model/user.dart';
import '../ui/dialogs.dart';
import '../ui/ui_utils.dart';
import '../utils/fortune.dart';



class MessageReceiver {

  static final MessageReceiver _service = MessageReceiver._internal();
  static bool enableMocking = false;


  factory MessageReceiver() {
    return _service;
  }

  MessageReceiver._internal() {}


  Future<String?> handleInviteAccepted(PlayHeader header, AcceptInviteMessage message) async {
    if (header.state == PlayState.InvitationRejected) {
      return "Match ${header.getReadablePlayId()} already rejected, cannot accept afterwards.";
    }
    else {
      header.state = PlayState.RemoteOpponentAccepted_ReadyToMove;
      header.playOpener = message.playOpenerDecision;
      return null;
    }
  }

}



