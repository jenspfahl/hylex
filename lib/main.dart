import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyle_9/model/matrix.dart';

import 'model/play.dart';

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
        body: Center(
          child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.all(16),
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
                Text(
                  "Current move ${_play.currentChip} for ${_play.currentRole} (round ${_play.currentRound})",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                      left: 0, top: 20, right: 0, bottom: 0),
                  child: FilledButton(
                    onPressed: () {
                      _resetGame();
                      setState(() {});
                    },
                    child: const Text('Submit move'),
                  ),
                )
              ]),
        ));
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
    if (chip != null) {
      return Padding(
        padding: EdgeInsets.all(_play.dimension > 5 ? 3 : 0),
        child: CircleAvatar(
          backgroundColor: chip.color,
          child: Text(spot.point.toString(),
              style: TextStyle(
                fontSize: _play.dimension > 7 ? 12 : 16,
                color: Colors.white, 
                fontWeight: FontWeight.bold,
              )),
        ),
      );
    }
    else {
      return Container();
    }

  }

  Future<void> _gridItemTapped(BuildContext context, int x, int y) async {

    setState(() {
      if (_play.matrix.isFree(Coordinate(x, y))) {
        final currentChip = _play.currentChip;
        if (currentChip != null) {
          _play.matrix.put(Coordinate(x, y), currentChip);
          if (_play.isGameOver()) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                "Game overs",
                textAlign: TextAlign.center,
              ),
              duration: const Duration(seconds: 2),
            ));
          }
          else {
            _play.nextChip();
            _play.switchRole();
            _play.incRound();
          }
        }
      }
      else {
        _play.matrix.remove(Coordinate(x, y));
        /*ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Not allowed",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
        ));*/
      }
    });



  }
}