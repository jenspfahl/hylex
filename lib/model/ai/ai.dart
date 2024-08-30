import 'dart:collection';

import 'package:hyle_9/model/ai/strategy.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';


class AiConfig {

  Map<String, Map<String, dynamic>> _parameters = HashMap();

  AiConfig();

  AiConfig.fromJsonMap(Map<String, dynamic> map) {
    final parameters = map["parameters"];
    if (parameters != null && parameters is Map<String, dynamic>) {
      _parameters = parameters.map((key, value) =>
          MapEntry(key, value));
    }
  }
  
  dynamic getParam(String aiIdentifier, String key) {
    var aiParameters = _parameters[aiIdentifier];
    if (aiParameters == null) {
      return null;
    }
    else {
      return aiParameters[key];
    }
  }

  setParam(String aiIdentifier, String key, dynamic value) {
    var aiParameters = _parameters[aiIdentifier];
    if (aiParameters == null) {
      aiParameters = HashMap();
      _parameters[aiIdentifier] = aiParameters;
    }
    aiParameters[key] = value;
  }

  Map<String, dynamic> toJson() => {
    'parameters' : _parameters,
  };
}

abstract class Ai<T> {

  static final P_SHOULD_THINK = "should_think";

  final AiConfig _aiConfig;
  final String _aiIdentifier;

  Ai(this._aiConfig, this._aiIdentifier);

  String get id => _aiIdentifier;
  defaultAiParams();

  dynamic getP(String key) {
    return _aiConfig.getParam(_aiIdentifier, key);
  }

  setP(String key, dynamic value) {
    _aiConfig.setParam(_aiIdentifier, key, value);
  }

  bool shouldThink(T data);
  think(T data);
}

abstract class PlayAi extends Ai<Play> {
  PlayAi(super._aiConfig, super._aiIdentifier);
}

class SprinkleResourcesAi extends PlayAi {

  final strategy = RandomFreeSpotStrategy();

  SprinkleResourcesAi(AiConfig config) : super(config, (SprinkleResourcesAi).toString());

  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  bool shouldThink(Play play) => probabilityOf(getP(Ai.P_SHOULD_THINK));

  @override
  think(Play play) {
    final freePlace = strategy.getFreePlace(play);
    if (freePlace != null) {
     // play.matrix.put(freePlace, piece, parentCellSpot: null);
    }
  }

}

class SprinkleAlienCellsAi extends PlayAi {

  final strategy = RandomFreeSpotStrategy();

  SprinkleAlienCellsAi(AiConfig config) : super(config, (SprinkleAlienCellsAi).toString());

  @override
  defaultAiParams()  {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.75);
  }

  @override
  bool shouldThink(Play play) => probabilityOf(getP(Ai.P_SHOULD_THINK));

  @override
  think(Play play) {
    final freePlace = strategy.getFreePlace(play);
    if (freePlace != null) {
      //play.matrix.put(freePlace, piece, parentCellSpot: null);
    }
  }
}

abstract class SpotAi extends Ai<Spot> {
  SpotAi(super.aiConfig, super.aiIdentifier);

  think(Spot spot);
}
class OrderAi extends SpotAi {
  OrderAi(super.aiConfig, super.aiIdentifier);

  think(Spot spot) {
    // TODO: implement think
    throw UnimplementedError();
  }

  @override
  defaultAiParams() {
    // TODO: implement defaultAiParams
    throw UnimplementedError();
  }

  @override
  bool shouldThink(Spot data) {
    // TODO: implement shouldThink
    throw UnimplementedError();
  }
}
