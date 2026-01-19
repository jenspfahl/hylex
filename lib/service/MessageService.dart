
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../model/messaging.dart';
import '../model/move.dart';
import '../model/play.dart';
import '../model/user.dart';
import '../ui/dialogs.dart';
import '../ui/ui_utils.dart';


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
        if (playHeader.rolesSwapped != true // don't do this if roles swapped
            && playHeader.actor == Actor.Invitee
            && playHeader.currentRound == 1) {
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
        user,
        (l10n) => user.name.isEmpty
            ? l10n.messaging_inviteMessageWithoutName(header.dimension)
            : l10n.messaging_inviteMessage(header.dimension, user.name),
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

    final localUserRole = header.actor.getActorRoleFor(playOpener);
    final remoteUserRole = localUserRole?.opponentRole;
    
    return _saveAndShare(
        serializedMessage,
        header,
        user,
        (l10n) => l10n.messaging_acceptInvitation(remoteUserRole?.name??"?", localUserRole?.name??"?"),
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
        user,
        (l10n) => l10n.messaging_rejectInvitation,
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
        user,
        (l10n) => l10n.messaging_nextMove(header.getLocalRoleForMultiPlay()?.name??"?", round),
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
        user,
        (l10n) =>  l10n.messaging_resign(round),
        contextProvider,
        saveState,
        share,
        showAllOptions,
    );
  }

  void _share(
      PlayHeader header,
      User user,
      SerializedMessage serializedMessage,
      String Function(AppLocalizations) getText,
      BuildContext context,
      bool saveState,
      bool showAllOptions,
      ) {

    final l10n = AppLocalizations.of(context)!;

    if (!showAllOptions && header.props[HeaderProps.rememberMessageSending] == "as_message") {
      _shareAsMessage(context, serializedMessage, getText, header, user);
    }
    else if (!showAllOptions && header.props[HeaderProps.rememberMessageSending] == "as_qr_code") {
      _shareAsQrCode(context, serializedMessage, header, user);
    }
    else {
    
      showModalBottomSheet(
        context: context,

        builder: (BuildContext context) {

          bool remember = false;
          bool signMessages = header.props[HeaderProps.signMessages] == true;
          String _messageLanguage = header.props[HeaderProps.messageLanguage] ?? Localizations.localeOf(context).languageCode;

          return SafeArea(
            child: FutureBuilder(
              future: PreferenceService().getBool(PreferenceService.PREF_SEND_MESSAGE_IN_DIFFERENT_LANGUAGES),
              builder: (context, asyncSnapshot) {
                return StatefulBuilder(
                  builder: (BuildContext context, setState) {

                    final showLanguages = asyncSnapshot.data??false;
                    final languagePopupMenuItems = showLanguages
                        ? ensureEnglishFirst(AppLocalizations.supportedLocales)
                            .map((locale) => PopupMenuItem<String>(
                                value: locale.languageCode,
                                child: Text(l10n.messaging_sendYourMoveAsMessageInLanguage(locale.languageCode.toUpperCase())),
                              ))
                            .toList()
                        : <PopupMenuItem<String>>[];

                    return Container(
                      height: 350,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          mainAxisSize: MainAxisSize.max,
                          spacing: 5,
                          children: [
                            Text(l10n.messaging_sendYourMove),
                            showLanguages ? buildFilledButtonWithDropDown(
                                context,
                                Icons.near_me,
                                l10n.messaging_sendYourMoveAsMessage,
                                _messageLanguage,
                                () async {
                                  header.props[HeaderProps.rememberMessageSending] = remember ? "as_message" : "";
                                  header.props[HeaderProps.signMessages] = signMessages;
                                  if (saveState) {
                                    await StorageService().savePlayHeader(header);
                                  }

                                  Navigator.of(context).pop();
                                  _shareAsMessage(context, serializedMessage, getText, header, user);
                                },
                                languagePopupMenuItems,
                                (popupId) {
                                  setState(() => _messageLanguage = popupId);
                                  if (header.props[HeaderProps.messageLanguage] != _messageLanguage) {
                                    header.props[HeaderProps.messageLanguage] = _messageLanguage;
                                    StorageService().savePlayHeader(header);
                                  }
                                },
                              )
                              : buildFilledButton(
                              context,
                              Icons.near_me,
                              l10n.messaging_sendYourMoveAsMessage,
                              () async {
                                header.props[HeaderProps.rememberMessageSending] = remember ? "as_message" : "";
                                header.props[HeaderProps.signMessages] = signMessages;
                                if (saveState) {
                                  await StorageService().savePlayHeader(header);
                                }

                                Navigator.of(context).pop();
                                _shareAsMessage(context, serializedMessage, getText, header, user);
                              },
                            ),


                            buildFilledButton(
                                context,
                                Icons.qr_code_2,
                                l10n.messaging_sendYourMoveAsQrCode,
                                    () async {
                                      header.props[HeaderProps.rememberMessageSending] = remember ? "as_qr_code" : "";
                                      header.props[HeaderProps.signMessages] = signMessages;

                                      if (saveState) {
                                        await StorageService().savePlayHeader(header);
                                      }
                                      Navigator.of(context).pop();
                                      _shareAsQrCode(context, serializedMessage, header, user);

                                }),
                            CheckboxListTile(
                                title: Text(l10n.messaging_rememberDecision),
                                value: remember,
                                dense: true,
                                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.elliptical(10, 20))),
                                onChanged: (value) {
                                  setState(() {
                                    if (value != null) {
                                      remember = value;
                                    }
                                  });
                                }),
                            if (PreferenceService().signMessages == SignMessages.OnDemand)
                              CheckboxListTile(
                                  title: Text(l10n.messaging_signMessages),
                                  value: signMessages,
                                  dense: true,
                                  checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.all(Radius.elliptical(10, 20))),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value != null) {
                                        signMessages = value;
                                      }
                                    });
                                  })
                          ],
                        )
                      ),
                    );
                  },
                );
              }
            ),
          );


        },
      );

    }

  }
  
  Future<void> _signMessageIfNeeded(SerializedMessage serializedMessage, PlayHeader header, User user) async {
    if (PreferenceService().signMessages == SignMessages.Never) {
      return;
    }
    if (PreferenceService().signMessages == SignMessages.Always
        || header.props[HeaderProps.signMessages] == true) {
      await serializedMessage.signMessage(user.id, user.userSeed);
    }
  }

  void _shareAsQrCode(BuildContext context, SerializedMessage message, PlayHeader playHeader, User user) {

    final l10n = AppLocalizations.of(context)!;

    _signMessageIfNeeded(message, playHeader, user).then((_) {
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
                    ? l10n.messaging_scanQrCodeFromOpponentWithName(playHeader.opponentName??"?")
                    : l10n.messaging_scanQrCodeFromOpponent, style: TextStyle(color: Colors.white)),
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
    });
    
  }

  void _shareAsMessage(BuildContext context, 
      SerializedMessage serializedMessage,
      String Function(AppLocalizations) getText,
      PlayHeader playHeader, 
      User user) {

    _signMessageIfNeeded(serializedMessage, playHeader, user).then((_) async {
      final overwriteLanguages = await PreferenceService().getBool(PreferenceService.PREF_SEND_MESSAGE_IN_DIFFERENT_LANGUAGES)??false;
      final language = overwriteLanguages
          ? playHeader.props[HeaderProps.messageLanguage] ?? Localizations.localeOf(context).languageCode
          : Localizations.localeOf(context).languageCode;
      final locale = Locale(language);
      final l10nForMessage = await AppLocalizations.delegate.load(locale);
      final text = getText(l10nForMessage);
      final shareMessage = '[${playHeader.getReadablePlayId()}] $text\n${serializedMessage.toUrl()}';

      SharePlus.instance.share(
          ShareParams(text: shareMessage, subject: '$APP_NAME interaction'));
    });
    
  }


  Future<SerializedMessage> _saveAndShare(
      SerializedMessage serializedMessage,
      PlayHeader header,
      User user,
      String Function(AppLocalizations) getText,
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

    debugPrint(" >>>>>>> ${serializedMessage.toUrl()}");
    if (share && contextProvider != null) {
      _share(header, user, serializedMessage, getText, contextProvider(), saveState, showAllOptions);
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



