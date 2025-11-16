


import 'chip.dart';
import 'common.dart';
import 'coordinate.dart';
import 'cursor.dart';


/**
 * A Move is a game move, which can either be a placed chip (initiated by Chaos, set as to) or
 * a move of an already placed chip from a source cell to a free destination cell (initiated by Order).
 * If a chip was not moved (Order skipped to move), the source and the destination are null.
 */
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


  /**
   * A Chaos move
   */
  Move.placed(GameChip chip, Coordinate where): this(chip: chip, from: null, to: where, skipped: false);

  /**
   * An possible Order move
   */
  Move.moved(GameChip chip, Coordinate from, Coordinate to): this(chip: chip, from: from, to: to, skipped: false);

  /**
   * An possible Order move, only for messaging
   */
  Move.movedForMessaging(Coordinate from, Coordinate to): this(chip: null, from: from, to: to, skipped: false);

  /**
   * An possible Order skip-move
   */
  Move.skipped(): this(skipped: true);

  bool isMove() => !skipped && from != to && from != null && to != null;

  bool isPlaced() => chip != null && from == null && to != null && !skipped;

  /**
   * Derives the initiating role from the move according to the game rules.
   */
  Role toRole() {
    if (isPlaced()) {
      return Role.Chaos;
    }
    else {
      return Role.Order;
    }
  }

  /**
   * Derives a Cursor to highlight this move (e.g. the previous opponent move).
   */
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

  String toReadableStringWithChipPlaceholder(PlayerType? playerType) {
    final playerTypeName = playerType == PlayerType.LocalUser
        ? " (${playerType!.getName()})"
        :"";
    if (isPlaced()) {
      return "Chaos$playerTypeName placed {chip} at ${to?.toReadableCoordinates()}";
    }
    else if (isMove()) {
      return "Order$playerTypeName moved {chip} from ${from?.toReadableCoordinates()} to ${to?.toReadableCoordinates()}";
    }
    else {
      return "Order$playerTypeName skipped this move";
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
      return "${chip?.name??"?"}@$from->$to";
    }
    else {
      return "${chip?.name??"?"}@$to";
    }
  }

  bool isFrom(Role role) {
    if (role == Role.Chaos) {
      return isPlaced();
    }
    else {
      return skipped || isMove();
    }
  }

}
