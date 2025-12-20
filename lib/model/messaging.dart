import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:bits/bits.dart';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/cupertino.dart';
import 'package:hyle_x/app.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/model/user.dart';
import 'package:hyle_x/utils/crypto.dart';

import 'chip.dart';
import 'common.dart';
import 'coordinate.dart';
import 'messaging.dart';
import 'move.dart';

const shareBaseUrl = "https://hx.jepfa.de/d/";
final deepLinkRegExp = RegExp("${shareBaseUrl}([a-z0-9\-_]+)/([a-z0-9\-_]+)(/[a-z0-9\-_]+)?", caseSensitive: false);


const allowedChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890- ';
final allowedCharsRegExp = RegExp(r'^[a-z0-9 -]*$', caseSensitive: false);
const maxDimension = 13;
const maxRound = maxDimension * maxDimension;
const playIdLength = 8;
const fallbackUserSeedLength = 32;
const userPubicKey = 44; //Ed25519 uses 32 byte keys, which has a length of 44 as Base64 encoded
const userPrivateKey = 44; //Ed25519 uses 32 byte keys, which has a length of 44 as Base64 encoded
const userIdLength = userPubicKey;
const userSeedLength = userPrivateKey;
const maxNameLength = 32;
const currentMessageVersion = 1;
const maxMessageVersion = 16;

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

  @override
  String toString() {
    return 'CommunicationContext{roundTripSignature: $roundTripSignature, predecessorMessage: $predecessorMessage, messageHistory.length: ${messageHistory.length}';
  }
}

/**
 * Header:
 * <version(4)><operation(4)><playId(5+8*5)><playSize(3)>
 */
abstract class Message {
  String playId;
  int version = currentMessageVersion;
  PlaySize playSize;

  Message(this.playId, this.playSize);

  SerializedMessage serialize(String userSeed) => _serializeWithSignature(userSeed: userSeed);

  SerializedMessage serializeWithContext(CommunicationContext comContext, String userSeed) {
    final serializedMessage = _serializeWithSignature(
        receivedSignature: comContext.predecessorMessage?.signature, userSeed: userSeed);
    comContext.registerSentMessage(serializedMessage);
    return serializedMessage;
  }


  SerializedMessage _serializeWithSignature(
      {
        String? receivedSignature,
        String? userSeed
      }) {

    final payloadBuffer = BitBuffer();
    final writer = payloadBuffer.writer();

    writeVersion(writer, version);
    writeEnum(writer, Operation.values, getOperation());
    writeString(writer, playId, playIdLength);
    writeEnum(writer, PlaySize.values, playSize);

    serializeToBuffer(writer);

    debugPrint("Payload: ${payloadBuffer.toBase64()}");
    debugPrint("Payload size: ${payloadBuffer.getSize()}");
    debugPrint("Payload free bits: ${payloadBuffer.getFreeBits()}");
    final signature = createUrlSafeSignature(
        payloadBuffer,
        userSeed: userSeed,
        previousSignatureBase64: receivedSignature);
    return SerializedMessage(
        payloadBuffer.toBase64().toUrlSafe(),
        signature
    );
  }


  void serializeToBuffer(BitBufferWriter writer);

  Operation getOperation();

}

/**
 * Header + body:
 * <playMode(2)><playOpener(2)><invitorUserId(5+16*5)><invitorUserName(5+32*5)>
 */
class InviteMessage extends Message {

  PlayMode playMode;
  PlayOpener playOpener;
  String invitorUserId;
  String invitorUserName;

  InviteMessage(
      String playId,
      PlaySize playSize,
      this.playMode,
      this.playOpener,
      this.invitorUserId,
      this.invitorUserName,
      ): super(playId, playSize);

  InviteMessage.fromHeaderAndUser(PlayHeader header, User user)  : this(
      header.playId,
      header.playSize,
      header.playMode, 
      header.playOpener!,
      user.id,
      user.name
  );

  factory InviteMessage.deserialize(
      BitBufferReader reader,
      String playId,
      PlaySize playSize) {

    return InviteMessage(
      playId,
      playSize,
      readEnum(reader, PlayMode.values),
      readEnum(reader, PlayOpener.values),
      readBase64String(reader, userIdLength),
      readString(reader),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeEnum(writer, PlayMode.values, playMode);
    writeEnum(writer, PlayOpener.values, playOpener);
    writeBase64String(writer, invitorUserId, userIdLength);
    writeString(writer, invitorUserName, maxNameLength);
  }

  @override
  Operation getOperation() => Operation.SendInvite;
}


/**
 * Header + body:
 * <playOpener(2)><inviteeUserId(5+16*5)><inviteeUserName(5+32*5)><initialMove()>
 */
class AcceptInviteMessage extends Message {
  PlayOpener playOpenerDecision;
  String inviteeUserId;
  String inviteeUserName;
  Move? initialMove;

  AcceptInviteMessage(
      String playId,
      PlaySize playSize,
      this.playOpenerDecision,
      this.inviteeUserId,
      this.inviteeUserName,
      this.initialMove,
      ): super(playId, playSize);

  factory AcceptInviteMessage.deserialize(
      BitBufferReader reader,
      String playId,
      PlaySize playSize) {

    final playOpener = readEnum(reader, PlayOpener.values);
    return AcceptInviteMessage(
      playId,
      playSize,
      playOpener,
      readBase64String(reader, userIdLength),
      readString(reader),
      playOpener == PlayOpener.Invitee ? readMove(reader, playSize.dimension) : null,
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeEnum(writer, PlayOpener.values, playOpenerDecision);
    writeBase64String(writer, inviteeUserId, userIdLength);
    writeString(writer, inviteeUserName, maxNameLength);
    if (playOpenerDecision == PlayOpener.Invitee && initialMove != null) {
      writeMove(writer, initialMove!, playSize.dimension);
    }
  }

  @override
  Operation getOperation() => Operation.AcceptInvite;
}


class RejectInviteMessage extends Message {

  String userId;

  RejectInviteMessage(
      String playId,
      PlaySize playSize,
      this.userId,
      ): super(playId, playSize);

  factory RejectInviteMessage.deserialize(
      BitBufferReader reader,
      String playId,
      PlaySize playSize) {

    return RejectInviteMessage(
      playId,
      playSize,
      readBase64String(reader, userIdLength),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeBase64String(writer, userId, userIdLength);
  }

  @override
  Operation getOperation() => Operation.RejectInvite;
}


class MoveMessage extends Message {
  int round;
  Move move;

  MoveMessage(
      String playId,
      PlaySize playSize,
      this.round,
      this.move,
      ): super(playId, playSize);

  factory MoveMessage.deserialize(
      BitBufferReader reader,
      String playId,
      PlaySize playSize,
      ) {
    
    return MoveMessage(
      playId,
      playSize,
      readRound(reader, playSize.dimension),
      readMove(reader, playSize.dimension),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeRound(writer, round, playSize.dimension);
    writeMove(writer, move, playSize.dimension);
  }

  @override
  Operation getOperation() => Operation.Move;
}

class ResignMessage extends Message {
  int round;

  ResignMessage(
      String playId,
      PlaySize playSize,
      this.round,
      ): super(playId, playSize);

  factory ResignMessage.deserialize(
      BitBufferReader reader,
      String playId,
      PlaySize playSize) {

    return ResignMessage(
      playId,
      playSize,
      readRound(reader, maxRound),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    writeRound(writer, round, playSize.dimension);
  }

  @override
  Operation getOperation() => Operation.Resign;
}

class FullStateMessage extends Message {
  Play play;
  User user;

  FullStateMessage(
      this.play,
      this.user,
      ): super(play.header.playId, play.header.playSize);

  factory FullStateMessage.deserialize(
      BitBufferReader reader, Play play, User user) {

    return FullStateMessage(
      play, user
      // TODO readInt(reader, maxRound),
    );
  }

  @override
  void serializeToBuffer(BitBufferWriter writer) {
    final header = play.header;

    writeEnum(writer, PlayMode.values, header.playMode);
    writeNullableEnum(writer, PlayOpener.values, header.playOpener);

    writeBase64String(writer, user.id, userIdLength);
    writeBase64String(writer, header.opponentId??"", userIdLength);

    writeEnum(writer, PlayState.values, header.state);
    writeRound(writer, header.currentRound, header.dimension);

    play.journal.forEach((move) {
      writeMove(writer, move, header.dimension);
    });
  }

  @override
  Operation getOperation() => Operation.FullState;
}

class SerializedMessage {
  String payload;
  String signature;
  String? auth;

  SerializedMessage(this.payload, this.signature, [this.auth]);

  // use extractAppLinkFromString(uri) to ensure correct URI !
  static SerializedMessage? fromString(String uri) {
    return fromUrl(Uri.parse(uri));
  }

  static SerializedMessage? fromUrl(Uri uri) {
    if (uri.pathSegments.length == 4) {
      return SerializedMessage(uri.pathSegments[1], uri.pathSegments[2], uri.pathSegments[3]);
    }
    else if (uri.pathSegments.length == 3) {
      return SerializedMessage(uri.pathSegments[1], uri.pathSegments[2]);
    }
    else if (uri.pathSegments.length == 2) {
      return SerializedMessage(uri.pathSegments[0], uri.pathSegments[1]);
    }
    else {
      return null;
    }
  }

  signMessage(String publicKeyBase64, String privateKeyBase64) async {
    final message = payload + signature;
    final publicKey = Base64Codec.urlSafe().decode(publicKeyBase64);
    final privateKey = Base64Codec.urlSafe().decode(privateKeyBase64);
    final keyPair = SimpleKeyPairData(
        privateKey,
        publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519);
    final authSig = await sign(message.codeUnits, keyPair);
    final authSigBase64 = Base64Codec.urlSafe().encode(authSig.bytes);
    auth = authSigBase64;
  }

  String extractPlayId() {

    final buffer = _createBufferFromPayload();
    final reader = buffer.reader();

    final version = readVersion(reader);
    if (version != currentMessageVersion) {
      throw Exception("Unsupported message version: $version");
    }


    readEnum(reader, Operation.values); // skip Operation
    return readString(reader);
  }

  int extractVersion() {

    final buffer = _createBufferFromPayload();
    final reader = buffer.reader();

    return readVersion(reader);
  }
  
  Operation extractOperation() {

    final buffer = _createBufferFromPayload();
    final reader = buffer.reader();

    final version = readVersion(reader);
    if (version != currentMessageVersion) {
      throw Exception("Unsupported message version: $version");
    }

    return readEnum(reader, Operation.values);
  }

  Future<(Message?, String?)> deserialize(
      CommunicationContext comContext,
      String? remotePublicKey,
      ) async {

    final payloadBuffer = _createBufferFromPayload();

    final errorMessage = _validateSignature(
        payloadBuffer,
        comContext,
        comparingSignatureBase64: signature);
    if (errorMessage != null) {
      return (null, errorMessage);
    }
    comContext.registerReceivedMessage(this);

    final reader = payloadBuffer.reader();

    final version = readVersion(reader);
    if (version != currentMessageVersion) {
      throw Exception("Unsupported message version: $version");
    }
    final operation = readEnum(reader, Operation.values);
    final playId = readString(reader);
    final playSize = readEnum(reader, PlaySize.values);

    var messageAndError = switch (operation) {
      Operation.SendInvite => (InviteMessage.deserialize(reader, playId, playSize), null),
      Operation.AcceptInvite => (AcceptInviteMessage.deserialize(reader, playId, playSize), null),
      Operation.RejectInvite => (RejectInviteMessage.deserialize(reader, playId, playSize), null),
      Operation.Move => (MoveMessage.deserialize(reader, playId, playSize), null),
      Operation.Resign => (ResignMessage.deserialize(reader, playId, playSize), null),
      //TODO Operation.FullState => (FullStateMessage.deserialize(reader, playId, playSize), null),
      _ => throw Exception("Unsupported operation: $operation"),
    };

    var publicKey = remotePublicKey;
    if (publicKey == null) {
      final message = messageAndError.$1;
      if (message is AcceptInviteMessage) {
        publicKey = message.inviteeUserId;
      }
      else if (message is RejectInviteMessage) {
        publicKey = message.userId;
      }
    }

    if (publicKey != null && auth != null) {
      final authValid = await _verifyAuth(
          (payload + signature).codeUnits,
          auth!,
          publicKey);
      if (!authValid) {
        print("remote pk: $publicKey");
        print("auth sig : $auth");
        return (null, "Invalid auth signature");
      }
    }

    return messageAndError;
  }

  BitBuffer _createBufferFromPayload() => BitBuffer.fromBase64(Base64Codec().normalize(payload));

  String toUrl() {
    if (auth != null) {
      return "$shareBaseUrl$payload/$signature/$auth";
    }
    else {
      return "$shareBaseUrl$payload/$signature";
    }
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


List<int> createSignature(
    List<int> blob,
    {
      String? userSeed,
      String? previousSignatureBase64,
    }) {
  final previousSignature = previousSignatureBase64 != null
      ? Base64Codec.urlSafe().decoder.convert(previousSignatureBase64)
      : (userSeed??"").codeUnits;
  final signature = sha256.convert(blob + previousSignature);
  return signature.bytes.take(6).toList();
}

Future<bool> _verifyAuth(List<int> blob, String sig, String publicKey) async {
  final sigBytes = Base64Codec.urlSafe().decode(sig);
  final publicKeyBytes = Base64Codec.urlSafe().decode(publicKey);
  return verify(blob, Signature(
      sigBytes,
      publicKey: SimplePublicKey(
          publicKeyBytes,
          type: KeyPairType.ed25519))
  );
}

String? _validateSignature(
    BitBuffer payloadBuffer,
    CommunicationContext comContext,
    {
        required String comparingSignatureBase64,
        String? userSeed
    }) {
  if (comContext.predecessorMessage?.signature == comparingSignatureBase64) {
    print("Message with signature $comparingSignatureBase64 already processed");
    return "This link has already been processed.";
  }
  if (comContext.roundTripSignature == null) {
    print("No validation for first chain element");
    return null;
  }
  final calculatedSignatureBase64 =
      createUrlSafeSignature(
          payloadBuffer,
          userSeed: userSeed,
          previousSignatureBase64: comContext.roundTripSignature);
  print("received payload ${payloadBuffer.toBase64()}");
  print("computed  sig $calculatedSignatureBase64");
  print("comparing sig $comparingSignatureBase64");
  print("roundTrip Sig ${comContext.roundTripSignature}");
  if (calculatedSignatureBase64 != comparingSignatureBase64) {
    print("signature mismatch $calculatedSignatureBase64 != $comparingSignatureBase64");
    final alreadyProcessed = comContext.messageHistory
        .where((m) => m.serializedMessage.signature == comparingSignatureBase64)
        .firstOrNull;
    var additionalInfo = "";
    if (isDebug) {
      additionalInfo += "\n calc: $calculatedSignatureBase64 \n comp:$comparingSignatureBase64";
      additionalInfo += "\n rnd sig: ${comContext.roundTripSignature} \n pre sig: ${comContext.predecessorMessage?.signature}";
      additionalInfo += "\n curr payload: ${payloadBuffer.toBase64()} \n prev payload: ${comContext.predecessorMessage?.payload}";
    }
    if (alreadyProcessed != null) {
      if (alreadyProcessed.channel == Channel.Out) {
        return "This link was intended for your opponent, not for you!$additionalInfo";
      }
      return "This link with was already processed by you!$additionalInfo";
    }
    return "This link is not the latest of the current match.$additionalInfo";
  }
  else {
    return null;
  }
}

String normalizeString(String string, int maxLength) {
  string = string.replaceAll(RegExp(r'[^a-zA-Z0-9\-\ ]'), " ");
  return (string.length < maxLength)
      ? string
      : string.substring(0, maxLength);
}




/**
 * only positive values supported!
 *
 * bits needed:
 * depending on maxValueExclusively (value range) --> bits:
 *     2 (0 -   1)  --> 1
 *     4 (0 -   3)  --> 2
 *     8 (0 -   7)  --> 3
 *    16 (0 -  15)  --> 4
 *    32 (0 -  31)  --> 5
 *    64 (0 -  63)  --> 6
 *   128 (0 - 127)  --> 7
 *   256 (0 - 255)  --> 8
 *   ...
 */
void writeInt(BitBufferWriter writer, int value, int maxValueExclusively) {
  if (maxValueExclusively <= 0) {
    throw Exception("maxValueExclusively must be greater 0");
  }
  if (value.isNegative) {
    throw Exception("negative values not supported by this method: writeInt");
  }
  if (value >= maxValueExclusively) {
    throw Exception("value $value must be lower than maxValueExclusively $maxValueExclusively");
  }
  writer.writeInt(value, signed: false, bits: getBitsNeeded(maxValueExclusively - 1));
}

int readInt(BitBufferReader reader, int maxValueExclusively) {
  return reader.readInt(signed: false, bits: getBitsNeeded(maxValueExclusively - 1));
}


/**
 * only positive on null values supported!
 *
 * bits needed:
 * <isNull(1)><value(see below)>
 *
 * depending on maxValueExclusively (value range) --> bits:
 *     2 (0 -   1)  --> 1
 *     4 (0 -   3)  --> 2
 *     8 (0 -   7)  --> 3
 *    16 (0 -  15)  --> 4
 *    32 (0 -  31)  --> 5
 *    64 (0 -  63)  --> 6
 *   128 (0 - 127)  --> 7
 *   256 (0 - 255)  --> 8
 *   ...
 */
void writeNullableInt(BitBufferWriter writer, int? nullableValue, int maxValueExclusively) {
  if (nullableValue?.isNegative == true) {
    throw Exception("negative values not supported by this method: writeNullableInt");
  }
  final isNull = nullableValue == null;
  writer.writeBit(isNull);
  if (!isNull) {
    writeInt(writer, nullableValue, maxValueExclusively);
  }
}

int? readNullableInt(BitBufferReader reader, int maxValueExclusively) {
  final isNull = reader.readBit();
  if (isNull) {
    return null;
  }
  else {
    return readInt(reader, maxValueExclusively);
  }
}

/**
 * bits needed:
 * depending on the Emum literal amount (value range) --> bits:
 *     2 (0 -   1)  --> 1
 *     4 (0 -   3)  --> 2
 *     8 (0 -   7)  --> 3
 *    16 (0 -  15)  --> 4
 *    32 (0 -  31)  --> 5
 *    ...
 */
void writeEnum<E extends Enum>(BitBufferWriter writer, List<E> values, E value) {
  writeInt(writer, value.index, values.length);
}

E readEnum<E extends Enum>(BitBufferReader reader, List<E> values) {
  final index = readInt(reader, values.length);
  return values.firstWhere((e) => e.index == index);
}

/**
 * bits needed:
 * <isNull(1)><value(see below)>

 * depending on the Emum literal amount (value range) --> bits:
 *     2 (0 -   1)  --> 1
 *     4 (0 -   3)  --> 2
 *     8 (0 -   7)  --> 3
 *    16 (0 -  15)  --> 4
 *    32 (0 -  31)  --> 5
 *    ...
 */
void writeNullableEnum<E extends Enum>(BitBufferWriter writer, List<E> values, E? value) {
  writeNullableInt(writer, value?.index, values.length);
}

E? readNullableEnum<E extends Enum>(BitBufferReader reader, List<E> values) {
  final index = readNullableInt(reader, values.length);
  if (index == null) {
    return null;
  }
  return values.firstWhere((e) => e.index == index);
}

/**
 * bits needed:
 * 5x5: 3
 * 7x7: 3
 * 9x9: 4
 * 11x11: 4
 * 13x13: 4
 */
void writeChip(BitBufferWriter writer, GameChip chip, int dimension) {
  writeInt(writer, chip.id, dimension);
}

GameChip readChip(BitBufferReader reader, int dimension) {
  final id = readInt(reader, dimension);
  return GameChip(id);
}


/**
 * bits needed:
 * 5x5: 5
 * 7x7: 6
 * 9x9: 7
 * 11x11: 7
 * 13x13: 8
 */
void writeCoordinate(BitBufferWriter writer, Coordinate where, int dimension) {
  final pos = (where.y * dimension) + where.x;
  writeInt(writer, pos, dimension * dimension);
}

Coordinate readCoordinate(BitBufferReader reader, int dimension) {
  final pos = readInt(reader, dimension * dimension);
  final x = pos % dimension;
  final y = pos ~/ dimension;
  return Coordinate(x, y);
}

/**
 * bits needed: 5-8
 * 5x5: 5
 * 7x7: 6
 * 9x9: 7
 * 11x11: 7
 * 13x13: 8
 */
void writeRound(BitBufferWriter writer, int round, int dimension) {
  writeInt(writer, max(round - 1, 0), dimension * dimension);
}

int readRound(BitBufferReader reader, int dimension) {
  return readInt(reader, dimension * dimension) + 1;
}

/**
 * For Chaos:
 * <isPlaced(1)><chip(3-4)><coordinate(5-8)>
 * For Order - skipped:
 * <isPlaced(1)><isSkipped(1)>
 * For Order - moved:
 * <isPlaced(1)><isSkipped(1)><coordinate(5-8)><isHorizontally(1)><atAxis(3-4)>
 */
void writeMove(BitBufferWriter writer, Move move, int dimension) {
  writer.writeBit(move.isPlaced());
  if (move.isPlaced()) {
    writeChip(writer, move.chip!, dimension);
    writeCoordinate(writer, move.to!, dimension);
  }
  else {
    writer.writeBit(move.skipped);
    if (!move.skipped) {
      writeCoordinate(writer, move.from!, dimension);
      final isHorizontally = move.from!.x != move.to!.x;
      writer.writeBit(isHorizontally);

      final atAxis = isHorizontally
          ? move.to!.x
          : move.to!.y;
      writeInt(writer, atAxis, dimension);
    }
  }
}


Move readMove(BitBufferReader reader, int dimension) {
  final isPlaced = reader.readBit();
  if (isPlaced) {
    final chip = readChip(reader, dimension);
    final to = readCoordinate(reader, dimension);
    return Move.placed(chip, to);
  }
  else {
    final isSkipped = reader.readBit();
    if (isSkipped) {
     return Move.skipped();
    }
    else {
      final from = readCoordinate(reader, dimension);
      final isHorizontally = reader.readBit();
      final atAxis = readInt(reader, dimension);
      return Move.movedForMessaging(from, isHorizontally ? Coordinate(atAxis, from.y) : Coordinate(from.x, atAxis));
    }
  }

}


/**
 * version between 1 and 16
 *
 * version(4)
 */
void writeVersion(BitBufferWriter writer, int version) {
  writeInt(writer, version - 1, maxMessageVersion);
}

int readVersion(BitBufferReader reader) {
  return readInt(reader, maxMessageVersion) + 1;
}


/**
 * max 63 chars long!
 *
 * bits needed:
 * <length(5)><char(6)>[0-32]
 */
writeString(BitBufferWriter writer, String string, int maxLength) {
  if (maxLength > 63) {
    throw Exception("max length too long");
  }
  if (maxLength <= 0) {
    throw Exception("max length too short");
  }
  string = normalizeString(string, maxLength);

  writer.writeInt(string.length, signed: false, bits: 6);
  string
      .codeUnits
      .map((c) => _convertCodeUnitToBase64(c))
      .forEach((bits) => writer.writeInt(bits, signed: false, bits: 6));
}

/**
 * max 63 chars long!
 *
 * bits needed:
 * <length(5)><char(6)>[0-32]
 */
writeBase64String(BitBufferWriter writer, String string, int maxLength) {
  writeString(writer, string.replaceAll('=', ""), maxLength);
}


/***
 * bits needed:
 * <length(32)><char(16)>[0-*]
 */
writeNullableObject(BitBufferWriter writer, Object? obj) {
  if (obj == null) {
    writer.writeString("");
  }
  else {
    final objJson = jsonEncode(obj);
    writer.writeString(objJson);
  }
}

Object? readNullableObject(BitBufferReader reader, Object Function(dynamic) mapToObj) {
  final string = reader.readString();
  if (string.isEmpty) {
    return null;
  }
  else {
    final map = jsonDecode(string);
    debugPrint(map.toString());
    return mapToObj(map);
  }
}


String readString(BitBufferReader reader) {
  final length = reader.readInt(signed: false, bits: 6);
  if (length == 0) {
    return "";
  }
  StringBuffer sb = StringBuffer();
  while (sb.length < length) {
    final codeUnit = _convertBase64ToCodeUnit(reader.readInt(signed: false, bits: 6));
    sb.write(String.fromCharCode(codeUnit));
  }
  return sb.toString();
}

String readBase64String(BitBufferReader reader, int length) {
  final string = readString(reader);
  return string.replaceAll(" ", "_").padRight(length, "=");
}

String createUrlSafeSignature(
    BitBuffer buffer,
    {
      String? userSeed,
      String? previousSignatureBase64
    }) {
  final signature = createSignature(
      buffer.getLongs(),
      userSeed: userSeed,
      previousSignatureBase64: previousSignatureBase64);
  return Base64Encoder().convert(signature).toUrlSafe();
}


int _convertCodeUnitToBase64(int codeUnit) => allowedChars.indexOf(String.fromCharCode(codeUnit));
int _convertBase64ToCodeUnit(int base64) => allowedChars[base64].codeUnits.first;


Uri? extractAppLinkFromString(String s) {
  final link = deepLinkRegExp.stringMatch(s);
  if (link == null) {
    print("No app link found in $s");
    return null;
  }
  final uri = Uri.parse(link);
  debugPrint("Extracted app link: $uri");
  return uri;
}

extension StringExtenion on String {
  String toUrlSafe() {
    return this.replaceAll("+", "-")
        .replaceAll("/", "_")
        .replaceAll("=", "");
  }
}
