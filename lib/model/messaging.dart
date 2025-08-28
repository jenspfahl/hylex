import 'dart:collection';
import 'dart:convert';

import 'package:bits/bits.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';

import 'chip.dart';
import 'common.dart';
import 'coordinate.dart';
import '../utils/fortune.dart';
import 'move.dart';


const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890- ';
const maxDimension = 13;
const maxRound = maxDimension * 2;
const playIdLength = 8;
const userIdLength = 16;
const maxNameLength = 32;

enum Channel {
  In, Out
}
class ChannelMessage {
  late Channel channel;
  late SerializedMessage serializedMessage;

  ChannelMessage(this.channel, this.serializedMessage);

  Map<String, dynamic> toJson() => {
    "channel": channel.name,
    "serializedMessage": serializedMessage.toString()
  };

  ChannelMessage.fromJson(Map<String, dynamic> map) {
    channel = Channel.values.firstWhere((p) => p.name == map['channel']);
    final message = map['serializedMessage'];
    serializedMessage = SerializedMessage.fromString(message)!;
  }
}

class CommunicationContext {
  String? roundTripSignature;
  SerializedMessage? predecessorMessage;
  List<ChannelMessage> messageHistory = [];

  void registerSentMessage(SerializedMessage serializedMessage) {
    this.roundTripSignature = serializedMessage.signature;
    debugPrint("saving roundTripSignature ${this.roundTripSignature}");
    final lastMessage = messageHistory.isNotEmpty
        ? messageHistory[messageHistory.length - 1]
        : null;

    if (lastMessage == null || lastMessage.serializedMessage != serializedMessage) {
      messageHistory.add(ChannelMessage(Channel.Out, serializedMessage));
    }
  }

  void registerReceivedMessage(SerializedMessage serializedMessage) {

    this.predecessorMessage = serializedMessage;
    debugPrint("saving predecessorMessage: ${this.predecessorMessage}");

    final lastMessage = messageHistory.isNotEmpty
        ? messageHistory[messageHistory.length - 1]
        : null;

    if (lastMessage == null || lastMessage.serializedMessage != serializedMessage) {
      messageHistory.add(ChannelMessage(Channel.In, serializedMessage));
    }
  }
}

abstract class Message {
  String playId;

  Message(this.playId);

  SerializedMessage serializeWithContext(CommunicationContext comContext) {
    final serializedMessage = _serializeWithSignature(comContext.predecessorMessage?.signature);
    comContext.registerSentMessage(serializedMessage);
    return serializedMessage;
  }

  SerializedMessage _serializeWithSignature(String? receivedSignature) {

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
  String invitingUserName;

  InviteMessage(
      String playId,
      this.playSize,
      this.playMode,
      this.playOpener,
      this.invitingUserId,
      this.invitingUserName,
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
    writeEnum(writer, PlaySize.values, playSize);
    writeEnum(writer, PlayMode.values, playMode);
    writeEnum(writer, PlayOpener.values, playOpener);
    writeString(writer, invitingUserId, userIdLength);
    writeString(writer, invitingUserName, maxNameLength);
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
      playOpener == PlayOpener.Invitee ? readMove(reader) : null,
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {

    writeEnum(writer, PlayOpener.values, playOpenerDecision);
    writeString(writer, invitedUserId, userIdLength);
    writeString(writer, invitedPlayerName, maxNameLength);
    if (playOpenerDecision == PlayOpener.Invitee) {
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

class ResignMessage extends Message {
  int round;

  ResignMessage(
      String playId,
      this.round,
      ): super(playId);

  factory ResignMessage.deserialize(
      BitBufferReader reader,
      String playId) {

    return ResignMessage(
      playId,
      readInt(reader, maxRound),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeInt(writer, round, maxRound);
  }

  @override
  Operation getOperation() => Operation.Resign;
}

class SerializedMessage {
  String payload;
  String signature;

  SerializedMessage(this.payload, this.signature);

  static SerializedMessage? fromString(String uri) {
    return fromUrl(Uri.parse(uri));
  }

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

  (Message?,String?) deserialize(CommunicationContext comContext) {

    final buffer = BitBuffer.fromBase64(Base64Codec().normalize(payload));

    final errorMessage = _validateSignature(buffer.getLongs(), comContext, signature);
    if (errorMessage != null) {
      return (null, errorMessage);
    }
    comContext.registerReceivedMessage(this);

    final reader = buffer.reader();

    final operation = readEnum(reader, Operation.values);
    final playId = readString(reader);

    switch (operation) {
      case Operation.SendInvite : return (InviteMessage.deserialize(reader, playId), null);
      case Operation.AcceptInvite : return (AcceptInviteMessage.deserialize(reader, playId), null);
      case Operation.RejectInvite : return (RejectInviteMessage.deserialize(reader, playId), null);
      case Operation.Move : return (MoveMessage.deserialize(reader, playId), null);
      case Operation.Resign : return (ResignMessage.deserialize(reader, playId), null);
      default: throw Exception("Unsupported operation: $operation");
    }
  }

  String toUrl() {
    return "https://hx.jepfa.de/$payload/$signature";
  }

  @override
  String toString() {
    return toUrl();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SerializedMessage &&
          runtimeType == other.runtimeType &&
          payload == other.payload &&
          signature == other.signature;

  @override
  int get hashCode => payload.hashCode ^ signature.hashCode;

  Uri toUri() => Uri.parse(toUrl());
}


void testMessaging() {

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
       PlayOpener.Invitor,
       invitingUserId,
       "Test.name,1234567890 abcdefghijklmnopqrstuvwxyz"
   );

   final serializedInvitationMessage = _send(invitationMessage.serializeWithContext(invitingContext));


   // receive invite
   final deserializedInviteMessage = serializedInvitationMessage.deserialize(invitedContext).$1 as InviteMessage;
   print("playId: ${deserializedInviteMessage.playId}");
   print("playSize: ${deserializedInviteMessage.playSize}");
   print("playMode: ${deserializedInviteMessage.playMode}");
   print("playOpener: ${deserializedInviteMessage.playOpener}");
   print("userId: ${deserializedInviteMessage.invitingUserId}");
   print("invitingName: ${deserializedInviteMessage.invitingUserName}");


   print("----- accept invite --------");

   // accept and respond to invite
   final acceptInviteMessage = AcceptInviteMessage(
       deserializedInviteMessage.playId,
       PlayOpener.Invitee,
       invitedUserId,
       "Remote opponents name",
       Move.placed(GameChip(1), Coordinate(3, 5)),
   );

   final serializedAcceptInviteMessage = _send(acceptInviteMessage.serializeWithContext(invitedContext));


   // receive accept invite
   final deserializedAcceptInviteMessage = serializedAcceptInviteMessage.deserialize(invitingContext).$1 as AcceptInviteMessage;

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
       Move.movedForMessaging(Coordinate(3, 5), Coordinate(0, 5)),
   );

   final serializedMoveMessage = _send(firstInvitingPlayerMoveMessage.serializeWithContext(invitingContext));

   final deserializedMoveMessage = serializedMoveMessage.deserialize(invitedContext).$1 as MoveMessage;

   print("playId: ${deserializedMoveMessage.playId}");
   print("round: ${deserializedMoveMessage.round}");
   print("move: ${deserializedMoveMessage.move}");


   print("-------------");

}



SerializedMessage _send(SerializedMessage message) {
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


String? _validateSignature(List<int> blob, CommunicationContext comContext, String comparingSignature) {
  if (comContext.predecessorMessage?.signature == comparingSignature) {
    print("Message with signature $comparingSignature already processed");
    return "This link has already been processed.";
  }
  final signature = Base64Encoder().convert(createSignature(blob, comContext.roundTripSignature)).toUrlSafe();
  print("computed  sig $signature");
  print("comparing sig $comparingSignature");
  print("roundTrip Sig ${comContext.roundTripSignature}");
  if (signature != comparingSignature) {
    print("signature mismatch $signature != $comparingSignature");
    return "This link is not the latest of the current match.";
  }
  else {
    return null;
  }
}

String _normalize(String string, int maxLength) {
  string = string.replaceAll(RegExp(r'[^a-zA-Z0-9\-\ ]'), " ");
  return (string.length < maxLength)
      ? string
      : string.substring(0, maxLength);
}

// only positive values
void writeInt(BitBufferWriter writer, int value, int maxValue) {
  writer.writeInt(value, signed: false, bits: getBitsNeeded(maxValue));
}

// only positive or null values
void writeNullableInt(BitBufferWriter writer, int? nullableValue, int maxValue) {
  final value = nullableValue == null ? 0 : nullableValue + 1;
  writeInt(writer, value, maxValue);
}

// only positive values
int readInt(BitBufferReader reader, int maxValue) {
  return reader.readInt(signed: false, bits: getBitsNeeded(maxValue));
}

// only positive or null values
int? readNullableInt(BitBufferReader reader, int maxValue) {
  final value = readInt(reader, maxValue);
  return value == 0 ? null : value - 1;
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
  writeChip(writer, move.isMove() ? null : move.chip);
  writeCoordinate(writer, move.from);
  writeCoordinate(writer, move.to);
}

void writeCoordinate(BitBufferWriter writer, Coordinate? where) {
  writeNullableInt(writer, where?.x, maxDimension);
  writeNullableInt(writer, where?.y, maxDimension);
}

void writeChip(BitBufferWriter writer, GameChip? chip) {
  writeNullableInt(writer, chip?.id, maxDimension);
}

Move? readMove(BitBufferReader reader) {
  try {
    final skipped = reader.readBit();
    final chip = readChip(reader);

    if (skipped) {
      return Move.skipped();
    }
    final from = readCoordinate(reader);
    final to = readCoordinate(reader);
    if (from != null) {
      return Move.movedForMessaging(from, to!);
    }
    else {
      return Move.placed(chip!, to!);
    }
  } catch (e) {
    print(e);
    throw e;
    //TODO return null;
  }
}

Coordinate? readCoordinate(BitBufferReader reader) {
  final x = readNullableInt(reader, maxDimension);
  final y = readNullableInt(reader, maxDimension);
  if (x != null && y != null) {
    return Coordinate(x, y);
  }
  else {
    return null;
  }
}

GameChip? readChip(BitBufferReader reader) {
  final id = readNullableInt(reader, maxDimension);
  if (id == null) {
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
