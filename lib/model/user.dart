import '../utils/fortune.dart';
import 'achievements.dart';
import 'messaging.dart';


class User {
  late String id;
  String name = "";
  late Achievements achievements;

  late String userSeed;

  User([String? id]) {
    this.id = id ?? generateRandomString(userIdLength);
    this.userSeed= generateRandomString(userSeedLength);
    achievements = Achievements();
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
