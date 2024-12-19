import 'dart:collection';
import 'move.dart';



class Stats {
  final _points = HashMap<Role, int>();
 
  Stats();

  Stats.fromJson(Map<String, dynamic> map) {

    final Map<String, dynamic> pointsMap = map['points']!;
    _points.addAll(pointsMap.map((key, value) {
      final role = Role.values.firstWhere((r) => r.name == key);
      return MapEntry(role, value);
    }));
  }

  Map<String, dynamic> toJson() => {
    'points' : _points.map((key, value) => MapEntry(key.name, value)),
  };

  
  int getPoints(Role role) => _points[role] ?? 0;

  void setPoints(Role role, int points) {
    _points[role] = points;
  }

  Role getWinner() {
    if (getPoints(Role.Order) > getPoints(Role.Chaos)) {
      return Role.Order;
    }
    return Role.Chaos;
  }

}
