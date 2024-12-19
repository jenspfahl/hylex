import 'dart:collection';
import 'dart:ffi';
import 'dart:ui';

import 'package:hyle_x/model/ai/strategy.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../move.dart';
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

abstract class Ai {

  static const P_SHOULD_THINK = "should_think";

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

  Future<Move> think(Play play, Function(Load) aiProgressListener);
}

abstract class ChaosAi extends Ai {
  ChaosAi(super._aiConfig, super._aiIdentifier, super._play);
}

class DefaultChaosAi extends ChaosAi {

  final strategy = MinimaxStrategy();

  DefaultChaosAi(AiConfig config, Play play) : super(config, (DefaultChaosAi).toString(), play);


  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  Future<Move> think(Play play, Function(Load) aiProgressListener) async {
    AiPathConfig depth = _getMaxDepthBasedOnWorkload(play);
    if (play.matrix.numberOfPlacedChips() == 0) {
      depth = AiPathConfig(play.currentRole, 1, {});
    }
    else if (play.matrix.numberOfPlacedChips() == 1) {
      depth = AiPathConfig(play.currentRole, 2, {});
    }
    return strategy.nextMove(play, depth, aiProgressListener);
  }
}

abstract class OrderAi extends Ai {
  OrderAi(super._aiConfig, super._aiIdentifier, super._play);
}


class DefaultOrderAi extends OrderAi {

  final strategy = MinimaxStrategy();
  DefaultOrderAi(AiConfig config, Play play) : super(config, (DefaultChaosAi).toString(), play);

  @override
  defaultAiParams() {
    setP(Ai.P_SHOULD_THINK, 0.5 * 0.25);
  }

  @override
  Future<Move> think(Play play, Function(Load) aiProgressListener) async {
    AiPathConfig path = _getMaxDepthBasedOnWorkload(play);
    if (play.matrix.numberOfPlacedChips() == 1) {
      path = AiPathConfig(play.currentRole, 2, {});
    }
    return strategy.nextMove(play, path, aiProgressListener);
  }
}

AiPathConfig _getMaxDepthBasedOnWorkload(Play play) {
  // 3 is the max to get reasonable predictions in time
  // Order--Chaos--Order-Chaos doesn't need a fourth Chaos as Chaos cannot remove gained points,
  // so we go with Order(3)--Chaos(2)--Order(1).
  if (play.currentRole == Role.Order) {
    if (play.dimension >= 9) {
      return AiPathConfig(Role.Order, 3, {1: Role.Order});
    }
    else {
      return AiPathConfig(Role.Order, 3, {});
    }
  }
  else { // current role
    if (play.dimension >= 9) {
      // Chaos(3)--Order(2)--Chaos(1) if larger dimension
      return AiPathConfig(Role.Chaos, 3, {2: Role.Order});
    }
    else {
      // Chaos(4)--Order(3)--Chaos(2)--Order(1)
      return AiPathConfig(Role.Chaos, 4, {3: Role.Order, 1: Role.Order});
    }
  }
}

class AiPathConfig {
  late Role startRole;
  late int depth;
  late Map<int, Role> specialTransitions;

  AiPathConfig(this.startRole, this.depth, this.specialTransitions);
}


