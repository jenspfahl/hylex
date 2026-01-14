import 'dart:math';

import 'package:collection/collection.dart';

final rnd = Random.secure();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
const _upperChars = 'ABCDEFGHIJKLMOPQRSTUVWXYZ';
const _upperVocals = 'AEIJOU';
const _upperConsonants = 'BCDFGHKLMPQRSTVWXZ';
const _digits = '1234567890';


int diceInt(int max) => rnd.nextInt(max);

String generateRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(rnd.nextInt(_chars.length))));

String toReadablePlayId(String id) {
  // ABCD-123
  if (id.length < 7) {
    return id;
  }
  if (id.codeUnits.sum % 3 == 0) {
    return _mapToCharSet(id.codeUnitAt(0), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(1), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(2), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(3), _upperVocals)
        + "-"
        + _mapToCharSet(id.codeUnitAt(4), _digits)
        + _mapToCharSet(id.codeUnitAt(5), _digits)
        + _mapToCharSet(id.codeUnitAt(6), _digits);
  }
  else {
    return _mapToCharSet(id.codeUnitAt(0), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(1), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(2), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(3), _upperConsonants)
        + "-"
        + _mapToCharSet(id.codeUnitAt(4), _digits)
        + _mapToCharSet(id.codeUnitAt(5), _digits)
        + _mapToCharSet(id.codeUnitAt(6), _digits);
  }
}

String toReadableUserId(String id) {
  // ABCDED-12
  if (id.length < 8) {
    return id;
  }
  if (id.codeUnits.sum % 3 == 0) {
    return _mapToCharSet(id.codeUnitAt(0), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(1), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(2), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(3), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(4), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(5), _upperVocals)
        + "-"
        + _mapToCharSet(id.codeUnitAt(6), _digits)
        + _mapToCharSet(id.codeUnitAt(7), _digits);
  }
  else {
    return _mapToCharSet(id.codeUnitAt(0), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(1), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(2), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(3), _upperConsonants)
        + _mapToCharSet(id.codeUnitAt(4), _upperVocals)
        + _mapToCharSet(id.codeUnitAt(5), _upperConsonants)
        + "-"
        + _mapToCharSet(id.codeUnitAt(6), _digits)
        + _mapToCharSet(id.codeUnitAt(7), _digits);
  }
}


String _mapToCharSet(int code, String charSet) => charSet[code % charSet.length];
