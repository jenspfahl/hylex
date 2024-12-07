
import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:hyle_x/model/chip.dart';

import '../fortune.dart';
import '../matrix.dart';
import '../play.dart';
import '../spot.dart';

final parallelCount = max(Platform.numberOfProcessors - 2, 2); // save two processors for UI
const POSSIBLE_PALINDROME_REWARD = 2;

abstract class Strategy {

  Future<Move> nextMove(Play play, int depth, Function(Load)? loadChangeListener);
}

class MinimaxStrategy extends Strategy {
  MinimaxStrategy();

  @override
  Future<Move> nextMove(Play play, int initialDepth, Function(Load)? loadChangeListener) async {

    final currentRole = play.currentRole;
    final currentChip = currentRole == Role.Order ? play.stock.getChipOfMostStock(): play.currentChip;

    final values = SplayTreeMap<int, Move>((a, b) => a.compareTo(b));

    final loadForecast = _predictLoad(currentRole, play.matrix, initialDepth);
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
          int value = message[0];
          Move move = message[1];

          // correct value for move to avoid common patterns
          if (!move.skipped) {
            value = _simplePatternDetection(play, move, value);
          }

          values.putIfAbsent(value, () {
            debugPrint("move received with value $value: $move");
            return move;
          });

          collected++;

          if (collected >= moves.length) {
            debugPrint("All values collected, trigger close isolates");
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
      sendPorts[slot]?.send([currentChip, currentRole, play.matrix, move, initialDepth]);
      round ++;
    }


    // wait for all isolate subs to be done
    await Future.wait(subscriptionWaits);


    debugPrint("All isolates are done, load: $load");
    if (currentRole == Role.Chaos) {
      final value = values.firstKey();
      final move = values[value!]!;
      debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: least valuable move for ${currentRole.name} id $move with a value of $value");
      return move;
    }
    else { // Order
      final value = values.lastKey();
      final move = values[value!]!;
      debugPrint("AI: ${currentRole.name}  $values");
      debugPrint("AI: most valuable move for ${currentRole.name} id $move with a value of $value");
      return move;
    }
  }

  int _simplePatternDetection(Play play, Move move, int value) {
    final moveTarget = play.matrix.getSpot(move.to!);
    var targetChip = play.currentChip;
    if (move.isMove()) {
      targetChip = play.matrix.getChip(move.from!);
    }
    //top
    if (moveTarget.getTopNeighbor()?.getTopNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip two times on top of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //bottom
    if (moveTarget.getBottomNeighbor()?.getBottomNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip two times on bottom of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //left
    if (moveTarget.getLeftNeighbor()?.getLeftNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip two times on left of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //right
    if (moveTarget.getRightNeighbor()?.getRightNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip two times on right of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    
    // one more possible palindrome
    //top
    if (moveTarget.getTopNeighbor()?.getTopNeighbor()?.getTopNeighbor()?.getTopNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip four times on top of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //bottom
    if (moveTarget.getBottomNeighbor()?.getBottomNeighbor()?.getBottomNeighbor()?.getBottomNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip four times on bottom of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //left
    if (moveTarget.getLeftNeighbor()?.getLeftNeighbor()?.getLeftNeighbor()?.getLeftNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip four times on left of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    //right
    if (moveTarget.getRightNeighbor()?.getRightNeighbor()?.getRightNeighbor()?.getRightNeighbor()?.content == targetChip) {
      debugPrint("found same $targetChip four times on right of $moveTarget");
      value += POSSIBLE_PALINDROME_REWARD;
    }
    return value;
  }

  Future<int> minimax(GameChip? currentChip, Role currentRole, Matrix matrix, int initialDepth, int depth, Load load) async {
    if (_isTerminal(matrix, depth)) {
      load.incProgress();
      return _getValue(matrix);
    }
    

    int value;
    Role opponentRole;
    if (currentRole == Role.Chaos) { // min
      value = 100000000;
      opponentRole = Role.Order;
    }
    else { // (currentRole == Role.Order) // max
      value = -100000000;
      opponentRole = Role.Chaos;
    }


    var moves = _getPossibleMoves(currentChip, matrix, currentRole); //try to limit
    for (final move in moves) {

      int newValue = await _tryNextMove(currentChip, opponentRole, matrix, move, initialDepth, depth, load);
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
        int initialDepth = message[4];

        final newValue = await _tryNextMove(currentChip, currentRole, matrix, move, initialDepth, initialDepth, load);
        resultPort.send([newValue, move]);
      }
    });


    await Future.wait([subscription.asFuture()]);

  }

  Future<int> _tryNextMove(GameChip? currentChip, Role currentRole, Matrix matrix, Move move, int initialDepth, int depth, Load load) async {
    final clonedMatrix = matrix.clone();
    _doMove(currentChip, clonedMatrix, move);
    return await minimax(currentChip, currentRole, clonedMatrix, initialDepth, depth - 1, load);
  }

  bool _isTerminal(Matrix matrix, int depth) {
    return depth == 0 || matrix.noFreeSpace();
  }

  int _getValue(Matrix matrix) {
    return matrix.getTotalPointsForOrder();
  }

  List<Move> _getPossibleMoves(GameChip? currentChip, Matrix matrix, Role forRole) {
    if (forRole == Role.Chaos) {
      // Chaos can only place new chips on free spots
      return matrix.streamFreeSpots().map(((spot) => Move.placed(currentChip!, spot.where))).toList();
    }
    else { // (forRole == Role.Order)

      // Order can only move placed chips, try that
      final moves = matrix.streamOccupiedSpots()
          .expand((from) => _getPossibleMovesFor(matrix, from));


      // Try to skip at random position
      final finalMoves = moves.toList();
      int pos = finalMoves.isEmpty ? 0 : diceInt(finalMoves.length);
      finalMoves.insert(pos, Move.skipped());

      return finalMoves;
    }
  }


  Iterable<Move> _getPossibleMovesFor(Matrix matrix, Spot from) {
    return matrix.getPossibleTargetsFor(from.where)
        .map((to) => Move.moved(from.content!, from.where, to.where));
  }

  _doMove(GameChip? currentChip, Matrix matrix, Move move) {
    if (move.isMove()) {
      matrix.move(move.from!, move.to!);
    }
    else if (!move.skipped) { // is placed
      matrix.put(move.from!, currentChip!);
    }
  }

  int _predictLoad(Role role, Matrix matrix, int depth) {
    int value = 0;
    var numberOfPlacedChips = matrix.numberOfPlacedChips();
    final totalCells = matrix.dimension.x * matrix.dimension.y;
    final possibleMaxMoves = (matrix.dimension.x + matrix.dimension.y) - 1; // only -1 to consider skip move

    for (int i = 0; i < depth; i++) {

      if (role == Role.Chaos) {
        final freeCells = totalCells - numberOfPlacedChips;

        final newValue = max(1, freeCells);

        value = max(1, value) * newValue;
       // debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, freeCells: $freeCells ==> $newValue");
        numberOfPlacedChips++; // add one for each placed chip by Chaos

        role = Role.Order;
      }
      else {
        final fillRatio = (numberOfPlacedChips - 1) / (totalCells - 1); // ratio based on all cells except current, therefore - 1
        final freeRatio = pow((1 - fillRatio), 2); // trying to determine an avg of moveable free cells
        final avgPossibleMoves = max(1, possibleMaxMoves * freeRatio);
        final avgPossibleMoveCount = numberOfPlacedChips * avgPossibleMoves;
        final newValue = max(1, avgPossibleMoveCount.round());

        value = max(1, value) * newValue;
       // debugPrint(" interim for $role: depth: $i, placedChips: $numberOfPlacedChips, avgPossibleMoves: $avgPossibleMoves, freeRatio: $freeRatio ==> $newValue");

        role = Role.Chaos;
      }
    }
    return value;

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


