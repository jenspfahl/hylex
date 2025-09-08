import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:qr_flutter/qr_flutter.dart';
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


  sendCurrentPlayState(
      PlayHeader playHeader,
      User user,
      BuildContext context,
      Function()? sentHandler) {
    if (!playHeader.isStateShareable()) {
      // cannot send this state
      print("It is not possible to send a message for state ${playHeader.state}");
      return;
    }
    switch (playHeader.state) {
      case PlayState.RemoteOpponentInvited: {
        sendRemoteOpponentInvitation(playHeader, user, context, sentHandler);
        break;
      }
      case PlayState.InvitationAccepted_WaitForOpponent: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          final lastMove = play?.lastMoveFromJournal;
          sendInvitationAccepted(playHeader, user, lastMove, context, sentHandler);
        });
        break;
      }
      case PlayState.InvitationRejected: {
        sendInvitationRejected(playHeader, user, context, sentHandler);
        break;
      }
      case PlayState.Lost:
      case PlayState.Won:
      case PlayState.WaitForOpponent: {
        if (playHeader.actor == Actor.Invitee && playHeader.currentRound == 1) {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            final lastMove = play?.lastMoveFromJournal;
            sendInvitationAccepted(playHeader, user, lastMove, context, sentHandler);
          });
        }
        else {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            sendMove(playHeader, user, play!.lastMoveFromJournal!, context, sentHandler);
          });
        }
        break;
      }
      case PlayState.Resigned: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          sendResignation(playHeader, user, context, sentHandler);
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
      BuildContext context,
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

    return _shareMessage('I (${user.name}) want to invite you to a HyleX match. Click the link to open it: ',
          serializedMessage, context, sentHandler, share);
  }

  SerializedMessage sendInvitationAccepted(
      PlayHeader header,
      User user,
      Move? initialMove,
      BuildContext context,
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
        serializedMessage, context, sentHandler, share);
  }

  SerializedMessage sendInvitationRejected(
      PlayHeader header,
      User user,
      BuildContext context,
      Function()? sentHandler,
      {bool share = true}) {
    final rejectMessage = RejectInviteMessage(
        header.playId,
        user.id);
    final serializedMessage = rejectMessage.serializeWithContext(header.commContext);

    return _shareMessage('I want to kindly reject your match request.',
        serializedMessage, context, sentHandler, share);
  }

  SerializedMessage sendMove(
      PlayHeader header,
      User user,
      Move move,
      BuildContext context,
      Function()? sentHandler,
      {bool share = true}) {
    final moveMessage = MoveMessage(header.playId, header.currentRound, move);
    final serializedMessage = moveMessage.serializeWithContext(header.commContext);

    return _shareMessage("This is my next move for round ${header.currentRound} as ${header.getLocalRoleForMultiPlay()!.name}.",
        serializedMessage, context, sentHandler, share);
  }

  SerializedMessage sendResignation(
      PlayHeader header,
      User user,
      BuildContext context,
      Function()? sentHandler,
      {bool share = true}) {
    final resignationMessage = ResignMessage(header.playId, header.currentRound);
    final serializedMessage = resignationMessage.serializeWithContext(header.commContext);

    return _shareMessage("Uff, I am giving up in round ${header.currentRound}.",
        serializedMessage, context, sentHandler, share);
  }

  void sendMessage(String text, SerializedMessage message, BuildContext context,
      Function()? sentHandler) {
    final playId = message.extractPlayId();
    final shareMessage = '[${toReadableId(playId)}] $text\n${message.toUrl()}';
    debugPrint("sending: [${toReadableId(playId)}] $text");
    debugPrint(" >>>>>>> ${message.toUrl()}");
    _share(shareMessage, message, context, sentHandler);
  }

  void _share(String shareMessage, SerializedMessage message, BuildContext context, Function()? sentHandler) {
    showModalBottomSheet( //TODO add handle to enlarge or close
      context: context,

      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (BuildContext context, setState) {


            return Container(
              height: 170,

              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Share your move with your opponent:"),
                    OutlinedButton(onPressed: () {
                      Navigator.of(context).pop();

                      SmartDialog.show(builder: (_) {

                        return Container(
                          width: 280,
                          height: 310,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Let this scanned by your opponent", style: TextStyle(color: Colors.white)),
                                QrImageView(
                                  data: message.toUrl(),
                                  version: QrVersions.auto,
                                  backgroundColor: Colors.white,
                                  size: 250.0,
                                )
                              ],
                            ),
                          ),
                        );




                      });


                    }, child: Text("As QR code")),
                    FilledButton(onPressed: () {
                      Navigator.of(context).pop();
                      SharePlus.instance.share(
                          ShareParams(text: shareMessage, subject: 'HyleX interaction'))
                          .then((result) {
                        if (sentHandler != null) sentHandler();
                      });
                    }, child: Text("As message")),
                  ],
                )
              ),
            );
          },
        );


      },
    );



  }

  SerializedMessage _shareMessage(
      String text,
      SerializedMessage serializedMessage,
      BuildContext context,
      Function()? sentHandler,
      bool share
      ) {

    if (share) {
      sendMessage(text, serializedMessage, context, sentHandler);
    }

    return serializedMessage;
  }

}



