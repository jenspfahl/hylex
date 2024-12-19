import 'dart:collection';

import 'coordinate.dart';
import 'matrix.dart';
import 'move.dart';



class Cursor {
  Coordinate? _start;
  Coordinate? _end;
  final _possibleTargets = HashSet<Coordinate>();

  bool temporary = false;

  Cursor();

  Cursor.fromJson(Map<String, dynamic> map) {

    final startKey = map['start'];
    if (startKey != null) {
      _start = Coordinate.fromKey(startKey);
    }

    final endKey = map['end'];
    if (endKey != null) {
      _end = Coordinate.fromKey(endKey);
    }

    final List<dynamic> targetSet = map['possibleTargets']!;
    _possibleTargets.addAll(targetSet.map((value) {
      return Coordinate.fromKey(value);
    }));

    temporary = map['temporary'] as bool;
  }

  Map<String, dynamic> toJson() => {
    if (start != null) 'start' : _start!.toKey(),
    if (end != null) 'end' : end!.toKey(),
    'possibleTargets' : _possibleTargets.map((value) => value.toKey()).toList(),
    "temporary": temporary
  };


  Coordinate? get end => _end;
  Coordinate? get start => _start;
  HashSet<Coordinate> get possibleTargets => _possibleTargets;

  bool get hasEnd => end != null;
  bool get hasStart => start != null;

  updateEnd(Coordinate where) {
    _end = where;
  }

  updateStart(Coordinate where) {
    _start = where;
  }

  clear({bool keepStart = false}) {
    if (!keepStart) {
      _start = null;
      clearPossibleTargets();
    }
    _end = null;
    temporary = false;
  }


  @override
  String toString() {
    return 'Cursor{_startWhere: $_start, _where: $_end, _possibleTargets: $_possibleTargets}';
  }

  void clearPossibleTargets() {
    _possibleTargets.clear();
  }


  void detectPossibleTargetsFor(Coordinate where, Matrix matrix) {
    clearPossibleTargets();

    _possibleTargets.addAll(matrix.getPossibleTargetsFor(where).map((spot) => spot.where));
  }

  bool isHorizontalMove() => _start != null && _end != null && _start!.y == _end!.y;

  bool isVerticalMove() => _start != null && _end != null && _start!.x == _end!.x;

  void adaptFromMove(Move move) {
    clear();
    if (move.isMove()) {
      updateStart(move.from!);
      updateEnd(move.to!);
    }
    else if (!move.skipped) {
      updateEnd(move.from!);
    }
  }

  bool contains(Coordinate where) => _start == where || _end == where;


}
