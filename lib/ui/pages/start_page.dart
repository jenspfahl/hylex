import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/utils/fortune.dart';

import '../../model/common.dart';
import '../../model/messaging.dart';
import '../../model/move.dart';
import '../../model/play.dart';
import '../../model/user.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';
import '../ui_utils.dart';
import 'game_ground.dart';
import 'multi_player_matches.dart';

enum MenuMode {
  None,
  SinglePlay,
  Multiplayer,
  MultiplayerNew,
  More
}


GlobalKey<StartPageState> globalStartPageKey = GlobalKey();

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  MenuMode _menuMode = MenuMode.None;

  Map<String, Route> _playRoutes = HashMap();


  User _user = User();

  late StreamSubscription<Uri> _uriLinkStreamSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 18, end: 30).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);


    StorageService().loadUser().then((user) =>
        setState(() {
          if (user != null) {
            _user = user;
          }
        }));

    _uriLinkStreamSub = AppLinks().uriLinkStream.listen((uri) {
      handleReceivedMessage(uri);
    });
  }

  void handleReceivedMessage(Uri uri) {
    final serializedMessage = SerializedMessage.fromUrl(uri);
    if (serializedMessage != null) {
      _handleMessage(serializedMessage);
    }
    else {
      debugPrint("invalid uri: $uri");
      buildAlertDialog("I cannot interpret this uri : $uri");
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
          buildAlertDialog("You already reacted to this invite. See ${header
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
            buildAlertDialog(error);
          }
        }
      }
      else if (header == null) {
        buildAlertDialog("Match ${toReadableId(serializedMessage
            .extractPlayId())} is not present! Did you delete it?");
      }
      else if (header.state.isFinal) {
        buildAlertDialog("Match ${toReadableId(
            serializedMessage.extractPlayId())} is already finished (${header
            .state.toMessage()}).");
      }
      else {
        final (message, error) = serializedMessage.deserialize(
            header.commContext);
        if (error != null) {
          buildAlertDialog(error);
        }
        else if (extractOperation == Operation.AcceptInvite) {
          _handleInviteAccepted(header, message as AcceptInviteMessage);
        }
        else if (extractOperation == Operation.RejectInvite) {
          _handleInviteRejected(header, message as RejectInviteMessage);
        }
        else if (extractOperation == Operation.Move) {
          _handleMove(header, message as MoveMessage);
        }
        else if (extractOperation == Operation.Resign) {
          _handleResign(header, message as ResignMessage);
        }
        else {
          buildAlertDialog("Unknown operation for $extractOperation for ${header
              .getReadablePlayId()}");
        }
      }
    } on Exception catch (e) {
      debugPrintStack();
      debugPrint(e.toString());

      buildAlertDialog("Cannot handle this message!");
    }

  }

  void _handleReceiveInvite(InviteMessage receivedInviteMessage, CommunicationContext comContext) {

    var dimension = receivedInviteMessage.playSize.toDimension();

    buildChoiceDialog(
        "${receivedInviteMessage
            .invitingUserName} invited you to a ${receivedInviteMessage.playMode.name.toLowerCase()} $dimension x $dimension match.",
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
        MessageService().sendInvitationRejected(header, _user, () async {
          await _saveAndNotify(header);
        });
      },
      thirdString: "Reply later",
      thirdHandler: () async {
        final header = PlayHeader.multiPlayInvitee(
            receivedInviteMessage,
            comContext,
            PlayState.InvitationPending);
        await _saveAndNotify(header);

      },
      fourthString: "Cancel",
      fourthHandler: () {},
    );

  }

  Future<void> _handleAcceptInvite(InviteMessage receivedInviteMessage, CommunicationContext comContext) async {

    final header = await _createAndStoreNewMultiPlay(receivedInviteMessage, comContext, _getStateFromPlayOpener(receivedInviteMessage.playOpener));
    return _handleAcceptInviteWithHeader(header);
  }


  Future<void> _handleAcceptInviteWithHeader(PlayHeader header) async {
    if (header.playOpener == PlayOpener.InvitedPlayerChooses) {
      _selectInvitedMultiPlayerOpener(context, (playOpener) async {
        header.playOpener = playOpener;
        header.state = _getStateFromPlayOpener(playOpener);
        await _saveAndNotify(header);

        if (playOpener == PlayOpener.Invitee) {
          _startMultiPlayerGame(context, header);
        }
        else {
          // reply back, invitor has to start
          MessageService().sendInvitationAccepted(header, _user, null,
                  () async {
                await _saveAndNotify(header);
              });
        }
      });
    }
    else if (header.playOpener == PlayOpener.Invitee) {
      header.playOpener = header.playOpener!;
      header.state = _getStateFromPlayOpener(header.playOpener!);
      await _saveAndNotify(header);

      _startMultiPlayerGame(context, header);
    }
    else if (header.playOpener == PlayOpener.Invitor) {
      header.playOpener = header.playOpener!;
      header.state = _getStateFromPlayOpener(header.playOpener!);
      MessageService().sendInvitationAccepted(header, _user, null,
              () async {
            await _saveAndNotify(header);
          });
    }
  }

  Future<PlayHeader> _createAndStoreNewMultiPlay(InviteMessage receivedInviteMessage, CommunicationContext comContext, PlayState state) async {
    final header = PlayHeader.multiPlayInvitee(
        receivedInviteMessage,
        comContext,
        state);
    await _saveAndNotify(header);
    return header;
  }


  Future<void> _handleInviteAccepted(PlayHeader header, AcceptInviteMessage message) async {
    if (header.state == PlayState.InvitationRejected) {
      buildAlertDialog("Match ${header.getReadablePlayId()} already rejected, cannot accept afterwards.");
    }
    else {
      header.state = PlayState.RemoteOpponentAccepted;
      header.playOpener = message.playOpenerDecision;
      await _saveAndNotify(header);

      buildAlertDialog("Match ${header.getReadablePlayId()} has been accepted.");
      StorageService().loadPlayFromHeader(header).then((play) {
        if (play != null) {
          _continueMultiPlayerGame(context, play, message.initialMove);
        }
        else {
          _startMultiPlayerGame(context, header, message.initialMove);
        }
      });
    }
  }

  Future<void> _saveAndNotify(PlayHeader header) async {
    await StorageService().savePlayHeader(header);
    globalMultiPlayerMatchesKey.currentState?.playHeaderChanged();
  }

  Future<void> _handleInviteRejected(PlayHeader header, RejectInviteMessage message) async {
    if (header.state == PlayState.InvitationRejected) {
      buildAlertDialog("Match ${header.getReadablePlayId()} already rejected.");
    }
    else {
      header.state = PlayState.InvitationRejected;
      await _saveAndNotify(header);

      buildAlertDialog("Match ${header.getReadablePlayId()} has been rejected.");
    }
  }

  void _handleMove(PlayHeader header, MoveMessage message) {

    StorageService().loadPlayFromHeader(header).then((play) {
      if (play != null) {
        play.header.state = PlayState.ReadyToMove;
        _continueMultiPlayerGame(context, play, message.move);
      }
      else {
        _startMultiPlayerGame(context, header, message.move);
      }
    });
  }

  Future<void> _handleResign(PlayHeader header, ResignMessage message) async {
    header.state = PlayState.OpponentResigned;
    await _saveAndNotify(header);

    StorageService().loadPlayFromHeader(header).then((play) {
      if (play != null) {
        //TODO register win
      }
    });
    buildAlertDialog("Your opponent '${header.opponentName}' gave up match ${header.getReadablePlayId()}, you win!");

  }


  @override
  Widget build(BuildContext context) {
    return _buildStartPage(context);
  }

  Widget _buildStartPage(BuildContext context) {
    return Container(
      color: Theme
          .of(context)
          .colorScheme
          .surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Container(
                child: _buildGameLogo()
            ),

            if (_user.name.isNotEmpty)
              Text(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                  "Hello ${_user.name}!")
            else if (kDebugMode)
              Text(
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                "Hello ${_user.getReadableId()}!"),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [

                _buildCell("Single Play", 0,
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
                    ? _buildCell("New Game", 0,
                    icon: CupertinoIcons.game_controller,
                    clickHandler: () async {
                      if (context.mounted) {
                        final json = await PreferenceService().getString(
                            PreferenceService.DATA_CURRENT_PLAY);
                        confirmOrDo(json != null,
                            'Starting a new game will delete an ongoing game.', () {
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
                    ? _buildCell("Send Invite", 3, icon: Icons.near_me,
                    clickHandler: () async {
                      if (context.mounted) {
                        _selectPlayerGroundSize(context, (playSize) =>
                            _selectMultiPlayerMode(context, (playerMode) =>
                                _selectInvitingMultiPlayerOpener(
                                    context, (playerOpener) {
                                      if (_user.name.isEmpty) {
                                        _inputUserName(context, (username) =>
                                            _inviteOpponent(
                                                context, playSize, playerMode,
                                                playerOpener));
                                      }
                                      else {
                                        _inviteOpponent(
                                            context, playSize, playerMode,
                                            playerOpener);
                                      }
                                    })));
                      }
                    }
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.SinglePlay
                    ? _buildCell("Resume", 0,
                    icon: Icons.not_started_outlined,
                    clickHandler: () async {
                      final play = await StorageService().loadCurrentSinglePlay();
                      if (play != null) {
                        SmartDialog.showLoading(msg: "Loading game ...");
                        await Future.delayed(const Duration(seconds: 1));

                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                              return HyleXGround(_user, play);
                            }));
                      }
                      else {
                        buildAlertDialog('No ongoing single play to resume.');
                      }
                    }
                )
                    : _buildEmptyCell(),

                _buildCell("Multiplayer", 2,
                    isMain: true,
                    icon: Icons.group,
                    clickHandler: () =>
                        setState(
                                () =>
                            _menuMode = _menuMode == MenuMode.Multiplayer
                                ? MenuMode.None
                                : MenuMode.Multiplayer)
                ),

                _menuMode == MenuMode.Multiplayer ||
                    _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("New Match", 3,
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
                    ? _buildCell("Continue Match", 4,
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
                    "How to Play", 1, icon: CupertinoIcons.question_circle_fill)
                    : _buildEmptyCell(),

                _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("Got Invited", 3, icon: Icons.qr_code_scanner,
                          longClickHandler: _showMultiPlayTestDialog
                       )
                    : _menuMode == MenuMode.More
                    ? _buildCell("Achievements", 1, icon: Icons.leaderboard,
                    clickHandler: () => _showAchievementDialog())
                    : _buildEmptyCell(),

                _buildCell("More", 1,
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

                  }, icon: const Icon(Icons.settings_outlined)),

                  IconButton(onPressed: () {
                    ask('Quit the app?', () {
                      SystemNavigator.pop();
                    });
                  }, icon: const Icon(Icons.exit_to_app_outlined)),

                  IconButton(onPressed: () {

                  }, icon: const Icon(Icons.info_outline)),
                ]),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uriLinkStreamSub.cancel();
    super.dispose();
  }

  void _selectPlayerGroundSize(BuildContext context,
      Function(PlaySize) handleChosenDimension) {
    _showDimensionChooser(
        context, (dimension) => handleChosenDimension(dimension));
  }

  void _showDimensionChooser(BuildContext context,
      Function(PlaySize) handleChosenDimension) {
    buildChoiceDialog(
      'Which ground size?',
      firstString: "5 x 5", firstHandler: () => handleChosenDimension(PlaySize.Size5x5),
      secondString: "7 x 7", secondHandler: () => handleChosenDimension(PlaySize.Size7x7),
      thirdString: "9 x 9", thirdHandler: () => handleChosenDimension(PlaySize.Size9x9),
      fourthString: "11 x 11", fourthHandler: () => handleChosenDimension(PlaySize.Size11x11),
      fifthString: "13 x 13", fifthHandler: () => handleChosenDimension(PlaySize.Size13x13),
    );
  }

  Widget _buildCell(String label, int colorIdx,
      {Function()? clickHandler, Function()? longClickHandler, IconData? icon, bool isMain = false}) {
    return GestureDetector(
      onTap: clickHandler ?? () {
        buildAlertDialog('Not yet implemented!', type: NotifyType.error);
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
    buildChoiceDialog(
      'Which role you will take?',
      firstString: "ORDER", firstHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalUser),
      secondString: "CHAOS", secondHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalAi),
      thirdString: "BOTH", thirdHandler: () => handleChosenPlayers(PlayerType.LocalUser, PlayerType.LocalUser),
      fourthString: "NONE", fourthHandler: () => handleChosenPlayers(PlayerType.LocalAi, PlayerType.LocalAi),
    );
  }

  void _selectInvitingMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    buildChoiceDialog(
      'Which role you will take?',
      firstString: "ORDER", firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: "CHAOS", secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
      thirdString: "INVITED DECIDES", thirdHandler: () => handlePlayOpener(PlayOpener.InvitedPlayerChooses),
    );
  }

  void _selectInvitedMultiPlayerOpener(BuildContext context,
      Function(PlayOpener) handlePlayOpener) {
    buildChoiceDialog(
      'Who shall start? The one who starts is Chaos.',
      firstString: "ME", firstHandler: () => handlePlayOpener(PlayOpener.Invitee),
      secondString: "THE OTHER", secondHandler: () => handlePlayOpener(PlayOpener.Invitor),
    );
  }

  void _selectMultiPlayerMode(BuildContext context,
      Function(PlayMode) handlePlayerMode) {
    buildChoiceDialog(
      'What kind of game fo you want to play? ',
      firstString: "HYLEX-STYLE", firstHandler: () => handlePlayerMode(PlayMode.HyleX),
      secondString: "CLASSIC-STYLE", secondHandler: () => handlePlayerMode(PlayMode.Classic),
    );
  }

  void _inputUserName(BuildContext context, Function(String) handleUsername) {
    buildInputDialog('What\'s your name?',
            prefilledText: _user.name,
            okHandler: (name) {
              _user.name = name;
              StorageService().saveUser(_user);

              return handleUsername(name);
            },
    );
  }

  Future<void> _startSinglePlayerGame(BuildContext context, PlayerType chaosPlayer,
      PlayerType orderPlayer, PlaySize playSize) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    await Future.delayed(const Duration(seconds: 1));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          final header = PlayHeader.singlePlay(playSize);
          return HyleXGround(
              _user,
              Play.newSinglePlay(header, chaosPlayer, orderPlayer));
        }));
  }

  Future<void> _startMultiPlayerGame(BuildContext context, PlayHeader header, [Move? firstOpponentMove]) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    final play = Play.newMultiPlay(header);
    await Future.delayed(const Duration(seconds: 1));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              _user,
              play,
              opponentMoveToApply: firstOpponentMove,
          );
        }));
  }

  Future<void> _continueMultiPlayerGame(BuildContext context, Play play, Move? opponentMove) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    await Future.delayed(const Duration(seconds: 1));


    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
            _user,
            play,
            opponentMoveToApply: opponentMove,
          );
        }));
    /*
    final routeKey = play.header.playId;
    var route = _playRoutes[routeKey] ?? MaterialPageRoute(builder: (context) {
      return HyleXGround(
          _user,
          play,
          opponentMoveToApply: opponentMove,
      );
    });
    _playRoutes[routeKey] = route;

    if (route.isCurrent == true) {
      // TODO apply play to current route either with a callback or a state change listener / GloblKey
    }
    else {
      Navigator.push(context, route);
    }*/

  }

  _inviteOpponent(BuildContext context, PlaySize playSize,
      PlayMode playMode, PlayOpener playOpener) {

    final header = PlayHeader.multiPlayInvitor(playSize, playMode, playOpener);

    MessageService().sendRemoteOpponentInvitation(header, _user,
            () => StorageService().savePlayHeader(header));
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

  Widget _buildGameLogo() {
    const chipPadding = 1.0;
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip("H", 20, 20, chipPadding, 4),
          _buildChip("Y", 20, 20, chipPadding, 5),
          Text("X",
              style: TextStyle(
                  fontSize: _animation.value,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.bold))
        ],
      ),
      Row(
        children: [
          _buildChip("L", 20, 20, chipPadding, 6),
          _buildChip("E", 20, 20, chipPadding, 7),
        ],
      ),
    ]);
  }

  _showAchievementDialog() {
    SmartDialog.show(builder: (_) {
      final greyed = _user.achievements.getOverallGameCount() == 0;
      List<Widget> children = [
              const Text(
                "Achievements",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              //if (_user.name != null) Text(_user.name!),
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
                  ask("Reset all stats to zero:", () {
                    _user.achievements.clearAll();
                    StorageService().saveUser(_user);
                    SmartDialog.dismiss();
                    _showAchievementDialog();
                  });

                },
                child: const Text("RESET")),
            OutlinedButton(
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightGreenAccent),
                onPressed: () => SmartDialog.dismiss(),
                child: const Text("CLOSE")),
          ],
        ),
      );

      return Container(
        height: 600,
        width: 350,
        decoration: BoxDecoration(
          color: Colors.black,
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
    SmartDialog.show(
        builder: (_) {

      return RemoteTestWidget(
        messageHandler: (message) => _handleMessage(message),
      );
    });
  }

  void handleReplyToInvitation(PlayHeader playHeader) {
    var dimension = playHeader.playSize.toDimension();

    buildChoiceDialog(
      "${playHeader.opponentName} invited you to a ${playHeader.playMode.name.toLowerCase()} $dimension x $dimension match.",
      width: 300,
      firstString: "Accept",
      firstHandler: () {
        // first ask for your name
        if (_user.name.isEmpty) {
          _inputUserName(context, (username) =>
              _handleAcceptInviteWithHeader(playHeader));
        }
        else {
          _handleAcceptInviteWithHeader(playHeader);
        }


      },
      secondString: "Reject",
      secondHandler: () {
        playHeader.state = PlayState.InvitationRejected;
        MessageService().sendInvitationRejected(playHeader, _user, () async {
          await _saveAndNotify(playHeader);
        });
      },
      thirdString: "Cancel",
      thirdHandler: () {},
    );
  }

  PlayState _getStateFromPlayOpener(PlayOpener playOpener) {
    return playOpener == PlayOpener.Invitor
        ? PlayState.InvitationAccepted_WaitForOpponent
        : PlayState.InvitationAccepted_ReadyToMove;
  }


}

