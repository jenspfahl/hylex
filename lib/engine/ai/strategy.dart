
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/chip.dart';

import '../../model/common.dart';
import '../../model/coordinate.dart';
import '../../utils/fortune.dart';
import '../../model/matrix.dart';
import '../../model/move.dart';
import '../../model/play.dart';
import '../../model/spot.dart';
import 'ai.dart';

final parallelCount = max(Platform.numberOfProcessors - 2, 2); // save two processors for UI
const POSSIBLE_PALINDROME_REWARD_1 = 2.5;
const POSSIBLE_PALINDROME_REWARD_2 = 1.75;
const POSSIBLE_PALINDROME_REWARD_AT_EDGE = 0.75;

abstract class Strategy {

  Future<Move> nextMove(Play play, AiPathConfig path, Function(Load)? loadChangeListener);
}

class MinimaxStrategy extends Strategy {
  MinimaxStrategy();

  @override
  Future<Move> nextMove(Play play, AiPathConfig path, Function(Load)? loadChangeListener) async {

    final currentRole = play.currentRole;
    final currentChip = currentRole == Role.Order ? play.stock.getChipOfMostStock(): play.currentChip;

    final values = SplayTreeMap<num, Move>((a, b) => a.compareTo(b));

    final loadForecast = _predictLoad(currentRole, play.matrix, path);
    final load = Load(loadForecast);
    if (loadChangeListener != null) {
      load.addListener(() {
        if (load.curr <= 10 || load.curr % 10000 == 0) loadChangeListener(load);
      });
    }

    var moves = _getPossibleMoves(currentChip, play.matrix, currentRole);

    final subscriptionWaits = <Future>[];
    final sendPorts = HashMap<int, SendPort>();

    int collected = 0;
    for (int i = 0; i < parallelCount; i++) {
      final resultPort = ReceivePort("sub_for_$i");
      final subscription = resultPort.listen((message) {

        if (message == "DONE") {
          // close this stream
         // debugPrint("Close sub $i");
         resultPort.close();
        }
        else if (message is SendPort) {
         // debugPrint("put send port: $message for $i");
          sendPorts.putIfAbsent(i, () => message);
        }
        else if (message == -1) {
          load.incProgress();
        }
        else if (message is List) {
          num value = message[0];
          Move move = message[1];

          // correct value for move to avoid common patterns
          if (!move.skipped) {
            value = _simplePatternDetection(play, move, value);
          }

          values.putIfAbsent(value, () {
            // debugPrint("move received with value $value: $move");
            return move;
          });

          collected++;

          if (collected >= moves.length) {
            debugPrint("All values collected, triggering close isolates");
            for (int i = 0; i < parallelCount; i++) {
              sendPorts[i]?.send("DONE");
            }
          }

        }
      },
      onError: (e) => debugPrint("isolate $i error: $e"),
      );

      //debugPrint("Spawn sub $subscription on $i");
      subscriptionWaits.add(subscription.asFuture());

      // Spawning an isolate per CPU copies all parameters. They are then completely detached from its originals
      await Isolate.spawn(_initiateIsolatePerCpu, [resultPort.sendPort, load.max]);
    }

    while (sendPorts.length < subscriptionWaits.length) {
      //debugPrint("Waiting for send ports, missing ${subscriptionWaits.length - sendPorts.length}");
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint("$parallelCount isolates ready to work!");

    int round = 0;
    for (final move in moves) {
      final slot = round % parallelCount;
      //debugPrint("send $move to $slot");
      sendPorts[slot]?.send([currentChip, currentRole, play.matrix, move, path]);
      round ++;
    }


    // wait for all isolate subs to be done
    await Future.wait(subscriptionWaits);


    debugPrint("All isolates are done, load: $load");
    if (currentRole == Role.Chaos) {
      final value = values.firstKey();
      final move = values[value!]!;
      //debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: least valuable move for ${currentRole.name} is $move with a value of $value");
      return move;
    }
    else { // Order
      final value = values.lastKey();
      final move = values[value!]!;

      if (value == 0 && !move.skipped) {
        debugPrint("AI: ${currentRole.name} no valuable move, skipped");
        return Move.skipped();
      }
      //debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: most valuable move for ${currentRole.name} is $move with a value of $value");
      return move;
    }
  }

  num _simplePatternDetection(Play play, Move move, num value) {
    final spotTo = play.matrix.getSpot(move.to!);
    var currentChip = play.currentChip;
    if (move.isMove()) {
      currentChip = play.matrix.getChip(move.from!);
    }
    if (currentChip == null) {
      return value;
    }

    final moveFrom = move.from != null ? play.matrix.getSpot(move.from!) : null;
    var gainedPatternPoints = _getValueByPatterns(currentChip, moveFrom, spotTo);
    //if (gainedPatternPoints > 0) debugPrint("AI: to: $spotTo --> increased by $gainedPatternPoints");

    value += gainedPatternPoints;
    if (move.isMove()) {
      // decrease from if move
      final spotFrom = play.matrix.getSpot(move.from!);
      var lostPatternPoints = _getValueByPatterns(currentChip, null, spotFrom);
      //if (lostPatternPoints > 0) debugPrint("AI: from: $spotFrom --> decreased by $lostPatternPoints");

      value -= lostPatternPoints;

    }

    return value;
  }

  num _getValueByPatterns(GameChip currentChip, Spot? moveFrom, Spot moveTo) { //TODO why from nullable???
    num value = 0;
    //top
    if (_isSecondNeighborTheSame(Direction.North, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_1;
    }
    //bottom
    if (_isSecondNeighborTheSame(Direction.South, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_1;
    }
    //left
    if (_isSecondNeighborTheSame(Direction.West, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_1;
    }
    //right
    if (_isSecondNeighborTheSame(Direction.East, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_1;
    }
    
    // one more possible palindrome
    //top
    if (_isFourthNeighborTheSame(Direction.North, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_2;
    }
    //bottom
    if (_isFourthNeighborTheSame(Direction.South, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_2;
    }
    //left
    if (_isFourthNeighborTheSame(Direction.West, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_2;
    }
    //right
    if (_isFourthNeighborTheSame(Direction.East, currentChip, moveFrom, moveTo)) {
      value += POSSIBLE_PALINDROME_REWARD_2;
    }
    
    // prefer to place at edges
    if (moveFrom != null && !_isInCorner(moveFrom)) {
      //top
      if (_isDirectAtEdge(Direction.North, moveTo)) {
        value += POSSIBLE_PALINDROME_REWARD_AT_EDGE;
      }
      //bottom
      if (_isDirectAtEdge(Direction.South, moveTo)) {
        value += POSSIBLE_PALINDROME_REWARD_AT_EDGE;
      }
      //left
      if (_isDirectAtEdge(Direction.West, moveTo)) {
        value += POSSIBLE_PALINDROME_REWARD_AT_EDGE;
      }
      //right
      if (_isDirectAtEdge(Direction.East, moveTo)) {
        value += POSSIBLE_PALINDROME_REWARD_AT_EDGE;
      }
    }
    return value;
  }

  Future<int> minimax(GameChip? currentChip, Role currentRole, Matrix matrix, AiPathConfig path, int depth, Move? lastMove, Load load) async {
    if (_isTerminal(matrix, depth)) {
      load.incProgress();
      return _getValue(matrix);
    }

    int value;
    if (currentRole == Role.Chaos) { // min
      value = 100000000;
    }
    else { // (currentRole == Role.Order) // max
      value = -100000000;
    }

    final specialTransitionRole = path.specialTransitions[depth];
    final isLastOrderStep = lastMove != null && currentRole == specialTransitionRole;

    var moves = _getPossibleMoves(currentChip, matrix, currentRole,
        isLastOrderStep: isLastOrderStep, lastMove: lastMove); //try to limit
    for (final move in moves) {

      int newValue = await _tryNextMove(currentChip, currentRole, matrix, move, path, depth, load);
      if (currentRole == Role.Chaos) { // min
        value = min(value, newValue);
      }
      else { // (currentRole == Role.Order) // max
        value = max(value, newValue);
      }
    }

    return value;
  }

  _initiateIsolatePerCpu(List<dynamic> initArgs) async {
    SendPort resultPort = initArgs[0];
    int maxLoad = initArgs[1];

    // add listener to load of the particular isolate
    final load = Load(maxLoad);
    load.addListener(() => resultPort.send(-1)); // -1 indicates an intermediate event, no final calculation


    final controlPort = ReceivePort();
    resultPort.send(controlPort.sendPort);

    final subscription = controlPort.listen((message) async {

     // debugPrint("receive $message");

      if (message == "DONE") {
        resultPort.send(message);
      }
      else {
        GameChip? currentChip = message[0];
        Role currentRole = message[1];
        Matrix matrix = message[2];
        Move move = message[3];
        AiPathConfig path = message[4];

        final newValue = await _tryNextMove(currentChip, currentRole, matrix, move, path, path.depth, load);
        resultPort.send([newValue, move]);
      }
    });


    await Future.wait([subscription.asFuture()]);

  }

  Future<int> _tryNextMove(GameChip? currentChip, Role currentRole, Matrix matrix, Move move, AiPathConfig path, int depth, Load load) async {
    final clonedMatrix = matrix.clone();
    _doMove(currentChip, clonedMatrix, move);
    return await minimax(currentChip, _oppositeRole(currentRole), clonedMatrix, path, depth - 1, move, load);
  }

  bool _isTerminal(Matrix matrix, int depth) {
    return depth == 0 || matrix.noFreeSpace();
  }

  int _getValue(Matrix matrix) {
    return matrix.getTotalPointsForOrder();
  }

  List<Move> _getPossibleMoves(GameChip? currentChip, Matrix matrix, Role forRole,
    {bool isLastOrderStep = false, Move? lastMove}) {
    if (forRole == Role.Chaos) {
      // Chaos can only place new chips on free spots
      return matrix.streamFreeSpots().map(((spot) => Move.placed(currentChip!, spot.where))).toList();
    }
    else { // (forRole == Role.Order)

      // Order can only move placed chips, try that,
      // but consider if isLastOrderStep == true:
      // 1. move last placed chip to everywhere as usual
      // 2. move all the other chips only to x and y axis of last places chip
      Iterable<Move> moves;
      final lastWhere = lastMove?.to;
     // if (isLastOrderStep) {
     //   debugPrint("isLastOrderStep pre = $isLastOrderStep lastMove=$lastMove at $lastWhere");
    //  }
      if (isLastOrderStep && lastWhere != null) {
       // debugPrint("isLastOrderStep with lastMove=$lastMove at $lastWhere");

        moves = matrix.streamOccupiedSpots()
            .expand((from) {
              if (from.where == lastWhere) {
               // debugPrint("found last placed $from on $lastWhere");

                final m = _getPossibleMovesFor(matrix, from);
               // debugPrint("found move size = ${m.length}");
                return m;
              }
              else {
                final m = _getPossibleMovesForLandingOnAxisOf(matrix, from, lastWhere);
               // debugPrint("found shorter move size = ${m.length}");
                return m;
              }
            });
      }
      else {
        moves = matrix.streamOccupiedSpots()
            .expand((from) => _getPossibleMovesFor(matrix, from));
      }


      // Try to skip at random position
      final finalMoves = moves.toList();
      int pos = finalMoves.isEmpty ? 0 : diceInt(finalMoves.length);
      finalMoves.insert(pos, Move.skipped());

      return finalMoves;
    }
  }


  Iterable<Move> _getPossibleMovesFor(Matrix matrix, Spot from) {
    return matrix.detectTraceForPossibleOrderMoves(from.where)
        .map((to) => Move.moved(from.content!, from.where, to.where));
  }

  Iterable<Move> _getPossibleMovesForLandingOnAxisOf(Matrix matrix, Spot from, Coordinate lastWhere) {
    return matrix.detectTraceForPossibleOrderMoves(from.where)
        .where((to) => to.where.x == lastWhere.x ||to.where.y == lastWhere.y)
        .map((to) => Move.moved(from.content!, from.where, to.where));
  }

  _doMove(GameChip? currentChip, Matrix matrix, Move move) {
    if (move.isMove()) {
      matrix.move(move.from!, move.to!);
    }
    else if (move.isPlaced()) {
      matrix.put(move.to!, currentChip!);
    }
  }

  int _predictLoad(Role role, Matrix matrix, AiPathConfig path) {
    int value = 0;
    var numberOfPlacedChips = matrix.numberOfPlacedChips();
    final totalCells = matrix.dimension.x * matrix.dimension.y;
    final possibleMaxMoves = (matrix.dimension.x + matrix.dimension.y) - 1; // only -1 to consider skip move

    for (int depth = path.depth; depth > 0; depth--) {

      if (role == Role.Chaos) {
        final freeCells = totalCells - numberOfPlacedChips;

        final newValue = max(1, freeCells);

        value = max(1, value) * newValue;
       // debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, freeCells: $freeCells ==> $newValue");
        numberOfPlacedChips++; // add one for each placed chip by Chaos

        role = Role.Order;
      }
      else { // Order

        final fillRatio = (numberOfPlacedChips - 1) / (totalCells - 1); // ratio based on all cells except current, therefore - 1
        final freeRatio = pow((1 - fillRatio), 2); // trying to determine an avg of moveable free cells
        final avgPossibleMoves = max(1, possibleMaxMoves * freeRatio);

        if (path.specialTransitions[depth] == Role.Order) {
          final avgPossibleMoves = 2;
          final avgPossibleMoveCount = numberOfPlacedChips * avgPossibleMoves;
          final newValue = (max(1, avgPossibleMoveCount.round()))
              + (possibleMaxMoves * (1 - fillRatio)).round(); // plus lastly placed chip

          value = max(1, value) * newValue;
        }
        else {
          final avgPossibleMoveCount = numberOfPlacedChips * avgPossibleMoves;
          final newValue = max(1, avgPossibleMoveCount.round());

          value = max(1, value) * newValue;
          // debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, avgPossibleMoves: $avgPossibleMoves, freeRatio: $freeRatio ==> $newValue");
        }
        role = Role.Chaos;
      }
    }
    return value;

  }

  Role _oppositeRole(Role role) => role == Role.Order ? Role.Chaos : Role.Order;

  bool _isInCorner(Spot from) {
    var northNeighbor = from.getNeighbor(Direction.North);
    var southNeighbor = from.getNeighbor(Direction.South);
    var eastNeighbor = from.getNeighbor(Direction.East);
    var westNeighbor = from.getNeighbor(Direction.West);

    return (northNeighbor == null && eastNeighbor == null)
        || (northNeighbor == null && westNeighbor == null)
        || (southNeighbor == null && eastNeighbor == null)
        || (southNeighbor == null && westNeighbor == null);

  }

  bool _isDirectAtEdge(Direction direction, Spot moveTarget) {
    var neighbor = moveTarget.getNeighbor(direction);
    return neighbor == null;
  }

  bool _isSecondNeighborTheSame(Direction direction, GameChip chip, Spot? from, Spot moveTarget) {
    var neighbor = moveTarget.getNeighbor(direction)?.getNeighbor(direction);
    return neighbor?.where != from?.where && neighbor?.content == chip;
  }

  bool _isFourthNeighborTheSame(Direction direction, GameChip chip, Spot? from, Spot moveTarget) {
    var neighbor = moveTarget.getNeighbor(direction)?.getNeighbor(direction)?.getNeighbor(direction)?.getNeighbor(direction);
    return neighbor?.where != from?.where && neighbor?.content == chip;
  }
}



class Load extends ChangeNotifier {
  int curr = 0;
  final int max;

  Load(this.max) {
    notifyListeners();
  }

  incProgress() {
    curr++;
    notifyListeners();
  }


  double get ratio => curr / max;
  int get readableRatio => (ratio * 100).ceil().clamp(0, 100);

  @override
  String toString() {
    return '$curr/$max ($ratio)';
  }

}


