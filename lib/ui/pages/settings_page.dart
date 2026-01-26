
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hyle_x/service/BackupRestoreService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/ui_utils.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:jwk/jwk.dart';
import 'package:pem/pem.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../l10n/app_localizations.dart';
import '../../model/messaging.dart';
import '../../model/user.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


  late int _debugEnableCounter;

  @override
  void initState() {
    super.initState();
    _debugEnableCounter = 0;

  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text('$APP_NAME ${l10n.settings}'), elevation: 0),
      body: FutureBuilder(
        future: _loadAllPrefs(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return _buildSettingsList(snapshot.data);
          }
          return Text("Loading...");
        },
      ),
    );
  }

  Widget _buildSettingsList(User user)  {

    final l10n = AppLocalizations.of(context)!;

    return SettingsList(
      lightTheme: SettingsThemeData(
          settingsListBackground: Theme
              .of(context)
              .colorScheme
              .surface,

      ),
      sections: [

        SettingsSection(
          title: Text(l10n.settings_gameSettings, style: TextStyle(color: Colors.brown[800])),
          tiles: [
            SettingsTile.switchTile(
              title: Text(l10n.settings_animateMoves),
              description: Text(l10n.settings_animateMovesDescription),
              initialValue: PreferenceService().animateMoves,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_ANIMATE_MOVES, value);
                setState(() => PreferenceService().animateMoves = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(l10n.settings_showCoordinates),
              description: Text(l10n.settings_showCoordinatesDescription),
              initialValue: PreferenceService().showCoordinates,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_COORDINATES, value);
                setState(() => PreferenceService().showCoordinates = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(l10n.settings_showPointsForOrder),
              description: Text(l10n.settings_showPointsForOrderDescription),
              initialValue: PreferenceService().showPoints,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_POINTS, value);
                setState(() => PreferenceService().showPoints = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(l10n.settings_showHints),
              description: Text(l10n.settings_showHintsDescription),
              initialValue: PreferenceService().showHints,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_HINTS, value);
                setState(() => PreferenceService().showHints = value);
              },
            ),
            SettingsTile.switchTile(
              title: Text(l10n.settings_showMoveErrors),
              description: Text(l10n.settings_showMoveErrorsDescription),
              initialValue: PreferenceService().showChipErrors,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_CHIP_ERRORS, value);
                setState(() => PreferenceService().showChipErrors = value);
              },
            ),
          ],
        ),

        SettingsSection(
          title: Text(l10n.settings_multiplayerSettings, style: TextStyle(color: Colors.brown[800])),
          tiles: [

            SettingsTile(
                title: user.name.isNotEmpty
                    ? Text(l10n.settings_changeYourName(user.name))
                    : Text(l10n.settings_setYourName),
                description: Text(l10n.settings_setOrChangeYourNameDescription),
                onPressed: (value) async {
                  showInputDialog(
                    l10n.dialog_yourName,
                    MaterialLocalizations.of(context),
                    prefilledText: user.name,
                    maxLength: maxNameLength,
                    okHandler: (name) async {
                      user.name = name;
                      await StorageService().saveUser(user);
                      setState(() {});
                    },
                    validationMessage: l10n.error_illegalCharsForUserName,
                    validationHandler: (v) => allowedCharsRegExp.hasMatch(v),
                  );
                }
            ),

            SettingsTile.switchTile(
              title: Text(l10n.settings_showLanguageSelectorForMessages),
              description: Text(l10n.settings_showLanguageSelectorForMessagesDescription),
              initialValue: PreferenceService().showLanguageSelectorForMessages,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SEND_MESSAGE_IN_DIFFERENT_LANGUAGES, value);
                setState(() => PreferenceService().showLanguageSelectorForMessages = value);
              },
            ),

            SettingsTile(
              enabled: user.hasSigningCapability(),
              title: Text('${l10n.settings_signMessages}: ${PreferenceService().signMessages.getName(l10n)}'),
              description: Text(l10n.settings_signMessagesDescription),
              onPressed: (_) {
                showChoiceDialog(l10n.settings_signMessagesExplanation,
                  width: 320,
                  height: 550,
                  highlightButtonIndex: PreferenceService().signMessages.index,
                  firstString: l10n.settings_signMessages_Never,
                  firstDescriptionString: l10n.settings_signMessagesDescription_Never,
                  firstHandler: () {
                    PreferenceService().signMessages = SignMessages.Never;
                    PreferenceService().setInt(PreferenceService.PREF_SIGN_ALL_MESSAGES, PreferenceService().signMessages.index);
                    setState(() {});
                  },
                  secondString: l10n.settings_signMessages_OnDemand,
                  secondDescriptionString: l10n.settings_signMessagesDescription_OnDemand,
                  secondHandler: () {
                    PreferenceService().signMessages = SignMessages.OnDemand;
                    PreferenceService().setInt(PreferenceService.PREF_SIGN_ALL_MESSAGES, PreferenceService().signMessages.index);
                    setState(() {});
                  },
                  thirdString: l10n.settings_signMessages_Always,
                  thirdDescriptionString: l10n.settings_signMessagesDescription_Always,
                  thirdHandler: () {
                    PreferenceService().signMessages = SignMessages.Always;
                    PreferenceService().setInt(PreferenceService.PREF_SIGN_ALL_MESSAGES, PreferenceService().signMessages.index);
                    setState(() {});
                  },

                );
              },

            ),
          ],
        ),

        SettingsSection(
          title: Text(l10n.settings_backupAndRestore, style: TextStyle(color: Colors.brown[800])),
          tiles: [
            SettingsTile(
              leading: Icon(Icons.download, color: Colors.brown[800]),
              title: Text(l10n.settings_backupAll),
              description: Text(l10n.settings_backupAllDescription),
              onPressed: (_) {
                showProgressDialog(l10n.settings_backupAll + " ...");
                BackupRestoreService().backup(
                        (message) => toastInfo(context, message ?? l10n.done + "!"),
                        (message) => toastLost(context, message))
                    .then((_) => SmartDialog.dismiss());
              },
            ),
            SettingsTile(
              leading: Icon(Icons.upload_file, color: Colors.brown[800]),
              title: Text(l10n.settings_restoreFromFile),
              description: Text(l10n.settings_restoreFromFileDescription),
              onPressed: (_) {
                ask(l10n.settings_restoreFromFileConfirmation,
                    AppLocalizations.of(context)!,
                    icon: Icons.warning,
                    () {
                      showProgressDialog(l10n.settings_restoreFromFile + " ...");

                      BackupRestoreService().restore(
                              () => toastInfo(context,"${l10n.done}!"),
                              (message) => toastLost(context, message))
                          .then((_) async {
                            await _loadAllPrefs();
                            setState(() {});
                          }).then((_) => SmartDialog.dismiss());;
                    });

              },
            ),

            SettingsTile(
              enabled: user.hasSigningCapability(),
              leading: Icon(Icons.key, color: Colors.brown[800]),
              title: Text(l10n.settings_sharePublicKey),
              description: Text(l10n.settings_sharePublicKeyDescription),
              onPressed: (_) {
                showChoiceDialog(l10n.settings_sharePublicKeyChooseFormat,
                    firstString: l10n.settings_sharePublicKeyChooseFormat_JWK,
                    firstHandler: () {
                      final publicKeyData = Base64Codec().decoder.convert(user.id);
                      final publicKey = SimplePublicKey(publicKeyData, type: KeyPairType.ed25519);
                      final jwk = Jwk.fromPublicKey(publicKey);
                      final json = jwk.toJson();
                      SharePlus.instance.share(
                          ShareParams(text: json.toString(), subject: 'Public Key JWK from ${toReadableUserId(user.id)}'));
                    },
                    secondString: l10n.settings_sharePublicKeyChooseFormat_PEM,
                    secondHandler: () {
                      final publicKey = Base64Codec().decoder.convert(user.id);
                      final pemBlock = PemCodec(PemLabel.publicKey).encode(publicKey);
                      SharePlus.instance.share(
                          ShareParams(text: pemBlock, subject: 'Public Key PEM from ${toReadableUserId(user.id)}'));
                    },
                    fourthString: l10n.close,
                    fourthHandler: () {}
                );

              },
            ),
          ],
        ),

        SettingsSection(
          tiles: [
            CustomSettingsTile(child:
              GestureDetector(
                onDoubleTap: () {
                  if (isDebug) {
                    showAlertDialog("Debug mode activated");
                  }
                  else {
                    // count to 10 to enable test debug mode
                    _debugEnableCounter++;
                    debugPrint("debug counter: $_debugEnableCounter");
                    if (_debugEnableCounter >= 4) {
                      setState(() {
                        isDebug = true;
                        _debugEnableCounter = 0;
                      });
                      showAlertDialog("Debug mode activated");
                    }
                  }
                },
                child: Padding(padding: EdgeInsets.all(32),
                  child: Text("User-Id: ${toReadableUserId(user.id)} ${isDebug ? "(Debug Mode)" : ""}")),
              )),

            CustomSettingsTile(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 10)),

          ],
        ),
      ],
    );
  }


  Future<User>_loadAllPrefs() async {
    return await StorageService().loadUser() ?? User();
  }

}
