
import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';


abstract class Strategy {
}

abstract class ChaosStrategy extends Strategy {
  Coordinate? getFreePlace(Play play);
}

class RandomFreeSpotStrategy extends ChaosStrategy {

  @override
  Coordinate? getFreePlace(Play play) {
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



abstract class OrderStrategy extends Strategy {
  Coordinate? getFreePlace(Spot fromSpot);
}

class FlatExpandingStrategy extends OrderStrategy {

  @override
  Coordinate? getFreePlace(Spot spot) {
      final freeNeighbors = spot
          .findFreeNeighbors()
          .map((e) => e.where);
      if (freeNeighbors.isNotEmpty) {
        final idx = diceInt(freeNeighbors.length);
        return freeNeighbors.toList()[idx];
      }
      else {
        return null;
      }
  }
}


class SurroundOtherStrategy extends OrderStrategy {
  
  final List<String> _toSurround;

  SurroundOtherStrategy(this._toSurround);

  @override
  Coordinate? getFreePlace(Spot spot) {
    final freeNeighborsCloseToToSurrounded = spot.findFreeNeighbors()
      .where((freeNeighbor) => _hasNeighborOfType(freeNeighbor, _toSurround))
      .map((e) => e.where);
    if (freeNeighborsCloseToToSurrounded.isNotEmpty) {
      final idx = diceInt(freeNeighborsCloseToToSurrounded.length);
      return freeNeighborsCloseToToSurrounded.toList()[idx];
    }
    else {
      return null;
    }
  }

  bool _hasNeighborOfType(Spot spot, List<String> typeIds) {
    return spot
      .streamNeighbors()
      .where((neighbor) => neighbor.content != null && typeIds.contains(neighbor.content!.index))
      .isNotEmpty;
  }
}
