
import 'dart:async';
import 'dart:collection';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/matrix.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/ui/pages/multi_player_matches.dart';
import 'package:hyle_x/ui/pages/remotetest/remote_test_widget.dart';
import 'package:hyle_x/ui/pages/start_page.dart';
import 'package:hyle_x/utils/dates.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../../engine/game_engine.dart';
import '../../model/chip.dart';
import '../../model/common.dart';
import '../chip_extension.dart';
import '../../model/coordinate.dart';
import '../../model/move.dart';
import '../../model/play.dart';
import '../../model/spot.dart';
import '../../model/stock.dart';
import '../../model/user.dart';
import '../ui_utils.dart';
import '../Tooltips.dart';
import '../dialogs.dart';

class HyleXGround extends StatefulWidget {
  User user;
  Play play;
  Move? opponentMoveToApply;
  Function()? loadHandler;

  HyleXGround(this.user, this.play, {super.key, this.opponentMoveToApply, this.loadHandler});

  @override
  State<HyleXGround> createState() => _HyleXGroundState();

}

class _HyleXGroundState extends State<HyleXGround> {

  late GameEngine gameEngine;

  GameChip? _emphasiseAllChipsOf;
  Role? _emphasiseAllChipsOfRole;
  bool _gameOverShown = false;
  
  late StreamSubscription<FGBGType> fgbgSubscription;

  final _chaosChipTooltip = "chaosChipTooltip";
  final _orderChipTooltip = "orderChipTooltip";
  final _stockChipToolTipKey = "stockChipToolTip";


  @override
  void initState() {
    super.initState();

    SmartDialog.dismiss(); // dismiss loading dialog


    if (widget.play.multiPlay) {
      gameEngine = MultiPlayerGameEngine(
          widget.play,
          widget.user,
          () => context,
          _handleGameOver
      );
    }
    else {
      gameEngine = SinglePlayerGameEngine(
          widget.play,
          widget.user,
          () => context,
          _handleGameOver
      );
    }


    fgbgSubscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.background) {
        // TODO could be removed, we save whenever we change the play
        gameEngine.savePlayState();
      }
    });

    gameEngine.addListener(_gameListener);

    gameEngine.startGame();
    
    if (widget.opponentMoveToApply != null) {
      gameEngine.opponentMoveReceived(widget.opponentMoveToApply!);
    }

    if (widget.loadHandler != null) {
      widget.loadHandler!();
    }
  }

  _handleGameOver() {
    if (!gameEngine.play.isMultiplayerPlay && !_gameOverShown) {
      _showGameOver(context);
      _gameOverShown = true;
    }
  }

  _gameListener() {
    if (mounted) {
      setState(() {
        debugPrint("update UI");
      });
      globalMultiPlayerMatchesKey.currentState?.playHeaderChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameBody();
  }

  @override
  void dispose() {
    gameEngine.pauseGame();
    gameEngine.removeListener(_gameListener);
    fgbgSubscription.cancel();

    super.dispose();
  }

  Widget _buildGameBody() {
    return WillPopScope(
      onWillPop: () async {
        await gameEngine.pauseGame(); //await to get the play saved to avoid race conditions
        Navigator.pop(super.context); // go to start page
        return true;
      },
      child: Scaffold(
                appBar: AppBar(
                  //automaticallyImplyLeading: false,
                  leadingWidth: 25,
                  title: GestureDetector(
                    onTap: () {
                      showAlertDialog(_getGameTitle(), icon: null);
                    },
                    child: Text(
                      _getGameTitle(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ),
                  actions: [
                    Visibility(
                      visible: _isUndoAllowed(),
                      child: IconButton(
                        icon: const Icon(Icons.undo_outlined),
                        onPressed: () {
                          if (!_isUndoAllowed()) {
                            toastInfo(context, "Undo not possible here");
                            return;
                          }
      
                          setState(() async {
                            if (gameEngine.play.hasStaleMove) {
                              gameEngine.play.undoStaleMove();
                              gameEngine.play.selectionCursor.clear();
                              await gameEngine.savePlayState();
                            }
                            else {
      
                              final recentRole = gameEngine.play.opponentRole.name;
                              final currentRole = gameEngine.play.currentRole.name;
                              var message = translate('dialogs.undoLastMove', args: {"recentRole" : recentRole});

                              if (gameEngine.play.isWithAiPlay && gameEngine.play.journal.length > 1) {
                                message = translate('dialogs.undoLastTwoMoves',
                                    args: {"recentRole" : recentRole, "currentRole": currentRole});
                              }

                              ask(message, () {
                                  setState(() async {
                                    await gameEngine.undoLastMove();
                                    toastInfo(context, "Undo competed");
                                  });
                                });
                            }
                          });
      
                        },
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          showModalBottomSheet(
                              showDragHandle: true,
                              context: context,

                              builder: (BuildContext context) {

                                return StatefulBuilder(
                                  builder: (BuildContext context, setSheetState) {

                                    // TODO potential memory leak, this listener is never removed within an ongoing play
                                    gameEngine.addListener(() {
                                      if (context.mounted) {
                                        setSheetState((){});
                                      }
                                    });

                                    final elements = gameEngine.play.journal
                                        .indexed
                                        .map((e) => _buildJournalEvent(e))
                                        .toList()
                                        .reversed
                                        .toList();

                                    elements.add(const Text(""));
                                    elements.add(_buildJournalLineSeparator(context, translate("gameStates.gameStarted")));
                                    if (gameEngine.play.isGameOver()) {
                                      elements.insert(0, _buildJournalLineSeparator(context, translate("gameStates.gameOver")));
                                      elements.insert(1, const Text(""));
                                    }
                                    return Container(
                                      height: MediaQuery.sizeOf(context).height / 2,
                                      width: MediaQuery.sizeOf(context).width,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.vertical,
                                          child: Center(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Column(
                                                  children: elements,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );


                            },
                          );
                        },
                        icon: const Icon(Icons.history)),
                    Visibility(
                      visible: !gameEngine.play.isMultiplayerPlay,
                      child: IconButton(
                        icon: const Icon(Icons.restart_alt_outlined),
                        onPressed: () => {

                          ask(translate('dialogs.restartGame'), () {
                                gameEngine.stopGame();
                                _gameOverShown = false;
                                gameEngine.startGame();
                          })
                        },
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isMultiplayerPlay && gameEngine.play.waitForOpponent,
                      child: GestureDetector(
                        onLongPress: () => _showMultiPlayTestDialog(gameEngine.play.header),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner),
                          onPressed: () {
                            globalStartPageKey.currentState?.scanNextMove();
                          },
                        ),
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isMultiplayerPlay && !gameEngine.play.waitForOpponent &&!gameEngine.play.isGameOver(),
                      child: IconButton(
                        icon: const Icon(Icons.sentiment_dissatisfied_outlined),
                        onPressed: () {
                          ask('Wanna give up?', () async {
                            await gameEngine.resignGame();
                            setState(() {});
                          });
                        },
                      ),
                    ),
                    if (gameEngine.play.isMultiplayerPlay)
                      PopupMenuButton<int>(
                        onSelected: (item) {
                          if (item == 0) {
                            _showGameDetails(gameEngine.play);
                          }
                          else if (gameEngine.play.classicModeFirstMatrix != null) {
                            _showFirstGameOfClassicMode(
                                gameEngine.play.classicModeFirstMatrix!,
                                gameEngine.play.header.getLocalRoleForMultiPlay()!.opponentRole,
                                gameEngine.play.stats.classicModeFirstRoundOrderPoints!);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<int>(value: 0, child: Text('Match Info')),
                          if (gameEngine.play.header.rolesSwapped == true 
                              && gameEngine.play.classicModeFirstMatrix != null)
                            PopupMenuItem<int>(value: 1, child: Text('Show first game')),
                        ],
                      ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildRoleIndicator(Role.Chaos, gameEngine.play.chaosPlayer, true),
                                  Column(children: [
                                    Text(translate("gameHeader.roundOf", args:
                                      {
                                        "round": gameEngine.play.currentRound,
                                        "totalRounds": gameEngine.play.maxRounds
                                      })
                                    ),
                                    if (gameEngine.play.header.rolesSwapped != null)
                                      Text (gameEngine.play.header.rolesSwapped! ? translate("gameHeader.rolesSwapped") : translate("playMode.classic"),
                                        style: TextStyle(fontStyle: FontStyle.italic),),
                                  ]),
                                  _buildRoleIndicator(Role.Order, gameEngine.play.orderPlayer, false),
                                ],
                              ),
                            ),
                            LinearProgressIndicator(
                              value: gameEngine.play.progress,
                              backgroundColor: Colors.brown[100],
                            ),
                            Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                  child: Center(
                                    child: GridView.builder(
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: gameEngine.play.stock.getTotalChipTypes(),
                                        ),
                                        itemBuilder: _buildChipStock,
                                        itemCount: gameEngine.play.stock.getTotalChipTypes(),
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics()),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                  height: 20,
                                  child: GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gameEngine.play.stock.getTotalChipTypes(),
                                      ),
                                      itemBuilder: _buildChipStockIndicator,
                                      itemCount: gameEngine.play.stock.getTotalChipTypes(),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics()),
                                ),
                              ],
                            ),
                            AspectRatio(
                              aspectRatio: 1,
                              child: _buildChipGrid(_buildBoardGrid),
                            ),
      
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                              child: _buildHint(context),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 0, top: 0, right: 0, bottom: 16),
                              child: _buildSubmitButton(context),
                            ),
                          ]),
                    ),
                  ),
                )),
    );

  }

  Container _buildJournalLineSeparator(BuildContext context, [String? text]) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Center(child: text != null
          ? Text("--------- $text ---------")
          : Text("------------------------------------")),
    );
  }

  Widget _buildChipGrid(NullableIndexedWidgetBuilder builder) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2.0)),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gameEngine.play.dimension,
          ),
          itemBuilder: builder,
          itemCount: gameEngine.play.maxRounds,
          physics: const NeverScrollableScrollPhysics()),
    );
  }

  String _getGameTitle() {
    return gameEngine.play.isMultiplayerPlay
                        ? gameEngine.play.header.getTitle()
                        : gameEngine.play.isFullAutomaticPlay
                          ? translate('gameTitle.automatic')
                          : gameEngine.play.isBothSidesSinglePlay
                            ? translate('gameTitle.alternate')
                            : translate('gameTitle.againstComputer');
  }

  Widget _buildJournalEvent((int, Move) e) {
    final maxRound = gameEngine.play.maxRounds;
    final isClassic = gameEngine.play.header.playMode == PlayMode.Classic;

    var swapThreshold = (maxRound * 2) - 1;
    var isRoleSwap = isClassic && (e.$1 == swapThreshold);
    var isSecondGame = isClassic && (e.$1 >= swapThreshold);

    var idx = (e.$1+1)/2;
    var round = isSecondGame ? idx.floor() : idx.ceil();
    if (isSecondGame) {
      round = (round % maxRound) + 1;
    }

    final move = e.$2;
    final role = move.toRole();
    final localPlayer = gameEngine.play.getPlayerTypeOf(role);
    final opponentPlayer = gameEngine.play.getPlayerTypeOf(role.opponentRole);

    Widget row = _buildMoveLine(move, prefix: "${translate("gameHeader.round", args: {"round" : round})}: ",
        playerType: !gameEngine.play.isBothSidesSinglePlay
            ? (isClassic
              ? (isSecondGame ? localPlayer : opponentPlayer)
              : localPlayer)
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (move.toRole() == Role.Order) _buildJournalLineSeparator(context),
        row,
        if (isRoleSwap) Text(""),
        if (isRoleSwap) _buildJournalLineSeparator(context, translate("gameHeader.rolesSwapped")),
        if (isRoleSwap) Text(""),
      ]
    );
  }


  _showMultiPlayTestDialog(PlayHeader playHeader) {
    if (isDebug) {
      SmartDialog.show(
          builder: (_) {
            return RemoteTestWidget(
              rootContext: context,
              playHeader: playHeader,
              messageHandler: (message) {
                globalStartPageKey.currentState?.handleReceivedMessage(
                    message.toUri());
              },
            );
          });
    }
  }



  Widget _buildMoveLine(Move move, {String? prefix, MainAxisAlignment? mainAxisAlignment, PlayerType? playerType}) {
    var eventLineString = move.toReadableStringWithChipPlaceholder(playerType);
    return _replaceWithChipIcon(prefix, eventLineString, mainAxisAlignment, move.chip);
  }

  Widget _replaceWithChipIcon(String? prefix, String text, MainAxisAlignment? mainAxisAlignment, GameChip? chip) {
    Widget row;
    if (text.contains("{chip}") && chip != null) {
      final split = text.split("{chip}");
      final first = split[0];
      final second = split[1];

      row = Wrap(
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
       // mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        children: [
          if (prefix != null)
            Text(prefix),
          Text("${first}${chip.getChipName()} "),
          CircleAvatar(
              backgroundColor: _getChipColor(chip, null),
              maxRadius: 6,
          ),
          Text(second),
        ],
      );
    }
    else {
      row = Wrap(alignment: WrapAlignment.start,
       // mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        children: [
          if (prefix != null)
            Text(prefix),
          Text(text),
        ],
      );
    }
    return row;
  }



  bool _isUndoAllowed() => !gameEngine.isBoardLocked()
      && !gameEngine.play.isGameOver()
      && !gameEngine.play.isFullAutomaticPlay
      && !gameEngine.play.isMultiplayerPlay
      && (!gameEngine.play.isJournalEmpty || gameEngine.play.hasStaleMove);


  Widget _buildHint(BuildContext context) {
    if (gameEngine.play.isGameOver()) {
      return Text(_buildWinnerOrLooserText(),
          style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center);
    }
    else if (gameEngine.play.currentPlayer == PlayerType.LocalAi) {
      return _buildAiProgressText();
    }
    else if (gameEngine.play.header.state == PlayState.FirstGameFinished_WaitForOpponent) {
      return Text("First game finished, roles will be swapped, so remote opponent becomes Chaos!");
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return Text(translate("gameStates.waitingForRemoteOpponent",
          args: {"name": gameEngine.play.currentRole.name}));
    }
    else {
      return _buildDoneText();
    }
  }

  String _buildWinnerOrLooserText() {
    final winnerRole = gameEngine.play.getWinnerRole();
    final looserRole = gameEngine.play.getLooserRole();
    final winnerPlayer = gameEngine.play.getWinnerPlayer();
    final looserPlayer = gameEngine.play.getLooserPlayer();

    if (gameEngine.play.isFullAutomaticPlay || gameEngine.play.isBothSidesSinglePlay) {
      return translate("gameStates.gameOverWinner",
          args: { "who" : winnerRole.name});
    }
    else if (gameEngine.play.isWithAiPlay) {
      if (winnerPlayer == PlayerType.LocalUser) {
        return translate("gameStates.gameOverWinner",
            args: { "who" : "${winnerRole.name} (${winnerPlayer.getName()})"});
      }
      else {
        return translate("gameStates.gameOverLooser",
            args: { "who" : "${looserRole.name} (${looserPlayer.getName()})"});
      }
    }
    else if (gameEngine.play.isMultiplayerPlay) {
      var localRole = gameEngine.play.header.getLocalRoleForMultiPlay();

      if (gameEngine.play.header.state == PlayState.Resigned) {
        return translate("gameStates.gameOverYouResigned");
      }
      else if (gameEngine.play.header.state == PlayState.OpponentResigned) {
        return translate("gameStates.gameOverOpponentResigned");
      }

      if (winnerRole == localRole) {
        return translate("gameStates.gameOverWinner",
            args: { "who" : "${localRole!.name}"});
      }
      else {
        return translate("gameStates.gameOverLooser",
            args: { "who" : "${localRole!.name}"});
      }
    }
    else {
      return "";
    }
    
  }

  String _buildLooserText() {
    final looserRole = gameEngine.play.getLooserRole();
    final looserPlayer = gameEngine.play.getLooserPlayer();

    return translate("gameStates.gameOverLooser",
        args: { "who" : "${looserRole.name} (${looserPlayer.name})"});
  }

  Row _buildAiProgressText() {
    final text = _buildAiProcessingText();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        text,
        const Text("  "),
        SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeCap: StrokeCap.butt,
            strokeWidth: 2,
            value: gameEngine.progressRatio,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
    ],);
  }

  Widget _buildSubmitButton(BuildContext context) {
    if (gameEngine.play.isGameOver()) {
      if (gameEngine.play.isMultiplayerPlay) {
        return Column(
          children: [
            if (gameEngine.play.getWinnerPlayer() != PlayerType.LocalUser && gameEngine.play.header.playMode == PlayMode.HyleX)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildFilledButton(context,
                    Icons.restart_alt,
                    translate('submitButton.rematch'),
                        () {

                      if (gameEngine.play.header.successorPlayId != null) {
                        showChoiceDialog(translate('dialogs.askForRematchAgain', args: {"playId": toReadableId(gameEngine.play.header.successorPlayId!)}),
                            firstString: translate('dialogs.askAgain'),
                            firstHandler: () {
                              globalStartPageKey.currentState?.inviteRemoteOpponentForRevenge(
                                  context,
                                  gameEngine.play.header.playSize,
                                  gameEngine.play.header.playMode,
                                  predecessorPlay: gameEngine.play.header
                              );
                            },
                            secondString: translate('common.cancel'),
                            secondHandler: () {  });
                      }
                      else {
                        globalStartPageKey.currentState?.inviteRemoteOpponentForRevenge(
                            context,
                            gameEngine.play.header.playSize,
                            gameEngine.play.header.playMode,
                            predecessorPlay: gameEngine.play.header
                        );
                      }

                    }),
              )
            ,
            if (gameEngine.play.header.isStateShareable())
              GestureDetector(
                onLongPress: () {
                  if (gameEngine is MultiPlayerGameEngine) {
                    (gameEngine as MultiPlayerGameEngine).shareGameMove(true);
                  }
                },
                child: buildOutlinedButton(
                    context,
                    Icons.near_me,
                    translate('submitButton.shareAgain'),
                        () {
                      if (gameEngine is MultiPlayerGameEngine) {
                        (gameEngine as MultiPlayerGameEngine).shareGameMove(false);
                      }
                    }
                ),
              ),
          ],
        );
      }
      else {
        return buildFilledButton(
            context,
            Icons.restart_alt,
            translate('submitButton.restart'),
            () async {
            await gameEngine.stopGame();
            _gameOverShown = false;
            gameEngine.startGame();
          });
      }
    }
    else if (gameEngine.play.currentPlayer == PlayerType.LocalUser) {
      if (gameEngine.play.header.state == PlayState.FirstGameFinished_ReadyToSwap) {
        return buildFilledButton(
            context,
            Icons.swap_horiz_outlined,
            translate('submitButton.swapRoles'),
                () {
              gameEngine.play.swapGameForClassicMode();
              gameEngine.savePlayState();
            },
        );
      }
      final isDirty = gameEngine.play.hasStaleMove;
      return buildFilledButton(
          context,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? Icons.redo
              : Icons.near_me,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? translate('submitButton.skipMove')
              : translate('submitButton.submitMove'),
          () {
            if (gameEngine.isBoardLocked()) {
              return;
            }
            if (gameEngine.play.isGameOver()) {
              return;
            }
            if (gameEngine.play.currentRole == Role.Chaos && !isDirty) {
              toastInfo(context, "Chaos has to place one chip before continuing!");
              return;
            }

            final skipMove = !isDirty && gameEngine.play.currentRole == Role.Order;
            if (gameEngine.play.multiPlay && skipMove) {
              ask(translate('dialogs.skipMove'), () async {
                gameEngine.play.applyStaleMove(Move.skipped());
                gameEngine.play.commitMove();
                gameEngine.nextPlayer();
              });
            }
            else {
              if (skipMove) {
                gameEngine.play.applyStaleMove(Move.skipped());
              }
              gameEngine.play.commitMove();
              gameEngine.nextPlayer();
            }
          },
        isBold: isDirty
      );
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return GestureDetector(
        onLongPress: () {
          if (gameEngine is MultiPlayerGameEngine) {
            (gameEngine as MultiPlayerGameEngine).shareGameMove(true);
          }
        },
        child: buildOutlinedButton(
            context,
            Icons.near_me,
            translate('submitButton.shareAgain'),
            () {
            if (gameEngine is MultiPlayerGameEngine) {
              (gameEngine as MultiPlayerGameEngine).shareGameMove(false);
            }
          }
        ),
      );
    }
    return Container();
  }

  Widget _buildDoneText() {
    Widget? lastMoveHint = null;

    final lastMove = gameEngine.play.lastMoveFromJournal;
    if (lastMove != null) {
      lastMoveHint = _buildMoveLine(lastMove, mainAxisAlignment: MainAxisAlignment.center);
    }

    var appendix = "";

    if (gameEngine.play.header.state == PlayState.FirstGameFinished_ReadyToSwap) {
      appendix = "➤ ${translate("requests.swapRoles")}";
    }
    else if (gameEngine.play.currentRole == Role.Order) {
      appendix = "➤ ${translate("requests.orderToMove")}";
    }
    else if (gameEngine.play.currentRole == Role.Chaos) {
      appendix = "➤ ${translate("requests.chaosToPlace")}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lastMoveHint != null)
          lastMoveHint,
        if (!gameEngine.play.isFullAutomaticPlay)
          _replaceWithChipIcon(null, appendix,
              MainAxisAlignment.center, gameEngine.play.currentChip)
      ],
    );
    
  }


  Widget _buildAiProcessingText() {
    if (gameEngine.play.currentRole == Role.Order) {
      return Text(translate("gameStates.waitingForPlayerToMove",
          args: {"name": gameEngine.play.currentRole.name}));
    }
    else {
      return _replaceWithChipIcon(null,
          translate("gameStates.waitingForPlayerToPlace",
              args: {
                "name": gameEngine.play.currentRole.name,
              }),
          MainAxisAlignment.center, gameEngine.play.currentChip);
    }
  }

  void _showGameOver(BuildContext context) {
    if (gameEngine.play.isBothSidesSinglePlay || gameEngine.play.isFullAutomaticPlay) {
      toastInfo(context, _buildWinnerOrLooserText());
    }
    else if (gameEngine.play.getWinnerPlayer() == PlayerType.LocalUser) {
      toastWon(context, _buildWinnerOrLooserText());
    }
    else {
      toastLost(context, _buildLooserText());
    }

  }

  Widget _buildRoleIndicator(Role role, PlayerType player, bool isLeftElseRight) {
    final isSelected = gameEngine.play.currentRole == role;
    final color = gameEngine.play.isGameOver()
        ? gameEngine.play.getWinnerRole() == role
          ? Colors.black
          : Colors.black
        : isSelected
          ? Colors.white
          : null;

    final backgroundColor = gameEngine.play.isGameOver() == true
        ? gameEngine.play.getWinnerRole() == role
        ? Colors.lightGreenAccent
        : Colors.redAccent
        : isSelected
        ? DIALOG_BG
        : null;

    var tooltipKey = role == Role.Chaos
        ? _chaosChipTooltip
        : _orderChipTooltip;
    final tooltipPrefix =
      gameEngine.play.isGameOver()
        ? gameEngine.play.getWinnerRole() == role
            ? translate("common.winner")
            : translate("common.looser")
        : isSelected
            ? translate("gameHeader.currentPlayer")
            : translate("gameHeader.waitingPlayer");

    final secondLine = (role == Role.Chaos && gameEngine.play.header.playMode != PlayMode.Classic)
        ? "\n${translate("gameHeader.chaosChipCount", args: {"count" : gameEngine.play.getChaosPointsPerChip()})}"
        : "";

    return SuperTooltip(
      controller: Tooltips().controlTooltip(tooltipKey),
      onShow: () => Tooltips().hideTooltipLater(tooltipKey),
      showBarrier: false,
      hideTooltipOnTap: true,
      content: Text(
        "$tooltipPrefix: ${player.getName()}$secondLine",
        softWrap: true,

        style: TextStyle(
          color: Colors.black,
        ),
      ),
      child: GestureDetector(
        onLongPressStart: (details) {
          setState(() {
            _emphasiseAllChipsOfRole = role;
          });
        },
        onLongPressEnd: (details) => {
          setState(() {
            _emphasiseAllChipsOfRole = null;
          })
        },
        child: buildRoleIndicator(role,
            playerType: player,
            gameEngine: gameEngine,
            isSelected: isSelected,
            color: color,
            backgroundColor: backgroundColor
        ),
      ),
    );
  }

  Widget _buildBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % gameEngine.play.matrix.dimension.x);
    y = (index / gameEngine.play.matrix.dimension.y).floor();
    final where = Coordinate(x, y);
    return GestureDetector(
      onTap: () {
        _gridItemTapped(context, where);
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(80), width: 0.5)),
          child: Center(
            child: _wrapLastMove(_buildGridItem(where), where),
          ),
        ),
      ),
    );
  }


  Widget _buildReadOnlyBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % gameEngine.play.matrix.dimension.x);
    y = (index / gameEngine.play.matrix.dimension.y).floor();
    final where = Coordinate(x, y);
    final chip = gameEngine.play.classicModeFirstMatrix!.getChip(where);
    final points = gameEngine.play.classicModeFirstMatrix!.getPoints(where);
    return GestureDetector(
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(80), width: 0.5)),
          child: Center(
            child: buildGameChip(
              points > 0 && PreferenceService().showPoints ? points.toString() : "",
              chipColor: chip != null ? _getChipColor(chip, where): null,
              dimension: gameEngine.play.dimension,
              showCoordinates: PreferenceService().showCoordinates,
              where: where,
            )
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(Coordinate where) {

    final spot = gameEngine.play.matrix.getSpot(where);
    final chip = spot.content;
    var pointText = spot.orderPoints > 0 && PreferenceService().showPoints ? spot.orderPoints.toString() : "";

    if (_emphasiseAllChipsOfRole == Role.Chaos) {
      if (chip != null && spot.orderPoints == 0 && gameEngine.play.header.playMode != PlayMode.Classic) {
        pointText = gameEngine.play.getChaosPointsPerChip().toString();
      }
      else {
        pointText = "";
      }
    }
    else if (_emphasiseAllChipsOfRole == Role.Order) {
      pointText = spot.orderPoints > 0 ? spot.orderPoints.toString() : "";
    }


    if (gameEngine.play.selectionCursor.end == where) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (gameEngine.play.selectionCursor.start == where) {
      return DottedBorder(
        options: RectDottedBorderOptions(
          dashPattern: const [2,4]),
        child: _buildChip(chip, pointText, where),
      );
    }
    return _buildChip(chip, pointText, where);

  }

  Widget _buildChip(GameChip? chip, String text, [Coordinate? where]) {

    bool possibleTarget = false;
    Spot? startSpot;
    if (gameEngine.play.currentRole == Role.Order && where != null) {
      var selectionCursor = gameEngine.play.selectionCursor;
      possibleTarget = selectionCursor.hasStart && selectionCursor.trace.contains(where);

      if (selectionCursor.hasEnd) {
        startSpot = gameEngine.play.matrix.getSpot(selectionCursor.end!);
      }
      else if (selectionCursor.hasStart) {
        startSpot = gameEngine.play.matrix.getSpot(selectionCursor.start!);
      }
    }


    // show trace of opponent move
    var opponentCursor = gameEngine.play.opponentCursor;
    if (startSpot == null && opponentCursor.hasEnd && where != null) {
      startSpot ??= gameEngine.play.matrix.getSpot(opponentCursor.end!);
      possibleTarget |= opponentCursor.trace.contains(where);
    }

    var shadedColor = startSpot?.content?.color.withOpacity(0.2);

    return buildGameChip(text,
      chipColor: chip != null ? _getChipColor(chip, where): null,
      backgroundColor: possibleTarget ? shadedColor : null,
      dimension: gameEngine.play.dimension,
      showCoordinates: PreferenceService().showCoordinates,
      where: where,
      onLongPressStart: (details) {
        setState(() {
          _emphasiseAllChipsOf = chip;
        });
      },
      onLongPressEnd: (details) => {
        setState(() {
          _emphasiseAllChipsOf = null;
        })
      },
    );
  }

  Color _getChipColor(GameChip chip, Coordinate? considerPointsAt) {
    Role? roleAtPos = null;
    if (_emphasiseAllChipsOfRole != null && considerPointsAt != null) {
      final points = gameEngine.play.matrix.getPoints(considerPointsAt);
      roleAtPos = points == 0 ? Role.Chaos : Role.Order;
    }
    return ((_emphasiseAllChipsOf != null && _emphasiseAllChipsOf != chip) 
        || (roleAtPos != null && _emphasiseAllChipsOfRole != roleAtPos))
        ? chip.color.withOpacity(0.2)
        : chip.color;
  }
  
 
  Future<void> _gridItemTapped(BuildContext context, Coordinate where) async {

    if (gameEngine.isBoardLocked()) {
      return;
    }

    setState(() {
      if (gameEngine.play.currentRole == Role.Chaos) {
        if (gameEngine.play.matrix.isFree(where)) {
          _handleFreeFieldForChaos(context, where);
        }
        else {
          _handleOccupiedFieldForChaos(where, context);
        }
      }
      if (gameEngine.play.currentRole == Role.Order) {
        if (gameEngine.play.matrix.isFree(where)) {
          _handleFreeFieldForOrder(context, where);
        }
        else {
          _handleOccupiedFieldForOrder(where, context);
        }
      }
    });
  }

  void _handleFreeFieldForChaos(BuildContext context, Coordinate coordinate) {
    final cursor = gameEngine.play.selectionCursor;
    if (cursor.end != null && !gameEngine.play.matrix.isFree(cursor.end!)) {
      toastInfo(context, "You have already placed a chip");
    }
    else {
      final currentChip = gameEngine.play.currentChip!;
      if (!gameEngine.play.stock.hasStock(currentChip)) {
        toastInfo(context, "No more stock for current chip");
      }
      gameEngine.play.applyStaleMove(Move.placed(currentChip, coordinate));
      gameEngine.play.selectionCursor.updateEnd(coordinate);
    }
  }

  void _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = gameEngine.play.selectionCursor;
    if (cursor.end != coordinate) {
      toastInfo(context, "You can only remove the current placed chip");
    }
    else {
      gameEngine.play.undoStaleMove();
      gameEngine.play.selectionCursor.clear();
    }
  }

  void _handleFreeFieldForOrder(BuildContext context, Coordinate coordinate) {
    final selectionCursor = gameEngine.play.selectionCursor;
    if (!selectionCursor.hasStart) {
      toastInfo(context, "Please select the chip to move first");
    }
    else if (/*!cursor.hasEnd && */selectionCursor.start == coordinate) {
      // clear start cursor if not target is selected
      gameEngine.play.undoStaleMove();
      selectionCursor.clear();
    }
    else if (!selectionCursor.trace.contains(coordinate) && selectionCursor.start != coordinate) {
      toastInfo(context, "Chip can only move horizontally or vertically through free cells");
    }
    else if (selectionCursor.hasStart) {
      if (selectionCursor.hasEnd) {
        final from = gameEngine.play.matrix.getSpot(selectionCursor.end!);
        // this is a correction move, so undo last move and apply again below
        gameEngine.play.undoStaleMove();
        gameEngine.play.applyStaleMove(Move.moved(from.content!, selectionCursor.start!, coordinate));
      }
      else {
        final from = gameEngine.play.matrix.getSpot(selectionCursor.start!);
        gameEngine.play.applyStaleMove(Move.moved(from.content!, selectionCursor.start!, coordinate));
      }

      if (selectionCursor.start == coordinate) {
        // move back to start is like a reset
        selectionCursor.clear();
      }
      else {
        selectionCursor.updateEnd(coordinate);
      }

    }
  }

  void _handleOccupiedFieldForOrder(Coordinate coordinate, BuildContext context) {
    final selectionCursor = gameEngine.play.selectionCursor;
    if (selectionCursor.start != null && selectionCursor.start != coordinate && selectionCursor.end != null) {
      toastInfo(context,
          "You can not move the selected chip on another one");

    }
    else if (selectionCursor.start == coordinate) {
      selectionCursor.clear();
    }
    else {
      selectionCursor.updateStart(coordinate);
      selectionCursor.detectTraceForPossibleOrderMoves(coordinate, gameEngine.play.matrix);
    }
  }

  Widget _buildChipStock(BuildContext context, int index) {
    final stockEntries = gameEngine.play.stock.getStockEntries();
    if (stockEntries.length <= index) {
      return const Text("?");
    }
    final entry = stockEntries.toList()[index];
    final isCurrent = gameEngine.play.currentChip == entry.chip;
    final chipText = isCurrent
        ? (gameEngine.play.currentRole == Role.Chaos
        ? translate("gameHeader.drawnChip")
        : translate("gameHeader.recentlyPlacedChip"))
        : translate("gameHeader.chip") ;
    final text = gameEngine.play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";
    final tooltipKey = "$_stockChipToolTipKey-$index";
    return SuperTooltip(
        controller: Tooltips().controlTooltip(tooltipKey),
        onShow: () => Tooltips().hideTooltipLater(tooltipKey),
        showBarrier: false,
        hideTooltipOnTap: true,
        content: Text(
          "$chipText ${entry.chip.getChipName()}\n${entry.amount} ${translate("common.left")}",
          softWrap: true,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        child: _buildChipStockItem(entry, text));
  }

  Widget _buildChipStockIndicator(BuildContext context, int index) {
    final stockEntries = gameEngine.play.stock.getStockEntries();
    final entry = stockEntries.toList()[index];
    if (gameEngine.play.currentChip == entry.chip) {
      return const Align(
          alignment: Alignment.topCenter,
          child: Text("▲", style: TextStyle(fontSize: 16),));
    }
    else {
      return Container();
    }
  }

  Padding _buildChipStockItem(StockEntry entry, String text) {
    if (gameEngine.play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(gameEngine.play.dimension > 5 ? gameEngine.play.dimension > 7 ? 0 : 2 : 4),
        child: Container(
            decoration: BoxDecoration(
              color: _getChipColor(entry.chip, null),
              border: Border.all(width: 1),
              borderRadius: const BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            child: _buildChip(entry.chip, text)
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.all(gameEngine.play.dimension > 5 ? gameEngine.play.dimension > 7 ? 0 : 4 : 8),
      child: _buildChip(entry.chip, text),
    );
  }

  Widget _wrapLastMove(Widget widget, Coordinate where) {
    if (gameEngine.play.opponentCursor.hasStart && gameEngine.play.opponentCursor.start == where) {
      return DottedBorder(
          options: CircularDottedBorderOptions(
            padding: EdgeInsets.zero,
            strokeWidth: 1,
            strokeCap: StrokeCap.butt,
            color: Colors.grey
          ),
          child: widget);
    }
    else if (gameEngine.play.opponentCursor.hasEnd && gameEngine.play.opponentCursor.end == where) {
      return DottedBorder(
          options: CircularDottedBorderOptions(
            padding: EdgeInsets.zero,
            strokeWidth: 3,
            strokeCap: StrokeCap.butt,
            color: Colors.grey
          ),
          child: widget);
    }
    return widget;
  }

  void _showGameDetails(Play play) {
    SmartDialog.show(builder: (_) {
      List<Widget> children = [
        const Text(
          "Match Info",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          play.header.getReadablePlayId(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const Divider(),
        _buildGameInfoRow("Mode:", play.header.playMode.getName()),
        if (play.header.playMode == PlayMode.Classic)
          _buildGameInfoRow("Game in match:", play.header.rolesSwapped == true ? "Second game" : "First game"),
        _buildGameInfoRow("Game Size:", "${play.header.playSize.dimension} x ${play.header.playSize.dimension}"),
        _buildGameInfoRow("Game opener:", "${play.header.getLocalRoleForMultiPlay() == Role.Chaos ? "You": "Opponent"}"),
        if (play.header.playMode == PlayMode.HyleX)
          _buildGameInfoRow("Points per unordered chip:", play.getChaosPointsPerChip().toString()),

        if (play.header.opponentName != null && play.header.opponentId != null)
          const Divider(),

        if (play.header.opponentName != null)
          _buildGameInfoRow("Opponent:", play.header.opponentName!),
        if (play.header.opponentId != null)
          _buildGameInfoRow("Opponent Id:", toReadableId(play.header.opponentId!)),


        const Divider(),


        _buildGameInfoRow("Match started at:", format(play.startDate)),
        if (play.header.lastTimestamp != null)
          _buildGameInfoRow("Last activity at:", format(play.header.lastTimestamp!)),
        if (play.endDate != null)
          _buildGameInfoRow("Match finished at:", format(play.endDate!)),
        if (play.endDate == null && !play.header.state.isFinal)
          _buildGameInfoRow("Match finished at:", "still ongoing"),
        if (play.header.state.toMessage().length > 20)
          _buildGameInfoWrap("Match status:", play.header.state.toMessage())
        else
          _buildGameInfoRow("Match status:", play.header.state.toMessage()),

      ];


      return Container(
        height: 500,
        width: 330,
        decoration: BoxDecoration(
          color: DIALOG_BG,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          ),
        ),
      );
    });
  }

  Widget _buildGameInfoRow(String key, String value) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      );
  }


  Widget _buildGameInfoWrap(String key, String value) {
    return Wrap(
      children: [
        Text(key + "  ",
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  void _showFirstGameOfClassicMode(Matrix matrix, Role localRole, int orderPoints) {
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      isScrollControlled: true,

      builder: (BuildContext context) {

        return StatefulBuilder(
          builder: (BuildContext context, setSheetState) {

            final chaosPlayerType = localRole == Role.Chaos ? PlayerType.LocalUser : PlayerType.RemoteUser;
            final orderPlayerType = localRole == Role.Chaos ? PlayerType.RemoteUser : PlayerType.LocalUser;
            return Container(
              height: MediaQuery.sizeOf(context).height / 1.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(children: [
                      Text("Final state of the first game"),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        buildRoleIndicator(Role.Chaos, playerType: chaosPlayerType, isSelected: false, backgroundColor: Colors.white),
                        buildRoleIndicator(Role.Order, playerType: orderPlayerType, isSelected: false, backgroundColor: Colors.white, points: orderPoints),
                      ],),
                      AspectRatio(aspectRatio: 1, child: _buildChipGrid(_buildReadOnlyBoardGrid))
                    ]),
                  ),
                ),
              ),
            );
          },
        );


      },
    );
  }

}

