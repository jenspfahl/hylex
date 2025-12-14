import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../utils/crypto.dart';
import '../utils/fortune.dart';
import 'achievements.dart';
import 'messaging.dart';


class User {
  String id = "";
  String name = "";
  late Achievements achievements;

  String userSeed = "";

  User() {
    generateKeys();
    achievements = Achievements();
  }

  generateKeys() async {
    final keyPair = await generateKeyPair();
    final privateKeyBase64 = Base64Codec.urlSafe().encode(await keyPair.extractPrivateKeyBytes());
    final publicKeyBase64 = Base64Codec.urlSafe().encode((await keyPair.extractPublicKey()).bytes);

    this.id = publicKeyBase64;
    this.userSeed = privateKeyBase64;
  }

  Future<void> awaitKeys() async {
    var value = 0;
    return Future.doWhile(() async {
      value++;
      if (value > 500) { // 5 seconds waiting time
        print("Cannot determine Keys, generate random ID without signing capabilities");
        id = generateRandomString(userIdLength);
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint("id l: ${id.length}");
      debugPrint("seed l: ${userSeed.length}");
      return id.length != userPubicKey || userSeed.length != userPrivateKey;
    } );
  }

  bool hasSigningCapability() => userSeed.length == userPrivateKey;

  User.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    userSeed = map['userSeed'] ?? "";
    name = map['name'];
    achievements = Achievements.fromJson(map['achievements']!);
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "userSeed": userSeed,
    "name" : name,
    "achievements" : achievements.toJson(),
  };

  String getReadableId() {
    return toReadableId(id);
  }

}
