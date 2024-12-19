import 'dart:collection';

import 'chip.dart';
import 'coordinate.dart';
import 'matrix.dart';


class Spot {
  Matrix _matrix;
  Coordinate _coordinate;
  GameChip? _content;
  int _point;

  Spot(this._matrix, this._coordinate, this._content, this._point);

  GameChip? get content => _content;

  int get point => _point;

  Coordinate get where => _coordinate;

  Matrix get matrix => _matrix;

  bool isFree() => _content == null;

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
    return neighbors.whereType<Spot>(); // filter out null Spots
  }

  Iterable<Spot> streamNeighborsForDirection(Direction direction) {
    final spots = HashSet<Spot>();
    _streamNeighborsForDirection(direction, spots);
    return spots;
  }

  _streamNeighborsForDirection(Direction direction, Set<Spot> spots) {
    final spot = getNeighbor(direction);
    if (spot != null && spot.content == null && spot.isInMatrixDimensions()) {
      spots.add(spot);
      spot._streamNeighborsForDirection(direction, spots);
    }
  }

  Spot? getNeighbor(Direction direction) {
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
    return spot;
  }
  
  Spot? getLeftNeighbor() {
    final left = where.left();
    if (!_matrix.isInDimensions(left)) {
      return null;
    }
    return Spot(_matrix, left, _matrix.getChip(left), _matrix.getPoint(left));
  }
    
  Spot? getRightNeighbor() {
    final right = where.right();
    if (!_matrix.isInDimensions(right)) {
      return null;
    }
    return Spot(_matrix, right, _matrix.getChip(right), _matrix.getPoint(right));
  }
  
  Spot? getTopNeighbor() {
    final top = where.top();
    if (!_matrix.isInDimensions(top)) {
      return null;
    }
    return Spot(_matrix, top, _matrix.getChip(top), _matrix.getPoint(top));
  }
    
  Spot? getBottomNeighbor() {
    final bottom = where.bottom();
    if (!_matrix.isInDimensions(bottom)) {
      return null;
    }
    return Spot(_matrix, bottom, _matrix.getChip(bottom), _matrix.getPoint(bottom));
  }

  Spot? getTopLeftNeighbor() {
    final topLeft = where.top().left();
    if (!_matrix.isInDimensions(topLeft)) {
      return null;
    }
    return Spot(_matrix, topLeft, _matrix.getChip(topLeft), _matrix.getPoint(topLeft));
  }
  
  Spot? getTopRightNeighbor() {
    final topRight = where.top().right();
    if (!_matrix.isInDimensions(topRight)) {
      return null;
    }
    return Spot(_matrix, topRight, _matrix.getChip(topRight), _matrix.getPoint(topRight));
  }
  
  Spot? getBottomLeftNeighbor() {
    final bottomLeft = where.bottom().left();
    if (!_matrix.isInDimensions(bottomLeft)) {
      return null;
    }
    return Spot(_matrix, bottomLeft, _matrix.getChip(bottomLeft), _matrix.getPoint(bottomLeft));
  }
  
  Spot? getBottomRightNeighbor() {
    final bottomRight = where.bottom().right();
    if (!_matrix.isInDimensions(bottomRight)) {
      return null;
    }
    return Spot(_matrix, bottomRight, _matrix.getChip(bottomRight), _matrix.getPoint(bottomRight));
  }

  bool isInMatrixDimensions() => _matrix.isInDimensions(where);
}
