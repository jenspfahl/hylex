

import 'chip.dart';
import 'coordinate.dart';
import 'cursor.dart';

enum Role {Chaos, Order}

class Move {
  GameChip? chip;
  Coordinate? from;
  Coordinate? to;
  bool skipped = false;

  Move({this.chip, this.from, this.to, required this.skipped});

  Move.fromJson(Map<String, dynamic> map) {
    final chipKey = map['chip'];
    if (chipKey != null) {
      chip = GameChip.fromKey(chipKey);
    }

    final fromKey = map['from'];
    if (fromKey != null) {
      from = Coordinate.fromKey(fromKey);
    }

    final toKey = map['to'];
    if (toKey != null) {
      to = Coordinate.fromKey(toKey);
    }


    skipped = map['skipped'] as bool;
  }

  Map<String, dynamic> toJson() => {
    if (chip != null) 'chip' : chip!.toKey(),
    if (from != null) 'from' : from!.toKey(),
    if (to != null) 'to' : to!.toKey(),
    'skipped' : skipped
  };

  Move.placed(GameChip chip, Coordinate where): this(chip: chip, from: where, to: where, skipped: false);
  Move.moved(GameChip chip, Coordinate from, Coordinate to): this(chip: chip, from: from, to: to, skipped: false);
  Move.skipped(): this(skipped: true);

  bool isMove() => !skipped && from != to && from != null && to != null;

  Role getRole() {
    if (isPlaced()) {
      return Role.Chaos;
    }
    else {
      return Role.Order;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Move && runtimeType == other.runtimeType &&
              chip == other.chip && from == other.from && to == other.to &&
              skipped == other.skipped;

  @override
  int get hashCode =>
      chip.hashCode ^ from.hashCode ^ to.hashCode ^ skipped.hashCode;

  @override
  String toString() {
    if (skipped) {
      return "-";
    }
    if (isMove()) {
      return "${chip?.name}@$from->$to";
    }
    else {
      return "${chip?.name}@$from";
    }
  }

  bool isPlaced() => !isMove() && !skipped;

  Cursor toCursor() {
    final cursor = Cursor();
    if (from != null) {
      cursor.updateStart(from!);
    }
    if (to != null) {
      cursor.updateEnd(to!);
    }
    return cursor;
  }

  String toReadableStringWithChipPlaceholder() { //TODO duplicate
    if (isPlaced()) {
      return "Chaos placed {chip} at ${to?.toReadableCoordinates()}";
    }
    else if (isMove()) {
      return "Order moved {chip} from ${from?.toReadableCoordinates()} to ${to?.toReadableCoordinates()}";
    }
    else {
      return "Order skipped this move";
    }
  }

}
