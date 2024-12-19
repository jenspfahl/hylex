
enum Direction { North, NorthEast, East, SouthEast, South, SouthWest, West, NorthWest }

class Coordinate {
  final int x;
  final int y;

  Coordinate(this.x, this.y);

  Coordinate.fromKey(String key)
      : this(int.parse(key.split("/").first), int.parse(key.split("/").last));

  String toKey() => "$x/$y";

  Coordinate left() => Coordinate(x - 1, y);

  Coordinate right() => Coordinate(x + 1, y);

  Coordinate top() => Coordinate(x, y - 1);

  Coordinate bottom() => Coordinate(x, y + 1);

  Coordinate getNeighbor(Direction direction) {
    switch (direction) {
      case Direction.North: return top();
      case Direction.South: return bottom();
      case Direction.East: return right();
      case Direction.West: return left();
      case Direction.NorthEast: return top().right();
      case Direction.NorthWest: return top().left();
      case Direction.SouthEast: return bottom().right();
      case Direction.SouthWest: return bottom().left();
    }
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() {
    return '{$x,$y}';
  }

  String toReadableCoordinates() {
    final x2 = String.fromCharCode('A'.codeUnitAt(0) + x);
    final y2 = y + 1;
    return '$x2$y2';
  }


}
