import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:share_plus/share_plus.dart';

import '../model/messaging.dart';
import '../model/move.dart';
import '../model/play.dart';
import '../model/user.dart';
import '../utils/fortune.dart';
import 'PreferenceService.dart';



class MessageService {

  static final MessageService _service = MessageService._internal();

  factory MessageService() {
    return _service;
  }

  MessageService._internal() {}


  sendCurrentPlayState(PlayHeader playHeader, User user, Function()? sentHandler) {
    if (!playHeader.isStateShareable()) {
      // cannot send this state
      print("It is not possible to send a message for state ${playHeader.state}");
      return;
    }
    switch (playHeader.state) {
      case PlayState.RemoteOpponentInvited: {
        sendRemoteOpponentInvitation(playHeader, user, sentHandler);
        break;
      }
      case PlayState.InvitationAccepted_WaitForOpponent: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          final lastMove = play?.lastMoveFromJournal;
          sendInvitationAccepted(playHeader, user, lastMove, sentHandler);
        });
        break;
      }
      case PlayState.InvitationRejected: {
        sendInvitationRejected(playHeader, user, sentHandler);
        break;
      }
      case PlayState.Lost:
      case PlayState.Won:
      case PlayState.WaitForOpponent: {
        if (playHeader.actor == Actor.Invitee && playHeader.currentRound == 1) {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            final lastMove = play?.lastMoveFromJournal;
            sendInvitationAccepted(playHeader, user, lastMove, sentHandler);
          });
        }
        else {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            sendMove(playHeader, user, play!.lastMoveFromJournal!, sentHandler);
          });
        }
        break;
      }
      case PlayState.Resigned: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          sendResignation(playHeader, user, sentHandler);
        });
        break;
      }
      case PlayState.InvitationAccepted_ReadyToMove:
      case PlayState.ReadyToMove:
      case PlayState.InvitationPending:
      case PlayState.RemoteOpponentAccepted:
      case PlayState.OpponentResigned:
      case PlayState.Closed:
      case PlayState.Initialised: {
        debugPrint("nothing to send for ${playHeader.state}, take action instead!");
      }

    }
  }


  SerializedMessage sendRemoteOpponentInvitation(
      PlayHeader header,
      User user,
      Function()? sentHandler,
      {bool share = true}) {
    final inviteMessage = InviteMessage(
        header.playId,
        header.playSize,
        header.playMode,
        header.playOpener!,
        user.id,
        user.name);
    final serializedMessage = inviteMessage.serializeWithContext(header.commContext);

    return _shareMessage('I (${user.name}) want to invite you to a HyleX match.',
          serializedMessage, sentHandler, share);
  }

  SerializedMessage sendInvitationAccepted(
      PlayHeader header,
      User user,
      Move? initialMove,
      Function()? sentHandler,
      {bool share = true}) {
    final playOpener = header.playOpener;
    if (playOpener == null  || playOpener == PlayOpener.InvitedPlayerChooses) {
      throw Exception("No playOpener decision");
    }
    final acceptMessage = AcceptInviteMessage(
        header.playId,
        playOpener,
        user.id,
        user.name,
        initialMove
    );
    final serializedMessage = acceptMessage.serializeWithContext(header.commContext);

    var localUserRole = header.actor.getActorRoleFor(playOpener);
    var remoteUserRole = localUserRole?.opponentRole;

    return _shareMessage("I am accepting your match request. I am ${localUserRole?.name}, you are ${remoteUserRole?.name}.",
        serializedMessage, sentHandler, share);
  }

  SerializedMessage sendInvitationRejected(
      PlayHeader header,
      User user,
      Function()? sentHandler,
      {bool share = true}) {
    final rejectMessage = RejectInviteMessage(
        header.playId,
        user.id);
    final serializedMessage = rejectMessage.serializeWithContext(header.commContext);

    return _shareMessage('I want to kindly reject your match request.',
        serializedMessage, sentHandler, share);
  }

  SerializedMessage sendMove(
      PlayHeader header,
      User user,
      Move move,
      Function()? sentHandler,
      {bool share = true}) {
    final moveMessage = MoveMessage(header.playId, header.currentRound, move);
    final serializedMessage = moveMessage.serializeWithContext(header.commContext);

    return _shareMessage("This is my next move for round ${header.currentRound}",
        serializedMessage, sentHandler, share);
  }

  SerializedMessage sendResignation(
      PlayHeader header,
      User user,
      Function()? sentHandler,
      {bool share = true}) {
    final resignationMessage = ResignMessage(header.playId, header.currentRound);
    final serializedMessage = resignationMessage.serializeWithContext(header.commContext);

    return _shareMessage("Uff, I am giving up in round ${header.currentRound}.",
        serializedMessage, sentHandler, share);
  }

  void sendMessage(String text, SerializedMessage message, Function()? sentHandler) {
    final playId = message.extractPlayId();
    final shareMessage = '[${toReadableId(playId)}] $text\n${message.toUrl()}';
    debugPrint("sending: [${toReadableId(playId)}] $text");
    debugPrint(" >>>>>>> ${message.toUrl()}");
    Share.share(shareMessage, subject: 'HyleX interaction')
        .then((result) {
      if (sentHandler != null) sentHandler();
    });
  }

  SerializedMessage _shareMessage(
      String text,
      SerializedMessage serializedMessage,
      Function()? sentHandler,
      bool share
      ) {

    if (share) {
      sendMessage(text, serializedMessage, sentHandler);
    }

    return serializedMessage;
  }

}



