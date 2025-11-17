
import 'package:flutter_translate/flutter_translate.dart';

class GameChip {

  late final int id;
  late final String name;

  GameChip(this.id) {
    name = String.fromCharCode('a'.codeUnitAt(0) + id);
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

  String _getChipI18nKey() {
    switch(id) {
      case 0: return "red";
      case 1: return "yellow";
      case 2: return "green";
      case 3: return "cyan";
      case 4: return "blue";
      case 5: return "pink";
      case 6: return "grey";
      case 7: return "brown";
      case 8: return "olive";
      case 9: return "moss";
      case 10: return "teal";
      case 11: return "indigo";
      case 12: return "purple";
      default: return "";
    }
  }


  String getChipName() {
    return translate("colors.${_getChipI18nKey()}");
  }
}

