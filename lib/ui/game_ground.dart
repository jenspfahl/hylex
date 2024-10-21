
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

class Hyle9Ground extends StatefulWidget {
  Player chaosPlayer;
  Player orderPlayer;
  int dimension;

  Hyle9Ground(this.chaosPlayer, this.orderPlayer, this.dimension, {super.key});

  @override
  State<Hyle9Ground> createState() => _Hyle9GroundState();
}

class _Hyle9GroundState extends State<Hyle9Ground> {

  late Play _play;
  GameChip? _emphasiseAllChipsOf;
  bool _boardLocked = false;

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
      title: 'Hyle9',
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
    _play.opponentMove.clear();
    if (move.skipped) {
      toastInfo(context, "Opponent skipped move");
    }
    else if (move.isMove()) {
      final chip = _play.matrix.remove(move.from!);
      if (chip != null) {
        final test = _play.matrix.getSpot(move.to!);
        if (test.content != null) {
          toastError(context, "!!! $test");
        }
        else {
          _play.matrix.put(move.to!, chip);
        }
      }

      _play.opponentMove.updateStart(move.from!);
      _play.opponentMove.update(move.to!);
    }
    else {
      _play.matrix.put(move.from!, _play.currentChip!, _play.stock);
      _play.opponentMove.update(move.from!);
    }

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
    debugPrint("intermediate load: $load, ${identityHashCode(load)}");

  }

  void _thinkIfAi(BuildContext? context) {
    if (!_play.isGameOver() && _play.currentPlayer == Player.Ai) {
      _boardLocked = true;
      _aiDone = null;
      _load = null;
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
                title: const Text('Hyle X'),
                actions: [
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
                                Text("Round ${_play.currentRound} of ${_play.dimension * _play.dimension}"),
                                _buildRoleIndicator(Role.Order, false),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            height: 70 - (_play.dimension.toDouble() * 2), //TODO calc cel lheight and use this
                            child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _play.stock.getChipTypes(),
                                ),
                                itemBuilder: _buildChipStock,
                                itemCount: _play.stock.getChipTypes(),
                                physics: const NeverScrollableScrollPhysics()),
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
      return FilledButton(
        onPressed: () {
          if (_boardLocked) {
            return;
          }
          if (_play.isGameOver()) {
            _doGameOver(context);
            return;
          }
          if (_play.currentRole == Role.Chaos && !_play.cursor.hasCursor) {
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
            : 'Submit move'),
      );
    }
    else if (_play.currentPlayer == Player.Ai) {
      if (_aiDone != null) {
        if (_aiDone == Role.Order) {
          if (_play.opponentMove.hasStartCursor && _play.opponentMove.hasCursor) {
            return Text("${_aiDone!.name} has moved from ${_play.opponentMove.startWhere} to ${_play.opponentMove.where}.");
          }
          else {
            return Text("${_aiDone!.name} has skipped its move.");
          }
        }
        else {
          return Text("${_aiDone!.name} has placed at ${_play.opponentMove.where}.");

        }
      }
      else {
        if (_aiDone == Role.Order) {
          return Text("Waiting for ${_play.currentRole.name} to move (${_load
              ?.readableRatio ?? "0" }%)...");
        }
        else {
          return Text("Waiting for ${_play.currentRole.name} to place (${_load
              ?.readableRatio ?? "0" }%)...");
        }
      }
    }
    else if (_play.currentPlayer == Player.RemoteUser) {
      return Text("Waiting for remote opponent to move...");
    }
    return Container();
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
    if (chip == null) {
      final possibleTarget =
          where != null
              && _play.currentRole == Role.Order
              && _play.cursor.hasStartCursor
              && _play.cursor.possibleTargets.contains(where);
      Spot? start;
      if (_play.currentRole == Role.Order) {
        if (_play.cursor.hasCursor) {
          start = _play.matrix.getSpot(_play.cursor.where!);
        }
        else if (_play.cursor.hasStartCursor) {
          start = _play.matrix.getSpot(_play.cursor.startWhere!);
        }
      }
      return Container(
        color: possibleTarget ? start?.content?.color.withOpacity(0.2)??Colors.limeAccent : null,
      );
    }
    return GestureDetector(
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

      _play.stats.setPoints(Role.Order, _play.matrix.getTotalPointsForOrder());
      _play.stats.setPoints(Role.Chaos, _play.matrix.getTotalPointsForChaos());

    });
  }

  void _handleFreeFieldForChaos(BuildContext context, Coordinate coordinate) {
    final cursor = _play.cursor;
    if (cursor.where != null) {
      toastInfo(context, "You have already placed a chip");
    }
    else {
      final currentChip = _play.currentChip!;
      if (!_play.stock.hasStock(currentChip)) {
        toastInfo(context, "No more stock for current chip");
      }
      _play.matrix.put(coordinate, currentChip, _play.stock);
      _play.cursor.update(coordinate);
    }
  }

  void _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = _play.cursor;
    if (cursor.where != coordinate) {
      toastInfo(context, "You can only remove the current placed chip");
    }
    else {
      _play.matrix.remove(coordinate, _play.stock);
      _play.cursor.clear();
    }
  }

  void _handleFreeFieldForOrder(BuildContext context, Coordinate coordinate) {
    final cursor = _play.cursor;
    if (!cursor.hasStartCursor) {
      toastInfo(context, "Please select a chip to move first");
    }
    else if (!cursor.hasCursor && cursor.startWhere == coordinate) {
      // clear source cursor if not target is selected
      cursor.clear();
    }
    else if (!cursor.possibleTargets.contains(coordinate) && cursor.startWhere != coordinate) {
      toastInfo(context, "Chip can only move horizontally or vertically in free space");
    }
    else if (cursor.hasStartCursor) {
      GameChip chip;
      if (cursor.hasCursor) {
        chip = _play.matrix.remove(cursor.where!, _play.stock)!;
      }
      else {
        chip = _play.matrix.remove(cursor.startWhere!, _play.stock)!;
      }
      _play.matrix.put(coordinate, chip, _play.stock);
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

  Padding _buildChipStockItem(StockEntry entry, String text) {
    if (_play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(_play.dimension > 5 ? _play.dimension > 7 ? 0 : 2 : 4),
        child: Container(
            decoration: BoxDecoration(
              color: _getChipBackgroundColor(entry.chip),
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
          strokeWidth: 1,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    else if (_play.opponentMove.hasCursor && _play.opponentMove.where == where) {
      return DottedBorder(
          strokeWidth: 3,
          strokeCap: StrokeCap.butt,
          borderType: BorderType.Circle,
          color: Colors.grey,
          child: widget);
    }
    return widget;
  }
}