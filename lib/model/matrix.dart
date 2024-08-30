import 'dart:collection';

import 'package:hyle_9/model/play.dart';
import 'package:hyle_9/model/spot.dart';

import 'chip.dart';



class Coordinate {
  final int x;
  final int y;

  Coordinate(this.x, this.y);

  Coordinate.fromJsonMap(Map<String, dynamic> map)
      : this(map["x"] as int, map["y"] as int);

  Coordinate.fromJsonKey(String key)
      : this(int.parse(key.split("/").first), int.parse(key.split("/").last));

  Coordinate left() => Coordinate(x - 1, y);

  Coordinate right() => Coordinate(x + 1, y);

  Coordinate top() => Coordinate(x, y - 1);

  Coordinate bottom() => Coordinate(x, y + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Map<String, dynamic> toJson() => {
    'x' : x,
    'y' : y,
  };

  String toJsonKey() => "$x/$y";

  @override
  String toString() {
    return 'Coordinates{x: $x, y: $y}';
  }

}

class Matrix {

  late final Coordinate _dimension;
  final Play _play;
  final _map = HashMap<Coordinate, GameChip>();

  Matrix(this._dimension, this._play);

  Matrix.fromJsonMap(Map<String, dynamic> map, this._play) {
    _dimension = Coordinate.fromJsonMap(map['dimension']!);

/*
    final Map<String,dynamic> mapMap = map['map']!;
    _map.addAll(mapMap.map((key, value) {
      final where = Coordinate.fromJsonKey(key);
      final Map<String, dynamic> pieceMap = value;
      final String typeId = pieceMap["id"];
      final pieceType = PieceType.fromId(typeId);
      if (pieceType is CellType) {
        final cell = Cell.fromJsonMap(pieceMap);
        return MapEntry(where, cell);
      }
      else if (pieceType is ResourceType) {
        final resource = Resource.fromJsonMap(pieceMap);
        return MapEntry(where, resource);
      }
      else {
        throw Exception("Unsupported type $pieceType");
      }
    }));
    */
  }

  Coordinate get dimension => _dimension;

  GameChip? get(Coordinate where) => _map[where];

  Spot getSpot(Coordinate where) {
    final piece = get(where);
    return Spot(_play, where, piece);
  }

  bool isFree(Coordinate where) {
    final curr = get(where);
    return curr == null;
  }

  put(Coordinate where, GameChip piece) {
    if (!_inDimensions(where, dimension)) {
      return;
    }

    remove(where);
    _map[where] = piece;

    //_play.stats.in(piece.type);


    //debugPrint("mx: put piece $piece");
  }

  GameChip? remove(Coordinate where) {
    final removedPiece = _map.remove(where);
    if (removedPiece != null) {

      //_play.stats.decPieces(removedPiece.type);

    }
    //debugPrint("mx: rm piece $removedPiece");

    return removedPiece;
  }

  bool _inDimensions(Coordinate where, Coordinate dimension) =>
      where.x >= 0 && where.x < dimension.x && where.y >= 0 && where.y < dimension.y;


  Map<String, dynamic> toJson() => {
    'dimension' : _dimension,
    'map' : _map.map((key, value) => MapEntry(key.toJsonKey(), value)),
    // shards can be derived from map during deserialization
  };


}