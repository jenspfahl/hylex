
import 'dart:async';
import 'dart:collection';

import 'package:app_links/app_links.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hyle_x/model/achievements.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../engine/game_engine.dart';
import '../model/chip.dart';
import '../model/chip_extension.dart';
import '../model/coordinate.dart';
import '../model/move.dart';
import '../model/play.dart';
import '../model/spot.dart';
import '../model/stock.dart';
import '../utils.dart';
import 'Tooltips.dart';
import 'dialogs.dart';

enum PlayerType {User, Ai, RemoteUser}

class HyleXGround extends StatefulWidget {
  User user;
  Play play;

  HyleXGround(this.user, this.play, {super.key});

  @override
  State<HyleXGround> createState() => _HyleXGroundState();

}

class _HyleXGroundState extends State<HyleXGround> {

  late GameEngine gameEngine;

  GameChip? _emphasiseAllChipsOf;
  bool _lastUndoMoveHighlighted = false;
  
  late BuildContext _builderContext;
  late StreamSubscription<FGBGType> fgbgSubscription;
  late StreamSubscription<Uri> _uriLinkStreamSub;

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
          widget.user);
    }
    else {
      gameEngine = SinglePlayerGameEngine(
          widget.play,
          widget.user);
    }

    fgbgSubscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.background) {
        gameEngine.savePlayState();
      }
    });

    gameEngine.addListener(_gameListener);

    gameEngine.startGame();

    _uriLinkStreamSub = AppLinks().uriLinkStream.listen((uri) {
      gameEngine.opponentMoveReceived(Move.skipped());

    });
  }

  _gameListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HyleX',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _buildGameBody(),
    );
  }

  @override
  void dispose() {
    _uriLinkStreamSub.cancel();
    gameEngine.pauseGame();
    gameEngine.removeListener(_gameListener);
    fgbgSubscription.cancel();

    super.dispose();
  }

  Widget _buildGameBody() {
    return Builder(
        builder: (context) {
          _builderContext = context;
          return Scaffold(
              appBar: AppBar(
                title: Text('HyleX ${gameEngine.play.getReadablePlayId()}'),
                actions: [
                  IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
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
                                height: 250, // Set your desired height
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
                      icon: const Icon(Icons.history)),
                  Visibility(
                    visible: _isUndoAllowed(),
                    child: IconButton(
                      icon: const Icon(Icons.undo_outlined),
                      onPressed: () {
                        if (!_isUndoAllowed()) {
                          toastError(context, "Undo not possible here");
                          return;
                        }

                        setState(() {
                          if (gameEngine.play.hasStaleMove) {
                            gameEngine.play.undoStaleMove();
                            gameEngine.play.selectionCursor.clear();
                            gameEngine.savePlayState();
                          }
                          else {

                            final recentRole = gameEngine.play.opponentRole.name;
                            ask('Undo $recentRole\'s last move?', () {
                                var lastMove = gameEngine.play.previousRound();
                                if (gameEngine.play.currentPlayer == PlayerType.Ai) {
                                  // undo AI move also
                                  lastMove = gameEngine.play.previousRound();
                                }

                                if (lastMove != null) {
                                  gameEngine.play.selectionCursor.adaptFromMove(lastMove);
                                  _lastUndoMoveHighlighted = true;
                                  final moveBefore = gameEngine.play.lastMoveFromJournal;
                                  if (moveBefore != null) {
                                    gameEngine.play.opponentCursor.adaptFromMove(moveBefore);
                                  }

                                  gameEngine.savePlayState();
                                }
                                else {
                                  // beginning of game
                                  gameEngine.startGame();
                                }
                              });
                          }
                        });

                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt_outlined),
                    onPressed: () => {

                      ask('Restart game?', () {
                            gameEngine.stopGame();
                            gameEngine.startGame();
                      })
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () => {

                      ask('Leave current game?', () {
                            gameEngine.pauseGame();
                            Navigator.pop(super.context); // go to start page
                          })
                    },
                  )
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
                                Text("Round ${gameEngine.play.currentRound} of ${gameEngine.play.maxRounds}"),
                                _buildRoleIndicator(Role.Order, gameEngine.play.orderPlayer, false),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(value: gameEngine.play.progress,),
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
                                left: 0, top: 0, right: 0, bottom: 10),
                            child: _buildSubmitButton(context),
                          ),
                        ]),
                  ),
                ),
              ));
        }
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
    Widget row;
    if (eventLineString.contains("{chip}")) {
      final split = eventLineString.split("{chip}");
      final first = split[0];
      final second = split[1];

      row = Row(
        mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
        children: [
          if (prefix != null)
            Text(prefix),
          Text(first),
          Text(move.chip!.getChipName()),
          const Text(" "),
          CircleAvatar(
              backgroundColor: _getChipBackgroundColor(move.chip!),
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
          Text(eventLineString),
        ],
      );
    }

    return row;
  }



  bool _isUndoAllowed() => !gameEngine.isBoardLocked() && !gameEngine.play.isGameOver() && !gameEngine.play.isFullAutomaticPlay && !gameEngine.play.isMultiplayerPlay && !gameEngine.play.isJournalEmpty;


  Widget _buildHint(BuildContext context) {
    if (gameEngine.play.isGameOver()) {
      return Text(_buildWinnerText());
    }
    else if (gameEngine.play.currentPlayer == PlayerType.Ai) {
      return _buildAiProgressText();
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return Text("Waiting for remote opponent (${gameEngine.play.currentRole.name}) to move..."); //TODO add link to share again
    }
    else {
      return _buildDoneText();
    }
  }

  String _buildWinnerText() {
    final winner = gameEngine.play.stats.getWinner();
    final winnerPlayer = gameEngine.play.getWinnerPlayer();
    var winnerPlayerName = winnerPlayer == PlayerType.User
        ? "You"
        : winnerPlayer == PlayerType.Ai
          ? "Computer"
          : "Remote opponent";
    return "Game over! ${winner.name} (${winnerPlayerName}) wins!";
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
      return FilledButton(
        onPressed: () {
          gameEngine.stopGame();
          gameEngine.startGame();
        },
        child: const Text("Restart"),
      );
    }
    else if (gameEngine.play.currentPlayer == PlayerType.User) {
      final isDirty = gameEngine.play.hasStaleMove;
      return FilledButton(
        onPressed: () {
          if (gameEngine.isBoardLocked()) {
            return;
          }
          if (gameEngine.play.isGameOver()) {
            return;
          }
          if (gameEngine.play.currentRole == Role.Chaos && !gameEngine.play.hasStaleMove) {
            toastInfo(context, "Chaos has to place one chip!");
            return;
          }

          if (!gameEngine.play.hasStaleMove && gameEngine.play.currentRole == Role.Order) {
            gameEngine.play.applyStaleMove(Move.skipped());
          }
          gameEngine.play.commitMove();
          gameEngine.nextPlayer();
          if (gameEngine.play.isGameOver()) {
            _showGameOver(context);
          }
        },
        child: Text(gameEngine.play.currentRole == Role.Order && !gameEngine.play.selectionCursor.hasEnd
            ? 'Skip move'
            : 'Submit move',
        style: TextStyle(fontWeight: isDirty ? FontWeight.bold : null)),
      );
    }
    else if (gameEngine.play.currentPlayer == PlayerType.RemoteUser) {
      return OutlinedButton(
        onPressed: () {
          if (gameEngine is MultiPlayerGameEngine) {
            (gameEngine as MultiPlayerGameEngine).shareGameMove();
          }
        },
        child: const Text("Share again"),
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
      appendix = "Now it's on Order to move a chip or skip!";
    }
    else {
      appendix = "Now it's on Chaos to place a chip!";
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lastMoveHint != null)
          lastMoveHint,
        if (!gameEngine.play.isFullAutomaticPlay)
          Text(appendix)
      ],
    );
    
  }


  Text _buildAiProcessingText() {
    if (gameEngine.play.currentRole == Role.Order) {
      return Text("Waiting for ${gameEngine.play.currentRole.name} to move ...");
    }
    else {
      return Text("Waiting for ${gameEngine.play.currentRole.name} to place ...");
    }
  }

  void _showGameOver(BuildContext? context) {
    setState(() {
      toastError(context ?? _builderContext, _buildWinnerText());
    });
  }

  Widget _buildRoleIndicator(Role role, PlayerType player, bool isLeftElseRight) {
    final isSelected = gameEngine.play.currentRole == role;
    final color = isSelected ? Colors.white : null;
    final icon = player == PlayerType.Ai ? MdiIcons.brain : player == PlayerType.RemoteUser ? Icons.record_voice_over : MdiIcons.account;
    var tooltipKey = role == Role.Chaos
        ? _chaosChipTooltip
        : _orderChipTooltip;
    final tooltipPrefix = isSelected ? "Current player" : "Waiting player";
    final tooltipPostfix = player == PlayerType.User ?  "You" : player == PlayerType.Ai ? "Computer" : "Remote opponent";
    final secondLine = role == Role.Chaos ? "\nUnordered chip counts ${gameEngine.play.getPointsPerChip()}": "";
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
      child: Chip(
          padding: EdgeInsets.zero,
          shape: isLeftElseRight
              ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20),bottomRight: Radius.circular(20)))
              : const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20))),
          label: isLeftElseRight
              ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 16),
                  const Text(" "),
                  Text("${role.name} - ${gameEngine.play.stats.getPoints(role)}", style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : null)),
                ],
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(" ${gameEngine.play.stats.getPoints(role)} - ${role.name}", style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : null)),
                  const Text(" "),
                  Icon(icon, color: color, size: 16),
                ],
              ),
          backgroundColor: isSelected ? Colors.black : null
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
    final pointText = spot.point > 0 ? spot.point.toString() : "";

    if (gameEngine.play.selectionCursor.end == where) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (gameEngine.play.selectionCursor.start == where) {
      return DottedBorder(
        dashPattern: const [2,4],
        child: _buildChip(chip, pointText, where),
      );
    }
    return _buildChip(chip, pointText, where);

  }

  Widget _buildChip(GameChip? chip, String text, [Coordinate? where]) {

    bool possibleTarget = false;
    Spot? startSpot;
    if (gameEngine.play.currentRole == Role.Order && where != null) {
      possibleTarget = gameEngine.play.selectionCursor.hasStart && gameEngine.play.selectionCursor.trace.contains(where);

      if (gameEngine.play.selectionCursor.hasEnd) {
        startSpot = gameEngine.play.matrix.getSpot(gameEngine.play.selectionCursor.end!);
      }
      else if (gameEngine.play.selectionCursor.hasStart) {
        startSpot = gameEngine.play.matrix.getSpot(gameEngine.play.selectionCursor.start!);
      }
    }


      // show trace of opponent move
    if (startSpot == null && gameEngine.play.opponentCursor.hasEnd && where != null) {
      startSpot ??= gameEngine.play.matrix.getSpot(gameEngine.play.opponentCursor.end!);
      possibleTarget |= gameEngine.play.opponentCursor.end! == where;
      if (gameEngine.play.opponentCursor.hasStart) {
        if (gameEngine.play.opponentCursor.isHorizontalMove()) {
          possibleTarget |= gameEngine.play.opponentCursor.end!.y == where.y &&
              (gameEngine.play.opponentCursor.start!.x <= where.x  && gameEngine.play.opponentCursor.end!.x >= where.x ||
                  gameEngine.play.opponentCursor.end!.x <= where.x  && gameEngine.play.opponentCursor.start!.x >= where.x);
        }
        else if (gameEngine.play.opponentCursor.isVerticalMove()) {
          possibleTarget |= gameEngine.play.opponentCursor.end!.x == where.x &&
              (gameEngine.play.opponentCursor.start!.y <= where.y  && gameEngine.play.opponentCursor.end!.y >= where.y ||
                  gameEngine.play.opponentCursor.end!.y <= where.y  && gameEngine.play.opponentCursor.start!.y >= where.y);
        }
      }
    }

    var shadedColor = startSpot?.content?.color.withOpacity(0.2);


    if (chip == null) {

      return Container(
        color: possibleTarget ? shadedColor : null,
        child: where != null && text.isEmpty
            ? Center(child: Text(_getPositionText(where, gameEngine.play.matrix.dimension),
                style: TextStyle(
                    fontSize: gameEngine.play.dimension > 9 ? 10 : null,
                    color: Colors.grey[400])))
            : null,
      );
    }
    return Container(
      color: possibleTarget ? shadedColor : null,
      child: GestureDetector(
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
        child: CircleAvatar(
          backgroundColor: _getChipBackgroundColor(chip),
          maxRadius: 60,
          child: Text(text,
              style: TextStyle(
                fontSize: gameEngine.play.dimension > 7 ? 12 : 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
        ),
      ),
    );
  }

  Color _getChipBackgroundColor(GameChip chip) {
    return _emphasiseAllChipsOf != null && _emphasiseAllChipsOf != chip
        ? chip.color.withOpacity(0.2)
        : chip.color;
  }

  Future<void> _gridItemTapped(BuildContext context, Coordinate where) async {

    if (gameEngine.isBoardLocked()) {
      return;
    }

    setState(() {
      if (_lastUndoMoveHighlighted) {
        gameEngine.play.selectionCursor.clear();
      }
      
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
      //game.play.matrix.put(coordinate, currentChip, game.play.stock);
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
    final cursor = gameEngine.play.selectionCursor;
    if (!cursor.hasStart) {
      toastInfo(context, "Please select a chip to move first");
    }
    else if (/*!cursor.hasEnd && */cursor.start == coordinate) {
      // clear start cursor if not target is selected
      gameEngine.play.undoStaleMove();
      cursor.clear();
    }
    else if (!cursor.trace.contains(coordinate) && cursor.start != coordinate) {
      toastInfo(context, "Chip can only move horizontally or vertically in free space");
    }
    else if (cursor.hasStart) {
      if (cursor.hasEnd) {
        final from = gameEngine.play.matrix.getSpot(cursor.end!);
        // this is a correction move, so undo last move and apply again below
        gameEngine.play.undoStaleMove();
        gameEngine.play.applyStaleMove(Move.moved(from.content!, cursor.start!, coordinate));
      }
      else {
        final from = gameEngine.play.matrix.getSpot(cursor.start!);
        gameEngine.play.applyStaleMove(Move.moved(from.content!, cursor.start!, coordinate));
      }

      if (cursor.start == coordinate) {
        // move back to start is like a reset
        cursor.clear();
      }
      else {
        cursor.updateEnd(coordinate);
      }

    }
  }

  void _handleOccupiedFieldForOrder(Coordinate coordinate, BuildContext context) {
    final cursor = gameEngine.play.selectionCursor;
    if (cursor.start != null && cursor.start != coordinate && cursor.end != null) {
      toastInfo(context,
          "You can not move the selected chip on another one");

    }
    else if (cursor.start == coordinate) {
      cursor.clear();
    }
    else {
      cursor.updateStart(coordinate);
      cursor.detectTraceForOrderMove(coordinate, gameEngine.play.matrix);
    }
  }

  Widget _buildChipStock(BuildContext context, int index) {
    final stockEntries = gameEngine.play.stock.getStockEntries();
    if (stockEntries.length <= index) {
      return const Text("?");
    }
    final entry = stockEntries.toList()[index];
    final text = gameEngine.play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";
    final tooltipKey = "$_stockChipToolTipKey-$index";
    return SuperTooltip(
        controller: Tooltips().controlTooltip(tooltipKey),
        onShow: () => Tooltips().hideTooltipLater(tooltipKey),
        showBarrier: false,
        hideTooltipOnTap: true,
        content: Text(
          "Chip ${entry.chip.getChipName()}",
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
              color: _getChipBackgroundColor(entry.chip),
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
          padding: EdgeInsets.zero,
          strokeWidth: 1,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    else if (gameEngine.play.opponentCursor.hasEnd && gameEngine.play.opponentCursor.end == where) {
      return DottedBorder(
          padding: EdgeInsets.zero,
          strokeWidth: 3,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    return widget;
  }

  String _getPositionText(Coordinate where, Coordinate dimension) {
    if (where.x == 0 && where.y == 0 ||
        where.x == 0 && where.y == dimension.y-1 ||
        where.x == dimension.x-1 && where.y == 0 ||
        where.x == dimension.x-1 && where.y == dimension.y-1) {
      return where.toReadableCoordinates();
    }
    else if (where.x > 0 && where.y == 0 || where.x > 0 && where.y == dimension.y-1) {
      return String.fromCharCode('A'.codeUnitAt(0) + where.x);
    }
    else if (where.y > 0 && where.x == 0 || where.y > 0 && where.x == dimension.x-1) {
      return (where.y + 1).toString();
    }
    else {
      return "";
    }
  }
}

