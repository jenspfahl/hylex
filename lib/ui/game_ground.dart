
import 'dart:isolate';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../model/ai/strategy.dart';
import '../model/chip.dart';
import '../model/matrix.dart';
import '../model/play.dart';
import '../model/spot.dart';
import '../utils.dart';
import 'dialogs.dart';

enum Player {User, Ai, RemoteUser}

class HyleXGround extends StatefulWidget {
  Player chaosPlayer;
  Player orderPlayer;
  int dimension;

  HyleXGround(this.chaosPlayer, this.orderPlayer, this.dimension, {super.key});

  @override
  State<HyleXGround> createState() => _HyleXGroundState();
}

class _HyleXGroundState extends State<HyleXGround> {

  late Play _play;
  GameChip? _emphasiseAllChipsOf;
  bool _boardLocked = false;
  bool _showOpponentTrace = false;

  late BuildContext _builderContext;

  Load? _load;

  Role? _aiDone;

  SendPort? _aiControlPort;

  @override
  void initState() {
    super.initState();
    SmartDialog.dismiss();

    _resetGame(null);
    _thinkIfAi(context);
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

  void _resetGame(BuildContext? context) {
    _play = Play(widget.dimension, widget.chaosPlayer, widget.orderPlayer);
    _play.nextChip();
    _boardLocked = false;
  }
  
  _aiControlHandlerReceived(SendPort aiIsolateControlPort) => _aiControlPort = aiIsolateControlPort;

  _aiNextMoveHandler(Move move) async {
    debugPrint("AI ready");
    _aiDone = _play.currentRole;

    _play.applyMove(move);
    _play.opponentMove.adaptFromMove(move);

    if (_play.isGameOver()) {
      _doGameOver(context);
      return;
    }

    _play.nextRound(false);

    setState(() {});

    await Future.delayed(const Duration(seconds: 2), (){});

    _thinkIfAi(context);
  }

  _aiProgressListener(Load load) {

    setState(() {
      _load = load;
    });
    //debugPrint("intermediate load: $load, ${identityHashCode(load)}");

  }

  void _thinkIfAi(BuildContext? context) {
    if (!_play.isGameOver() && _play.currentPlayer == Player.Ai) {
      _boardLocked = true;
      _aiDone = null;
      _load = null;
      _showOpponentTrace = true;
      _play.startThinking(
          _aiProgressListener, _aiNextMoveHandler, _aiControlHandlerReceived);
    }
    else {
      setState(() {
        _boardLocked = false;
      });
    }
  }

  Widget _buildGameBody() {
    return Builder(
        builder: (context) {
          _builderContext = context;
          return Scaffold(
              appBar: AppBar(
                title: const Text('HyleX'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.undo_outlined),
                    onPressed: () {
                      if (_play.isGameOver() || _play.isFullAutomaticPlay || _play.isMultiplayerPlay) { //TODO hide icon in this case
                        toastError(context, "Undo not possible here");
                        return;
                      }

                      setState(() {
                        if (_play.isDirty) {
                          _play.undoLastMove();
                        }
                        else {

                          buildChoiceDialog(180, 180, 'Undo last opponent move?',
                              "YES", ()
                              {
                                SmartDialog.dismiss();

                                _play.previousRound();
                                if (_play.currentPlayer == Player.Ai) {
                                  // undo AI move also
                                  _play.previousRound();
                                  _thinkIfAi(context);
                                }

                              },  "NO", () {
                                SmartDialog.dismiss();
                              });

                        }
                      });

                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt_outlined),
                    onPressed: () => {

                      buildChoiceDialog(180, 180, 'Restart game?',
                          "YES", ()
                          {
                            setState(() {
                              _killAiThinking();

                              _resetGame(context);
                            });
                            SmartDialog.dismiss();
                            _thinkIfAi(context);
                          },  "NO", () {
                            SmartDialog.dismiss();
                          })
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app),
                    onPressed: () => {

                      buildChoiceDialog(180, 180, 'Leave current game?',
                          "YES", ()
                          {
                            // TODO save current
                            SmartDialog.dismiss();

                            _killAiThinking();

                            Navigator.pop(super.context); // go to start page
                          },  "NO", () {
                            SmartDialog.dismiss();
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
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildRoleIndicator(Role.Chaos, true),
                                Text("Round ${_play.currentRound} of ${_play.maxRounds}"),
                                _buildRoleIndicator(Role.Order, false),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(value: _play.progress,),
                          Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8),
                                child: Center(
                                  child: GridView.builder(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: _play.stock.getTotalChipTypes(),
                                      ),
                                      itemBuilder: _buildChipStock,
                                      itemCount: _play.stock.getTotalChipTypes(),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics()),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                height: 20,
                                child: GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: _play.stock.getTotalChipTypes(),
                                    ),
                                    itemBuilder: _buildChipStockIndicator,
                                    itemCount: _play.stock.getTotalChipTypes(),
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
                                    crossAxisCount: _play.dimension,
                                  ),
                                  itemBuilder: _buildBoardGrid,
                                  itemCount: _play.dimension * _play.dimension,
                                  physics: const NeverScrollableScrollPhysics()),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(
                                left: 0, top: 20, right: 0, bottom: 0),
                            child: _buildSubmitButtonOrHint(context),
                          ),
                        ]),
                  ),
                ),
              ));
        }
    );
  }

  void _killAiThinking() {
    _aiControlPort?.send('KILL');
  }

  Widget _buildSubmitButtonOrHint(BuildContext context) {
    if (_play.isGameOver()) {
      final winner = _play.finishGame();
      return Text("Game over! ${winner.name} wins!");
    }
    else if (_play.currentPlayer == Player.User) {
      final isDirty = _play.isDirty;
      return FilledButton(
        onPressed: () {
          if (_boardLocked) {
            return;
          }
          if (_play.isGameOver()) {
            _doGameOver(context);
            return;
          }
          if (_play.currentRole == Role.Chaos && !_play.isDirty) {
            toastInfo(context, "Chaos has to place one chip!");
            return;
          }

          setState(() {
            _play.nextRound(true);
          });
          _thinkIfAi(context);
        },
        child: Text(_play.currentRole == Role.Order && !_play.cursor.hasCursor
            ? 'Skip move'
            : 'Submit move',
        style: TextStyle(fontWeight: isDirty ? FontWeight.bold : null)),
      );
    }
    else if (_play.currentPlayer == Player.Ai) {
      if (_aiDone != null) {
        return _buildAiDoneText();
      }
      else {
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
                value: _load?.ratio,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
        ],);
      }
    }
    else if (_play.currentPlayer == Player.RemoteUser) {
      return const Text("Waiting for remote opponent to move...");
    }
    return Container();
  }

  Text _buildAiDoneText() {
    if (_aiDone == Role.Order) {
      if (_play.opponentMove.hasStartCursor && _play.opponentMove.hasCursor) {
        return Text("${_aiDone!.name} has moved from ${_play.opponentMove.startWhere?.toReadableCoordinates()} to ${_play.opponentMove.where?.toReadableCoordinates()}.");
      }
      else {
        return Text("${_aiDone!.name} has skipped its move.");
      }
    }
    else {
      return Text("${_aiDone!.name} has placed at ${_play.opponentMove.where?.toReadableCoordinates()}.");
    }
  }

  Text _buildAiProcessingText() {
    if (_play.currentRole == Role.Order) {
      return Text("Waiting for ${_play.currentRole.name} to move ...");
    }
    else {
      return Text("Waiting for ${_play.currentRole.name} to place ...");
    }
  }

  void _doGameOver(BuildContext? context) {
    setState(() {
      final winner = _play.finishGame();
      toastError(context ?? _builderContext, "GAME OVER, ${winner.name} WINS!");
      _boardLocked = true;
    });
  }

  Widget _buildRoleIndicator(Role role, bool isLeftElseRight) {
    final isSelected = _play.currentRole == role;
    return Chip(
        shape: isLeftElseRight
            ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20),bottomRight: Radius.circular(20)))
            : const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20))),
        label: isLeftElseRight
            ? Text("${role.name} - ${_play.stats.getPoints(role)}", style: TextStyle(color: isSelected ? Colors.white : null))
            : Text(" ${_play.stats.getPoints(role)} - ${role.name}", style: TextStyle(color: isSelected ? Colors.white : null)),
        backgroundColor: isSelected ? Colors.black : null
    );
  }

  Widget _buildBoardGrid(BuildContext context, int index) {
    int x, y = 0;
    x = (index % _play.matrix.dimension.x);
    y = (index / _play.matrix.dimension.y).floor();
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

    final spot = _play.matrix.getSpot(where);
    final chip = spot.content;
    final pointText = spot.point > 0 ? spot.point.toString() : "";

    if (_play.cursor.where == where) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (_play.cursor.startWhere == where) {
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
    if (_play.currentRole == Role.Order && where != null) {
      possibleTarget =
          where != null
              && _play.cursor.hasStartCursor
              && _play.cursor.possibleTargets.contains(where);

      if (_play.cursor.hasCursor) {
        startSpot = _play.matrix.getSpot(_play.cursor.where!);
      }
      else if (_play.cursor.hasStartCursor) {
        startSpot = _play.matrix.getSpot(_play.cursor.startWhere!);
      }
    }

    // show trace of opponent move
    if (_showOpponentTrace && _play.opponentMove.hasCursor && where != null) {
      startSpot ??= _play.matrix.getSpot(_play.opponentMove.where!);
      possibleTarget |= _play.opponentMove.where! == where;
      if (_play.opponentMove.hasStartCursor) {
        if (_play.opponentMove.isHorizontalMove()) {
          possibleTarget |= _play.opponentMove.where!.y == where.y &&
              (_play.opponentMove.startWhere!.x <= where.x  && _play.opponentMove.where!.x >= where.x ||
                  _play.opponentMove.where!.x <= where.x  && _play.opponentMove.startWhere!.x >= where.x);
        }
        else if (_play.opponentMove.isVerticalMove()) {
          possibleTarget |= _play.opponentMove.where!.x == where.x &&
              (_play.opponentMove.startWhere!.y <= where.y  && _play.opponentMove.where!.y >= where.y ||
                  _play.opponentMove.where!.y <= where.y  && _play.opponentMove.startWhere!.y >= where.y);
        }
      }
    }

    var shadedColor = startSpot?.content?.color.withOpacity(0.2);


    if (chip == null) {
      return Container(
        color: possibleTarget ? shadedColor : null,
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
                fontSize: _play.dimension > 7 ? 12 : 16,
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

    if (_boardLocked) {
      return; //TODO allow long tab for locked boards
    }

    _showOpponentTrace = false;

    setState(() {
      if (_play.currentRole == Role.Chaos) {
        if (_play.matrix.isFree(where)) {
          _handleFreeFieldForChaos(context, where);
        }
        else {
          _handleOccupiedFieldForChaos(where, context);
        }
      }
      if (_play.currentRole == Role.Order) {
        if (_play.matrix.isFree(where)) {
          _handleFreeFieldForOrder(context, where);
        }
        else {
          _handleOccupiedFieldForOrder(where, context);
        }
      }
    });
  }

  void _handleFreeFieldForChaos(BuildContext context, Coordinate coordinate) {
    final cursor = _play.cursor;
    if (cursor.where != null && !_play.matrix.isFree(cursor.where!)) {
      toastInfo(context, "You have already placed a chip");
    }
    else {
      final currentChip = _play.currentChip!;
      if (!_play.stock.hasStock(currentChip)) {
        toastInfo(context, "No more stock for current chip");
      }
      _play.applyMove(Move.placed(currentChip, coordinate));
      //_play.matrix.put(coordinate, currentChip, _play.stock);
      _play.cursor.update(coordinate);
    }
  }

  void _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = _play.cursor;
    if (cursor.where != coordinate) {
      toastInfo(context, "You can only remove the current placed chip");
    }
    else {
      _play.undoLastMove();
      _play.cursor.clear();
    }
  }

  void _handleFreeFieldForOrder(BuildContext context, Coordinate coordinate) {
    final cursor = _play.cursor;
    if (!cursor.hasStartCursor) {
      toastInfo(context, "Please select a chip to move first");
    }
    else if (!cursor.hasCursor && cursor.startWhere == coordinate) {
      // clear start cursor if not target is selected
      _play.undoLastMove();
      cursor.clear();
    }
    else if (!cursor.possibleTargets.contains(coordinate) && cursor.startWhere != coordinate) {
      toastInfo(context, "Chip can only move horizontally or vertically in free space");
    }
    else if (cursor.hasStartCursor) {
      Spot from;
      if (cursor.hasCursor) {
        from = _play.matrix.getSpot(cursor.where!);
        // this is a correction move, so undo last move and apply again below
        _play.undoLastMove();
      }
      else {
        from = _play.matrix.getSpot(cursor.startWhere!);
      }
      _play.applyMove(Move.moved(from.content!, cursor.startWhere!, coordinate));

      if (cursor.startWhere == coordinate) {
        // move back to start is like a reset
        cursor.clear();
      }
      else {
        cursor.update(coordinate);
      }

    }
  }

  void _handleOccupiedFieldForOrder(Coordinate coordinate, BuildContext context) {
    final cursor = _play.cursor;
    if (cursor.startWhere != null && cursor.startWhere != coordinate && cursor.where != null) {
      toastInfo(context,
          "You can not move the selected chip on another one");

    }
    else if (cursor.startWhere == coordinate) {
      cursor.clear();
    }
    else {
      cursor.updateStart(coordinate);
      cursor.detectPossibleTargetsFor(coordinate, _play.matrix);
    }
  }

  Widget _buildChipStock(BuildContext context, int index) {
    final stockEntries = _play.stock.getStockEntries();
    if (stockEntries.length <= index) {
      return const Text("?");
    }
    final entry = stockEntries.toList()[index];
    final text = _play.dimension > 9 ? "${entry.amount}" : "${entry.amount}x";

    return _buildChipStockItem(entry, text);
  }

  Widget _buildChipStockIndicator(BuildContext context, int index) {
    final stockEntries = _play.stock.getStockEntries();
    final entry = stockEntries.toList()[index];
    if (_play.currentChip == entry.chip) {
      return const Align(
          alignment: Alignment.topCenter,
          child: Text("▲", style: TextStyle(fontSize: 16),));
    }
    else {
      return Container();
    }
  }

  Padding _buildChipStockItem(StockEntry entry, String text) {
    if (_play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(_play.dimension > 5 ? _play.dimension > 7 ? 0 : 2 : 4),
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
      padding: EdgeInsets.all(_play.dimension > 5 ? _play.dimension > 7 ? 0 : 4 : 8),
      child: _buildChip(entry.chip, text),
    );
  }

  Widget _wrapLastMove(Widget widget, Coordinate where) {
    if (_play.opponentMove.hasStartCursor && _play.opponentMove.startWhere == where) {
      return DottedBorder(
          padding: EdgeInsets.zero,
          strokeWidth: 1,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    else if (_play.opponentMove.hasCursor && _play.opponentMove.where == where) {
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
}