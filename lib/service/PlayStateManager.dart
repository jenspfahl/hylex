
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
import '../ui/pages/multi_player_matches.dart';
import '../ui/ui_utils.dart';
import '../utils/fortune.dart';



class PlayStateManager {

  static final PlayStateManager _service = PlayStateManager._internal();
  static bool enableMocking = false;


  factory PlayStateManager() {
    return _service;
  }

  PlayStateManager._internal() {}



  Future<String?> doAcceptInvite(PlayHeader header, PlayOpener playOpenerDecision) async {
    if (header.playOpener == PlayOpener.InviteeChooses) {
      header.playOpener = playOpenerDecision;
    }
    try {
      header.state = header.playOpener! == PlayOpener.Invitor
          ? PlayState.InvitationAccepted_WaitForOpponent
          : PlayState.InvitationAccepted_ReadyToMove;
      await StorageService().savePlayHeader(header);
      return null;
    } on Exception catch (e) {
      print(e);
      return "Match ${header.getReadablePlayId()} cannot progress with this message!";
    }
  }

  Future<String?> handleInviteAcceptedByRemote(PlayHeader header, AcceptInviteMessage message) async {
    if (header.state == PlayState.InvitationRejected) {
      return "Match ${header.getReadablePlayId()} already rejected, cannot accept afterwards.";
    }
    else {
      try {
        header.state = PlayState.RemoteOpponentAccepted_ReadyToMove;
        header.playOpener = message.playOpenerDecision;
        header.opponentId = message.inviteeUserId;
        header.opponentName = message.inviteeUserName;
        await StorageService().savePlayHeader(header);
        return null;
      } on Exception catch (e) {
        print(e);
        return "Match ${header.getReadablePlayId()} cannot be accepted by this message!";
      }
    }
  }

  Future<String?> doAndHandleRejectInvite(PlayHeader header, [RejectInviteMessage? message]) async {
    if (header.state == PlayState.InvitationRejected) {
      return "Match ${header.getReadablePlayId()} already rejected.";
    }
    else {
      try {
        header.state = PlayState.InvitationRejected;
        if (message != null) {
          header.opponentId = message.userId;
        }
        await StorageService().savePlayHeader(header);
        return null;
      } on Exception catch (e) {
        print(e);
        return "Match ${header.getReadablePlayId()} cannot be rejected by this message!";
      }
    }
  }

  Future<String?> doResign(PlayHeader header, User user) async {
    try {
      header.state = PlayState.Resigned;
      final play = await StorageService().loadPlayFromHeader(header);
      if (play != null) {
        var role = header.getLocalRoleForMultiPlay()!;
        user.achievements.incLostGame(role, header.dimension);
        StorageService().saveUser(user);
      }
      await StorageService().savePlayHeader(header);
      return null;
    } on Exception catch (e) {
      print(e);
      return "Match ${header.getReadablePlayId()} cannot be resigned by this message!";
    }
  }


  Future<String?> handleResignedByRemote(PlayHeader header, User user) async {
    try {
      header.state = PlayState.OpponentResigned;
      final play = await StorageService().loadPlayFromHeader(header);
      if (play != null) {
        play.finishGame();
        var role = header.getLocalRoleForMultiPlay()!;
        user.achievements.incWonGame(role, header.dimension);
        user.achievements.registerPointsForScores(
            role,
            header.dimension,
            play.stats.getPoints(role));
        await StorageService().saveUser(user);
      }
      await StorageService().savePlayHeader(header);
      return null;
    } on Exception catch (e) {
      print(e);
      return "Match ${header.getReadablePlayId()} cannot be resigned by this message!";
    }
  }


}



