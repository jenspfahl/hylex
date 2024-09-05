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

abstract class Ai { // OrderAi, ChaosAi, TensorFlowOrderAi, ProgrammaticOrderAi, ...

  static final P_SHOULD_THINK = "should_think";

  final AiConfig _aiConfig;
  final String _aiIdentifier;
  final Play _play;

  Ai(this._aiConfig, this._aiIdentifier, this._play);

  String get id => _aiIdentifier;
  defaultAiParams();

  dynamic getP(String key) {
    return _aiConfig.getParam(_aiIdentifier, key);
  }

  setP(String key, dynamic value) {
    _aiConfig.setParam(_aiIdentifier, key, value);
  }

  think(Play play);
}

abstract class ChaosAi extends Ai {
  ChaosAi(super._aiConfig, super._aiIdentifier, super._play);
}

class TensorFlowChaosAi extends ChaosAi {

  final strategy = RandomFreeSpotStrategy();

  TensorFlowChaosAi(AiConfig config, Play play) : super(config, (TensorFlowChaosAi).toString(), play);

  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  think(Play play) {
    /*final freePlace = strategy.getFreePlace(play);
    if (freePlace != null) {
      play.matrix.put(freePlace, piece, parentCellSpot: null);
    }*/
  }

}


class PureRandomChaosAi extends ChaosAi {

  final strategy = RandomFreeSpotStrategy();

  PureRandomChaosAi(AiConfig config, Play play) : super(config, (PureRandomChaosAi).toString(), play);

  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  think(Play play) {
    while (true) {
      if (play.matrix.noFreeSpace()) {
        return;
      }
      final freePlace = strategy.placeChip(play);
      if (freePlace != null && play.currentChip != null) {
        play.matrix.put(freePlace, play.currentChip!);
        return;
      }
    }

  }
}


abstract class OrderAi extends Ai {
  OrderAi(super._aiConfig, super._aiIdentifier, super._play);
}


class AlwaysSkipAi extends OrderAi {


  AlwaysSkipAi(AiConfig config, Play play) : super(config, (PureRandomChaosAi).toString(), play);

  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  think(Play play) {
     // no move
  }
}

