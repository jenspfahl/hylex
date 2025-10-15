
import 'dart:async';
import 'dart:collection';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/service/PreferenceService.dart';
import 'package:hyle_x/ui/pages/multi_player_matches.dart';
import 'package:hyle_x/ui/pages/start_page.dart';
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

  HyleXGround(this.user, this.play, {super.key, this.opponentMoveToApply});

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
                  title: Text(
                    gameEngine.play.isMultiplayerPlay
                        ? gameEngine.play.header.getTitle()
                        : gameEngine.play.isFullAutomaticPlay
                          ? "Automatic Play"
                          : gameEngine.play.isBothSidesSinglePlay
                            ? "Alternate Single Play"
                            : "Single Play against AI",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
                              var message = 'Undo last move from $recentRole?';

                              if (gameEngine.play.isWithAiPlay && gameEngine.play.journal.length > 1) {
                                message = 'Undo last move from $recentRole? This will also undo the previous move from ${currentRole}.';
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

                                    elements.add(const Text("------ Game started ------"));
                                    if (gameEngine.play.isGameOver()) {
                                      elements.insert(0, const Text("------ Game over ------"));
                                    }
                                    return Container(
                                      height: 250,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 32, 8, 0),
                                        child: SingleChildScrollView(
                                          child: Center(
                                            child: Column(children: elements),
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

                          ask('Restart game?', () {
                                gameEngine.stopGame();
                                _gameOverShown = false;
                                gameEngine.startGame();
                          })
                        },
                      ),
                    ),
                    Visibility(
                      visible: gameEngine.play.isMultiplayerPlay && gameEngine.play.waitForOpponent,
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          globalStartPageKey.currentState?.scanNextMove();
                        },
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
                                    Text("Round ${gameEngine.play.currentRound} of ${gameEngine.play.maxRounds}"),
                                    if (gameEngine.play.header.rolesSwapped != null)
                                      Text (gameEngine.play.header.rolesSwapped! ? "Roles swapped" : "Classic Style", style: TextStyle(fontStyle: FontStyle.italic),),
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
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black, width: 2.0)),
                                child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gameEngine.play.dimension,
                                    ),
                                    itemBuilder: _buildBoardGrid,
                                    itemCount: gameEngine.play.dimension * gameEngine.play.dimension,
                                    physics: const NeverScrollableScrollPhysics()),
                              ),
                            ),
      
                            Padding(
                              padding: const EdgeInsets.all(10),
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

  Widget _buildJournalEvent((int, Move) e) {
    final move = e.$2;
    final round = ((e.$1+1)/2).ceil();
    Widget row = _buildMoveLine(move, prefix: "Round $round: ");

    return Column(
      children: [
        if (move.toRole() == Role.Order) Text("------------------------------------"),
        row,
      ]
    );
  }


  Widget _buildMoveLine(Move move, {String? prefix, MainAxisAlignment? mainAxisAlignment}) {
    var eventLineString = move.toReadableStringWithChipPlaceholder();
    return _replaceWithChipIcon(prefix, eventLineString, mainAxisAlignment, move.chip);
  }

  Widget _replaceWithChipIcon(String? prefix, String text, MainAxisAlignment? mainAxisAlignment, GameChip? chip) {
    Widget row;
    if (text.contains("{chip}") && chip != null) {
      final split = text.split("{chip}");
      final first = split[0];
      final second = split[1];
    
      row = Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        children: [
          if (prefix != null)
            Text(prefix),
          Text(first),
          Text(chip.getChipName()),
          const Text(" "),
          CircleAvatar(
              backgroundColor: _getChipColor(chip, null),
              maxRadius: 6,
          ),
          Text(second),
        ],
      );
    }
    else {
      row = Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
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
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return Text("Waiting for remote opponent (${gameEngine.play.currentRole.name}) to move...");
    }
    else {
      return _buildDoneText();
    }
  }

  String _buildWinnerOrLooserText() {
    final winnerRole = gameEngine.play.getWinnerRole();
    final winnerPlayer = gameEngine.play.getWinnerPlayer();

    if (gameEngine.play.isFullAutomaticPlay || gameEngine.play.isBothSidesSinglePlay) {
      return "Game over! ${winnerRole.name} won this game!";
    }
    else if (gameEngine.play.isWithAiPlay) {
      if (winnerPlayer == PlayerType.LocalUser) {
        return "Game over! You (${winnerRole.name}) won this game!";
      }
      else {
        return "Game over! You (${winnerRole.opponentRole.name}) lost this game!";
      }
    }
    else if (gameEngine.play.isMultiplayerPlay) {
      var localRole = gameEngine.play.header.getLocalRoleForMultiPlay();

      var cause = "";
      if (gameEngine.play.header.state == PlayState.Resigned) {
        cause = ", because you resigned";
      }
      else if (gameEngine.play.header.state == PlayState.OpponentResigned) {
        cause = ", because the opponent resigned";
      }

      if (winnerRole == localRole) {
        return "Game over! You (${localRole!.name}) won this game$cause!";
      }
      else {
        return "Game over! You (${localRole!.name}) lost this game$cause!";
      }
    }
    else {
      return "";
    }
    
  }

  String _buildLooserText() {
    final looserRole = gameEngine.play.getLooserRole();
    final looserPlayer = gameEngine.play.getLooserPlayer();
    var looserPlayerName = looserPlayer == PlayerType.LocalUser
        ? "You"
        : looserPlayer == PlayerType.LocalAi
          ? "Computer"
          : "Remote opponent";
    return "Game over! ${looserRole.name} (${looserPlayerName}) looses this game!";
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
                    "Ask for a rematch",
                        () {

                      if (gameEngine.play.header.successorPlayId != null) {
                        showChoiceDialog("You already asked for a rematch with ${toReadableId(gameEngine.play.header.successorPlayId!)}.",
                            firstString: 'Ask again',
                            firstHandler: () {
                              globalStartPageKey.currentState?.inviteRemoteOpponentForRevenge(
                                  context,
                                  gameEngine.play.header.playSize,
                                  gameEngine.play.header.playMode,
                                  predecessorPlay: gameEngine.play.header
                              );
                            },
                            secondString: 'Cancel',
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
                    "Share again",
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
            "Restart",
            () async {
            await gameEngine.stopGame();
            _gameOverShown = false;
            gameEngine.startGame();
          });
      }
    }
    else if (gameEngine.play.currentPlayer == PlayerType.LocalUser) {
      final isDirty = gameEngine.play.hasStaleMove;
      return buildFilledButton(
          context,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? Icons.redo
              : Icons.near_me,
          gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
              ? 'Skip move'
              : 'Submit move',
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
              ask('Do you really want to skip this move?', () async {
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
            "Share again",
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

    if (gameEngine.play.currentRole == Role.Order) {
      appendix = "➤ Now it's on Order to move a chip or skip!";
    }
    else {
      appendix = "➤ Now it's on Chaos to place next chip {chip} !";
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
      return Text("Waiting for ${gameEngine.play.currentRole.name} to move ...");
    }
    else {
      return _replaceWithChipIcon(null, "Waiting for ${gameEngine.play.currentRole.name} to place {chip} ...",
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

    final iconData = player == PlayerType.LocalAi ? MdiIcons.brain : player == PlayerType.RemoteUser ? Icons.transcribe : MdiIcons.account;
    final icon = Transform.flip(
        flipX: player == PlayerType.RemoteUser,
        child: Icon(iconData, color: color, size: 16));

    var tooltipKey = role == Role.Chaos
        ? _chaosChipTooltip
        : _orderChipTooltip;
    final tooltipPrefix =
      gameEngine.play.isGameOver()
        ? gameEngine.play.getWinnerRole() == role
            ? "Winner"
            : "Looser"
        : isSelected
            ? "Current player"
            : "Waiting player";
    final tooltipPostfix = player == PlayerType.LocalUser ?  "You" : player == PlayerType.LocalAi ? "Computer" : "Remote opponent";

    final secondLine = (role == Role.Chaos && gameEngine.play.header.playMode != PlayMode.Classic)
        ? "\nOne unordered chip counts ${gameEngine.play.getPointsPerChip()}"
        : "";

    return SuperTooltip(
      controller: Tooltips().controlTooltip(tooltipKey),
      onShow: () => Tooltips().hideTooltipLater(tooltipKey),
      showBarrier: false,
      hideTooltipOnTap: true,
      content: Text(
        "$tooltipPrefix: $tooltipPostfix$secondLine",
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

  Widget _buildGridItem(Coordinate where) {

    final spot = gameEngine.play.matrix.getSpot(where);
    final chip = spot.content;
    var pointText = spot.points > 0 ? spot.points.toString() : "";

    if (_emphasiseAllChipsOfRole == Role.Chaos) {
      if (chip != null && spot.points == 0 && gameEngine.play.header.playMode != PlayMode.Classic) {
        pointText = gameEngine.play.getPointsPerChip().toString();
      }
      else {
        pointText = "";
      }
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
        ? (gameEngine.play.currentRole == Role.Chaos ? "Drawn chip" : "Recently placed chip")
        : "Chip";
    final text = gameEngine.play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";
    final tooltipKey = "$_stockChipToolTipKey-$index";
    return SuperTooltip(
        controller: Tooltips().controlTooltip(tooltipKey),
        onShow: () => Tooltips().hideTooltipLater(tooltipKey),
        showBarrier: false,
        hideTooltipOnTap: true,
        content: Text(
          "$chipText ${entry.chip.getChipName()}\n${entry.amount} left",
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

}

