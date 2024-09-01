
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
  Coordinate _from;
  Coordinate _to;

  Move(this._from, this._to);
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


