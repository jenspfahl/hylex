import 'dart:collection';
import 'dart:math';

import '../service/BitsService.dart';
import 'achievements.dart';
import 'fortune.dart';
import 'move.dart';


class User {
  late String id;
  String? name;
  late Achievements achievements;

  User() {
    id = generateRandomString(userIdLength);
    achievements = Achievements();
  }

  User.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    achievements = Achievements.fromJson(map['achievements']!);
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    if (name != null) "name" : name,
    "achievements" : achievements.toJson(),
  };

  String getReadableId() {
    return toReadableId(id);
  }}
