
import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hyle_9/model/chip.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';


abstract class Strategy {

}

class LookAheadForChaosStrategy extends Strategy {

  Move nextMove(Play play, int depth) {
    final currentChip = play.currentChip;
    final currentRole = play.currentRole;
    if (currentRole != Role.Chaos) {
      throw Exception("Not Chaos' move!");
    }
    if (currentChip == null) {
      throw Exception("No current chip to place!");
    }
    if (play.isGameOver()) {
      throw Exception("Game is over!");
    }

    final currentOrderReward = play.matrix.getTotalPointsForOrder();

    // collect reward points for Order and sort points ascending
    final orderRewards = SplayTreeMap<int, List<Move>>((a, b) => a.compareTo(b));

    tryNextMoves(play.matrix, currentChip, orderRewards, currentRole, depth, []);

    // decide for least points for Order
    final leastPoints = orderRewards.entries.first;
    debugPrint("AI: most beneficial next move for Chaos: ${leastPoints.value.first} (curr $currentOrderReward, most ${leastPoints.key}) - ${leastPoints.value}");
    return leastPoints.value.first;

  }

}

class MinimaxStrategy extends Strategy {
  Move nextMove(Play play, int depth) {

    final currentRole = play.currentRole;
    final currentChip = play.currentChip;

    final values = SplayTreeMap<int, Move>((a, b) => a.compareTo(b));

    minimax(currentChip, currentRole, play.matrix, depth, values);

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

  int minimax(GameChip? currentChip, Role currentRole, Matrix matrix, int depth, Map<int, Move>? values) {
    if (_isTerminal(matrix, depth)) {
      return _getValue(matrix);
    }

    int value = 0;
    if (currentRole == Role.Chaos) { // min
      value = 100000000;
      for (final move in _getMoves(currentChip, matrix, currentRole)) {
        _doMove(currentChip, matrix, move);
        var newValue = minimax(currentChip, Role.Order, matrix, depth - 1, null);
        _undoMove(currentChip, matrix, move);
        value = min(value, newValue);
        values?.putIfAbsent(value, () => move);
      }
    }
    else { //  (currentRole == Role.Order) // max
      value = -100000000;
      for (final move in _getMoves(currentChip, matrix, currentRole)) {
        _doMove(currentChip, matrix, move);
        var newValue = minimax(currentChip, Role.Chaos, matrix, depth - 1, null);
        _undoMove(currentChip, matrix, move);
        value = max(value, newValue);
        values?.putIfAbsent(value, () => move);
      }
    }

    return value;
  }

  bool _isTerminal(Matrix matrix, int depth) {
    return depth == 0 || matrix.noFreeSpace();
  }

  int _getValue(Matrix matrix) {
    return matrix.getTotalPointsForOrder();
  }

  Iterable<Move> _getMoves(GameChip? currentChip, Matrix matrix, Role forRole) {
    if (forRole == Role.Chaos) {
      // Chaos can only place new chips on free spots
      return matrix.streamFreeSpots().map(((spot) => Move.placed(currentChip!, spot.where)));
    }
    else { // (forRole == Role.Order)

      // Order can only move placed chips, try that
      final moves = <Move>[];
      for (final spot in matrix.streamOccupiedSpots()) {
        final chip = spot.content;
        if (chip != null) {
          matrix.getPossibleTargetsFor(spot.where).forEach((possibleTarget) {
            final move = Move.moved(chip, spot.where, possibleTarget);
            moves.add(move);
          });
        }
      }
      // Try to skip
      moves.add(Move.skipped());
      moves.shuffle();
      return moves;
    }
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
  _undoMove(GameChip? currentChip, Matrix matrix, Move move) {

    if (move.isMove()) {
      final chip = matrix.remove(move.to!);
      matrix.put(move.from!, chip!);
    }
    else if (!move.skipped) { // is placed
      matrix.remove(move.from!);
    }
    
  }
}

class LookAheadForOrderStrategy extends Strategy {

  Move nextMove(Play play, int depth) {
    final currentChip = play.currentChip;
    final currentRole = play.currentRole;
    if (currentRole != Role.Order) {
      throw Exception("Not Order's move!");
    }
    if (currentChip == null) {
      throw Exception("No current chip to place!");
    }
    if (play.isGameOver()) {
      throw Exception("Game is over!");
    }

    final currentOrderReward = play.matrix.getTotalPointsForOrder();

    // collect reward points for current role and sort points ascending
    final orderRewards = SplayTreeMap<int, List<Move>>((a, b) => a.compareTo(b));

    tryNextMoves(play.matrix, currentChip, orderRewards, currentRole, depth, []);


    // decide for most points for Order
    final mostPoints = orderRewards.entries.last;

    // check whether any move is beneficial
    if (mostPoints.key > currentOrderReward) {
      debugPrint("AI: most beneficial next move for Order: ${mostPoints.value.first} (curr $currentOrderReward, most ${mostPoints.key}) - ${mostPoints.value}");
      return mostPoints.value.first;
    }
    else {
      // if not, just skip
      debugPrint("AI: no beneficial next move for Order, skipping (curr $currentOrderReward, most ${mostPoints.key})");
      return Move.skipped();
    }

  }
}

void tryNextMoves(Matrix matrix, GameChip currentChip, SplayTreeMap<int, List<Move>> orderRewards, Role forRole, int depth, List<Move> moves) {

  if (depth == 0) {
    // add reward when end of path reached
    collectReward(matrix, orderRewards, forRole, depth, moves);
    return;
  }

  if (forRole == Role.Chaos) {
    // Chaos can only place new chips on free spots
    var freeSpots = matrix.streamFreeSpots();
    if (freeSpots.isEmpty) {
      collectReward(matrix, orderRewards, forRole, depth, moves);
      return;
    }
    for (final spot in freeSpots) {

      matrix.put(spot.where, currentChip);

      final newMoves = List<Move>.from(moves);
      final move = Move.placed(currentChip, spot.where);
      newMoves.add(move);

      // debugPrint("AI: try move $move for $forRole ($depth) : $moves");

      // simulate all possible next steps which is Order
      tryNextMoves(matrix, currentChip, orderRewards, Role.Order, depth - 1, newMoves);

      matrix.remove(spot.where);
    }
  }
  else if (forRole == Role.Order) {

    // Order can only move placed chips, try that
    var occupiedSpots = matrix.streamOccupiedSpots();
    if (occupiedSpots.isEmpty) {
      collectReward(matrix, orderRewards, forRole, depth, moves);
      return;
    }
    for (final spot in occupiedSpots) {
      final chip = matrix.remove(spot.where);
      if (chip != null) {

        matrix.getPossibleTargetsFor(spot.where).forEach((possibleTarget) {
          matrix.put(possibleTarget, chip);

          final newMoves = List<Move>.from(moves);
          final move = Move.moved(chip, spot.where, possibleTarget);
          newMoves.add(move);

          // debugPrint("AI: try move $move for $forRole ($depth) : $moves");

          // simulate all possible next steps which is Chaos
          tryNextMoves(matrix, currentChip, orderRewards, Role.Chaos, depth - 1, newMoves);

          matrix.remove(possibleTarget);
        });

        matrix.put(spot.where, chip);
      }
    }

    // Try to skip
    final newMoves = List<Move>.from(moves);
    final move = Move.skipped();
    newMoves.add(move);

    // debugPrint("AI: try skip move $move for $forRole ($depth) : $moves");

    // simulate all possible next steps which is Chaos
    tryNextMoves(matrix, currentChip, orderRewards, Role.Chaos, depth - 1, newMoves);

  }
}

void collectReward(Matrix matrix, SplayTreeMap<int, List<Move>> orderRewards, Role forRole, int depth, List<Move> moves) {
  final orderReward = matrix.getTotalPointsForOrder();
  orderRewards.putIfAbsent(orderReward, () {
    debugPrint("AI: add reward $orderReward for $forRole ($depth) : $moves");
    return moves;
  });
}



abstract class ChaosStrategy extends Strategy {
  Coordinate? placeChip(Play play);
}

class RandomFreeSpotStrategy extends ChaosStrategy {

  @override
  Coordinate? placeChip(Play play) {
    final x = diceInt(play.matrix.dimension.x);
    final y = diceInt(play.matrix.dimension.y);
    final where = Coordinate(x, y);
    if (play.matrix.isFree(where)) {
      return where;
    }
    else {
      return null;
    }
  }
}

class FindMostValuableSpotStrategy extends ChaosStrategy {

  @override
  Coordinate? placeChip(Play play) {

    final currentChip = play.currentChip;
    if (currentChip == null) {
      return null;
    }

    final currentPointsForOrder = play.stats.getPoints(Role.Order);

    // collect
    final possiblePoints = SplayTreeMap<int, Coordinate>((a, b) => a.compareTo(b));
    play.matrix.streamFreeSpots().forEach((spot) {
      play.matrix.put(spot.where, currentChip);
      final pointsForOrder = play.matrix.getTotalPointsForOrder();
      //debugPrint("currentPointsForOrder=$currentPointsForOrder points=$pointsForOrder --> ${currentPointsForOrder - pointsForOrder}");
      possiblePoints.putIfAbsent(currentPointsForOrder - pointsForOrder, () => spot.where);
      play.matrix.remove(spot.where);
    });

    //debugPrint("ordered" + possiblePoints.toString());
    // decide
    final lessPoints = possiblePoints.entries.lastOrNull;
    if (lessPoints != null) {
      return lessPoints.value;
    }
    return null;
  }
}

abstract class OrderStrategy extends Strategy {
  Move? nextMove(Play play);
}

class FindMostValuableMoveStrategy extends OrderStrategy {

  @override
  Move? nextMove(Play play) {

    final currentPointsForOrder = play.stats.getPoints(Role.Order);

    // collect
    final possiblePoints = SplayTreeMap<int, Move>((a, b) => a.compareTo(b));
    play.matrix.streamOccupiedSpots().forEach((spot) {

      final chip = play.matrix.remove(spot.where);
      if (chip != null) {

        play.matrix.getPossibleTargetsFor(spot.where).forEach((possibleTarget) {
          play.matrix.put(possibleTarget, chip);
          final pointsForOrder = play.matrix.getTotalPointsForOrder();
          possiblePoints.putIfAbsent(
              currentPointsForOrder - pointsForOrder, () => Move.moved(chip, spot.where, possibleTarget));
          play.matrix.remove(possibleTarget);
        });

        play.matrix.put(spot.where, chip);
      }

    });

    // decide
    final mostPoints = possiblePoints.entries.firstOrNull;
    if (mostPoints != null) {
      return mostPoints.value;
    }
    return null;
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


