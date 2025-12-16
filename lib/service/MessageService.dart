
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_translate/flutter_translate.dart';
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
      case PlayState.FirstGameFinished_WaitForOpponent:
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
      case PlayState.FirstGameFinished_ReadyToSwap:
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
    final serializedMessage = inviteMessage.serializeWithContext(header.commContext, user.userSeed);

    return _saveAndShare(
        serializedMessage, 
        header,
        user.name.isEmpty
            ? translate("messaging.inviteMessageWithoutName", args: {"dimension" : header.dimension})
            : translate("messaging.inviteMessage", args: {"name" : user.name, "dimension" : header.dimension}),
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
        header.playSize,
        playOpener,
        user.id,
        user.name,
        initialMove
    );
    final serializedMessage = acceptMessage.serializeWithContext(header.commContext, user.userSeed);

    var localUserRole = header.actor.getActorRoleFor(playOpener);
    var remoteUserRole = localUserRole?.opponentRole;
    
    return _saveAndShare(
        serializedMessage,
        header,
        translate("messaging.acceptInvitation",
            args: {"role" : localUserRole?.name, "opponentRole" : remoteUserRole?.name}),
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
        header.playSize,
        user.id);
    final serializedMessage = rejectMessage.serializeWithContext(header.commContext, user.userSeed);

    return _saveAndShare(
        serializedMessage,
        header,
        translate("messaging.rejectInvitation"),
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
      }) async {
    final round = await _getRoundForState(header);
    final moveMessage = MoveMessage(
        header.playId,
        header.playSize,
        round,
        move);
    final serializedMessage = moveMessage.serializeWithContext(header.commContext, user.userSeed);

    return _saveAndShare(
        serializedMessage,
        header,
        translate("messaging.nextMove",
          args: {"role" : header.getLocalRoleForMultiPlay()?.name, "round" : round}),
        contextProvider,
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
      }) async {
    final round = await _getRoundForState(header);

    final resignationMessage = ResignMessage(
        header.playId,
        header.playSize,
        round);
    final serializedMessage = resignationMessage.serializeWithContext(header.commContext, user.userSeed);

    return _saveAndShare(
        serializedMessage,
        header,
        translate("messaging.resign",
          args: {"round" : round}),
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
                height: 320,

                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
                    spacing: 5,
                    children: [
                      Text(translate("messaging.sendYourMove")),
                      buildFilledButton(
                          context,
                          Icons.near_me,
                          translate("messaging.sendYourMoveAsMessage"),
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
                          translate("messaging.sendYourMoveAsQrCode"),
                              () async {
                                header.props["remember"] = remember ? "as_qr_code" : "";
                                if (saveState) {
                                  await StorageService().savePlayHeader(header);
                                }
                                Navigator.of(context).pop();
                                _shareAsQrCode(context, message, header);

                          }),
                      CheckboxListTile(
                          title: Text(translate("messaging.rememberDecision")),
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
        height: 370,
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
              Text(playHeader.opponentName != null
                  ? translate("messaging.scanQrCodeFromOpponentWithName", args: {"name" : playHeader.opponentName})
                  : translate("messaging.scanQrCodeFromOpponent"), style: TextStyle(color: Colors.white)),
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

  Future<int> _getRoundForState(PlayHeader header) async {
    final play = await StorageService().loadPlayFromHeader(header);
    if (play == null) {
      return 0;
    }
    final currentRole = play.currentRole;
    final currentRound = header.currentRound;
    // transition from Order to Chaos increased the round
    return currentRole == Role.Chaos && currentRound > 1
        ? currentRound - 1
        : currentRound;
  }

}



