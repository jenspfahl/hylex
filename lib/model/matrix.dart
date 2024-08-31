import 'dart:collection';
import 'dart:math';

import 'package:flutter/cupertino.dart';
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
    return '{$x,$y}';
  }

}

class Matrix {

  late final Coordinate _dimension;
  final Play _play;
  final _chipMap = HashMap<Coordinate, GameChip>();
  final _pointMapX = HashMap<Coordinate, int>();
  final _pointMapY = HashMap<Coordinate, int>();

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

  GameChip? getChip(Coordinate where) => _chipMap[where];
  int getPoint(Coordinate where) => (_pointMapX[where] ?? 0) + (_pointMapY[where] ?? 0);

  Spot getSpot(Coordinate where) {
    final piece = getChip(where);
    final point = getPoint(where);
    return Spot(_play, where, piece, point);
  }

  bool isFree(Coordinate where) {
    final curr = getChip(where);
    return curr == null;
  }

  put(Coordinate where, GameChip piece) {
    if (!_inDimensions(where, dimension)) {
      return;
    }

    remove(where);
    _chipMap[where] = piece;

    _calcPoints(where);

    //_play.stats.in(piece.type);


    //debugPrint("mx: put piece $piece");
  }

  GameChip? remove(Coordinate where) {
    final removedPiece = _chipMap.remove(where);
    if (removedPiece != null) {

    //  _play.stats.decPoints(removedPiece.type);

    }
    //debugPrint("mx: rm piece $removedPiece");

    _pointMapX.remove(where);
    _pointMapY.remove(where);
    _calcPoints(where);

    return removedPiece;
  }

  bool _inDimensions(Coordinate where, Coordinate dimension) =>
      where.x >= 0 && where.x < dimension.x && where.y >= 0 && where.y < dimension.y;


  Map<String, dynamic> toJson() => {
    'dimension' : _dimension,
    'map' : _chipMap.map((key, value) => MapEntry(key.toJsonKey(), value)),
    // shards can be derived from map during deserialization
  };

  void _calcPoints(Coordinate where) {
    final words = <Word>[];
    var word = Word();
    
    // on x-axis
    final x = where.x;
    for (int y = 0; y < _dimension.y; y++) {
      var coordinate = Coordinate(x, y);
      _pointMapX.remove(coordinate);
      final chip = getChip(coordinate);
      if (chip == null && !word.isEmpty()) {
        words.add(word);
        word = Word();
      }
      else if (chip != null) {
        word.add(PointKey(Coordinate(x, y), chip.index));
      }
    }
    if (!word.isEmpty()) {
      words.add(word);
    }

    debugPrint("X-Words: $words");

    for (var word in words) {
      _findPalindromes(word, _pointMapX);
    }

    words.clear();

    // on y-axis
    final y = where.y;
    for (int x = 0; x < _dimension.x; x++) {
      var coordinate = Coordinate(x, y);
      _pointMapY.remove(coordinate);
      final chip = getChip(coordinate);
      if (chip == null && !word.isEmpty()) {
        words.add(word);
        word = Word();
      }
      else if (chip != null) {
        word.add(PointKey(Coordinate(x, y), chip.index));
      }
    }
    if (!word.isEmpty()) {
      words.add(word);
    }

    debugPrint("Y-Words: $words");

    for (var word in words) {
      _findPalindromes(word, _pointMapY);
    }
  }

  void _findPalindromes(Word word, Map<Coordinate, int> pointMap) {

    final wordLength = word.length();
    for (int start = 0; start < wordLength - 1; start++ ) {
      for (int end = wordLength; end > 1; end-- ) {
        if (start + 1 < end) {
          var subword = word.subword(start, end);
          final isPalindrome = _findPalindrome(subword, pointMap);
          debugPrint("Try find palindrome for $start-$end ($wordLength) => $subword   ---> $isPalindrome");

        }
      }
    }
  }

  bool _findPalindrome(Word word, Map<Coordinate, int> pointMap) {
    if (word.isWordPalindrome()) {
      for (PointKey pointKey in word.pointKeys) {
        final currPoints = pointMap[pointKey.where];
        pointMap[pointKey.where] = (currPoints ?? 0) + 1;
      }
      return true;
    }
    return false;
  }
  


}

class PointKey {
  final Coordinate _where;
  final String _index;
  
  PointKey(this._where, this._index);

  String get index => _index;
  Coordinate get where => _where;

  @override
  String toString() {
    return '$_index@$_where';
  }
}

class Word {
  final List<PointKey> _pointKeys = [];

  Word();

  Word.data(List<PointKey> pKs) {
    _pointKeys.addAll(pKs);
  }

  add(PointKey pointKey) {
    _pointKeys.add(pointKey);
  }
  
  String toWord() {
    return _pointKeys.map((e) => e.index).join();
  }  
  
  String toReversedWord() => _pointKeys.reversed.map((e) => e.index).join();
  
  bool isWord() => _pointKeys.length >= 2;
  
  bool isWordPalindrome() => isWord() && toWord() == toReversedWord();

  bool isEmpty() => _pointKeys.isEmpty;

  List<PointKey> get pointKeys => _pointKeys;

  @override
  String toString() {
    return '"${toWord()}" - ($_pointKeys)';
  }

  int length() => _pointKeys.length;

  Word subword(int start, int end) {
    return Word.data(_pointKeys.sublist(start, end));
  }


}