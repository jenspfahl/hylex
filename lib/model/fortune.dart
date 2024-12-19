import 'dart:math';

final rnd = Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

bool probabilityOf(double probability) => rnd.nextDouble() < probability;

bool fiftyFifty() => rnd.nextBool();

dynamic flip(dynamic a, dynamic b) => probabilityOf(0.5) ? a : b;

dynamic flipWithProbability(double probabilityForA, dynamic a, dynamic b) => probabilityOf(probabilityForA) ? a : b;

int diceInt(int max) => rnd.nextInt(max);

double diceDouble(double max) => rnd.nextDouble() * max;

String generateRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(rnd.nextInt(_chars.length))));

extension DoubleFortuneExtensions on double {

  double fuzzyIncrease(double probability, double maxDecrease) {
    return flipWithProbability(probability, this + diceDouble(maxDecrease), this);
  }

  double fuzzyDecrease(double probability, double maxDecrease) {
    return flipWithProbability(probability, this - diceDouble(maxDecrease), this);
  }
}

extension IntFortuneExtensions on int {
  
  int fuzzyTo(int to) {
    return rnd.nextInt(to - this + 1) + this;
  }

  int fuzzyIncrease(double probability, int maxDecrease) {
    return flipWithProbability(probability, this + diceInt(maxDecrease), this);
  }

  int fuzzyDecrease(double probability, int maxDecrease) {
    return flipWithProbability(probability, this - diceInt(maxDecrease), this);
  }
}

extension ListFortuneExtensions on List {
  T diceElement<T>() {
    final idx = diceInt(this.length);
    return this[idx];
  }
}


