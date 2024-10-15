
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hyle_9/model/chip.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';


abstract class Strategy {

  Future<Move> nextMove(Play play, int depth);
}

class MinimaxStrategy extends Strategy {
  @override
  Future<Move> nextMove(Play play, int depth) async {

    final currentRole = play.currentRole;
    final currentChip = play.currentChip;

    final values = SplayTreeMap<int, Move>((a, b) => a.compareTo(b));

    final loadForecast = _predictLoad(currentRole, play.matrix, depth);
    final load = Load(loadForecast);

    await minimax(currentChip, currentRole, play.matrix, depth, load, values);

    debugPrint("Load: $load");
    if (currentRole == Role.Chaos) {
      final value = values.firstKey();
      final move = values[value!]!;
      debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: least valuable move for ${currentRole.name} id $move with a value of $value");
      return move;
    }
    else { // Order
      final value = values.lastKey();
      final move = values[value!]!;
      debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: most valuable move for ${currentRole.name} id $move with a value of $value");
      return move;
    }
  }

  Future<int> minimax(GameChip? currentChip, Role currentRole, Matrix matrix, int depth, Load load, Map<int, Move>? values) async {
    if (_isTerminal(matrix, depth)) {
      return _getValue(matrix);
    }

    int value;
    Role opponentRole;
    if (currentRole == Role.Chaos) { // min
      value = 100000000;
      opponentRole = Role.Order;
    }
    else { // (currentRole == Role.Order) // max
      value = -100000000;
      opponentRole = Role.Chaos;
    }

    final resultPorts = <ReceivePort>[];
    var moves = _getMoves(currentChip, matrix, currentRole);
    for (final move in moves) {
      if (_doInParallel(depth, values)) {
        final resultPort = ReceivePort();
        Isolate.spawn(_tryNextMoveAsync, [resultPort.sendPort, currentChip, opponentRole, matrix, move, depth, load]);
        resultPorts.add(resultPort);
      }
      else {
        int newValue = await _tryNextMove(currentChip, opponentRole, matrix, move, depth, load);
        if (currentRole == Role.Chaos) { // min
          value = min(value, newValue);
        }
        else { // (currentRole == Role.Order) // max
          value = max(value, newValue);
        }
        //debugPrint("  in depth result: $depth: $value $move for $currentRole");
        values?.putIfAbsent(value, () => move);
      }
    }

    if (resultPorts.isNotEmpty) {
      final valuesAndMoves = await Future.wait(resultPorts.map((resultPort) => resultPort.first));
      for (var valueAndMoveAndLoad in valuesAndMoves) {
        int value = valueAndMoveAndLoad[0];
        Move move = valueAndMoveAndLoad[1];
        Load singleLoad = valueAndMoveAndLoad[2];
        load.addProgress(singleLoad.curr);
        //debugPrint("received: $value $move");
        values?.putIfAbsent(value, () => move);
      }
    }

    return value;
  }

  _tryNextMoveAsync(List<dynamic> args) {
    SendPort resultPort = args[0];
    GameChip? currentChip = args[1];
    Role currentRole = args[2];
    Matrix matrix = args[3];
    Move move = args[4];
    int depth = args[5];
    Load load = args[6];

    _tryNextMove(currentChip, currentRole, matrix, move, depth, load).then((newValue) {
      resultPort.send([newValue, move, load]);
    });
  }

  Future<int> _tryNextMove(GameChip? currentChip, Role currentRole, Matrix matrix, Move move, int depth, Load load) async {
    final clonedMatrix = matrix.clone();
    _doMove(currentChip, clonedMatrix, move);
    var newValue = await minimax(currentChip, currentRole, clonedMatrix, depth - 1, load, null);
    if (_isTerminal(matrix, depth - 1)) {
      load.incProgress();
    }
    return newValue;
  }

  bool _isTerminal(Matrix matrix, int depth) {
    return depth == 0 || matrix.noFreeSpace();
  }

  int _getValue(Matrix matrix) {
    return matrix.getTotalPointsForOrder();
  }

  List<Move> _getMoves(GameChip? currentChip, Matrix matrix, Role forRole) {
    if (forRole == Role.Chaos) {
      // Chaos can only place new chips on free spots
      return matrix.streamFreeSpots().map(((spot) => Move.placed(currentChip!, spot.where))).toList();
    }
    else { // (forRole == Role.Order)

      // Order can only move placed chips, try that
      final moves = matrix.streamOccupiedSpots()
          .expand((from) => _getPossibleMovesFor(matrix, from));


      // Try to skip at random position
      final finalMoves = moves.toList();
      int pos = diceInt(finalMoves.length);
      finalMoves.insert(pos, Move.skipped());

      return finalMoves;
    }
  }


  Iterable<Move> _getPossibleMovesFor(Matrix matrix, Spot from) {
    return matrix.getPossibleTargetsFor(from.where)
        .map((to) => Move.moved(from.content!, from.where, to.where));
  }

  _doMove(GameChip? currentChip, Matrix matrix, Move move) {
    if (move.isMove()) {
      final chip = matrix.remove(move.from!);
      matrix.put(move.to!, chip!);
    }
    else if (!move.skipped) { // is placed
      matrix.put(move.from!, currentChip!);
    }
  }

  bool _doInParallel(int depth, Map<int, Move>? values) => depth >= 3 && values != null;

  int _predictLoad(Role role, Matrix matrix, int depth) {
    int value = 0;
    var numberOfPlacedChips = matrix.numberOfPlacedChips();
    final totalCells = matrix.dimension.x * matrix.dimension.y;
    final possibleMaxMoves = (matrix.dimension.x + matrix.dimension.y) - 1; // only -1 to consider skip move

    for (int i = 0; i < depth; i++) {

      if (role == Role.Chaos) {
        final freeCells = totalCells - numberOfPlacedChips;

        final newValue = max(1, freeCells);

        value = max(1, value) * newValue;
        debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, freeCells: $freeCells ==> $newValue");
        numberOfPlacedChips++; // add one for each placed chip by Chaos

        role = Role.Order;
      }
      else {
        final fillRatio = (numberOfPlacedChips - 1) / (totalCells - 1); // ratio based on all cells except current, therefore - 1
        final freeRatio = pow((1 - fillRatio), 2); // trying to determine an avg of moveable free cells
        final avgPossibleMoves = max(1, possibleMaxMoves * freeRatio);
        final avgPossibleMoveCount = numberOfPlacedChips * avgPossibleMoves;
        final newValue = max(1, avgPossibleMoveCount.round());

        value = max(1, value) * newValue;
        debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, avgPossibleMoves: $avgPossibleMoves, freeRatio: $freeRatio ==> $newValue");

        role = Role.Chaos;
      }
    }
    return value;

  }
}



class Move {
  GameChip? chip;
  Coordinate? from;
  Coordinate? to;
  bool skipped = false;

  Move({this.chip, this.from, this.to, required this.skipped});

  Move.placed(GameChip chip, Coordinate where): this(chip: chip, from: where, to: where, skipped: false);
  Move.moved(GameChip chip, Coordinate from, Coordinate to): this(chip: chip, from: from, to: to, skipped: false);
  Move.skipped(): this(skipped: true);

  bool isMove() => !skipped && from != to;


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Move && runtimeType == other.runtimeType &&
              chip == other.chip && from == other.from && to == other.to &&
              skipped == other.skipped;

  @override
  int get hashCode =>
      chip.hashCode ^ from.hashCode ^ to.hashCode ^ skipped.hashCode;

  @override
  String toString() {
    if (skipped) {
      return "-";
    }
    if (isMove()) {
      return "${chip?.id}@$from->$to";
    }
    else {
      return "${chip?.id}@$from";
    }
  }

}

class Load {
  int curr = 0;
  final int max;

  Load(this.max);

  incProgress() {
    curr++;
  }

  addProgress(int val) {
   curr += val;
  }

  double get ratio => curr / max;

  @override
  String toString() {
    return '$curr/$max ($ratio)';
  }

}


