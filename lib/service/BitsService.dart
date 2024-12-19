import 'dart:convert';

import 'package:bits/bits.dart';
import 'package:crypto/crypto.dart';

import '../model/chip.dart';
import '../model/coordinate.dart';
import '../model/fortune.dart';
import '../model/move.dart';


const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890- ';
const maxDimension = 13;
const maxRound = maxDimension * 2;

enum Operation {
  sendInvite,  //000
  acceptInvite, //001
  rejectInvite, //010
  move, //011,
  unused1, //100
  unused2, //101
  unused3, //110
  unused4, //111
} // 3 bits

enum PlayMode { normal, classic } // 1 bit

enum PlayOpener { invitingPlayer, invitedPlayer, invitedPlayerChooses } // 2 bites

enum PlaySize { d5, d7, d9, d11, d13 } // 3 bits



void main() {

  final playId = generateRandomString(8);
  
  
   _testSendInvite(playId);

  _testSendInviteResponse(playId);


}

void _testSendInvite(String playId) {
  final (invitationBlob, signature) = createInvitationBlob(
    playId,
    PlaySize.d7,
    PlayMode.normal,
    PlayOpener.invitingPlayer,
    "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz"
  );
  print("invitationBlob = $invitationBlob");
  print("signature = $signature");

  final (operation, _playId, playSize, playMode, playOpener, invitingName) = readInvitationBlob(invitationBlob);
  print("operation: $operation");
  print("playId: $_playId");
  print("playSize: $playSize");
  print("playMode: $playMode");
  print("playOpener: $playOpener");
  print("invitingName: $invitingName");
}

void _testSendInviteResponse(String playId) {
  final (blob, signature) = createInvitationResponseBlob(
    playId,
    true,
    PlayOpener.invitedPlayer,
    "Remote opponents name"
  );
  print("blob = $blob");
  print("sig = $signature");

  final (operation, _playId, playOpener, invitedName, round, initialMove) = readInvitationResponseBlob(blob);
  print("operation: $operation");
  print("playId: $_playId");
  print("playOpener: $playOpener");
  print("invitedName: $invitedName");
  print("round: $round");
  print("initialMove: $initialMove");

}

(String, String) createInvitationBlob(String playId, PlaySize size, PlayMode mode,
    PlayOpener opener, String invitingPlayerName) {
  BitBuffer buffer = BitBuffer();
  var writer = buffer.writer();
  writeEnum(writer, Operation.values, Operation.sendInvite);
  writeString(writer, playId, 8);
  writeEnum(writer, PlayMode.values, mode);
  writeEnum(writer, PlaySize.values, size);
  writeEnum(writer, PlayOpener.values, opener);
  writeString(writer, invitingPlayerName, 32); // max 32 chars!

  final signature = createSignature(buffer.getLongs(), null);
  return (
    buffer.toBase64().toUrlSafe(),
    Base64Encoder().convert(signature).toUrlSafe()
  );
}


(Operation, String, PlayMode, PlaySize, PlayOpener, String) readInvitationBlob(String blob) {
  BitBuffer buffer = BitBuffer.fromBase64(blob);
  var reader = buffer.reader();
  return (
    readEnum(reader, Operation.values),
    readString(reader),
    readEnum(reader, PlayMode.values),
    readEnum(reader, PlaySize.values),
    readEnum(reader, PlayOpener.values),
    readString(reader),
  );
}

(String, String) createInvitationResponseBlob(String playId, bool accepted,
    PlayOpener? opener, String? invitingPlayerName) {
  final buffer = BitBuffer();
  final writer = buffer.writer();
  writeEnum(writer, Operation.values, accepted ? Operation.acceptInvite : Operation.rejectInvite);
  writeString(writer, playId, 8);
  if (accepted) {
    writeEnum(writer, PlayOpener.values, opener!);
    writeString(writer, invitingPlayerName!, 32); // max 32 chars!
    if (opener == PlayOpener.invitedPlayer) {
      writeInt(writer, 1, maxRound);
      writeMove(writer, Move.placed(GameChip(1), Coordinate(3, 5)));
    }
  }

  final signature = createSignature(buffer.getLongs(), null);
  return (
    buffer.toBase64().toUrlSafe(),
    Base64Encoder().convert(signature).toUrlSafe()
  );}


(Operation, String, PlayOpener?, String?, int? round, Move? openerMove) readInvitationResponseBlob(String blob) {
  final buffer = BitBuffer.fromBase64(blob);
  final reader = buffer.reader();
  return (
    readEnum(reader, Operation.values),
    readString(reader),
    readEnum(reader, PlayOpener.values),
    readString(reader),
    readInt(reader, maxRound),
    readMove(reader),
  );
}

List<int> createSignature(List<int> blob, List<int>? previousSignature) {
  var signature = sha256.convert(blob + (previousSignature != null ? previousSignature : []));
  return signature.bytes.take(6).toList();
}

String _normalize(String string, int maxLength) {
  string = string.replaceAll(RegExp(r'[^a-zA-Z0-9\-\ ]'), " ");
  return (string.length < maxLength)
      ? string
      : string.substring(0, maxLength);
}

void writeInt(BitBufferWriter writer, int value, int maxValue) {
  writer.writeInt(value, signed: false, bits: getBitsNeeded(maxValue));
}

int readInt(BitBufferReader reader, int maxValue) {
  return reader.readInt(signed: false, bits: getBitsNeeded(maxValue));
}

void writeEnum<E extends Enum>(BitBufferWriter writer, List<E> values, E value) {
  writer.writeInt(value.index, signed: false, bits: getBitsNeeded(values.length));
}

E readEnum<E extends Enum>(BitBufferReader reader, List<E> values) {
  final index = reader.readInt(signed: false, bits: getBitsNeeded(values.length));
  return values.firstWhere((e) => e.index == index);
}


void writeMove(BitBufferWriter writer, Move move) {
  writer.writeBit(move.skipped);
  writeChip(writer, move.chip);
  writeCoordinate(writer, move.from);
  writeCoordinate(writer, move.to);
}

void writeCoordinate(BitBufferWriter writer, Coordinate? where) {
  writer.writeInt(where?.x??-1, signed: true, bits: getBitsNeeded(maxDimension));
  writer.writeInt(where?.y??-1, signed: true, bits: getBitsNeeded(maxDimension));
}

void writeChip(BitBufferWriter writer, GameChip? chip) {
  writer.writeInt(chip?.id??-1, signed: true, bits: getBitsNeeded(maxDimension));
}

Move? readMove(BitBufferReader reader) {
  try {
    final skipped = reader.readBit();
    final chip = readChip(reader);

    if (skipped || chip == null) {
      return Move.skipped();
    }
    final from = readCoordinate(reader);
    final to = readCoordinate(reader);
    if (from != null) {
      return Move.moved(chip, from, to!);
    }
    else {
      return Move.placed(chip, to!);
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Coordinate? readCoordinate(BitBufferReader reader) {
  final x = reader.readInt(signed: true, bits: getBitsNeeded(maxDimension));
  final y = reader.readInt(signed: true, bits: getBitsNeeded(maxDimension));
  if (x != -1 && y != -1) {
    return Coordinate(x, y);
  }
  else {
    return null;
  }
}

GameChip? readChip(BitBufferReader reader) {
  final id = reader.readInt(signed: true, bits: getBitsNeeded(maxDimension));
  if (id == -1) {
    return null;
  }
  return GameChip(id);
}

int _convertCodeUnitToBase64(int codeUnit) => chars.indexOf(String.fromCharCode(codeUnit));
int _convertBase64ToCodeUnit(int base64) => chars[base64].codeUnits.first;

// max 63 chars long chars long
writeString(BitBufferWriter writer, String string, int maxLength) {
  if (maxLength > 63) {
    throw Exception("String too long");
  }
  string = _normalize(string, maxLength);
  // max length 32-1 to fit into 5 bits
  writer.writeInt(string.length, signed: false, bits: 6);
  string
      .codeUnits
      .map((c) => _convertCodeUnitToBase64(c))
      .forEach((bits) => writer.writeInt(bits, signed: false, bits: 6));
}

String readString(BitBufferReader reader) {
  final length = reader.readInt(signed: false, bits: 6);

  StringBuffer sb = StringBuffer();
  while (sb.length < length) {
    final codeUnit = _convertBase64ToCodeUnit(reader.readInt(signed: false, bits: 6));
    sb.write(String.fromCharCode(codeUnit));
  }
  return sb.toString();
}


extension StringExtenion on String {
  String toUrlSafe() {
    return this.replaceAll(RegExp("#"), "-").replaceAll(RegExp("/"), "_");
  }
}
