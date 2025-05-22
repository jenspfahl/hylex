import 'dart:convert';

import 'package:bits/bits.dart';
import 'package:crypto/crypto.dart';

import '../model/chip.dart';
import '../model/common.dart';
import '../model/coordinate.dart';
import '../utils/fortune.dart';
import '../model/move.dart';


const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890- ';
const maxDimension = 13;
const maxRound = maxDimension * 2;
const playIdLength = 8;
const userIdLength = 16;
const maxNameLength = 32;


class CommunicationContext {
  String? previousSignature;

  CommunicationContext();
  
  updatePreviousSignature(String signature) => previousSignature = signature;

}

abstract class Message {
  String playId;

  Message(this.playId);

  SerializedMessage serialize(String? receivedSignature) {

    final buffer = BitBuffer();
    final writer = buffer.writer();

    writeEnum(writer, Operation.values, getOperation());

    writeString(writer, playId, playIdLength);
    serializeToBuffer(writer);

    final signature = _createUrlSafeSignature(buffer, receivedSignature);
    return SerializedMessage(
        buffer.toBase64().toUrlSafe(),
        signature
    );
  }

  void serializeToBuffer(BitBufferWriter writer);

  Operation getOperation();

  String _createUrlSafeSignature(BitBuffer buffer, String? previousSignatureBase64) {
    final signature = createSignature(buffer.getLongs(), previousSignatureBase64);
    return Base64Encoder().convert(signature).toUrlSafe();
  }
}

class InviteMessage extends Message {

  PlaySize playSize;
  PlayMode playMode;
  PlayOpener playOpener;
  String invitingUserId;
  String invitingPlayerName;

  InviteMessage(
      String playId,
      this.playSize,
      this.playMode,
      this.playOpener,
      this.invitingUserId,
      this.invitingPlayerName,
      ): super(playId);

  factory InviteMessage.deserialize(
      BitBufferReader reader,
      String playId) {

    return InviteMessage(
      playId,
      readEnum(reader, PlaySize.values),
      readEnum(reader, PlayMode.values),
      readEnum(reader, PlayOpener.values),
      readString(reader),
      readString(reader),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeEnum(writer, PlayMode.values, playMode);
    writeEnum(writer, PlaySize.values, playSize);
    writeEnum(writer, PlayOpener.values, playOpener);
    writeString(writer, invitingUserId, userIdLength);
    writeString(writer, invitingPlayerName, maxNameLength);
  }

  @override
  Operation getOperation() => Operation.SendInvite;
}

class AcceptInviteMessage extends Message {
  PlayOpener playOpenerDecision;
  String invitedUserId;
  String invitedPlayerName;
  Move? initialMove;

  AcceptInviteMessage(
      String playId,
      this.playOpenerDecision,
      this.invitedUserId,
      this.invitedPlayerName,
      this.initialMove,
      ): super(playId);

  factory AcceptInviteMessage.deserialize(
      BitBufferReader reader,
      String playId) {

    final playOpener = readEnum(reader, PlayOpener.values);
    return AcceptInviteMessage(
      playId,
      playOpener,
      readString(reader),
      readString(reader),
      playOpener == PlayOpener.InvitedPlayer ? readMove(reader) : null,
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {

    writeEnum(writer, PlayOpener.values, playOpenerDecision);
    writeString(writer, invitedUserId, userIdLength);
    writeString(writer, invitedPlayerName, maxNameLength);
    if (playOpenerDecision == PlayOpener.InvitedPlayer) {
      writeMove(writer, initialMove!);
    }
  }

  @override
  Operation getOperation() => Operation.AcceptInvite;
}


class RejectInviteMessage extends Message {

  String userId;

  RejectInviteMessage(
      String playId,
      this.userId,
      ): super(playId);

  factory RejectInviteMessage.deserialize(
      BitBufferReader reader,
      String playId) {

    return RejectInviteMessage(
      playId,
      readString(reader),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeString(writer, userId, userIdLength);
  }

  @override
  Operation getOperation() => Operation.RejectInvite;
}


class MoveMessage extends Message {
  int round;
  Move move;

  MoveMessage(
      String playId,
      this.round,
      this.move,
      ): super(playId);

  factory MoveMessage.deserialize(
      BitBufferReader reader,
      String playId) {
    
    return MoveMessage(
      playId,
      readInt(reader, maxRound),
      readMove(reader)!,
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeInt(writer, round, maxRound);
    writeMove(writer, move);
  }

  @override
  Operation getOperation() => Operation.Move;
}

class SerializedMessage {
  String payload;
  String signature;

  SerializedMessage(this.payload, this.signature);

  static SerializedMessage? fromUrl(Uri uri) {
    if (uri.pathSegments.length == 2) {
      return SerializedMessage(uri.pathSegments[0], uri.pathSegments[1]);
    }
    else {
      return null;
    }
  }

  String extractPlayId() {

    final buffer = BitBuffer.fromBase64(Base64Codec().normalize(payload));
    final reader = buffer.reader();

    readEnum(reader, Operation.values);
    return readString(reader);
  }
  
  Operation extractOperation() {

    final buffer = BitBuffer.fromBase64(Base64Codec().normalize(payload));
    final reader = buffer.reader();

    return readEnum(reader, Operation.values);
  }

  Message deserialize(CommunicationContext comContext) {
    return _deserializeAndValidate(comContext);
  }

  Message deserializeWithoutValidation() {
    return _deserializeAndValidate(null);
  }
  
  Message _deserializeAndValidate(CommunicationContext? comContext) {

    final buffer = BitBuffer.fromBase64(Base64Codec().normalize(payload));

    if (comContext != null) {
      validateSignature(
          buffer.getLongs(), comContext.previousSignature, signature);
    }

    final reader = buffer.reader();

    final operation = readEnum(reader, Operation.values);
    final playId = readString(reader);

    switch (operation) {
      case Operation.SendInvite : return InviteMessage.deserialize(reader, playId);
      case Operation.AcceptInvite : return AcceptInviteMessage.deserialize(reader, playId);
      case Operation.RejectInvite : return RejectInviteMessage.deserialize(reader, playId);
      case Operation.Move : return MoveMessage.deserialize(reader, playId);
      default: throw Exception("Unsupported operation: $operation");
    }
  }

  String toUrl() {
    return "https://hx.jepfa.de/$payload/$signature";
  }

}

class BitsService {

  static final BitsService _service = BitsService._internal();

  factory BitsService() {
    return _service;
  }

  BitsService._internal() {}

  SerializedMessage sendMessage(Message message, CommunicationContext commContext) {
    return message.serialize(commContext.previousSignature);
  }

  Message receiveMessage(SerializedMessage serializedMessage, CommunicationContext commContext) {
    return serializedMessage.deserialize(commContext);
  }
}

void main() {

   final invitingUserId = generateRandomString(userIdLength);
   final invitedUserId = generateRandomString(userIdLength);
   final playId = generateRandomString(playIdLength);

   final invitingContext = CommunicationContext();
   final invitedContext = CommunicationContext();

   print("----- send invite --------");


   // send invite
   final invitationMessage = InviteMessage(
       playId,
       PlaySize.Size7x7,
       PlayMode.HyleX,
       PlayOpener.InvitingPlayer,
       invitingUserId,
       "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz"
   );

   final serializedInvitationMessage = _send(invitationMessage.serialize(null), invitingContext);


   // receive invite
   final deserializedInviteMessage = serializedInvitationMessage.deserialize(invitedContext) as InviteMessage;
   print("playId: ${deserializedInviteMessage.playId}");
   print("playSize: ${deserializedInviteMessage.playSize}");
   print("playMode: ${deserializedInviteMessage.playMode}");
   print("playOpener: ${deserializedInviteMessage.playOpener}");
   print("userId: ${deserializedInviteMessage.invitingUserId}");
   print("invitingName: ${deserializedInviteMessage.invitingPlayerName}");


   print("----- accept invite --------");

   // accept and respond to invite
   final acceptInviteMessage = AcceptInviteMessage(
       deserializedInviteMessage.playId,
       PlayOpener.InvitedPlayer,
       invitedUserId,
       "Remote opponents name",
       Move.placed(GameChip(1), Coordinate(3, 5)),
   );

   final serializedAcceptInviteMessage = _send(acceptInviteMessage.serialize(serializedInvitationMessage.signature), invitedContext);


   // receive accept invite
   final deserializedAcceptInviteMessage = serializedAcceptInviteMessage.deserialize(invitingContext) as AcceptInviteMessage;

   print("playId: ${deserializedAcceptInviteMessage.playId}");
   print("playOpener: ${deserializedAcceptInviteMessage.playOpenerDecision}");
   print("userId: ${deserializedAcceptInviteMessage.invitedUserId}");
   print("invitedName: ${deserializedAcceptInviteMessage.invitedPlayerName}");
   print("initialMove: ${deserializedAcceptInviteMessage.initialMove}");

 /*  print("------ reject invite -------");


   // accept and respond to invite
   final rejectInviteMessage = RejectInviteMessage(
     deserializedInviteMessage.playId);

   final serializedRejectInviteMessage = _send(rejectInviteMessage.serialize(serializedInvitationMessage), invitedContext);


   // receive reject invite
   final deserializedRejectInviteMessage = serializedRejectInviteMessage.deserialize(invitingContext) as RejectInviteMessage;

   print("playId: ${deserializedRejectInviteMessage.playId}");
*/
   print("----- first move --------");

   // first order move from inviting player
   final firstInvitingPlayerMoveMessage = MoveMessage(
       playId,
       1,
       Move.moved(GameChip(1), Coordinate(3, 5), Coordinate(0, 5)),
   );

   final serializedMoveMessage = _send(firstInvitingPlayerMoveMessage.serialize(serializedAcceptInviteMessage.signature), invitingContext);

   final deserializedMoveMessage = serializedMoveMessage.deserialize(invitedContext) as MoveMessage;

   print("playId: ${deserializedMoveMessage.playId}");
   print("round: ${deserializedMoveMessage.round}");
   print("move: ${deserializedMoveMessage.move}");


   print("-------------");

}



SerializedMessage _send(SerializedMessage message, CommunicationContext comContext) {
  comContext.previousSignature = message.signature;

  print("|");
  print("|");
  print("payload = ${message.payload}");
  print("signature = ${message.signature}");
  print("url = ${message.toUrl()}");
  print("|");
  print("|");
  print("|");
  print("V");

  return message;
}




List<int> createSignature(List<int> blob, String? previousSignatureBase64) {
  final previousSignature = previousSignatureBase64 != null
      ? Base64Codec.urlSafe().decoder.convert(previousSignatureBase64)
      : null;
  final signature = sha256.convert(blob + (previousSignature != null ? previousSignature : []));
  return signature.bytes.take(6).toList();
}


void validateSignature(List<int> blob, String? previousSignature, String comparingSignature) {
  final signature = Base64Encoder().convert(createSignature(blob, previousSignature)).toUrlSafe();
  print("sig1 $signature");
  print("sig2 $comparingSignature");
  if (signature != comparingSignature) {
    throw Exception("signature mismatch");
  }
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
    return this.replaceAll(RegExp("#"), "-")
        .replaceAll(RegExp("/"), "_")
        .replaceAll(RegExp("="), "");
  }
}
