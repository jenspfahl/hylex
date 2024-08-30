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

class _Hyle9GroundState extends State<Hyle9Ground>
    with SingleTickerProviderStateMixin {
  // The board should be in square shape so we only need one size
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

  List<List<double>> _initEmptyBoard() =>
      List.generate(_play.matrix.dimension.x, (_) => List.filled(_play.matrix.dimension.y, 0));

  void _resetGame() {
    _play = Play();
    _play.nextChip();
  }

  Widget _buildGameBody() {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
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
                   // width: 365,
                    //height: 365,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2.0)),
                    child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _play.matrix.dimension.x,
                        ),
                        itemBuilder: _buildAgentBoardItems,
                        itemCount: _play.matrix.dimension.x * _play.matrix.dimension.y,
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

  Widget _buildAgentBoardItems(BuildContext context, int index) {
    int x, y = 0;
    x = (index / _play.matrix.dimension.x).floor();
    y = (index % _play.matrix.dimension.x);
    return GestureDetector(
      onTap: () {
        _gridItemTapped(context, x, y);
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5)),
          child: Center(
            child: _buildGridItem(x, y, 'agent'),
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int x, int y, String agentOrPlayer) {

    Color gridItemColor;
    final chip = _play.matrix.get(Coordinate(x, y));
    if (chip != null) {
      gridItemColor = chip.color;
    }
    else {
      gridItemColor = Colors.white;
    }


    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: CircleAvatar(
        backgroundColor: gridItemColor,
      ),
    );
  }

  Future<void> _gridItemTapped(BuildContext context, int x, int y) async {

    setState(() {
      if (_play.matrix.isFree(Coordinate(x, y))) {
        _play.matrix.put(Coordinate(x, y), _play.currentChip!);
        _play.nextChip();
        _play.switchRole();
        _play.incRound();
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            "Not allowed",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
        ));
      }
    });



  }
}