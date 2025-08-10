import '../utils/fortune.dart';
import 'achievements.dart';
import 'messaging.dart';


class User {
  late String id;
  String name = "";
  late Achievements achievements;

  User([String? id]) {
    this.id = id ?? generateRandomString(userIdLength);
    achievements = Achievements();
  }

  User.fromJson(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    achievements = Achievements.fromJson(map['achievements']!);
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name" : name,
    "achievements" : achievements.toJson(),
  };

  String getReadableId() {
    return toReadableId(id);
  }}
