
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



class MessageService {

  static final MessageService _service = MessageService._internal();
  static bool enableMocking = false;


  factory MessageService() {
    return _service;
  }

  MessageService._internal() {}


  sendCurrentPlayState(
      PlayHeader playHeader,
      User user,
      BuildContext Function()? contextProvider,
      bool showAllOptions) {
    if (!playHeader.isStateShareable()) {
      // cannot send this state
      print("It is not possible to send a message for state ${playHeader.state}");
      return;
    }

    if (enableMocking) {
      print("sendState ${playHeader.state}");
      return;
    }


    switch (playHeader.state) {
      case PlayState.RemoteOpponentInvited: {
        sendRemoteOpponentInvitation(playHeader, user, contextProvider, showAllOptions: showAllOptions);
        break;
      }

      case PlayState.InvitationAccepted_WaitForOpponent: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          final lastMove = play?.lastMoveFromJournal;
          sendInvitationAccepted(playHeader, user, lastMove, contextProvider, showAllOptions: showAllOptions);
        });
        break;
      }
      case PlayState.InvitationRejected: {
        sendInvitationRejected(playHeader, user, contextProvider, showAllOptions: showAllOptions);
        break;
      }
      case PlayState.Lost:
      case PlayState.Won:
      case PlayState.WaitForOpponent: {
        if (playHeader.actor == Actor.Invitee && playHeader.currentRound == 1) {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            final lastMove = play?.lastMoveFromJournal;
            sendInvitationAccepted(playHeader, user, lastMove, contextProvider, showAllOptions: showAllOptions);
          });
        }
        else {
          StorageService().loadPlayFromHeader(playHeader).then((play) {
            sendMove(playHeader, user, play!.lastMoveFromJournal!, contextProvider, showAllOptions: showAllOptions);
          });
        }
        break;
      }
      case PlayState.Resigned: {
        StorageService().loadPlayFromHeader(playHeader).then((play) {
          sendResignation(playHeader, user, contextProvider, showAllOptions: showAllOptions);
        });
        break;
      }
      case PlayState.InvitationAccepted_ReadyToMove:
      case PlayState.ReadyToMove:
      case PlayState.InvitationPending:
      case PlayState.RemoteOpponentAccepted_ReadyToMove:
      case PlayState.OpponentResigned:
      case PlayState.Closed:
      case PlayState.Initialised: {
        debugPrint("nothing to send for ${playHeader.state}, take action instead!");
      }
    }
  }
  
  Future<SerializedMessage> sendRemoteOpponentInvitation(
      PlayHeader header,
      User user,
      BuildContext Function()? contextProvider,
      {
        bool saveState = true, 
        bool share = true,
        bool showAllOptions = false,
      }) {
    final inviteMessage = InviteMessage.fromHeaderAndUser(header, user);
    final serializedMessage = inviteMessage.serializeWithContext(header.commContext);

    return _saveAndShare(
        serializedMessage, 
        header,
        'I (${user.name}) want to invite you to a $APP_NAME match. Click the link to open it: ',
        contextProvider,
        saveState, 
        share,
        showAllOptions,
    );
  }


  Future<SerializedMessage> sendInvitationAccepted(
      PlayHeader header,
      User user,
      Move? initialMove,
      BuildContext Function()? contextProvider,
      {
        bool saveState = true,
        bool share = true,
        bool showAllOptions = false,
      }) {
    final playOpener = header.playOpener;
    if (playOpener == null  || playOpener == PlayOpener.InviteeChooses) {
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
    
    return _saveAndShare(
        serializedMessage,
        header,
        "I am accepting your match request. I am ${localUserRole?.name}, you are ${remoteUserRole?.name}.",
        contextProvider,
        saveState,
        share,
        showAllOptions,
    );
  }

  
  Future<SerializedMessage> sendInvitationRejected(
      PlayHeader header,
      User user,
      BuildContext Function()? contextProvider,
      {
        bool saveState = true,
        bool share = true,
        bool showAllOptions = false,
      }) {
    final rejectMessage = RejectInviteMessage(
        header.playId,
        user.id);
    final serializedMessage = rejectMessage.serializeWithContext(header.commContext);

    return _saveAndShare(
        serializedMessage,
        header,
        'I want to kindly reject your match request.',
        contextProvider,
        saveState,
        share,
        showAllOptions,
    );
  }

  Future<SerializedMessage> sendMove(
      PlayHeader header,
      User user,
      Move move,
      BuildContext Function()? contextProvider,
      {
        bool saveState = true,
        bool share = true,
        bool showAllOptions = false,
      }) {
    final moveMessage = MoveMessage(header.playId, header.currentRound, move);
    final serializedMessage = moveMessage.serializeWithContext(header.commContext);

    return _saveAndShare(
        serializedMessage,
        header,
        "This is my next move for round ${header.currentRound} as ${header.getLocalRoleForMultiPlay()?.name}.",        contextProvider,
        saveState,
        share,
        showAllOptions,
    );
  }

  Future<SerializedMessage> sendResignation(
      PlayHeader header,
      User user,
      BuildContext Function()? contextProvider,
      {
        bool saveState = true,
        bool share = true,
        bool showAllOptions = false,
      }) {
    final resignationMessage = ResignMessage(header.playId, header.currentRound);
    final serializedMessage = resignationMessage.serializeWithContext(header.commContext);

    return _saveAndShare(
        serializedMessage,
        header,
        "Uff, I am giving up in round ${header.currentRound}.",
        contextProvider,
        saveState,
        share,
        showAllOptions,
    );
  }

  void _share(
      PlayHeader header,
      String shareMessage,
      SerializedMessage message,
      BuildContext context,
      bool saveState,
      bool showAllOptions,
      ) {

    if (!showAllOptions && header.props["remember"] == "as_message") {
      _shareAsMessage(context, shareMessage);
    }
    else if (!showAllOptions && header.props["remember"] == "as_qr_code") {
      _shareAsQrCode(context, message, header);
    }
    else {
    
      showModalBottomSheet(
        context: context,

        builder: (BuildContext context) {

          bool remember = false;

          return StatefulBuilder(
            builder: (BuildContext context, setState) {


              return Container(
                height: 300,

                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    spacing: 5,
                    children: [
                      Text("Share your request or move with your opponent:"),
                      buildFilledButton(
                          context,
                          Icons.near_me,
                          "As message",
                              () async {
                            header.props["remember"] = remember ? "as_message" : "";
                            if (saveState) {
                              await StorageService().savePlayHeader(header);
                            }

                            Navigator.of(context).pop();
                            _shareAsMessage(context, shareMessage);
                          }),
                      buildFilledButton(
                          context,
                          Icons.qr_code_2,
                          "As QR code",
                              () async {
                                header.props["remember"] = remember ? "as_qr_code" : "";
                                if (saveState) {
                                  await StorageService().savePlayHeader(header);
                                }
                                Navigator.of(context).pop();
                                _shareAsQrCode(context, message, header);

                          }),
                      CheckboxListTile(
                          title: Text("Remember my decision for this match"),
                          value: remember,
                          dense: true,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.elliptical(10, 20))),
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                remember = value;
                              }
                            });
                          })

                    ],
                  )
                ),
              );
            },
          );


        },
      );

    }

  }

  void _shareAsQrCode(BuildContext context, SerializedMessage message, PlayHeader playHeader) {

    SmartDialog.show(builder: (_) {
    
      return Container(
        width: 280,
        height: 330,
        decoration: BoxDecoration(
          color: DIALOG_BG,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("[${playHeader.getReadablePlayId()}]", style: TextStyle(color: Colors.white)),
              Text("Let your opponent scan this!", style: TextStyle(color: Colors.white)),
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
  }

  void _shareAsMessage(BuildContext context, String shareMessage) {
    SharePlus.instance.share(
        ShareParams(text: shareMessage, subject: '$APP_NAME interaction'));
  }


  Future<SerializedMessage> _saveAndShare(
      SerializedMessage serializedMessage,
      PlayHeader header,
      String message,
      BuildContext Function()? contextProvider,
      bool saveState,
      bool share,
      bool showAllOptions,
      ) async {
    if (enableMocking) {
      print("send ${serializedMessage.toUrl()}");
      return serializedMessage;
    }

    if (saveState) {
      await StorageService().savePlayHeader(header);
    }

    final playId = serializedMessage.extractPlayId();
    final shareMessage = '[${toReadableId(playId)}] $message\n${serializedMessage.toUrl()}';
    debugPrint("sending: [${toReadableId(playId)}] $message");
    debugPrint(" >>>>>>> ${serializedMessage.toUrl()}");
    if (share && contextProvider != null) {
      _share(header, shareMessage, serializedMessage, contextProvider(), saveState, showAllOptions);
    }
    return serializedMessage;
  }

}



