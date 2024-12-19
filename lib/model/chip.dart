
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

  String getChipName() {
    switch(id) {
      case 0: return "Red";
      case 1: return "Yellow";
      case 2: return "Green";
      case 3: return "Cyan";
      case 4: return "Blue";
      case 5: return "Pink";
      case 6: return "Grey";
      case 7: return "Brown";
      case 8: return "Honey";
      case 9: return "Moss";
      case 10: return "Indigo";
      case 11: return "Violet";
      case 12: return "Purple";
      default: return "";
    }
  }

}

