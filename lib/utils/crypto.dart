import 'package:cryptography/cryptography.dart';

Future<SimpleKeyPair> generateKeyPair([String? seed]) async {
  final algorithm = Ed25519();
  return seed != null
      ? algorithm.newKeyPairFromSeed(seed.padRight(32, "=").codeUnits)
      : algorithm.newKeyPair();
}

Future<Signature> sign(List<int> message, KeyPair keyPair) async {
  final algorithm = Ed25519();
  return algorithm.sign(
    message,
    keyPair: keyPair,
  );
}

Future<bool> verify(List<int> message, Signature signature) async {
  final algorithm = Ed25519();
  return algorithm.verify(
    message,
    signature: signature,
  );
}