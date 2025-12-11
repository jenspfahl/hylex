import 'dart:convert';

import '../utils/crypto.dart';
import '../utils/fortune.dart';
import 'achievements.dart';
import 'messaging.dart';


class User {
  late String id;
  String name = "";
  late Achievements achievements;

  late String userSeed;

  User([String? id]) {
    if (id != null) {
      this.id = id;
    }
    else {
      generateIds();
    }

    achievements = Achievements();
  }

  generateIds() async {
    final keyPair = await generateKeyPair();
    final privateKeyBase64 = Base64Codec.urlSafe().encode(await keyPair.extractPrivateKeyBytes());
    final publicKeyBase64 = Base64Codec.urlSafe().encode((await keyPair.extractPublicKey()).bytes);

    this.id = publicKeyBase64;
    this.userSeed = privateKeyBase64;
  }

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
  }}
