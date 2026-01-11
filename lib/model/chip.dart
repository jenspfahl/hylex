
import '../l10n/app_localizations.dart';

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

  String getChipName(AppLocalizations l10n) {
    switch(id) {
      case 0: return l10n.color_red;
      case 1: return l10n.color_yellow;
      case 2: return l10n.color_green;
      case 3: return l10n.color_cyan;
      case 4: return l10n.color_blue;
      case 5: return l10n.color_pink;
      case 6: return l10n.color_grey;
      case 7: return l10n.color_brown;
      case 8: return l10n.color_olive;
      case 9: return l10n.color_moss;
      case 10: return l10n.color_teal;
      case 11: return l10n.color_indigo;
      case 12: return l10n.color_purple;
      default: return "";
    }
  }


}

