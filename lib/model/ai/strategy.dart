
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:hyle_9/model/chip.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';


abstract class Strategy {
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
        play.cursor.detectPossibleTargetsFor(spot.where, play.matrix);
        for (final possibleTarget in play.cursor.possibleTargets) {

          play.matrix.put(possibleTarget, chip);
          final pointsForOrder = play.matrix.getTotalPointsForOrder();
          possiblePoints.putIfAbsent(
              currentPointsForOrder - pointsForOrder, () => Move.moved(chip, spot.where, possibleTarget));
          play.matrix.remove(possibleTarget);

        }

        play.cursor.clearPossibleTargets();
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
      return "${chip?.id}@$from";
    }
    return "${chip?.id}@$from->$to";
  }

}


