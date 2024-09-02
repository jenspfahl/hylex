

import 'dart:collection';

import 'package:hyle_9/model/play.dart';

import 'chip.dart';
import 'matrix.dart';

enum Direction { North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest }


class Spot {
  Play _play;
  Coordinate _coordinate;
  GameChip? _content;
  int _point;

  Spot(this._play, this._coordinate, this._content, this._point);

  GameChip? get content => _content;

  int get point => _point;

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
    final spots = HashSet<Spot>();
    _streamNeighborsForDirection(direction, spots);
    return spots;
  }

  _streamNeighborsForDirection(Direction direction, Set<Spot> spots) {
    Spot? spot;
    switch (direction) {
      case Direction.East:
        spot = getRightNeighbor();
        break;
      case Direction.West:
        spot = getLeftNeighbor();
        break;
      case Direction.North:
        spot = getTopNeighbor();
        break;
      case Direction.South:
        spot = getBottomNeighbor();
        break;
      case Direction.NorthEast:
        spot = getTopRightNeighbor();
        break;
      case Direction.NorthWest:
        spot = getTopLeftNeighbor();
        break;
      case Direction.SouthEast:
        spot = getBottomRightNeighbor();
        break;
      case Direction.SouthWest:
        spot = getBottomLeftNeighbor();
        break;
    }
    if (spot.content == null && spot.isInMatrixDimensions()) {
      spots.add(spot);
      spot._streamNeighborsForDirection(direction, spots);
    }
    else {
      return spots;
    }

  }
  
  Spot getLeftNeighbor() {
    final left = where.left();
    return Spot(_play, left, _play.matrix.getChip(left), _play.matrix.getPoint(left));
  }
    
  Spot getRightNeighbor() {
    final right = where.right();
    return Spot(_play, right, _play.matrix.getChip(right), _play.matrix.getPoint(right));
  }
    
  Spot getTopNeighbor() {
    final top = where.top();
    return Spot(_play, top, _play.matrix.getChip(top), _play.matrix.getPoint(top));
  }
    
  Spot getBottomNeighbor() {
    final bottom = where.bottom();
    return Spot(_play, bottom, _play.matrix.getChip(bottom), _play.matrix.getPoint(bottom));
  }

  Spot getTopLeftNeighbor() {
    final topLeft = where.top().left();
    return Spot(_play, topLeft, _play.matrix.getChip(topLeft), _play.matrix.getPoint(topLeft));
  }
  
  Spot getTopRightNeighbor() {
    final topRight = where.top().right();
    return Spot(_play, topRight, _play.matrix.getChip(topRight), _play.matrix.getPoint(topRight));
  }
  
  Spot getBottomLeftNeighbor() {
    final bottomLeft = where.bottom().left();
    return Spot(_play, bottomLeft, _play.matrix.getChip(bottomLeft), _play.matrix.getPoint(bottomLeft));
  }
  
  Spot getBottomRightNeighbor() {
    final bottomRight = where.bottom().right();
    return Spot(_play, bottomRight, _play.matrix.getChip(bottomRight), _play.matrix.getPoint(bottomRight));
  }

  bool isInMatrixDimensions() => _play.matrix.isInDimensions(where);
}
