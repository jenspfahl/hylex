import 'package:hyle_x/engine/ai/strategy.dart';

import '../../model/common.dart';
import '../../model/move.dart';
import '../../model/play.dart';


abstract class Ai {
  Future<Move> think(Play play, Function(Load) aiProgressListener);
}

class DefaultChaosAi extends Ai {

  final strategy = MinimaxStrategy();

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

class DefaultOrderAi extends Ai {

  final strategy = MinimaxStrategy();


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
  late int _depth;
  late Map<int, Role> specialTransitions;

  AiPathConfig(this.startRole, this._depth, this.specialTransitions);

  int get depth => _depth;
}


