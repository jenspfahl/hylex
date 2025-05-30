import 'dart:collection';

import 'coordinate.dart';
import 'matrix.dart';
import 'move.dart';


/**
 * A cursor is a visual element to highlight a selected cell (the end) or a move (start and end).
 * It can additionally highlight a trace, e.g. to point out possible moves (trace).
 */
class Cursor {
  Coordinate? _start;
  Coordinate? _end;

  final _trace = HashSet<Coordinate>();

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

    final List<dynamic> targetSet = map['trace']!;
    _trace.addAll(targetSet.map((value) {
      return Coordinate.fromKey(value);
    }));

  }

  Map<String, dynamic> toJson() => {
    if (start != null) 'start' : _start!.toKey(),
    if (end != null) 'end' : end!.toKey(),
    'trace' : _trace.map((value) => value.toKey()).toList(),
  };


  Coordinate? get end => _end;
  Coordinate? get start => _start;
  HashSet<Coordinate> get trace => _trace;

  bool get hasEnd => end != null;
  bool get hasStart => start != null;

  updateEnd(Coordinate where) {
    _end = where;
  }

  updateStart(Coordinate where) {
    _start = where;
  }

  clear() {
    _start = null;
    _end = null;
    clearTrace();
  }


  @override
  String toString() {
    return 'Cursor{start: $_start, end: $_end, trace: $_trace}';
  }

  void clearTrace() {
    _trace.clear();
  }

  void detectTraceForOrderMove(Coordinate where, Matrix matrix) {
    clearTrace();

    _trace.addAll(matrix.detectTraceForOrderMove(where).map((spot) => spot.where));
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
