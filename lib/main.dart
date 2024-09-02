import 'dart:async';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:hyle_9/model/chip.dart';
import 'package:hyle_9/model/matrix.dart';
import 'package:hyle_9/utils.dart';

import 'model/play.dart';
import 'package:hyle_9/model/spot.dart';

void main() {
  runApp(const Hyle9Ground());
}

class Hyle9Ground extends StatefulWidget {
  const Hyle9Ground({super.key});

  @override
  State<Hyle9Ground> createState() => _Hyle9GroundState();
}

class _Hyle9GroundState extends State<Hyle9Ground> {

  late Play _play;

  @override
  void initState() {
    super.initState();
    _resetGame();
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

  void _resetGame() {
    _play = Play(11); //must be odd: 5, 7, 9, 11 or 13
    _play.nextChip();
  }

  Widget _buildGameBody() {
    return Builder(
      builder: (context) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Hyle 9'),
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
                              Text("Round ${_play.currentRound}"),
                              _buildRoleIndicator(Role.Order, false),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          height: 70 - (_play.dimension.toDouble() * 2), //TODO calc cel lheight and use this
                          child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _play.stock.getChips(),
                              ),
                              itemBuilder: _buildChipStock,
                              itemCount: _play.stock.getChips(),
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
                          child: FilledButton(
                            onPressed: () {
                              if (_play.isGameOver()) {
                                toastError(context, "GAME OVER!");
                              }
                              else if (_play.currentRole == Role.Chaos && !_play.cursor.hasCursor) {
                                toastInfo(context, "Chaos has to place one chip!");
                              }
                              else if (_play.currentRole == Role.Order && !_play.cursor.hasCursor) {
                                //TODO ask to proceed without move
                                toastInfo(context, "Order did not make a move"); //TODO this is not conform to the rules!
                              }
                              else {
                                setState(() {
                                  _play.nextRound();
                                });
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _resetGame();
                              });
                            },
                            child: const Text('Submit move'),
                          ),
                        ),
                      ]),
                ),
              ),
            ));
      }
    );
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
    x = (index / _play.matrix.dimension.x).floor();
    y = (index % _play.matrix.dimension.y);
    return GestureDetector(
      onTap: () {
        _gridItemTapped(context, x, y);
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withAlpha(80), width: 0.5)),
          child: Center(
            child: _buildGridItem(x, y),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int x, int y) {

    var where = Coordinate(x, y);
    final spot = _play.matrix.getSpot(where);
    final chip = spot.content;
    final pointText = spot.point > 0 ? spot.point.toString() : "";

    if (_play.cursor.where == spot.where) {
      return DottedBorder(
        child: _buildChip(chip, pointText, where),
      );
    }
    else if (_play.cursor.startWhere == spot.where) {
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
    return Padding(
      padding: EdgeInsets.all(_play.dimension > 5 ? 3 : 0),
      child: CircleAvatar(
          backgroundColor: chip.color,
          child: Text(text,
              style: TextStyle(
                fontSize: _play.dimension > 7 ? 12 : 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
        ),
    );
  }

  Future<void> _gridItemTapped(BuildContext context, int x, int y) async {

    var coordinate = Coordinate(x, y);
    setState(() {
      if (_play.currentRole == Role.Chaos) {
        if (_play.matrix.isFree(coordinate)) {
          _handleFreeFieldForChaos(context, coordinate);
        }
        else {
          _handleOccupiedFieldForChaos(coordinate, context);
        }
      }
      if (_play.currentRole == Role.Order) {
        if (_play.matrix.isFree(coordinate)) {
          _handleFreeFieldForOrder(context, coordinate);
        }
        else {
          _handleOccupiedFieldForOrder(coordinate, context);
        }
      }
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
      _play.matrix.put(coordinate, currentChip);
      _play.cursor.update(coordinate);
    }
  }

  void _handleOccupiedFieldForChaos(Coordinate coordinate, BuildContext context) {
    final cursor = _play.cursor;
    if (cursor.where != coordinate) {
      toastInfo(context, "You can only remove the current placed chip");
    }
    else {
      _play.matrix.remove(coordinate);
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
        chip = _play.matrix.remove(cursor.where!)!;
      }
      else {
        chip = _play.matrix.remove(cursor.startWhere!)!;
      }
      _play.matrix.put(coordinate, chip);
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

    if (_play.currentChip == entry.chip) {
      return Padding(
        padding: EdgeInsets.all(_play.dimension > 5 ? _play.dimension > 7 ? 0 : 2 : 4),
        child: Container(
            decoration: BoxDecoration(
              color: entry.chip.color.withOpacity(0.9),
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
}