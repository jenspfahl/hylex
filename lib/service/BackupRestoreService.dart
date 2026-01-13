import 'dart:convert';
import 'dart:io';

import 'package:bits/buffer.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hyle_x/model/common.dart';
import 'package:hyle_x/model/messaging.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/play.dart';
import '../model/user.dart';
import '../ui/pages/multi_player_matches.dart';
import 'PreferenceService.dart';


class BackupRestoreService {
  static final BackupRestoreService _service = BackupRestoreService._internal();

  static const extension = "backup";

  static const int export_file_magic = 5952965291224;
  static const int export_file_version = 1;

  factory BackupRestoreService() {
    return _service;
  }

  BackupRestoreService._internal();

  Future<void> backup(Function(String?) successHandler, Function(String) errorHandler) async {
    try {

      final destPath = await FilePicker.platform.getDirectoryPath();
      if (destPath != null) {

        var storagePermission = await Permission.manageExternalStorage.request(); // after Android 10
        if (!storagePermission.isGranted) {
          storagePermission = await Permission.storage.request(); // before Android 10
          if (!storagePermission.isGranted) {
            errorHandler('Please give permission');
            return;
          }
        }


        final saveIn = Directory(destPath);
        final basePath = "${saveIn.path}/hylex";

        int? version;
        while(await File(_getFullPath(basePath, version)).exists()) {
          if (version == null) {
            version = 1;
          }
          else {
            version++;
          }
          if (version > 100000) {
            errorHandler('Cannot create backup file!');
            return;
          }
        }

        final dstFile = await File(_getFullPath(basePath, version));



        final user = await StorageService().loadUser();
        final currentSinglePlay = await StorageService().loadCurrentSinglePlay();
        final allPlayHeaders = await StorageService().loadAllPlayHeaders();

        final bitBuffer = BitBuffer();
        final writer = bitBuffer.writer();

        writer.writeBits(export_file_magic, getBitsNeeded(export_file_magic));
        writer.writeInt(export_file_version);
        writeNullableObject(writer, user);
        writeNullableObject(writer, currentSinglePlay);
        writer.writeInt(allPlayHeaders.length);

        for (int i = 0; i < allPlayHeaders.length; i++) {
          final header = allPlayHeaders[i];
          writeNullableObject(writer, header);
          final play = await StorageService().loadPlayFromHeader(header);
          writeNullableObject(writer, play);
        }

        final data = bitBuffer.toBase64Compressed();
        final signature = sha256.convert(bitBuffer.getLongs());
        final signatureBase64 = Base64Codec.urlSafe().encode(signature.bytes);

        debugPrint("Start writing user ... :" + data);
        debugPrint("Signature:" + signatureBase64);

        await dstFile.writeAsString(data + "/" + signatureBase64);

        successHandler(dstFile.path);
      }
    } on Exception catch (e) {
      errorHandler("Cannot export data! " + e.toString());
      print(e);
    }

  }

  Future<void> restore(Function(bool) successHandler, Function(String) errorHandler) async {

    try {
      final result = await FilePicker.platform.pickFiles();

      if (result != null) {
        try {
          final source = File(result.files.single.path!);
          debugPrint("file to take from: ${source.path}");

          final all = await source.readAsString();
          final split = all.split("/");
          if (split.length != 2) throw Exception("There is no clear signature");
          final data = split[0];
          final signature = split[1];

          final bitBuffer = BitBuffer.fromBase64Compressed(data);

          final signatureFromData = sha256.convert(bitBuffer.getLongs());
          final signatureFromDataBase64 = Base64Codec.urlSafe().encode(signatureFromData.bytes);

          if (signatureFromDataBase64 != signature) throw Exception("Signature mismatch: $signatureFromDataBase64, but should $signature");

          final reader = bitBuffer.reader();

          final magic = reader.readBits(getBitsNeeded(export_file_magic));
          if (magic != export_file_magic) throw Exception("This is not a HyleX backup file");
          final version = reader.readInt();
          if (version != export_file_version) throw Exception("Unsupported version of HyleX backup file: $version");

          final user = readNullableObject(reader, (map) => User.fromJson(map)) as User?;
          final currentSinglePlay = readNullableObject(reader, (map) => Play.fromJson(map)) as Play?;

          debugPrint("Restored: $user");
          debugPrint("Restored: $currentSinglePlay");

          if (user != null) {
            StorageService().saveUser(user);
          }

          if (currentSinglePlay != null) {
            StorageService().savePlay(currentSinglePlay);
          }


          final playHeaders = reader.readInt();

          debugPrint("Restored headers: $playHeaders");

          for (int i = 0; i < playHeaders; i++) {
            final header = readNullableObject(reader, (map) => PlayHeader.fromJson(map)) as PlayHeader?;
            final play = readNullableObject(reader, (map) => Play.fromJson(map)) as Play?;
            debugPrint("Restored $i: $header");
            debugPrint("Restored $i: $play");

            if (header != null) {
              StorageService().savePlayHeader(header);
            }

            if (play != null) {
              StorageService().savePlay(play);
            }
          }



        } catch (e, trace) {
          print(e);
          debugPrintStack(stackTrace: trace);
          debugPrint("corrupt file detected, ignore it!");

          errorHandler("This is not a HyleX backup file or it is corrupted!");
          return;
        }


        successHandler(true);
      } else {
        successHandler(false);
      }
    } catch (e) {
      errorHandler("Cannot import backup file!");
      print(e);
    }
  }


  String _getFullPath(String basePath, int? version) =>
      version != null ? "$basePath ($version).$extension" : "$basePath.$extension";
}

