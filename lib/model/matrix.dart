import 'dart:collection';

import 'package:hyle_x/model/spot.dart';
import 'package:hyle_x/model/stock.dart';

import 'chip.dart';
import 'coordinate.dart';
import '../utils/fortune.dart';


class Matrix {

  late final Coordinate _dimension;
  final _chipMap = HashMap<Coordinate, GameChip>();
  final _pointMapX = HashMap<Coordinate, int>();
  final _pointMapY = HashMap<Coordinate, int>();

  Matrix(this._dimension);

  Matrix.fromJson(Map<String, dynamic> map) {
    _dimension = Coordinate.fromKey(map['dimension']!);
    
    final Map<String, dynamic> chipMap = map['chipMap']!;
    _chipMap.addAll(chipMap.map((key, value) {
      final where = Coordinate.fromKey(key);
      final gameChip = GameChip.fromKey(value);
      return MapEntry(where, gameChip);
    }));   
    
    final Map<String, dynamic> pointMapX = map['pointMapX']!;
    _pointMapX.addAll(pointMapX.map((key, value) {
      final where = Coordinate.fromKey(key);
      return MapEntry(where, value);
    }));
        
    final Map<String, dynamic> pointMapY = map['pointMapY']!;
    _pointMapY.addAll(pointMapY.map((key, value) {
      final where = Coordinate.fromKey(key);
      return MapEntry(where, value);
    }));

  }
  
  Map<String, dynamic> toJson() => {
    'dimension' : _dimension.toKey(),
    'chipMap' : _chipMap.map((key, value) => MapEntry(key.toKey(), value.toKey())),
    'pointMapX' : _pointMapX.map((key, value) => MapEntry(key.toKey(), value)),
    'pointMapY' : _pointMapY.map((key, value) => MapEntry(key.toKey(), value)),
  };

  Coordinate get dimension => _dimension;

  GameChip? getChip(Coordinate where) => _chipMap[where];

  int getPoints(Coordinate where) => (_pointMapX[where] ?? 0) + (_pointMapY[where] ?? 0);

  Spot getSpot(Coordinate where) {
    final piece = getChip(where);
    final point = getPoints(where);
    return Spot(this, where, piece, point);
  }

  bool isFree(Coordinate where) {
    final curr = getChip(where);
    return curr == null;
  }


  Set<Spot> detectTraceForPossibleOrderMoves(Coordinate where) {
    final targets = HashSet<Spot>();

    targets.addAll(
        getSpot(where).findFreeNeighborsInDirection(Direction.West));
    targets.addAll(
        getSpot(where).findFreeNeighborsInDirection(Direction.East));
    targets.addAll(
        getSpot(where).findFreeNeighborsInDirection(Direction.North));
    targets.addAll(
        getSpot(where).findFreeNeighborsInDirection(Direction.South));

    return targets;
  }


  put(Coordinate where, GameChip chip, [Stock? stock,  bool calculate = true]) {
    if (!_inDimensions(where, dimension)) {
      return;
    }
    stock?.decStock(chip);

    _chipMap[where] = chip;

    if (calculate) _calcPoints(where);
  }

  GameChip? remove(Coordinate where, [Stock? stock, bool calculate = true]) {
    if (!_inDimensions(where, dimension)) {
      return null;
    }

    final removedChip = _chipMap.remove(where);
    if (removedChip != null) {
      _pointMapX.remove(where);
      _pointMapY.remove(where);

      if (calculate) _calcPoints(where);

      stock?.putBack(removedChip);
    }

    return removedChip;
  }


  void move(Coordinate from, Coordinate to) {
    final chip = remove(from, null, false);
    if (chip != null) {
      put(to, chip, null, false);
      if (from.x == to.x) { // moved vertically
        _calcPointsOnXAxis(from.x);
        _calcPointsOnYAxis(from.y);
        _calcPointsOnYAxis(to.y);
      }
      else if (from.y == to.y) { // moved horizontally
        _calcPointsOnXAxis(from.x);
        _calcPointsOnXAxis(to.x);
        _calcPointsOnYAxis(from.y);
      }
      else {
        _calcPoints(from);
        _calcPoints(to);
      }
    }
  }


  List<Spot> streamOccupiedSpots() {
    final list = _chipMap.entries
        .map((elem) => Spot(this, elem.key, elem.value, getPoints(elem.key)))
        .toList();
    list.shuffle(rnd);
    return list;
  }

  List<Spot> streamFreeSpots() {
    final freeSpots = <Spot>[];
    for (int x = 0; x < _dimension.x; x++) {
      for (int y = 0; y < _dimension.y; y++) {
        final where = Coordinate(x, y);
        if (isFree(where)) {
          freeSpots.add(getSpot(where));
        }
      }
    }
    freeSpots.shuffle(rnd);
    return freeSpots;
  }

  bool isInDimensions(Coordinate where) => _inDimensions(where, dimension);

  bool _inDimensions(Coordinate where, Coordinate dimension) =>
      where.x >= 0 && where.x < dimension.x && where.y >= 0 && where.y < dimension.y;
  

  void _calcPointsOnXAxis(int x) {
    final words = <Word>[];
    var word = Word();
    
    for (int y = 0; y < _dimension.y; y++) {
      var coordinate = Coordinate(x, y);
      _pointMapX[coordinate] = 0;
      final chip = getChip(coordinate);
      if (chip == null && !word.isEmpty()) {
        words.add(word);
        word = Word();
      }
      else if (chip != null) {
        word.add(Letter(chip.name, coordinate));
      }
    }
    if (!word.isEmpty()) {
      words.add(word);
    }

    //debugPrint("X-Words: $words");

    for (var word in words) {
      _findPalindromes(word, _pointMapX);
    }

  }

  void _calcPointsOnYAxis(int y) {
    final words = <Word>[];
    var word = Word();

    for (int x = 0; x < _dimension.x; x++) {
      var coordinate = Coordinate(x, y);
      _pointMapY[coordinate] = 0;
      final chip = getChip(coordinate);
      if (chip == null && !word.isEmpty()) {
        words.add(word);
        word = Word();
      }
      else if (chip != null) {
        word.add(Letter(chip.name, coordinate));
      }
    }
    if (!word.isEmpty()) {
      words.add(word);
    }

    //debugPrint("Y-Words: $words");

    for (var word in words) {
      _findPalindromes(word, _pointMapY);
    }
  }


  void _calcPoints(Coordinate where) {
    _calcPointsOnXAxis(where.x);
    _calcPointsOnYAxis(where.y);
  }


  void _findPalindromes(Word word, Map<Coordinate, int> pointMap) {

    final wordLength = word.length();
    for (int start = 0; start < wordLength - 1; start++ ) {
      for (int end = wordLength; end > 1; end-- ) {
        if (start + 1 < end) {
          final subword = word.subWord(start, end);
          _countIfPalindrome(subword, pointMap);
          //debugPrint("Try find palindrome for $start-$end ($wordLength) => $subword   ---> $isPalindrome");
        }
      }
    }
  }

  _countIfPalindrome(Word word, Map<Coordinate, int> pointMap) {
    if (word.isWordPalindrome()) {
      for (Letter letter in word.letters) {
        final currPoints = pointMap[letter.where];
        pointMap[letter.where] = (currPoints ?? 0) + 1;
      }
    }
  }

  int getTotalPointsForOrder() {
    return
      (_pointMapX.isNotEmpty ? _pointMapX.values.reduce((v, e) => v + e) : 0) +
          (_pointMapY.isNotEmpty ? _pointMapY.values.reduce((v, e) => v + e) : 0);
  }

  int getTotalPointsForChaos() {
    return _chipMap.keys.map((where) => getPoints(where)).where((v) => v == 0).length * getPointsPerChip(dimension.x);
  }

  int getPointsPerChip(int dimension) {
    if (dimension == 5) {
      return 20;
    }
    else if (dimension == 7) {
      return 10;
    }
    else if (dimension == 9) {
      return 5;
    }
    if (dimension == 11) {
      return 2;
    }
    else {
      return 1;
    }
  }

  bool noFreeSpace() => _chipMap.values.length >= dimension.x * dimension.y;

  int numberOfPlacedChips() => _chipMap.length;

  Matrix clone() {
    final clonedMatrix = Matrix(_dimension);
    clonedMatrix._chipMap.addAll(_chipMap);
    clonedMatrix._pointMapX.addAll(_pointMapX);
    clonedMatrix._pointMapY.addAll(_pointMapY);
    return clonedMatrix;
  }

  bool isEmpty() => _chipMap.isEmpty;


}

class Letter {
  final String _value;
  final Coordinate _where;
  
  Letter(this._value, this._where);

  String get value => _value;
  Coordinate get where => _where;

  @override
  String toString() {
    return '$_value@$_where';
  }
}

class Word {
  final List<Letter> _letters = [];

  Word();

  Word.data(List<Letter> letters) {
    _letters.addAll(letters);
  }

  add(Letter pointKey) {
    _letters.add(pointKey);
  }
  
  String toWord() {
    return _letters.map((e) => e.value).join();
  }  
  
  String toReversedWord() => _letters.reversed.map((e) => e.value).join();
  
  bool isWord() => _letters.length >= 2;
  
  bool isWordPalindrome() {
    final length = _letters.length;

    if (length == 2) {
      return _letters[0].value == _letters[1].value;
    }
    else if (length == 3) {
      return _letters[0].value == _letters[2].value;
    }
    else if (length == 4) {
      return _letters[0].value == _letters[3].value && _letters[1].value == _letters[2].value;
    }
    else if (length == 5) {
      return _letters[0].value == _letters[4].value && _letters[1].value == _letters[3].value;
    }
    else if (length >= 6 ) {
      return toWord() == toReversedWord();
    }
    else {
      return false;
    }
  }

  bool isEmpty() => _letters.isEmpty;

  List<Letter> get letters => _letters;

  @override
  String toString() {
    return '"${toWord()}" - ($_letters)';
  }

  int length() => _letters.length;

  Word subWord(int start, int end) {
    return Word.data(_letters.sublist(start, end));
  }

}