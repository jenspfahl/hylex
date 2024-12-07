
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:hyle_x/model/achievements.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../model/ai/strategy.dart';
import '../model/chip.dart';
import '../model/matrix.dart';
import '../model/play.dart';
import '../model/spot.dart';
import '../service/PreferenceService.dart';
import '../utils.dart';
import 'dialogs.dart';

enum Player {User, Ai, RemoteUser}

class HyleXGround extends StatefulWidget {
  User user;
  Player chaosPlayer;
  Player orderPlayer;
  int dimension;
  Play? loadedPlay;


  HyleXGround(this.user, this.chaosPlayer, this.orderPlayer, this.dimension, {super.key});

  HyleXGround.load(this.user, Play play, {super.key}) : chaosPlayer = play.chaosPlayer, orderPlayer = play.orderPlayer, dimension = play.dimension, loadedPlay = play;

  @override
  State<HyleXGround> createState() => _HyleXGroundState();

}

class _HyleXGroundState extends State<HyleXGround> {

  late Game game;

  GameChip? _emphasiseAllChipsOf;

  late BuildContext _builderContext;
  late StreamSubscription<FGBGType> fgbgSubscription;

  final _chaosChipTooltipController = SuperTooltipController();
  final _orderChipTooltipController = SuperTooltipController();

  @override
  void initState() {
    super.initState();

    SmartDialog.dismiss(); // dismiss loading dialog


    if (widget.loadedPlay != null) {
      game = Game(widget.loadedPlay!, widget.user);
      debugPrint("Game restored from saved play state");
    }
    else {
      game = Game(Play(widget.dimension, widget.chaosPlayer, widget.orderPlayer), widget.user);
      debugPrint("New game created");

    }

    fgbgSubscription = FGBGEvents.instance.stream.listen((event) {
      if (event == FGBGType.background) {
        game.savePlay();
      }
    });

    game.addListener(_gameListener);

    if (widget.loadedPlay != null) {
      game.resumeGame();
    }
    else {
      game.restartGame();
    }
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
    game.leave();
    game.removeListener(_gameListener);
    fgbgSubscription.cancel();

    super.dispose();
  }

  Widget _buildGameBody() {
    return Builder(
        builder: (context) {
          _builderContext = context;
          return Scaffold(
              appBar: AppBar(
                title: const Text('HyleX'),
                actions: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.history)),
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
                          if (game.play.hasStaleMove) {
                            game.play.undoStaleMove();
                            game.play.cursor.clear();
                            game.savePlay();
                          }
                          else {

                            final recentRole = game.play.opponentRole.name;
                            ask('Undo $recentRole\'s last move?', () {
                                var lastMove = game.play.previousRound();
                                if (game.play.currentPlayer == Player.Ai) {
                                  // undo AI move also
                                  lastMove = game.play.previousRound();
                                }

                                if (lastMove != null) {
                                  game.play.cursor.adaptFromMove(lastMove);
                                  game.play.cursor.temporary = true;
                                  final moveBefore = game.play.lastMoveFromJournal;
                                  if (moveBefore != null) {
                                    game.play.opponentMove.adaptFromMove(moveBefore);
                                  }

                                  game.savePlay();
                                }
                                else {
                                  // beginning of game
                                  game.restartGame();
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
                            game.restartGame();
                      })
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () => {

                      ask('Leave current game?', () {
                            game.leave();
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
                                _buildRoleIndicator(Role.Chaos, game.play.chaosPlayer, true),
                                Text("Round ${game.play.currentRound} of ${game.play.maxRounds}"),
                                _buildRoleIndicator(Role.Order, game.play.orderPlayer, false),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(value: game.play.progress,),
                          Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                                child: Center(
                                  child: GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: game.play.stock.getTotalChipTypes(),
                                      ),
                                      itemBuilder: _buildChipStock,
                                      itemCount: game.play.stock.getTotalChipTypes(),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics()),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                                height: 20,
                                child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: game.play.stock.getTotalChipTypes(),
                                    ),
                                    itemBuilder: _buildChipStockIndicator,
                                    itemCount: game.play.stock.getTotalChipTypes(),
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
                                    crossAxisCount: game.play.dimension,
                                  ),
                                  itemBuilder: _buildBoardGrid,
                                  itemCount: game.play.dimension * game.play.dimension,
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



  bool _isUndoAllowed() => !game.isBoardLocked() && !game.play.isGameOver() && !game.play.isFullAutomaticPlay && !game.play.isMultiplayerPlay && !game.play.isJournalEmpty;


  Widget _buildHint(BuildContext context) {
    if (game.play.isGameOver()) {
      final winner = game.play.stats.getWinner();
      return Text("Game over! ${winner.name} wins!");
    }
    else if (game.recentOpponentRole != null) {
      return _buildDoneText(game.recentOpponentRole!, game.play.opponentMove);
    }
    else if (game.play.currentPlayer == Player.Ai) {
      return _buildAiProgressText();
    }
    else if (game.play.currentPlayer == Player.RemoteUser) {
      return const Text("Waiting for remote opponent to move...");
    }
    else if (game.play.isBothSidesSinglePlay && !game.play.isJournalEmpty) {
      final lastMove = game.play.lastMoveFromJournal!;
      final previousRole = lastMove.isPlaced() ? Role.Chaos : Role.Order;
      return _buildDoneText(previousRole, lastMove.toCursor());
    }
    else {
      return const Text("Place a chip on a free space!");
    }
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
            value: game.aiLoad?.ratio,
            backgroundColor: Colors.grey.shade300,
          ),
        ),
    ],);
  }

  Widget _buildSubmitButton(BuildContext context) {
    if (game.play.isGameOver()) {
      return FilledButton(
        onPressed: () => game.restartGame(),
        child: const Text("Restart"),
      );
    }
    else if (game.play.currentPlayer == Player.User) {
      final isDirty = game.play.hasStaleMove;
      return FilledButton(
        onPressed: () {
          if (game.isBoardLocked()) {
            return;
          }
          if (game.play.isGameOver()) {
            return;
          }
          if (game.play.currentRole == Role.Chaos && !game.play.hasStaleMove) {
            toastInfo(context, "Chaos has to place one chip!");
            return;
          }

          if (!game.play.hasStaleMove && game.play.currentRole == Role.Order) {
            game.play.applyStaleMove(Move.skipped());
          }
          game.play.commitMove();
          game.nextRound();
          if (game.play.isGameOver()) {
            _showGameOver(context);
          }
        },
        child: Text(game.play.currentRole == Role.Order && !game.play.cursor.hasEnd
            ? 'Skip move'
            : 'Submit move',
        style: TextStyle(fontWeight: isDirty ? FontWeight.bold : null)),
      );
    }
    return Container();
  }

  Text _buildDoneText(Role role, Cursor cursor) {
    final text = _createDoneString(role, cursor);
    var appendix = "";
    if (role == Role.Order) {
      appendix = "Now it's on Chaos to place a chip!";
    }
    else {
      appendix = "Now it's on Order to move a chip or skip!";
    }

    if (!game.play.isFullAutomaticPlay) {
      return Text(
          textAlign: TextAlign.center, "$text\n$appendix");
    }
    else {
      return Text(
          textAlign: TextAlign.center, text);
    }
  }

  String _createDoneString(Role role, Cursor cursor) {
    if (role == Role.Order) {
      if (cursor.hasStart && cursor.hasEnd) {
        return "${role.name} has moved from ${cursor.start?.toReadableCoordinates()} to ${cursor.end?.toReadableCoordinates()}.";
      }
      else {
        return "${role.name} has skipped its move.";
      }
    }
    else {
      return "${role.name} has placed at ${cursor.end?.toReadableCoordinates()}.";
    }
  }

  Text _buildAiProcessingText() {
    if (game.play.currentRole == Role.Order) {
      return Text("Waiting for ${game.play.currentRole.name} to move ...");
    }
    else {
      return Text("Waiting for ${game.play.currentRole.name} to place ...");
    }
  }

  void _showGameOver(BuildContext? context) {
    setState(() {
      final winner = game.play.currentRole;
      toastError(context ?? _builderContext, "GAME OVER, ${winner.name} WINS!");
    });
  }

  Widget _buildRoleIndicator(Role role, Player player, bool isLeftElseRight) {
    final isSelected = game.play.currentRole == role;
    final color = isSelected ? Colors.white : null;
    final icon = player == Player.Ai ? MdiIcons.brain : player == Player.RemoteUser ? Icons.record_voice_over : MdiIcons.account;
    var controller = role == Role.Chaos ? _chaosChipTooltipController : _orderChipTooltipController;
    var otherController = role == Role.Order ? _chaosChipTooltipController : _orderChipTooltipController;
    final tooltipPrefix = isSelected ? "Current player" : "Waiting player";
    final tooltipPostfix = player == Player.User ?  "You" : player == Player.Ai ? "Computer" : "Remote opponent";
    return SuperTooltip(
      controller: controller,
      showBarrier: false,
      content: Text(
        "$tooltipPrefix: $tooltipPostfix",
        softWrap: true,
        
        style: TextStyle(
          color: Colors.black,
        ),
      ),
      child: GestureDetector(
        onTap: () async {
          await otherController.hideTooltip();
          await controller.hideTooltip();
          await controller.showTooltip();
        
          Future.delayed(Duration(seconds: 3), () {
            controller.hideTooltip();
          });
        },
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
                    Text("${role.name} - ${game.play.stats.getPoints(role)}", style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : null)),
                  ],
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(" ${game.play.stats.getPoints(role)} - ${role.name}", style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : null)),
                    const Text(" "),
                    Icon(icon, color: color, size: 16),
                  ],
                ),
            backgroundColor: isSelected ? Colors.black : null
        ),
      ),
    );
  }

  Widget _buildBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % game.play.matrix.dimension.x);
    y = (index / game.play.matrix.dimension.y).floor();
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

    final spot = game.play.matrix.getSpot(where);
    final chip = spot.content;
    final pointText = spot.point > 0 ? spot.point.toString() : "";

    if (game.play.cursor.end == where) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (game.play.cursor.start == where) {
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
    if (game.play.currentRole == Role.Order && where != null) {
      possibleTarget = game.play.cursor.hasStart && game.play.cursor.possibleTargets.contains(where);

      if (game.play.cursor.hasEnd) {
        startSpot = game.play.matrix.getSpot(game.play.cursor.end!);
      }
      else if (game.play.cursor.hasStart) {
        startSpot = game.play.matrix.getSpot(game.play.cursor.start!);
      }
    }

    // show trace of opponent move
    if (game.showOpponentTrace && game.play.opponentMove.hasEnd && where != null) {
      startSpot ??= game.play.matrix.getSpot(game.play.opponentMove.end!);
      possibleTarget |= game.play.opponentMove.end! == where;
      if (game.play.opponentMove.hasStart) {
        if (game.play.opponentMove.isHorizontalMove()) {
          possibleTarget |= game.play.opponentMove.end!.y == where.y &&
              (game.play.opponentMove.start!.x <= where.x  && game.play.opponentMove.end!.x >= where.x ||
                  game.play.opponentMove.end!.x <= where.x  && game.play.opponentMove.start!.x >= where.x);
        }
        else if (game.play.opponentMove.isVerticalMove()) {
          possibleTarget |= game.play.opponentMove.end!.x == where.x &&
              (game.play.opponentMove.start!.y <= where.y  && game.play.opponentMove.end!.y >= where.y ||
                  game.play.opponentMove.end!.y <= where.y  && game.play.opponentMove.start!.y >= where.y);
        }
      }
    }

    var shadedColor = startSpot?.content?.color.withOpacity(0.2);


    if (chip == null) {

      return Container(
        color: possibleTarget ? shadedColor : null,
        child: where != null && text.isEmpty
            ? Center(child: Text(_getPositionText(where, game.play.matrix.dimension),
                style: TextStyle(
                    fontSize: game.play.dimension > 9 ? 10 : null,
                    color: Colors.grey[400])))
            : null,
      );
    }
    return Container(
      color: possibleTarget ? shadedColor : null,
      child: GestureDetector(
        onLongPressStart: (details) => {
          setState(() {
            _emphasiseAllChipsOf = chip;
          })
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
                fontSize: game.play.dimension > 7 ? 12 : 16,
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

    if (game.isBoardLocked()) {
      return;
    }

    setState(() {
      if (game.play.cursor.temporary) {
        game.play.cursor.clear();
      }
      if (game.play.currentRole == Role.Chaos) {
        if (game.play.matrix.isFree(where)) {
          _handleFreeFieldForChaos(context, where);
        }
        else {
          _handleOccupiedFieldForChaos(where, context);
        }
      }
      if (game.play.currentRole == Role.Order) {
        if (game.play.matrix.isFree(where)) {
          _handleFreeFieldForOrder(context, where);
        }
        else {
          _handleOccupiedFieldForOrder(where, context);
        }
      }
    });
  }

  void _handleFreeFieldForChaos(BuildContext context, Coordinate coordinate) {
    final cursor = game.play.cursor;
    if (cursor.end != null && !game.play.matrix.isFree(cursor.end!)) {
      toastInfo(context, "You have already placed a chip");
    }
    else {
      final currentChip = game.play.currentChip!;
      if (!game.play.stock.hasStock(currentChip)) {
        toastInfo(context, "No more stock for current chip");
      }
      game.play.applyStaleMove(Move.placed(currentChip, coordinate));
      //game.play.matrix.put(coordinate, currentChip, game.play.stock);
      game.play.cursor.updateEnd(coordinate);
    }
  }

  void _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = game.play.cursor;
    if (cursor.end != coordinate) {
      toastInfo(context, "You can only remove the current placed chip");
    }
    else {
      game.play.undoStaleMove();
      game.play.cursor.clear();
    }
  }

  void _handleFreeFieldForOrder(BuildContext context, Coordinate coordinate) {
    final cursor = game.play.cursor;
    if (!cursor.hasStart) {
      toastInfo(context, "Please select a chip to move first");
    }
    else if (/*!cursor.hasEnd && */cursor.start == coordinate) {
      // clear start cursor if not target is selected
      game.play.undoStaleMove();
      cursor.clear();
    }
    else if (!cursor.possibleTargets.contains(coordinate) && cursor.start != coordinate) {
      toastInfo(context, "Chip can only move horizontally or vertically in free space");
    }
    else if (cursor.hasStart) {
      if (cursor.hasEnd) {
        final from = game.play.matrix.getSpot(cursor.end!);
        // this is a correction move, so undo last move and apply again below
        game.play.undoStaleMove();
        game.play.applyStaleMove(Move.moved(from.content!, cursor.start!, coordinate));
      }
      else {
        final from = game.play.matrix.getSpot(cursor.start!);
        game.play.applyStaleMove(Move.moved(from.content!, cursor.start!, coordinate));
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
    final cursor = game.play.cursor;
    if (cursor.start != null && cursor.start != coordinate && cursor.end != null) {
      toastInfo(context,
          "You can not move the selected chip on another one");

    }
    else if (cursor.start == coordinate) {
      cursor.clear();
    }
    else {
      cursor.updateStart(coordinate);
      cursor.detectPossibleTargetsFor(coordinate, game.play.matrix);
    }
  }

  Widget _buildChipStock(BuildContext context, int index) {
    final stockEntries = game.play.stock.getStockEntries();
    if (stockEntries.length <= index) {
      return const Text("?");
    }
    final entry = stockEntries.toList()[index];
    final text = game.play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";

    return _buildChipStockItem(entry, text);
  }

  Widget _buildChipStockIndicator(BuildContext context, int index) {
    final stockEntries = game.play.stock.getStockEntries();
    final entry = stockEntries.toList()[index];
    if (game.play.currentChip == entry.chip) {
      return const Align(
          alignment: Alignment.topCenter,
          child: Text("▲", style: TextStyle(fontSize: 16),));
    }
    else {
      return Container();
    }
  }

  Padding _buildChipStockItem(StockEntry entry, String text) {
    if (game.play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(game.play.dimension > 5 ? game.play.dimension > 7 ? 0 : 2 : 4),
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
      padding: EdgeInsets.all(game.play.dimension > 5 ? game.play.dimension > 7 ? 0 : 4 : 8),
      child: _buildChip(entry.chip, text),
    );
  }

  Widget _wrapLastMove(Widget widget, Coordinate where) {
    if (game.play.opponentMove.hasStart && game.play.opponentMove.start == where) {
      return DottedBorder(
          padding: EdgeInsets.zero,
          strokeWidth: 1,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    else if (game.play.opponentMove.hasEnd && game.play.opponentMove.end == where) {
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


class Game extends ChangeNotifier {

  User user;
  Play play;
  bool waitForOpponent = false;
  Role? recentOpponentRole;
  bool showOpponentTrace = false;
  Load? aiLoad;

  SendPort? _aiControlPort;

  Game(this.play, this.user);

  restartGame() {
    kill();
    play.reset();
    waitForOpponent = false;
    recentOpponentRole = null;
    savePlay();
    notifyListeners();
    if (play.currentPlayer == Player.Ai) {
      _think();
    }
  }

  resumeGame() {
    if (play.currentPlayer == Player.Ai) {
      _think();
    }
  }

  nextRound() {

    if (play.isGameOver()) {
      debugPrint("Game over, no next round");
      finish();
      return;
    }

    play.nextRound(!showOpponentTrace);
    savePlay();
    notifyListeners();

    if (play.currentPlayer == Player.Ai) {
      _think();
    }

  }


  bool isBoardLocked() => waitForOpponent || play.isGameOver();

  void _think() {
    waitForOpponent = true;
    aiLoad = null;
    showOpponentTrace = true;
    notifyListeners();

    Future.delayed(Duration(milliseconds: play.isFullAutomaticPlay ? 2500 :  0), () {
      recentOpponentRole = null;

      play.startThinking((Load load)
      {
        aiLoad = load;
        notifyListeners();
      },
          _aiNextMoveHandler,
              (SendPort aiIsolateControlPort) => _aiControlPort = aiIsolateControlPort);
    });

  }


  _aiNextMoveHandler(Move move) {
    debugPrint("AI ready");
    waitForOpponent = false;
    recentOpponentRole = play.currentRole;

    play.applyStaleMove(move);
    play.opponentMove.adaptFromMove(move);
    play.commitMove();

    if (play.isGameOver()) {
      finish();
      notifyListeners();
    }
    else {
      notifyListeners();
      nextRound();
    }
  }


  void kill() {
    _aiControlPort?.send('KILL');
  }

  void savePlay() {
    if (play.isGameOver()) {
      PreferenceService().remove(PreferenceService.DATA_CURRENT_PLAY);
    }
    else {
      final jsonToSave = jsonEncode(play);
      //debugPrint(getPrettyJSONString(game.play));
      debugPrint("Save current play");
      PreferenceService().setString(PreferenceService.DATA_CURRENT_PLAY, jsonToSave);
    }
  }

  void leave() {
    savePlay();
    kill();
  }

  Role finish() {
    final winner = play.finishGame();
    if (!play.isFullAutomaticPlay && !play.isBothSidesSinglePlay) {
      if (winner == Role.Order) {
        if (play.orderPlayer == Player.User) {
          user.achievements.incWonGame(Role.Order, play.dimension);
          user.achievements.registerPointsForScores(Role.Order, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.chaosPlayer == Player.User) {
          user.achievements.incLostGame(Role.Chaos, play.dimension);
        }
      }
      else if (winner == Role.Chaos) {
        if (play.chaosPlayer == Player.User) {
          user.achievements.incWonGame(Role.Chaos, play.dimension);
          user.achievements.registerPointsForScores(Role.Chaos, play.dimension, play.stats.getPoints(winner));
        }
        else if (play.orderPlayer == Player.User) {
          user.achievements.incLostGame(Role.Order, play.dimension);
        }
      }
      _saveUser();
    }

    return winner;
  }

  void _saveUser() {
    final jsonToSave = jsonEncode(user);
    debugPrint(getPrettyJSONString(user));
    debugPrint("Save current user");
    PreferenceService().setString(PreferenceService.DATA_CURRENT_USER, jsonToSave);
    //TODO notify start widget
  }

}