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
    final actor = playHeader.actor;
    if (!playHeader.state.forActors.contains(actor)) {
      // cannot send this state
      print("Actor $actor is not allowed to send a message for state ${playHeader.state}");
      return;
    }
    switch (playHeader.state) {
      case PlayState.RemoteOpponentInvited: {
        sendRemoteOpponentInvitation(playHeader, user, sentHandler);
        break;
      }
      case PlayState.InvitationAccepted: {
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
      case PlayState.WaitForOpponent: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          sendMove(playHeader, user, play!.lastMoveFromJournal!, sentHandler);
        });
        break;
      }
      case PlayState.Resigned: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          sendResignation(playHeader, user, sentHandler);
        });
        break;
      }
      case PlayState.InvitationPending:
      case PlayState.Initialised: {
        debugPrint("nothing to send for ${playHeader.state}, take action instead!");
      }
        // TODO: Handle this case.
        throw UnimplementedError();
      case PlayState.ReadyToMove:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PlayState.Lost:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PlayState.Won:
        // TODO: Handle this case.
        throw UnimplementedError();
        case PlayState.OpponentResigned:
        // TODO: Handle this case.
        throw UnimplementedError();
      case PlayState.Closed:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }


  void sendRemoteOpponentInvitation(PlayHeader header, User user, Function()? sentHandler) {
    final inviteMessage = InviteMessage(
        header.playId,
        header.playSize,
        header.playMode,
        header.playOpener!,
        user.id,
        user.name);
    final serializedMessage = inviteMessage.serializeWithContext(header.commContext);

    sendMessage('I (${user.name}) want to invite you to a HyleX match.',
        serializedMessage, sentHandler);
  }

  void sendInvitationAccepted(PlayHeader header, User user, Move? initialMove, Function()? sentHandler) {
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

    sendMessage("I am accepting your match request. I am ${localUserRole?.name}, you are ${remoteUserRole?.name}.",
        serializedMessage, sentHandler);
  }
  
  void sendInvitationRejected(PlayHeader header, User user, Function()? sentHandler) {
    final rejectMessage = RejectInviteMessage(
        header.playId,
        user.id);
    final serializedMessage = rejectMessage.serializeWithContext(header.commContext);

    sendMessage('I want to kindly reject your match request.',
        serializedMessage, sentHandler);
  }

  void sendMove(PlayHeader header, User user, Move move, Function()? sentHandler) {
    final moveMessage = MoveMessage(header.playId, header.currentRound, move);
    final serializedMessage = moveMessage.serializeWithContext(header.commContext);

    sendMessage("This is my next move for round ${header.currentRound}", serializedMessage, sentHandler);
  }

  void sendResignation(PlayHeader header, User user, Function()? sentHandler) {
    final resignationMessage = ResignMessage(header.playId, header.currentRound);
    final serializedMessage = resignationMessage.serializeWithContext(header.commContext);

    sendMessage("Uff, I am giving up in round ${header.currentRound}.", serializedMessage, sentHandler);
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
  
}

