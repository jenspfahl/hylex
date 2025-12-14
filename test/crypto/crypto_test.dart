import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyle_x/engine/game_engine.dart';
import 'package:hyle_x/model/chip.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/model/coordinate.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/model/move.dart';
import 'package:hyle_x/model/play.dart';
import 'package:hyle_x/model/user.dart';
import 'package:hyle_x/service/MessageService.dart';
import 'package:hyle_x/service/PlayStateManager.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/utils/crypto.dart';
import 'package:hyle_x/utils/fortune.dart';

void main() {

  group("Test crypto", () {


    test('test gen key pair', () async {


      final keyPair = await generateKeyPair();


      final signature = await sign("test".codeUnits, keyPair);
      final valid = await verify("test".codeUnits, signature);

      expect(valid, true);

      final privateKeyBase64 = Base64Codec.urlSafe().encode(await keyPair.extractPrivateKeyBytes());
      final publicKeyBase64 = Base64Codec.urlSafe().encode((await keyPair.extractPublicKey()).bytes);
      final signatureBase64 = Base64Codec.urlSafe().encode(await signature.bytes);


      print(signatureBase64);
      print(publicKeyBase64);
      print(privateKeyBase64);

    });
    

  });

}


