import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher_string.dart';

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

  @override
  void initState() {
    super.initState();

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
      toastInfo(context, "Cannot read URL from shared text: $err");
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
        toastInfo(context, "Cannot read URL from shared text.");
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
      showAlertDialog("I cannot interpret this uri : $uri");
    }
  }

  Future<void> _handleMessage(SerializedMessage serializedMessage) async {
    final playId = serializedMessage.extractPlayId();
    final extractOperation = serializedMessage.extractOperation();
    final header = await StorageService().loadPlayHeader(playId);

    try {
      debugPrint("received: [$playId] ${extractOperation.name}");
      if (extractOperation == Operation.SendInvite) {
        if (header != null) {
          showAlertDialog("You already reacted to this invite. See ${header
              .getReadablePlayId()}");
          //TODO add button to jump to this match entry
        }
        else {
          final comContext = CommunicationContext();
          final (message, error) = serializedMessage.deserialize(comContext);
          if (message != null) {
            _handleReceiveInvite(message as InviteMessage, comContext);
          }
          else if (error != null) {
            showAlertDialog(error);
          }
        }
      }
      else if (header == null) {
        showAlertDialog("Match ${toReadableId(serializedMessage
            .extractPlayId())} is not present! Did you delete it?");
      }
      else if (header.state.isFinal) {
        showAlertDialog("Match ${toReadableId(
            serializedMessage.extractPlayId())} is already finished (${header
            .state.toMessage()}).");
      }
      else {
        final (message, error) = serializedMessage.deserialize(
            header.commContext);
        if (error != null) {
          showAlertDialog(error);
        }
        else if (extractOperation == Operation.AcceptInvite) {
          _handleInviteAccepted(header, message as AcceptInviteMessage);
        }
        else if (extractOperation == Operation.RejectInvite) {
          _handleInviteRejected(header);
        }
        else if (extractOperation == Operation.Move) {
          _handleMove(header, message as MoveMessage);
        }
        else if (extractOperation == Operation.Resign) {
          _handleResign(header, message as ResignMessage);
        }
        else {
          showAlertDialog("Unknown operation for $extractOperation for ${header
              .getReadablePlayId()}");
        }
      }
    } on Exception catch (e) {
      debugPrintStack();
      debugPrint(e.toString());

      showAlertDialog("Cannot handle this message!");
    }

  }

  void _handleReceiveInvite(InviteMessage receivedInviteMessage, CommunicationContext comContext) {

    var dimension = receivedInviteMessage.playSize.dimension;

    showChoiceDialog(
        "${receivedInviteMessage
            .invitorUserName} invited you to a ${receivedInviteMessage.playMode.name.toLowerCase()} $dimension x $dimension match.",
      width: 300,
      firstString: "Accept",
      firstHandler: () {
        // first ask for your name
        if (_user.name.isEmpty) {
          _inputUserName(context, (username) =>
              _handleAcceptInvite(receivedInviteMessage, comContext));
        }
        else {
          _handleAcceptInvite(receivedInviteMessage, comContext);
        }


      },
      secondString: "Reject",
      secondHandler: () {
        final header = PlayHeader.multiPlayInvitee(
            receivedInviteMessage,
            comContext,
            PlayState.InvitationRejected);
        MessageService().sendInvitationRejected(header, _user, () => context);
      },
      thirdString: "Reply later",
      thirdHandler: () {
        final header = PlayHeader.multiPlayInvitee(
            receivedInviteMessage,
            comContext,
            PlayState.InvitationPending);
        StorageService().savePlayHeader(header);

      },
      fourthString: translate('common.cancel'),
      fourthHandler: () {},
    );

  }

  Future<void> _handleAcceptInvite(InviteMessage receivedInviteMessage, CommunicationContext comContext) async {

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



  Future<void> _handleInviteAccepted(PlayHeader header, AcceptInviteMessage message) async {
    final errorMessage = await PlayStateManager().handleInviteAcceptedByRemote(header, message);

    if (errorMessage != null) {
      showAlertDialog(errorMessage);
    }
    else {
      StorageService().loadPlayFromHeader(header).then((play) {
        if (play != null) {
          _continueMultiPlayerGame(context, play, message.initialMove, () {
            showAlertDialog("Match ${header.getReadablePlayId()} has been accepted.");
          });
        }
        else {
          _startMultiPlayerGame(context, header, message.initialMove, () {
            showAlertDialog("Match ${header.getReadablePlayId()} has been accepted.");
          });
        }
      });
    }
  }


  Future<void> _handleInviteRejected(PlayHeader header) async {
    final error = await PlayStateManager().doAndHandleRejectInvite(header);
    if (error != null) {
      showAlertDialog(error);
    }
    else {
      showAlertDialog("Match ${header.getReadablePlayId()} has been rejected.");
    }
  }

  void _handleMove(PlayHeader header, MoveMessage message) {

    StorageService().loadPlayFromHeader(header).then((play) {
      if (play != null) {
        _continueMultiPlayerGame(context, play, message.move);
      }
      else {
        _startMultiPlayerGame(context, header, message.move);
      }
    });
  }

  Future<void> _handleResign(PlayHeader header, ResignMessage message) async {

    final error = await PlayStateManager().handleResignedByRemote(header, _user);
    if (error != null) {
      showAlertDialog(error);
    }
    else {
      StorageService().loadPlayFromHeader(header).then((play) {
        if (play != null) {
          _continueMultiPlayerGame(context, play, null, () {
            showAlertDialog(
                "Your opponent '${header.opponentName}' gave up match ${header
                    .getReadablePlayId()}, you win!");
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
        padding: const EdgeInsets.fromLTRB(24, 52, 24, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                child: _buildGameLogo(20)
            ),

            if (_user.name.isNotEmpty)
              Text(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                  translate('common.hello', args: {'name' : _user.name})
              )
            else if (isDebug)
              Text(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                  translate('common.hello', args: {'name' : _user.getReadableId()})
              ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildCell(translate('startMenu.singlePlay'), 0,
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
                    ? _buildCell(translate('startMenu.newGame'), 0,
                    icon: CupertinoIcons.game_controller,
                    clickHandler: () async {
                      if (context.mounted) {
                        final json = await PreferenceService().getString(
                            PreferenceService.DATA_CURRENT_PLAY);
                        confirmOrDo(json != null,
                            translate('dialogs.overwriteGame'), () {
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
                    ? _buildCell(translate('startMenu.sendInvite'), 3, icon: Icons.near_me,
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
                    ? _buildCell(translate('startMenu.resumeGame'), 0,
                    icon: Icons.not_started_outlined,
                    clickHandler: () async {
                      final play = await StorageService().loadCurrentSinglePlay();
                      if (play != null) {
                        await showShowLoading(translate('dialogs.loadingGame'));

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return HyleXGround(_user, play);
                            },
                                settings: RouteSettings(name: PLAY_GROUND)
                            ));
                      }
                      else {
                        showAlertDialog('No ongoing single play to resume.');
                      }
                    }
                )
                    : _buildEmptyCell(),

                _buildCell(translate('startMenu.multiPlay'), 2,
                    isMain: true,
                    icon: Icons.group,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.Multiplayer
                                ? MenuMode.None
                                : MenuMode.Multiplayer),
                    longClickHandler: () {
                      setState(() {
                        isDebug = !isDebug;
                      });
                      showAlertDialog("Debug mode set to $isDebug");
                    }
                ),

                _menuMode == MenuMode.Multiplayer ||
                    _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(translate('startMenu.newMatch'), 3,
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
                    ? _buildCell(translate('startMenu.continueMatch'), 4,
                  icon: Icons.sports_tennis,
                  clickHandler: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return MultiPlayerMatches(_user, key: globalMultiPlayerMatchesKey,);
                        }));
                  }
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.More
                    ? _buildCell(
                    translate('startMenu.howToPlay'), 1, icon: CupertinoIcons.question_circle_fill,
                    clickHandler: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                          return Intro();
                        })))
                    : _buildEmptyCell(),

                _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell(translate('startMenu.scanCode'), 3, icon: Icons.qr_code_scanner,
                          clickHandler: scanNextMove,
                          longClickHandler: _showMultiPlayTestDialog
                       )
                    : _menuMode == MenuMode.More
                    ? _buildCell(translate('startMenu.achievements'), 1, icon: Icons.leaderboard,
                    clickHandler: () => _showAchievementDialog())
                    : _buildEmptyCell(),

                _buildCell(translate('startMenu.more'), 1,
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
                    ask(translate('dialogs.quitTheApp'), () {
                      SystemNavigator.pop();
                    });
                  }, icon: const Icon(Icons.exit_to_app_outlined)),

                  IconButton(onPressed: () async {
                    final packageInfo = await PackageInfo.fromPlatform();

                    final text = translate('dialogs.aboutDesc2');
                    final splitText = text.split("{homepage}");

                    showAboutDialog(
                      context: context,
                      applicationName: APP_NAME,
                      applicationVersion:packageInfo.version,
                        children: [
                          const Divider(),
                          Text(translate('dialogs.aboutDesc1')),
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
                          const Text('© Jens Pfahl 2025', style: TextStyle(fontSize: 12)),
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
          okHandler: (value) => handleChosenDimension(PlaySize.fromDimension(int.parse(value))));
    }
    else {
      showChoiceDialog(
        translate('dialogs.whichGroundSize'),
        width: 300,
        firstString: "5 x 5",
        firstDescriptionString: translate('dialogs.groundSize5'),
        firstHandler: () => handleChosenDimension(PlaySize.Size5x5),
        secondString: "7 x 7",
        secondDescriptionString: translate('dialogs.groundSize7'),
        secondHandler: () => handleChosenDimension(PlaySize.Size7x7),
        thirdString: "9 x 9",
        thirdDescriptionString: translate('dialogs.groundSize9'),
        thirdHandler: () => handleChosenDimension(PlaySize.Size9x9),
        fourthString: "11 x 11",
        fourthDescriptionString: translate('dialogs.groundSize11'),
        fourthHandler: () => handleChosenDimension(PlaySize.Size11x11),
        fifthString: "13 x 13",
        fifthDescriptionString: translate('dialogs.groundSize13'),
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
      translate('dialogs.whatRole'),
      width: 300,
      firstString: Role.Order.name,
      firstDescriptionString: translate('dialogs.whatRoleOrder'),
      firstHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalUser),
      secondString: Role.Chaos.name,
      secondDescriptionString: translate('dialogs.whatRoleChaos'),
      secondHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalAi),
      thirdString: translate('dialogs.roleBoth'),
      thirdDescriptionString: translate('dialogs.whatRoleBoth'),
      thirdHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalUser),
      fourthString: translate('dialogs.roleNone'),
        fourthDescriptionString: translate('dialogs.whatRoleNone'),
      fourthHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalAi),
    );
  }

  void _selectInvitorMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    showChoiceDialog(
      translate('dialogs.whatRole'),
      width: 300,
      height: 500,
      firstString: Role.Order.name,
      firstDescriptionString: translate('dialogs.whatRoleOrderForMultiPlay'),
      firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: Role.Chaos.name,
      secondDescriptionString: translate('dialogs.whatRoleChaosForMultiPlay'),
      secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
      thirdString: translate('dialogs.roleInviteeDecides'),
      thirdDescriptionString: translate('dialogs.whatRoleInviteeDecides'),
      thirdHandler: () => handlePlayOpener(PlayOpener.InviteeChooses),
    );
  }

  void _selectInviteeMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    showChoiceDialog(
      'Who shall start? The one who starts is Chaos.',
      firstString: "ME", firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: "THE OTHER", secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
    );
  }

  void _selectMultiPlayerMode(BuildContext context,
      Function(PlayMode) handlePlayerMode) {
    showChoiceDialog(
      translate('dialogs.whatKindOfMatch'),
      width: 300,
      height: 450,
      firstString: PlayMode.HyleX.getName(),
      firstDescriptionString: translate('dialogs.whatKindOfMatchHylexStyle'),
      firstHandler: () => handlePlayerMode(PlayMode.HyleX),
      secondString: PlayMode.Classic.getName(),
      secondDescriptionString: translate('dialogs.whatKindOfMatchClassicStyle'),
      secondHandler: () => handlePlayerMode(PlayMode.Classic),
    );
  }

  void _inputUserName(BuildContext context, Function(String) handleUsername) {
    showInputDialog(translate('dialogs.yourName'),
            prefilledText: _user.name,
            maxLength: maxNameLength,
            okHandler: (name) {
              _user.name = name;
              StorageService().saveUser(_user);

              return handleUsername(name);
            },
    );
  }

  Future<void> _startSinglePlayerGame(BuildContext context, PlayerType chaosPlayer,
      PlayerType orderPlayer, PlaySize playSize) async {
    await showShowLoading(translate('dialogs.initGame'));
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
    await showShowLoading(translate('dialogs.initGame'));
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
    await showShowLoading(translate('dialogs.loadingGame'));

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

    MessageService().sendRemoteOpponentInvitation(header, _user, () => context, showAllOptions: true)
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
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip("H", size, size, chipPadding, 4),
          _buildChip("Y", size, size, chipPadding, 5),
          Text("X",
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold))
        ],
      ),
      Row(
        children: [
          _buildChip("L", size, size, chipPadding, 7),
          _buildChip("E", size, size, chipPadding, 8),
        ],
      ),
    ]);
  }

  _showAchievementDialog() {
    SmartDialog.show(builder: (_) {
      final greyed = _user.achievements.getOverallGameCount() == 0;
      List<Widget> children = [
              Text(
                translate('startMenu.achievements'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(),
              _buildHOverallTotalScoreHead(_user.achievements.getOverallScore()),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildWonLostTotalHead(greyed, prefix: "Overall ", dense: false),
                  _buildWonLostTotalCounts(greyed,
                    _user.achievements.getOverallWonCount(),
                    _user.achievements.getOverallLostCount(),
                    _user.achievements.getOverallGameCount(),
                    dense: false,
                  ),
                ],
              ),

            ];

      children.addAll(_buildStatsForDimension(5));
      children.addAll(_buildStatsForDimension(7));
      children.addAll(_buildStatsForDimension(9));
      children.addAll(_buildStatsForDimension(11));
      children.addAll(_buildStatsForDimension(13));

      children.add(const Divider());
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () {
                  ask(translate('dialogs.resetAchievements'), () {
                    _user.achievements.clearAll();
                    StorageService().saveUser(_user);
                    SmartDialog.dismiss();
                    _showAchievementDialog();
                  });

                },
                child: Text(translate('common.reset'))),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () => SmartDialog.dismiss(),
                child: Text(translate('common.close'))),
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
  }

  List<Widget> _buildStatsForDimension(int dimension) {
    final greyed =
        _user.achievements.getTotalGameCount(Role.Order, dimension) == 0
        && _user.achievements.getTotalGameCount(Role.Chaos, dimension) == 0;
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
              _user.achievements.getHighScore(Role.Chaos, dimension),
              _user.achievements.getTotalScore(Role.Chaos, dimension)
          ),
          _buildHighAndTotalScore(greyed,
              _user.achievements.getHighScore(Role.Order, dimension),
              _user.achievements.getTotalScore(Role.Order, dimension)
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWonLostTotalHead(greyed),
          _buildWonLostTotalCounts(greyed,
              _user.achievements.getWonGamesCount(Role.Chaos, dimension),
              _user.achievements.getLostGamesCount(Role.Chaos, dimension),
              _user.achievements.getTotalGameCount(Role.Chaos, dimension),
          ),
          _buildWonLostTotalCounts(greyed,
              _user.achievements.getWonGamesCount(Role.Order, dimension),
              _user.achievements.getLostGamesCount(Role.Order, dimension),
              _user.achievements.getTotalGameCount(Role.Order, dimension),
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
          const TextSpan(text: 'Overall '),
          const TextSpan(text: "Total Score", style: TextStyle(color: Colors.cyanAccent)),
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
          TextSpan(text: "High", style: TextStyle(color: greyed ? Colors.grey : Colors.yellowAccent)),
          const TextSpan(text: '/'),
          TextSpan(text: "Total Score", style: TextStyle(color: greyed ? Colors.grey : Colors.cyanAccent)),
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
          TextSpan(text: "Won", style: TextStyle(color: greyed ? Colors.grey : Colors.lightGreenAccent)),
          const TextSpan(text: '/'),
          TextSpan(text: "Lost", style: TextStyle(color: greyed ? Colors.grey : Colors.redAccent)),
          const TextSpan(text:'/'),
          TextSpan(text: "Total Count", style: TextStyle(color: greyed ? Colors.grey : Colors.lightBlueAccent)),
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
              messageHandler: (message) => _handleMessage(message),
            );
          });
    }
  }

  void handleReplyToInvitation(PlayHeader playHeader) {
    var dimension = playHeader.playSize.dimension;

    showChoiceDialog(
      "${playHeader.opponentName} invited you to a ${playHeader.playMode.name.toLowerCase()} $dimension x $dimension match.",
      width: 300,
      firstString: "Accept",
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
      secondString: "Reject",
      secondHandler: () async {
        final error = await PlayStateManager().doAndHandleRejectInvite(playHeader);
        if (error != null) {
          showAlertDialog(error);
        }
        else {
          await MessageService().sendInvitationRejected(playHeader, _user, () => context);
        }
      },
      thirdString: translate('common.cancel'),
      thirdHandler: () {},
    );
  }

  void scanNextMove() {
    showModalBottomSheet(
      context: context,

      builder: (BuildContext context) {
        _requestCameraPermission();

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
                      Text(translate('sheets.scanOrPasteMessage')),
                      Text(""),
                      buildFilledButton(
                          context,
                          Icons.qr_code_scanner,
                          translate('sheets.scanMessage'),
                          () {
                        Navigator.of(context).pop();

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
                                  translate('sheets.scanMessageError'),
                                  duration: Duration(seconds: 5));
                            }
                          }
                        });


                      }),
                      buildOutlinedButton(
                          context,
                          Icons.paste,
                          translate('sheets.pasteMessage'),
                          () {
                        Navigator.of(context).pop();

                        showInputDialog(translate('sheets.pasteMessageHere'),
                          height: 380,
                          minLines: 3,
                          maxLines: 3,
                          okHandler: (s) {
                            final uri = extractAppLinkFromString(s);
                            if (uri == null) {
                              showAlertDialog(
                                  translate('sheets.pasteMessageError'),
                                  duration: Duration(seconds: 5)
                              );
                            }
                            else {
                              handleReceivedMessage(uri);
                            }
                          },
                          thirdText: translate('sheets.pasteMessage'),
                          thirdHandler: (controller) async {
                            final data = await Clipboard.getData("text/plain");
                            if (data?.text != null) {
                              controller.value = new TextEditingValue(text: data!.text!);
                            }
                          }
                        );
                        }),
                    ],
                  )
              ),
            );
          },
        );


      },
    );

  }



  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera permission is required to scan QR codes')),
        );
      }
    }
  }

}

