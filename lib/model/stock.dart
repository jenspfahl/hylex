import 'dart:collection';
import 'dart:math';

import 'package:hyle_x/model/chip.dart';
import 'fortune.dart';



class StockEntry {
  GameChip chip;
  int amount;

  StockEntry(this.chip, this.amount);

  bool isEmpty() => amount == 0;
}

class Stock {
  final _available = HashMap<GameChip, int>();

  Stock(Map<GameChip, int> initialStock) {
    _available.addAll(initialStock);
  }

  Stock.fromJson(Map<String, dynamic> map) {

    final Map<String, dynamic> stockMap = map['available']!;
    _available.addAll(stockMap.map((key, value) {
      final chip = GameChip.fromKey(key);
      return MapEntry(chip, value);
    }));
  }

  Map<String, dynamic> toJson() => {
    'available' : _available.map((key, value) => MapEntry(key.toKey(), value)),
  };


  Iterable<StockEntry> getStockEntries() {
    final entries = _available
      .entries
      .map((e) => StockEntry(e.key, e.value))
      .toList();
    
    entries.sort((e1, e2) => e1.chip.name.compareTo(e2.chip.name));
    return entries;
  }

  int getStock(GameChip chip) => _available[chip] ?? 0;

  bool hasStock(GameChip chip) => getStock(chip) > 0;

  decStock(GameChip chip) {
    final curr = getStock(chip);
    _available[chip] = max(0, curr - 1);
  }


  GameChip? drawNext() {
    if (isEmpty()) {
      return null;
    }
    final nextChipIndex = diceInt(_available.length);
    final nextChip = _available.keys.indexed.firstWhere((e) => e.$1 == nextChipIndex).$2;
    final stockForChip = _available[nextChip]??0;
    if (stockForChip <= 0) {
      return drawNext();
    }
    return nextChip;
  }

  void putBack(GameChip chip) {
    final stockForChip = _available[chip]??0;
    _available[chip] = stockForChip + 1;
  }

  GameChip? getChipOfMostStock() {
    final entries = getStockEntries().toList();
    entries.sort((e1, e2) => e2.amount.compareTo(e1.amount));
    return entries.firstOrNull?.chip;
  }


  int getTotalStock() => _available.values.reduce((v, e) => v + e);

  bool isEmpty() {

    return getTotalStock() == 0;
  }

  int getTotalChipTypes() => _available.length;



}
