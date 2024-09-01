import 'dart:async';
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
    _play = Play(7); //must be odd: 5, 7, 9, 11 or 13
    _play.nextChip();
  }

  Widget _buildGameBody() {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Hyle 9'),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: _buildChipStock()),
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
        ));
  }

  Widget _buildRoleIndicator(Role role, bool isLeftElseRight) {
    final isSelected = _play.currentRole == role;
    return Chip(
      shape: isLeftElseRight
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20),bottomRight: Radius.circular(20)))
          : const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20))),
      label: Text(role.name, style: TextStyle(color: isSelected ? Colors.white : null)),
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

    final spot = _play.matrix.getSpot(Coordinate(x, y));
    final chip = spot.content;
    final pointText = spot.point > 0 ? spot.point.toString() : "";
    if (chip != null) {
      return Padding(
        padding: EdgeInsets.all(_play.dimension > 5 ? 3 : 0),
        child: _buildChip(chip, pointText),
      );
    }
    else {
      return Container();
    }

  }

  CircleAvatar _buildChip(GameChip chip, String text) {
    return CircleAvatar(
        backgroundColor: chip.color,
        child: Text(text,
            style: TextStyle(
              fontSize: _play.dimension > 7 ? 12 : 16,
              color: Colors.white, 
              fontWeight: FontWeight.bold,
            )),
      );
  }

  Future<void> _gridItemTapped(BuildContext context, int x, int y) async {

    setState(() {
      var coordinate = Coordinate(x, y);
      if (_play.matrix.isFree(coordinate)) {
        final currentChip = _play.currentChip;
        if (currentChip != null) {
          if (_play.stock.hasStock(currentChip)) {
            _play.matrix.put(coordinate, currentChip);
          }
          else {
            toastInfo(context, "No more stock for current chip");
          }
        }
        else {
          // should not happen since after submit this is checked
        }
      }
      else {
        _play.matrix.remove(coordinate);


      }
    });



  }

  List<Widget> _buildChipStock() {
    /*if (_play.currentRole != Role.Chaos) {
      return [];
    }*/
    final stockEntries = _play.stock.getStockEntries();
    return stockEntries.map((entry) {
      if (_play.currentChip == entry.chip) {
        return Container(
          decoration: BoxDecoration(
            color: entry.chip.color.withOpacity(0.9),
            borderRadius: const BorderRadius.all(
              Radius.circular(10.0),
            ),
          ),
          child: _buildChip(entry.chip, "${entry.amount}x")
        );
      }
      return _buildChip(entry.chip, "${entry.amount}x");
    }).toList();
  }
}