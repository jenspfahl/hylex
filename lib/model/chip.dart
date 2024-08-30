import 'dart:ui';

import 'package:hyle_9/model/matrix.dart';



class GameChip {
  final int value;
  final Color color;

  GameChip(this.value, this.color);

  Map<String, dynamic> toJson() => {
    'value' : value,
  };

  @override
  String toString() {
    return 'Chip{value: $value, color: $color}';
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
    'v' : type.value,
  //  'pI' : _placedInRound,
    //'pB' : _placedBy.index,
  };

  @override
  String toString() {
    return 'Journal{role: $role, type: $type, from: $from, to: $to, placedInRound: $placedInRound}';
  }
}