import 'dart:collection';
import 'dart:ui';

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
    int depth = _getMaxDepthBasedOnWorkload(play);
    if (play.matrix.numberOfPlacedChips() == 0) {
      depth = 1;
    }
    else if (play.matrix.numberOfPlacedChips() == 1) {
      depth = 2;
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
    int depth = _getMaxDepthBasedOnWorkload(play);
    if (play.matrix.numberOfPlacedChips() == 1) {
      depth = 2;
    }
    return strategy.nextMove(play, depth, aiProgressListener);
  }
}

int _getMaxDepthBasedOnWorkload(Play play) {
  int depth = 4;
  if (play.matrix.dimension.x >= 9) {
    depth = 3;
  }

  return depth;
}


