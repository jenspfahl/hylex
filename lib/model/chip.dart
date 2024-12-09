import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hyle_x/model/matrix.dart';

import '../utils.dart';



class GameChip {

  late final int id;
  late final String name;
  late final Color color;

  GameChip(this.id) {
    name = String.fromCharCode('a'.codeUnitAt(0) + id);
    color = getColorFromIdx(id);
  }

  factory GameChip.fromKey(String key) {
    final id = int.parse(key);
    return GameChip(id);
  }

  String toKey() => id.toString();


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameChip &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chip-$name';
  }

}
