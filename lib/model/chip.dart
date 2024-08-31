import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hyle_9/model/matrix.dart';



class GameChip {
  final String index;
  final Color color;

  GameChip(this.index, this.color);

  Map<String, dynamic> toJson() => {
    'index' : index,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameChip &&
          runtimeType == other.runtimeType &&
          index == other.index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() {
    return 'Chip-$index';
  }

}

enum PlacedBy {User, Ai}
enum Role {Chaos, Order}

class Journal {

  Role role;
  GameChip type;
  Coordinate from;
  Coordinate? to;

  int placedInRound;
  PlacedBy placedBy;

  Journal(this.role, this.type, this.from, this.to, this.placedInRound, this.placedBy);


  Map<String, dynamic> toJson() => {
    'v' : type.index,
  //  'pI' : _placedInRound,
    //'pB' : _placedBy.index,
  };

  @override
  String toString() {
    return 'Journal{role: $role, type: $type, from: $from, to: $to, placedInRound: $placedInRound}';
  }
}