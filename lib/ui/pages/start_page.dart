import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:share_plus/share_plus.dart';

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


class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  MenuMode _menuMode = MenuMode.None;

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
      final serializedMessage = SerializedMessage.fromUrl(uri);
      if (serializedMessage != null) {
        _handleMessage(serializedMessage);
      }
      else {
        debugPrint("invalid uri: $uri");
        buildAlertDialog("I cannot interpret this uri : $uri");
      }
    });
  }

  Future<void> _handleMessage(SerializedMessage serializedMessage) async {
    final playId = serializedMessage.extractPlayId();
    final extractOperation = serializedMessage.extractOperation();
    final header = await StorageService().loadPlayHeader(playId);

    debugPrint("received: [$playId] ${extractOperation.name}");
    if (extractOperation == Operation.SendInvite) {
      if (header != null) {
        buildAlertDialog("You already reacted to this invite. See ${header.getReadablePlayId()}");
        //TODO add button to jump to this match entry
      }
      else {
        final message = serializedMessage.deserializeWithoutValidation() as InviteMessage;
        _handleReceiveInvite(message);
      }
    }
    else if (header == null) {
      buildAlertDialog("Match ${toReadableId(serializedMessage.extractPlayId())} is not present! Did you delete it?");
    }
    else if (header.state.isFinal) {
      buildAlertDialog("Match ${toReadableId(serializedMessage.extractPlayId())} is already finished (${header.state.toMessage()}).");
    }
    else if (extractOperation == Operation.AcceptInvite) {
      final message = serializedMessage.deserialize(header.commContext) as AcceptInviteMessage;
      _handleInviteAccepted(header, message);
    }
    else if (extractOperation == Operation.RejectInvite) {
      final message = serializedMessage.deserialize(header.commContext) as RejectInviteMessage;
      _handleInviteRejected(header, message);
    }
    else if (extractOperation == Operation.Move) {
      final message = serializedMessage.deserialize(header.commContext) as MoveMessage;
      _handleMove(header, message);
    }
    else if (extractOperation == Operation.Resign) {
      final message = serializedMessage.deserialize(header.commContext) as ResignMessage;
      _handleResign(header, message);
    }
    else {
      buildAlertDialog("Unknown operation for $extractOperation for ${header.getReadablePlayId()}");
    }

  }

  void _handleReceiveInvite(InviteMessage receivedInviteMessage) {

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
              _handleAcceptInvite(receivedInviteMessage));
        }
        else {
          _handleAcceptInvite(receivedInviteMessage);
        }


      },
      secondString: "Reject",
      secondHandler: () {
        final header = PlayHeader.multiPlayInvitee(receivedInviteMessage, PlayState.InvitationRejected);
        MessageService().sendInvitationRejected(header, _user, () => StorageService().savePlayHeader(header));
      },
      thirdString: "Reply later",
      thirdHandler: () {
        final header = PlayHeader.multiPlayInvitee(receivedInviteMessage, PlayState.InvitationPending);
        StorageService().savePlayHeader(header);

      },
      fourthString: "Cancel",
      fourthHandler: () {},
    );

  }

  void _handleAcceptInvite(InviteMessage receivedInviteMessage) {
    final header = PlayHeader.multiPlayInvitee(receivedInviteMessage, PlayState.InvitationAccepted);
    StorageService().savePlayHeader(header);
    if (receivedInviteMessage.playOpener == PlayOpener.InvitedPlayerChooses) {
      _selectInvitedMultiPlayerOpener(context, (playOpener) {
        header.playOpener = playOpener;
        StorageService().savePlayHeader(header);
    
        if (playOpener == PlayOpener.Invitee) {
          _startMultiPlayerGame(context, header);
        }
        else {
          // reply back, they have to start
          MessageService().sendInvitationAccepted(header, _user, null,
                  () => StorageService().savePlayHeader(header));
        }
      });
    }
    else if (receivedInviteMessage.playOpener == PlayOpener.Invitee) {
      _startMultiPlayerGame(context, header);
    }
    else if (receivedInviteMessage.playOpener == PlayOpener.Invitor) {
      MessageService().sendInvitationAccepted(header, _user, null,
              () => StorageService().savePlayHeader(header));
    }
  }


  void _handleInviteAccepted(PlayHeader header, AcceptInviteMessage message) {
    if (header.state == PlayState.InvitationRejected) {
      buildAlertDialog("Match ${header.getReadablePlayId()} already rejected, cannot accept afterwards.");
    }
    else {
      header.state = PlayState.InvitationAccepted;
      StorageService().savePlayHeader(header);

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

  void _handleInviteRejected(PlayHeader header, RejectInviteMessage message) {
    if (header.state == PlayState.InvitationRejected) {
      buildAlertDialog("Match ${header.getReadablePlayId()} already rejected.");
    }
    else {
      header.state = PlayState.InvitationRejected;
      StorageService().savePlayHeader(header);
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

  void _handleResign(PlayHeader header, ResignMessage message) {
    
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
                          return MultiPlayerMatches(_user);
                        }));
                  }
                )
                    : _buildEmptyCell(),

                _menuMode == MenuMode.More
                    ? _buildCell(
                    "How to Play", 1, icon: CupertinoIcons.question_circle_fill)
                    : _buildEmptyCell(),

                _menuMode == MenuMode.MultiplayerNew
                    ? _buildCell("Got Invited", 3, icon: Icons.qr_code_2)
                    : _menuMode == MenuMode.More
                    ? _buildCell("Achievements", 1, icon: Icons.leaderboard,
                    clickHandler: () => _buildAchievementDialog())
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
      {Function()? clickHandler, IconData? icon, bool isMain = false}) {
    return GestureDetector(
      onTap: clickHandler ?? () {
        buildAlertDialog('Not yet implemented!', type: NotifyType.error);
      },
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

  Future<void> _startMultiPlayerGame(BuildContext context, PlayHeader header, [Move? firstMove]) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    final play = Play.newMultiPlay(header);
    if (firstMove != null) {
      play.nextPlayer();
      play.applyStaleMove(firstMove);
      play.commitMove();
    }
    await Future.delayed(const Duration(seconds: 1));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              _user,
              play);
        }));
  }

  Future<void> _continueMultiPlayerGame(BuildContext context, Play play, Move? move) async {
    SmartDialog.showLoading(msg: "Loading game ...");
    if (move != null) {
      play.nextPlayer();
      play.applyStaleMove(move);
      play.commitMove();
    }
    await Future.delayed(const Duration(seconds: 1));
    Navigator.push(context,
        MaterialPageRoute(builder: (context) {
          return HyleXGround(
              _user,
              play);
        }));
  }

  _inviteOpponent(BuildContext context, PlaySize playSize,
      PlayMode playMode, PlayOpener playOpener) {

    final header = PlayHeader.multiPlayInvitor(playSize, playMode, playOpener, PlayState.RemoteOpponentInvited);

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

  _buildAchievementDialog() {
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
                    _buildAchievementDialog();
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


}
