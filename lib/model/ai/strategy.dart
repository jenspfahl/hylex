
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

abstract class OrderStrategy extends Strategy {
  Move? nextMove(Play play);
}

class FlatExpandingStrategy extends OrderStrategy {

  @override
  Move? nextMove(Play play) {
      /*final freeNeighbors = spot
          .findFreeNeighbors()
          .map((e) => e.where);
      if (freeNeighbors.isNotEmpty) {
        final idx = diceInt(freeNeighbors.length);
        return freeNeighbors.toList()[idx];
      }
      else {*/
        return null;
    /*  }*/
  }
}


