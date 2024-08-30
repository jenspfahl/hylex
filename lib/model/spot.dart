

import 'package:hyle_9/model/play.dart';

import 'chip.dart';
import 'matrix.dart';

enum Direction { North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest }


class Spot {
  Play _play;
  Coordinate _coordinate;
  GameChip? _content;
  
  Spot(this._play, this._coordinate, this._content);

  GameChip? get content => _content;

  Coordinate get where => _coordinate;

  Play get play => _play;

  isFree() => _content == null;

  @override
  String toString() {
    return 'Spot{_coordinate: $_coordinate, _piece: $_content}';
  }

  Iterable<Spot> findFreeNeighbors() {
    return streamNeighbors()  //TODO instead of stream this info, store a bitset about free neighbors when updating pieces to the matrix !!!!
        .where((spot) => spot.isFree());
  }

  Iterable<Spot> findFreeNeighborsInDirection(Direction direction) {
    return streamNeighborsForDirection(direction)
        .where((spot) => spot.isFree());
  }
  
  Iterable<Spot> streamNeighbors() {
    final neighbors = [
      getLeftNeighbor(), 
      getRightNeighbor(),
      getTopNeighbor(),
      getBottomNeighbor(),
      getTopLeftNeighbor(),
      getTopRightNeighbor(),
      getBottomLeftNeighbor(),
      getBottomRightNeighbor(),
    ];
    return neighbors;
  }

  Iterable<Spot> streamNeighborsForDirection(Direction direction) {
    switch (direction) {
      case Direction.East: return [
       // getTopRightNeighbor(),
        getRightNeighbor(),
       // getBottomRightNeighbor()
      ];
      case Direction.West: return [
      //  getTopLeftNeighbor(),
        getLeftNeighbor(),
      //  getBottomLeftNeighbor()
      ];
      case Direction.North: return [
      //  getTopLeftNeighbor(),
        getTopNeighbor(),
      //  getTopRightNeighbor(),
      ];
      case Direction.South: return [
      //  getBottomLeftNeighbor(),
        getBottomNeighbor(),
       // getBottomRightNeighbor()
      ];
      case Direction.NorthEast: return [
       // getTopNeighbor(),
        getTopRightNeighbor(),
      //  getRightNeighbor()
      ];
      case Direction.NorthWest: return [
       // getLeftNeighbor(),
        getTopLeftNeighbor(),
        //getTopNeighbor()
      ];
      case Direction.SouthEast: return [
       // getRightNeighbor(),
        getBottomRightNeighbor(),
       // getBottomNeighbor(),
      ];
      case Direction.SouthWest: return [
      //  getLeftNeighbor(),
        getBottomLeftNeighbor(),
      //  getBottomNeighbor()
      ];
    }
  }
  
  Spot getLeftNeighbor() {
    final left = where.left();
    return Spot(_play, left, _play.matrix.get(left));
  }
    
  Spot getRightNeighbor() {
    final right = where.right();
    return Spot(_play, right, _play.matrix.get(right));
  }
    
  Spot getTopNeighbor() {
    final top = where.top();
    return Spot(_play, top, _play.matrix.get(top));
  }
    
  Spot getBottomNeighbor() {
    final bottom = where.bottom();
    return Spot(_play, bottom, _play.matrix.get(bottom));
  }

  Spot getTopLeftNeighbor() {
    final topLeft = where.top().left();
    return Spot(_play, topLeft, _play.matrix.get(topLeft));
  }
  
  Spot getTopRightNeighbor() {
    final topRight = where.top().right();
    return Spot(_play, topRight, _play.matrix.get(topRight));
  }
  
  Spot getBottomLeftNeighbor() {
    final bottomLeft = where.bottom().left();
    return Spot(_play, bottomLeft, _play.matrix.get(bottomLeft));
  }
  
  Spot getBottomRightNeighbor() {
    final bottomRight = where.bottom().right();
    return Spot(_play, bottomRight, _play.matrix.get(bottomRight));
  }
}
