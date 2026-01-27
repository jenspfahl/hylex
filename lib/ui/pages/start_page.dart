import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/pages/qr_reader.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/ui/pages/settings_page.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:tri_switcher/tri_switcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../l10n/app_localizations.dart';
import '../../model/achievements.dart';
import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/move.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../service/PlayStateManager.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';
import '../ui_utils.dart';
import 'game_ground.dart';
import 'intro.dart';
import 'multi_player_matches.dart';

enum MenuMode {
  None,
  SinglePlay,
  Multiplayer,
  MultiplayerNew,
  More
}

const PLAY_GROUND = "play_ground";

GlobalKey<StartPageState> globalStartPageKey = GlobalKey();

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> {

  MenuMode _menuMode = MenuMode.None;

  User _user = User();

  late StreamSubscription<Uri> _uriLinkStreamSub;
  late StreamSubscription _intentSub;

  int _logoH = 4;
  int _logoY = 5;
  int _logoL = 6;
  int _logoE = 7;

  bool _lockMessageDialog = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;


  @override
  void initState() {
    super.initState();
    _lockMessageDialog = false;

    PreferenceService().getInt(PreferenceService.DATA_LOGO_COLOR_H).then((c) => setState(() {if (c != null) _logoH = c;} ));
    PreferenceService().getInt(PreferenceService.DATA_LOGO_COLOR_Y).then((c) => setState(() {if (c != null) _logoY = c;} ));
    PreferenceService().getInt(PreferenceService.DATA_LOGO_COLOR_L).then((c) => setState(() {if (c != null) _logoL = c;} ));
    PreferenceService().getInt(PreferenceService.DATA_LOGO_COLOR_E).then((c) => setState(() {if (c != null) _logoE = c;} ));

    StorageService().loadUser().then((user) =>
        setState(() {
          if (user != null) {
            _user = user;
          }
        }));

    _uriLinkStreamSub = AppLinks().uriLinkStream.listen((uri) {
      handleReceivedMessage(uri);
    });

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _readAndParseSharedText(value);
    }, onError: (err) {
      showAlertDialog("${l10n.error_cannotExtractUrl}: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _readAndParseSharedText(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _readAndParseSharedText(List<SharedMediaFile> value) {
    final message = value.firstOrNull;
    if (message != null) {
      debugPrint("intent message: ${message.mimeType} / ${message.path} / ${message.message}");

      final uri = extractAppLinkFromString(message.path);
      if (uri == null) {
        if (isDebug) {
          showAlertDialog(l10n.error_cannotExtractUrl + ": " + message.path + " message: " + (message.message??""));
        }
        else {
          showAlertDialog(l10n.error_cannotExtractUrl);
        }

      }
      else {
        handleReceivedMessage(uri);
      }
    }
  }

  void handleReceivedMessage(Uri uri) {
    final serializedMessage = SerializedMessage.fromUrl(uri);
    if (serializedMessage != null) {
      _handleMessage(serializedMessage);
    }
    else {
      debugPrint("invalid uri: $uri");
      showAlertDialog("${l10n.error_cannotParseUrl}: $uri");
    }
  }

  Future<void> _handleMessage(SerializedMessage serializedMessage) async {

    if (_lockMessageDialog) {
      debugPrint("message dialog locked");
      return;
    }
    //Ensure we dismiss all dialogs before to not run into race conditions.
    _lockMessageDialog = true;
    Future.delayed(Duration(milliseconds: 500), () => _lockMessageDialog = false);

    final playId = serializedMessage.extractPlayId();
    final extractOperation = serializedMessage.extractOperation();
    final header = await StorageService().loadPlayHeader(playId);

    try {
      debugPrint("received: [$playId] ${extractOperation.name}");
      if (extractOperation == Operation.SendInvite) {
        if (header != null) {
          showAlertDialog(l10n.error_alreadyReactedToInvite(header.getReadablePlayId()));
          //TODO add button to jump to this match entry
        }
        else {
          final comContext = CommunicationContext();
          final (message, error) = await serializedMessage.deserialize(comContext, null, l10n);
          if (message != null) {
            final inviteMessage = message as InviteMessage;
            if (inviteMessage.invitorUserId == _user.id) {
              showAlertDialog(l10n.error_cannotReactToOwnInvitation);
            }
            else {
              _handleReceiveInvite(serializedMessage, inviteMessage, comContext);
            }
          }
          else if (error != null) {
            showAlertDialog(error);
          }
        }
      }
      else if (header == null) {
        showAlertDialog(l10n.error_matchMotFound(toReadablePlayId(playId)));
      }
      else if (header.state.isFinal) {
        showAlertDialog(l10n.error_matchAlreadyFinished(header.getReadablePlayId()));
      }
      else {
        final (message, error) = await serializedMessage.deserialize(
            header.commContext, header.opponentId, l10n);
        if (error != null) {
          showAlertDialog(error);
          return;
        }

        if (extractOperation == Operation.AcceptInvite) {
          _handleInviteAccepted(serializedMessage, header, message as AcceptInviteMessage);
        }
        else if (extractOperation == Operation.RejectInvite) {
          _handleInviteRejected(serializedMessage, header, message as RejectInviteMessage);
        }
        else if (extractOperation == Operation.Move) {
          _handleMove(serializedMessage, header, message as MoveMessage);
        }
        else if (extractOperation == Operation.Resign) {
          _handleResign(serializedMessage, header, message as ResignMessage);
        }
        else {
          showAlertDialog("Unknown operation for $extractOperation for ${header
              .getReadablePlayId()}");
        }
      }
    } on Exception catch (e) {
      debugPrintStack();
      debugPrint(e.toString());

      showAlertDialog("Cannot handle this message!\n" + e.toString());
    }

  }

  Future<void> _handleReceiveInvite(
      SerializedMessage serializedMessage,
      InviteMessage receivedInviteMessage,
      CommunicationContext comContext) async {

    var playId = receivedInviteMessage.playId;
    var opponentName = receivedInviteMessage.invitorUserName;
    var playMode = receivedInviteMessage.playMode;
    var dimension = receivedInviteMessage.playSize.dimension;
    var playOpener = receivedInviteMessage.playOpener;

    await SmartDialog.dismiss();

    showChoiceDialog(
      switch (playOpener) {
        PlayOpener.Invitor => l10n.messaging_invitationMessage_Invitor(dimension, opponentName, playMode.getName(l10n)),
        PlayOpener.Invitee => l10n.messaging_invitationMessage_Invitee(dimension, opponentName, playMode.getName(l10n)),
        PlayOpener.InviteeChooses => l10n.messaging_invitationMessage_InviteeChooses(dimension, opponentName, playMode.getName(l10n)),
        PlayOpener.unused11 => throw UnimplementedError(),
      },
      title: toReadablePlayId(playId),
      width: 300,
      firstString: l10n.accept,
      firstHandler: () {
        // first ask for your name
        if (_user.name.isEmpty) {
          _inputUserName(context, (username) =>
              _handleAcceptInvite(serializedMessage, receivedInviteMessage, comContext));
        }
        else {
          _handleAcceptInvite(serializedMessage, receivedInviteMessage, comContext);
        }


      },
      secondString: l10n.decline,
      secondHandler: () {
        comContext.registerReceivedMessage(serializedMessage);

        final header = PlayHeader.multiPlayInvitee(
            receivedInviteMessage,
            comContext,
            PlayState.InvitationRejected);
        MessageService().sendInvitationRejected(header, _user, () => context);
      },
      thirdString: l10n.replyLater,
      thirdHandler: () {
        comContext.registerReceivedMessage(serializedMessage);

        final header = PlayHeader.multiPlayInvitee(
            receivedInviteMessage,
            comContext,
            PlayState.InvitationPending);
        StorageService().savePlayHeader(header);

      },
      fourthString: MaterialLocalizations.of(context).cancelButtonLabel,
      fourthHandler: () {},
    );

  }

  Future<void> _handleAcceptInvite(
      SerializedMessage serializedMessage,
      InviteMessage receivedInviteMessage,
      CommunicationContext comContext) async {

    comContext.registerReceivedMessage(serializedMessage);

    //  check if meanwhile a header exists due to a race condition. This is a last resort if the ui allows it due to a bug.
    final existingHeader = await StorageService().loadPlayHeader(receivedInviteMessage.playId);
    if (existingHeader != null) {
      throw Exception("A play with ID ${existingHeader.getReadablePlayId()} already exists!");
    }
    final header = PlayHeader.multiPlayInvitee(
        receivedInviteMessage,
        comContext,
        PlayState.InvitationPending);
    return _handleAcceptInviteAfterReplyLater(header);
  }


  Future<void> _handleAcceptInviteAfterReplyLater(PlayHeader header) async {
    if (header.playOpener == PlayOpener.InviteeChooses) {
      _selectInviteeMultiPlayerOpener(context, (playOpener) async {
        _continueAcceptInvite(header, playOpener);
      });
    }
    else {
      _continueAcceptInvite(header, header.playOpener!);
    }
  }

  Future<void> _continueAcceptInvite(PlayHeader header, PlayOpener playOpener) async {
    await PlayStateManager().doAcceptInvite(header, playOpener);

    if (header.playOpener == PlayOpener.Invitee) {
      _startMultiPlayerGame(context, header);
    }
    else if (header.playOpener == PlayOpener.Invitor) {
      await MessageService().sendInvitationAccepted(header, _user, null, () => context);
    }
  }



  Future<void> _handleInviteAccepted(
      SerializedMessage serializedMessage,
      PlayHeader header,
      AcceptInviteMessage message) async {
    final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(header, message);

    if (errorMessage != null) {
      showAlertDialog(errorMessage);
    }
    else {
      header.commContext.registerReceivedMessage(serializedMessage);
      await StorageService().savePlayHeader(header);

      StorageService().loadPlayFromHeader(header).then((play) {
        if (play != null) {
          _continueMultiPlayerGame(context, play, message.initialMove, () {
            showAlertDialog(l10n.messaging_matchAccepted(header.getReadablePlayId()));
          });
        }
        else {
          _startMultiPlayerGame(context, header, message.initialMove, () {
            showAlertDialog(l10n.messaging_matchAccepted(header.getReadablePlayId()));
          });
        }
      });
    }
  }


  Future<void> _handleInviteRejected(
      SerializedMessage serializedMessage,
      PlayHeader header,
      RejectInviteMessage message) async {
    final error = await PlayStateManager().doAndHandleRejectInvite(header, message);
    if (error != null) {
      showAlertDialog(error);
    }
    else {
      header.commContext.registerReceivedMessage(serializedMessage);
      await StorageService().savePlayHeader(header);

      showAlertDialog(l10n.messaging_matchDeclined(header.getReadablePlayId()));
    }
  }

  Future<void> _handleMove(
      SerializedMessage serializedMessage,
      PlayHeader header,
      MoveMessage message) async {

    header.commContext.registerReceivedMessage(serializedMessage);
    await StorageService().savePlayHeader(header);

    StorageService().loadPlayFromHeader(header).then((play) {
      if (play != null) {
        _continueMultiPlayerGame(context, play, message.move);
      }
      else {
        _startMultiPlayerGame(context, header, message.move);
      }
    });
  }

  Future<void> _handleResign(
      SerializedMessage serializedMessage,
      PlayHeader header,
      ResignMessage message) async {

    final error = await PlayStateManager().handleResignedByRemote(header, _user);
    if (error != null) {
      showAlertDialog(error);
    }
    else {
      header.commContext.registerReceivedMessage(serializedMessage);
      await StorageService().savePlayHeader(header);

      StorageService().loadPlayFromHeader(header).then((play) {
        if (play != null) {
          _continueMultiPlayerGame(context, play, null, () {
            showAlertDialog(l10n.messaging_opponentResigned(
                header.opponentName ?? "?", header.getReadablePlayId()));
          });
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme
          .of(context)
          .colorScheme
          .surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 52, 24, 12 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                child: _buildGameLogo(20)
            ),

            if (isDebug)
              GestureDetector(
                onLongPress: () {
                  if (_user.hasSigningCapability()) {
                    showAlertDialog("User Public Key: ${_user.id}");
                  }
                  else {
                    showAlertDialog("User ID: ${_user.id}");
                  }
                },
                  child: _buildHello())
            else
              _buildHello(),

            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildCell(l10n.startMenu_singlePlay, 0,
                    isMain: true,
                    icon: Icons.person,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.SinglePlay
                                ? MenuMode.None
                                : MenuMode.SinglePlay)
                ),

                _menuMode == MenuMode.SinglePlay
                    ? _buildCell(l10n.startMenu_newGame, 0,
                    icon: CupertinoIcons.game_controller,
                    clickHandler: () async {
                      if (context.mounted) {
                        final json = await PreferenceService().getString(
                            PreferenceService.DATA_CURRENT_PLAY);
                        confirmOrDo(json != null,
                            l10n.dialog_overwriteGame,
                            MaterialLocalizations.of(context), () {
                              _selectPlayerGroundSize(context, (dimension) =>
                                  _selectSinglePlayerMode(
                                      context, (chaosPlayer, orderPlayer) =>
                                      _startSinglePlayerGame(
                                          context, chaosPlayer, orderPlayer,
                                          dimension)));
                            });
                      }
                    }
                )
                    : _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(l10n.startMenu_sendInvite, 3, icon: Icons.near_me,
                    clickHandler: () async {
                      if (context.mounted) {
                        _selectPlayerGroundSize(context, (playSize) =>
                            _selectMultiPlayerMode(context, (playMode) =>
                              inviteRemoteOpponentForRevenge(context, playSize, playMode)));
                      }
                    }
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.SinglePlay
                    ? _buildCell(l10n.startMenu_resumeGame, 0,
                    icon: Icons.not_started_outlined,
                    clickHandler: () async {
                      final play = await StorageService().loadCurrentSinglePlay();
                      if (play != null) {
                        await showProgressDialog(l10n.dialog_loadingGame);

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return HyleXGround(_user, play);
                            },
                                settings: RouteSettings(name: PLAY_GROUND)
                            ));
                      }
                      else {
                        showAlertDialog(l10n.error_nothingToResume);
                      }
                    }
                )
                    : _buildEmptyCell(),

                _buildCell(l10n.startMenu_multiPlay, 2,
                    isMain: true,
                    icon: Icons.group,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.Multiplayer
                                ? MenuMode.None
                                : MenuMode.Multiplayer),
                    longClickHandler: () {
                      if (isDebug) {
                          setState(() {
                            isDebug = !isDebug;
                          });
                          showAlertDialog("Debug mode set to $isDebug");
                      }
                    }
                ),

                _menuMode == MenuMode.Multiplayer ||
                    _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(l10n.startMenu_newMatch, 3,
                    icon: Icons.sports_score,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.MultiplayerNew
                                ? MenuMode.Multiplayer
                                : MenuMode.MultiplayerNew))
                    : _buildEmptyCell(),

                _menuMode == MenuMode.Multiplayer ||
                    _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(l10n.startMenu_continueMatch, 4,
                  icon: Icons.sports_tennis,
                  clickHandler: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return MultiPlayerMatches(_user, key: globalMultiPlayerMatchesKey);
                        }));
                  }
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.More
                    ? _buildCell(
                    l10n.startMenu_howToPlay, 1, icon: CupertinoIcons.question_circle_fill,
                    clickHandler: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return Intro();
                        })))
                    : _buildEmptyCell(),

                _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(l10n.startMenu_scanCode, 3, icon: Icons.qr_code_scanner,
                          clickHandler: () => scanNextMove(forceShowAllOptions: false),
                          longClickHandler: _showMultiPlayTestDialog
                       )
                    : _menuMode == MenuMode.More
                    ? _buildCell(l10n.startMenu_achievements, 1, icon: Icons.leaderboard,
                    clickHandler: () => _showAchievementDialog())
                    : _buildEmptyCell(),

                _buildCell(l10n.startMenu_more, 1,
                    isMain: true,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.More
                                ? MenuMode.None
                                : MenuMode.More)
                ),


              ],

            ),

            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () {
                    Navigator.push(super.context, MaterialPageRoute(builder: (context) => SettingsPage()))
                        .then((value) {
                          StorageService().loadUser().then((value) {
                            if (value != null) {
                              setState(() {
                                _user = value;
                              });
                            }
                          });

                    });
                  }, icon: const Icon(Icons.settings_outlined)),

                  IconButton(onPressed: () {
                    ask(l10n.dialog_quitTheApp, l10n, () {
                      SystemNavigator.pop();
                    });
                  }, icon: const Icon(Icons.exit_to_app_outlined)),

                  IconButton(onPressed: () async {
                    final packageInfo = await PackageInfo.fromPlatform();

                    final text = l10n.dialog_aboutDesc2("{homepage}");
                    final splitText = text.split("{homepage}");

                    showAboutDialog(
                      context: context,
                      applicationName: APP_NAME,
                      applicationVersion:packageInfo.version,
                        children: [
                          const Divider(),
                          Text(l10n.dialog_aboutDesc1),
                          const Text(''),
                          InkWell(
                              child: Text.rich(
                                TextSpan(
                                  text: splitText.first,
                                  children: <TextSpan>[
                                    TextSpan(text: GITHUB_HOMEPAGE, style: const TextStyle(decoration: TextDecoration.underline)),
                                    TextSpan(text: splitText.last),
                                  ],
                                ),
                              ),
                              onTap: () {
                                launchUrlString(HOMEPAGE_SCHEME + GITHUB_HOMEPAGE + GITHUB_HOMEPAGE_PATH, mode: LaunchMode.externalApplication);
                              }),
                          const Divider(),
                          const Text('© Jens Pfahl 2026', style: TextStyle(fontSize: 12)),
                        ],
                        applicationIcon: SizedBox(width: 56, height: 56,
                            child: _buildGameLogo(12))
                    );
                  }, icon: const Icon(Icons.info_outline)),
                ]),
          ],
        ),
      ),
    );
  }

  void inviteRemoteOpponentForRevenge(
      BuildContext context,
      PlaySize
      playSize, PlayMode playMode,
        {
          PlayHeader? predecessorPlay
        }
      ) {
    return _selectInvitorMultiPlayerOpener(
                  context, (playerOpener) {
                    if (_user.name.isEmpty) {
                      _inputUserName(context, (username) =>
                          _inviteOpponent(
                              context, playSize, playMode,
                              playerOpener, predecessorPlay));
                    }
                    else {
                      _inviteOpponent(
                          context, playSize, playMode,
                          playerOpener, predecessorPlay);
                    }
                  });
  }

  @override
  void dispose() {
    _uriLinkStreamSub.cancel();
    _intentSub.cancel();

    super.dispose();
  }

  void _selectPlayerGroundSize(BuildContext context,
      Function(PlaySize) handleChosenDimension) {
    _showDimensionChooser(
        context, (dimension) => handleChosenDimension(dimension));
  }

  void _showDimensionChooser(BuildContext context,
      Function(PlaySize) handleChosenDimension) {
    if (isDebug) {
      showInputDialog("Which ground size? Allowed values: 2,3,4,5,7,9,11,13",
        MaterialLocalizations.of(context),
        okHandler: (value) => handleChosenDimension(PlaySize.fromDimension(int.parse(value))),
        validationMessage: "This language is not supported!",
        validationHandler: (v) => PlaySize.values.map((s) => s.dimension.toString()).contains(v),
      );
    }
    else {
      showChoiceDialog(
        l10n.dialog_whichGroundSize,
        width: 300,
        firstString: "5 x 5",
        firstDescriptionString: l10n.dialog_groundSize5,
        firstHandler: () => handleChosenDimension(PlaySize.Size5x5),
        secondString: "7 x 7",
        secondDescriptionString: l10n.dialog_groundSize7,
        secondHandler: () => handleChosenDimension(PlaySize.Size7x7),
        thirdString: "9 x 9",
        thirdDescriptionString: l10n.dialog_groundSize9,
        thirdHandler: () => handleChosenDimension(PlaySize.Size9x9),
        fourthString: "11 x 11",
        fourthDescriptionString: l10n.dialog_groundSize11,
        fourthHandler: () => handleChosenDimension(PlaySize.Size11x11),
        fifthString: "13 x 13",
        fifthDescriptionString: l10n.dialog_groundSize13,
        fifthHandler: () => handleChosenDimension(PlaySize.Size13x13),
      );
    }
  }

  Widget _buildCell(String label, int colorIdx,
      {Function()? clickHandler, Function()? longClickHandler, IconData? icon, bool isMain = false}) {
    return GestureDetector(
      onTap: clickHandler ?? () {
        showAlertDialog('Not yet implemented!');
      },
      onLongPress: longClickHandler,
      child: _buildChip(label, 80, isMain ? 15 : 13, 5, colorIdx, icon),
    );
  }

  Container _buildEmptyCell() {
    return Container(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(), left: BorderSide())
      ),
    );
  }

  void _selectSinglePlayerMode(BuildContext context,
      Function(PlayerType, PlayerType) handleChosenPlayers) {
    showChoiceDialog(
      l10n.dialog_whatRole,
      width: 300,
      height: 550,
      firstString: Role.Order.name,
      firstDescriptionString: l10n.dialog_whatRoleOrder,
      firstHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalUser),
      secondString: Role.Chaos.name,
      secondDescriptionString: l10n.dialog_whatRoleChaos,
      secondHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalAi),
      thirdString: l10n.dialog_roleBoth,
      thirdDescriptionString: l10n.dialog_whatRoleBoth,
      thirdHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalUser),
      fourthString: l10n.dialog_roleNone,
        fourthDescriptionString: l10n.dialog_whatRoleNone,
      fourthHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalAi),
    );
  }

  void _selectInvitorMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    showChoiceDialog(
      l10n.dialog_whatRole,
      width: 300,
      height: 500,
      firstString: Role.Order.name,
      firstDescriptionString: l10n.dialog_whatRoleOrderForMultiPlay,
      firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: Role.Chaos.name,
      secondDescriptionString: l10n.dialog_whatRoleChaosForMultiPlay,
      secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
      thirdString: l10n.dialog_roleInviteeDecides,
      thirdDescriptionString: l10n.dialog_whatRoleInviteeDecides,
      thirdHandler: () => handlePlayOpener(PlayOpener.InviteeChooses),
    );
  }

  void _selectInviteeMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    showChoiceDialog(
        l10n.dialog_whoToStart,
      firstString: l10n.dialog_whoToStartMe, firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: l10n.dialog_whoToStartTheOther, secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
    );
  }

  void _selectMultiPlayerMode(BuildContext context,
      Function(PlayMode) handlePlayerMode) {
    showChoiceDialog(
      l10n.dialog_whatKindOfMatch,
      width: 300,
      height: 450,
      firstString: PlayMode.HyleX.getName(l10n),
      firstDescriptionString: l10n.dialog_whatKindOfMatchHylexStyle,
      firstHandler: () => handlePlayerMode(PlayMode.HyleX),
      secondString: PlayMode.Classic.getName(l10n),
      secondDescriptionString: l10n.dialog_whatKindOfMatchClassicStyle,
      secondHandler: () => handlePlayerMode(PlayMode.Classic),
    );
  }

  void _inputUserName(BuildContext context, Function(String) handleUsername) {
    showInputDialog(l10n.dialog_yourName,
            MaterialLocalizations.of(context),
            prefilledText: _user.name,
            maxLength: maxNameLength,
            validationMessage: l10n.error_illegalCharsForUserName,
            validationHandler: (v) => allowedCharsRegExp.hasMatch(v),
            okHandler: (name) {
              _user.name = name;
              StorageService().saveUser(_user);

              return handleUsername(name);
            },
    );
  }

  Future<void> _startSinglePlayerGame(BuildContext context, PlayerType chaosPlayer,
      PlayerType orderPlayer, PlaySize playSize) async {
    await showProgressDialog(l10n.dialog_initGame);
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          final header = PlayHeader.singlePlay(playSize);
          return HyleXGround(
              _user,
              Play.newSinglePlay(header, chaosPlayer, orderPlayer));
        },
            settings: RouteSettings(name: PLAY_GROUND)));
  }

  Future<void> _startMultiPlayerGame(
      BuildContext context,
      PlayHeader header,
      [
        Move? firstOpponentMove,
        Function()? loadHandler,
      ]) async {
    await showProgressDialog(l10n.dialog_initGame);
    final play = Play.newMultiPlay(header);
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              _user,
              play,
              opponentMoveToApply: firstOpponentMove,
              loadHandler: loadHandler,
          );
        },
          settings: RouteSettings(name: PLAY_GROUND),
        ), (r) {
          return r.settings.name != PLAY_GROUND|| r.isFirst;
        }
    );
  }

  Future<void> _continueMultiPlayerGame(
      BuildContext context,
      Play play,
      Move? opponentMove,
      [Function()? loadHandler]
      ) async {
    await showProgressDialog(l10n.dialog_loadingGame);

    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
            _user,
            play,
            opponentMoveToApply: opponentMove,
            loadHandler: loadHandler,
          );
        },
          settings: RouteSettings(name: PLAY_GROUND),
        ), (r) {
          return r.settings.name != PLAY_GROUND || r.isFirst;
        }
    );

  }

  _inviteOpponent(BuildContext context, PlaySize playSize,
      PlayMode playMode, PlayOpener playOpener, PlayHeader? predecessor) {

    final header = PlayHeader.multiPlayInvitor(playSize, playMode, playOpener);
    StorageService().savePlayHeader(header);

    MessageService().sendRemoteOpponentInvitation(header, _user, () => context,
        showAllOptions: true,
        showPlayCreatedMessage: true)
        .then((_) {
          if (predecessor != null) {
            predecessor.successorPlayId = header.playId;
            StorageService().savePlayHeader(predecessor);
          }
    });
  }

  Widget _buildChip(String label, double radius, double textSize,
      double padding, int colorIdx, [IconData? icon]) {
    final text = Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    color: Colors.white,
                    fontWeight: icon == null ? FontWeight.bold : null,
                  )
              );
    final content = icon != null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              text,
            ],
          )
        : text;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(), left: BorderSide())
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: CircleAvatar(
          backgroundColor: getColorFromIdx(colorIdx),
          radius: radius,
          child: content,
        ),
      ),
    );
  }

  Widget _buildGameLogo(double size) {
    const chipPadding = 1.0;
    return GestureDetector(
      onTap: () => setState(() {
        _logoH = diceInt(maxDimension + 1);
        _logoY = diceInt(maxDimension + 1);
        _logoL = diceInt(maxDimension + 1);
        _logoE = diceInt(maxDimension + 1);
        PreferenceService().setInt(PreferenceService.DATA_LOGO_COLOR_H, _logoH);
        PreferenceService().setInt(PreferenceService.DATA_LOGO_COLOR_Y, _logoY);
        PreferenceService().setInt(PreferenceService.DATA_LOGO_COLOR_L, _logoL);
        PreferenceService().setInt(PreferenceService.DATA_LOGO_COLOR_E, _logoE);
      }),
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChip("H", size, size, chipPadding, _logoH),
            _buildChip("Y", size, size, chipPadding, _logoY),
            Text("X",
                style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold))
          ],
        ),
        Row(
          children: [
            _buildChip("L", size, size, chipPadding, _logoL),
            _buildChip("E", size, size, chipPadding, _logoE),
          ],
        ),
      ]),
    );
  }

  _showAchievementDialog() {
    SmartDialog.show(builder: (_) {

      var filterScope = Scope.All;

      return StatefulBuilder(
          builder: (BuildContext context, setState) {
            final greyed = _user.achievements.getOverallGameCount(filterScope) == 0;

            var filterText = switch(filterScope) {
              Scope.All => l10n.achievements_all,
              Scope.Single => l10n.achievements_single,
              Scope.Multi => l10n.achievements_multi,
            };

            List<Widget> children = [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${l10n.startMenu_achievements} - $filterText",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TriSwitcher(
                      initialPosition: switch(filterScope) {
                        Scope.All => SwitchPosition.left,
                        Scope.Single => SwitchPosition.center,
                        Scope.Multi => SwitchPosition.right,
                      },
                      firstStateBackgroundColor: Colors.brown,
                      secondStateBackgroundColor: Colors.brown.shade200,
                      thirdStateBackgroundColor: Colors.brown.shade200,
                      firstStateToggleColor: Colors.brown.shade900,
                      secondStateToggleColor: Colors.red,
                      thirdStateToggleColor: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      icons: const [
                        Icon(Icons.filter_alt_outlined, color: Colors.brown),
                        Icon(Icons.person, color: Colors.white),
                        Icon(Icons.group, color: Colors.white),
                      ],
                      onChanged: (SwitchPosition position) {
                        setState(() => filterScope = switch(position) {
                          SwitchPosition.left => Scope.All,
                          SwitchPosition.center => Scope.Single,
                          SwitchPosition.right => Scope.Multi,
                        });
                      }),
                ],
              ),
              const Divider(),
              _buildHOverallTotalScoreHead(_user.achievements.getOverallScore(filterScope)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWonLostTotalHead(greyed, prefix: l10n.achievements_overall + " ", dense: false),
                  _buildWonLostTotalCounts(greyed,
                    _user.achievements.getOverallWonCount(filterScope),
                    _user.achievements.getOverallLostCount(filterScope),
                    _user.achievements.getOverallGameCount(filterScope),
                    dense: false,
                  ),
                ],
              ),

            ];

            children.addAll(_buildStatsForDimension(5, filterScope));
            children.addAll(_buildStatsForDimension(7, filterScope));
            children.addAll(_buildStatsForDimension(9, filterScope));
            children.addAll(_buildStatsForDimension(11, filterScope));
            children.addAll(_buildStatsForDimension(13, filterScope));

            children.add(const Divider());
            children.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.lightGreenAccent),
                      onPressed: () {
                        ask(l10n.dialog_resetAchievements, l10n, () {
                          _user.achievements.clearAll();
                          StorageService().saveUser(_user);
                          SmartDialog.dismiss();
                          _showAchievementDialog();
                        });

                      },
                      child: Text(l10n.reset)),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.lightGreenAccent),
                      onPressed: () => SmartDialog.dismiss(),
                      child: Text(l10n.close)),
                ],
              ),
            );

            return Container(
              height: 600,
              width: 350,
              decoration: BoxDecoration(
                color: DIALOG_BG,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: children,
                ),
              ),
            );
          });

    });
  }

  List<Widget> _buildStatsForDimension(int dimension, Scope scope) {
    final greyed =
        _user.achievements.getTotalGameCount(Role.Order, dimension, scope) == 0
        && _user.achievements.getTotalGameCount(Role.Chaos, dimension, scope) == 0;
    return [
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$dimension x $dimension", style: const TextStyle(color: Colors.white)),
          const Text("  "),
          const Text("Chaos", style: TextStyle(color: Colors.white)),
          const Text("Order", style: TextStyle(color: Colors.white)),
        ],
      ),
      const Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHighAndTotalScoreHead(greyed),
          _buildHighAndTotalScore(greyed,
              _user.achievements.getHighScore(Role.Chaos, dimension, scope),
              _user.achievements.getTotalScore(Role.Chaos, dimension, scope)
          ),
          _buildHighAndTotalScore(greyed,
              _user.achievements.getHighScore(Role.Order, dimension, scope),
              _user.achievements.getTotalScore(Role.Order, dimension, scope)
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWonLostTotalHead(greyed),
          _buildWonLostTotalCounts(greyed,
              _user.achievements.getWonGamesCount(Role.Chaos, dimension, scope),
              _user.achievements.getLostGamesCount(Role.Chaos, dimension, scope),
              _user.achievements.getTotalGameCount(Role.Chaos, dimension, scope),
          ),
          _buildWonLostTotalCounts(greyed,
              _user.achievements.getWonGamesCount(Role.Order, dimension, scope),
              _user.achievements.getLostGamesCount(Role.Order, dimension, scope),
              _user.achievements.getTotalGameCount(Role.Order, dimension, scope),
          ),

        ],
      ),

    ];
  }

  Widget _buildHOverallTotalScoreHead(num total) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        children: <TextSpan>[
          TextSpan(text: l10n.achievements_overall + ' '),
          TextSpan(text: l10n.achievements_totalScore, style: TextStyle(color: Colors.cyanAccent)),
          const TextSpan(text: ': '),
          TextSpan(text: total.toString(), style: const TextStyle(color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _buildHighAndTotalScoreHead(bool greyed) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: greyed ? Colors.grey : Colors.white,
        ),
        children: <TextSpan>[
          TextSpan(text: l10n.achievements_high, style: TextStyle(color: greyed ? Colors.grey : Colors.yellowAccent)),
          const TextSpan(text: '/'),
          TextSpan(text: l10n.achievements_totalScore, style: TextStyle(color: greyed ? Colors.grey : Colors.cyanAccent)),
          const TextSpan(text: ': '),
        ],
      ),
    );
  }

  Widget _buildHighAndTotalScore(bool greyed, num high, num total) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 12,
          color: greyed ? Colors.grey : Colors.white,
        ),
        children: <TextSpan>[
          TextSpan(text: high.toString(), style: TextStyle(color: greyed ? Colors.grey : Colors.yellowAccent)),
          const TextSpan(text: ' / '),
          TextSpan(text: total.toString(), style: TextStyle(color: greyed ? Colors.grey : Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _buildWonLostTotalHead(bool greyed, {String? prefix, bool dense = true}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: dense ? 12: 14,
          color: greyed ? Colors.grey : Colors.white,
        ),
        children: <TextSpan>[
          if (prefix != null)
            TextSpan(text: prefix),
          TextSpan(text: l10n.achievements_won, style: TextStyle(color: greyed ? Colors.grey : Colors.lightGreenAccent)),
          const TextSpan(text: '/'),
          TextSpan(text: l10n.achievements_lost, style: TextStyle(color: greyed ? Colors.grey : Colors.redAccent)),
          const TextSpan(text:'/'),
          TextSpan(text: l10n.achievements_totalCount, style: TextStyle(color: greyed ? Colors.grey : Colors.lightBlueAccent)),
          const TextSpan(text: ': '),
        ],
      ),
    );
  }

  Widget _buildWonLostTotalCounts(bool greyed, num won, num lost, num total, {bool dense = true}) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: dense ? 12: 14,
          color: greyed ? Colors.grey : Colors.white,
        ),
        children: <TextSpan>[
          TextSpan(text: won.toString(), style: TextStyle(color: greyed ? Colors.grey : Colors.lightGreenAccent)),
          const TextSpan(text: ' / '),
          TextSpan(text: lost.toString(), style: TextStyle(color: greyed ? Colors.grey : Colors.redAccent)),
          const TextSpan(text: ' / '),
          TextSpan(text: total.toString(), style: TextStyle(color: greyed ? Colors.grey : Colors.lightBlueAccent)),
        ],
      ),
    );
  }

  _showMultiPlayTestDialog() {
    if (isDebug) {
      SmartDialog.show(
          builder: (_) {
            return RemoteTestWidget(
              rootContext: context,
              localUser: _user,
              messageHandler: (message) => _handleMessage(message),
            );
          });
    }
  }

  void handleReplyToInvitation(PlayHeader playHeader) {

    var opponentName = playHeader.opponentName;
    var playId = playHeader.playId;
    var playOpener = playHeader.playOpener;
    var playMode = playHeader.playMode;
    var dimension = playHeader.playSize.dimension;

    showChoiceDialog(
      switch (playOpener!) {
        PlayOpener.Invitor => l10n.messaging_invitationMessage_Invitor(dimension, opponentName?? "?", playMode.getName(l10n)),
        PlayOpener.Invitee => l10n.messaging_invitationMessage_Invitee(dimension, opponentName?? "?", playMode.getName(l10n)),
        PlayOpener.InviteeChooses => l10n.messaging_invitationMessage_InviteeChooses(dimension, opponentName?? "?", playMode.getName(l10n)),
        PlayOpener.unused11 => throw UnimplementedError(),
      },
      title: toReadablePlayId(playId),
      width: 300,
      firstString: l10n.accept,
      firstHandler: () {
        // first ask for your name
        if (_user.name.isEmpty) {
          _inputUserName(context, (username) =>
              _handleAcceptInviteAfterReplyLater(playHeader));
        }
        else {
          _handleAcceptInviteAfterReplyLater(playHeader);
        }


      },
      secondString: l10n.decline,
      secondHandler: () async {
        final error = await PlayStateManager().doAndHandleRejectInvite(playHeader);
        if (error != null) {
          showAlertDialog(error);
        }
        else {
          await MessageService().sendInvitationRejected(playHeader, _user, () => context);
        }
      },
      thirdString: MaterialLocalizations.of(context).cancelButtonLabel,
      thirdHandler: () {},
    );
  }

  void scanNextMove({
    PlayHeader? header = null,
    required bool forceShowAllOptions,
  }) {

    if (!forceShowAllOptions && header?.props[HeaderProps.rememberMessageReading] == "from_message") {
      _readFromMessage();
    }
    else if (!forceShowAllOptions && header?.props[HeaderProps.rememberMessageReading] == "from_qr_code") {
      _readFromQrCode(context);
    }
    else {
      showModalBottomSheet(
        context: context,

        builder: (BuildContext context) {
          _requestCameraPermission();

          bool remember = false;

          return SafeArea(
            child: StatefulBuilder(
              builder: (BuildContext context, setState) {
                return Container(
                  height: 350,
            
                  child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        mainAxisSize: MainAxisSize.max,
                        spacing: 5,
                        children: [
                          Text(l10n.action_scanOrPasteMessage),
                          Text(""),
                          buildFilledButton(
                              context,
                              Icons.qr_code_scanner,
                              l10n.action_scanMessage,
                                  () {
            
                                    if (header != null) {
                                      header.props[HeaderProps.rememberMessageReading] = remember ? "from_qr_code" : "";
                                      StorageService().savePlayHeader(header);
                                    }
            
                                    Navigator.of(context).pop();
                                _readFromQrCode(context);
                              }),
                          buildOutlinedButton(
                              context,
                              Icons.paste,
                              l10n.action_pasteMessage,
                                  () {
                                    if (header != null) {
                                      header.props[HeaderProps.rememberMessageReading] = remember ? "from_message" : "";
                                      StorageService().savePlayHeader(header);
                                    }
                                    Navigator.of(context).pop();
                                    _readFromMessage();
                              }),
                          if (header != null) CheckboxListTile(
                              title: Text(l10n.messaging_rememberDecision),
                              value: remember,
                              dense: true,
                              checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.all(
                                      Radius.elliptical(10, 20))),
                              onChanged: (value) {
                                setState(() {
                                  if (value != null) {
                                    remember = value;
                                  }
                                });
                              }),
                        ],
                      )
                  ),
                );
              },
            ),
          );
        },
      );
    }

  }

  void _readFromMessage() {
    showInputDialog(
        l10n.action_pasteMessageHere,
        MaterialLocalizations.of(context),
        height: 380,
        minLines: 3,
        maxLines: 3,
        okHandler: (s) {
          final uri = extractAppLinkFromString(s);
          if (uri == null) {
            showAlertDialog(
                l10n.action_pasteMessageError,
                duration: Duration(seconds: 5)
            );
          }
          else {
            handleReceivedMessage(uri);
          }
        },
        thirdText: l10n.action_pasteMessage,
        thirdHandler: (controller) async {
          final data = await Clipboard.getData(
              "text/plain");
          if (data?.text != null) {
            controller.value =
            new TextEditingValue(text: data!.text!);
          }
        }
    );
  }

  void _readFromQrCode(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return QrReaderPage();
        })).then((result) {
      if (result != null) {
        try {
          final uri = Uri.parse(result);
          handleReceivedMessage(uri);
        } catch (e) {
          print(e);
          showAlertDialog(
              l10n.action_scanMessageError,
              duration: Duration(seconds: 5));
        }
      }
    });
  }



  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error_cameraPermissionNeeded)),
        );
      }
    }
  }

  Widget _buildHello() {
    if (_user.name.isNotEmpty)
      return Text(
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
          l10n.hello(_user.name)
      );
    else if (isDebug)
      return Text(
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
          l10n.hello(_user.getReadableId())
      );
      else
        return Container();
  }

}

