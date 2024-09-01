import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hyle_9/model/matrix.dart';



class GameChip {
  final String id;
  final Color color;

  GameChip(this.id, this.color);

  Map<String, dynamic> toJson() => {
    'id' : id,
  };

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
    return 'Chip-$id';
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
    'v' : type.id,
  //  'pI' : _placedInRound,
    //'pB' : _placedBy.index,
  };

  @override
  String toString() {
    return 'Journal{role: $role, type: $type, from: $from, to: $to, placedInRound: $placedInRound}';
  }
}