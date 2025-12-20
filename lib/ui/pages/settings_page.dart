
import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:hyle_x/service/BackupRestoreService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/ui_utils.dart';
import 'package:hyle_x/utils/fortune.dart';
import 'package:jwk/jwk.dart';
import 'package:pem/pem.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart';
import '../../main.dart';
import '../../model/messaging.dart';
import '../../model/user.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  late LocalizationDelegate localizationDelegate;

  @override
  void initState() {
    super.initState();
    localizationDelegate = LocalizedApp.of(context).delegate;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$APP_NAME Settings'), elevation: 0),
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

    return SettingsList(
      lightTheme: SettingsThemeData(
          settingsListBackground: Theme
              .of(context)
              .colorScheme
              .surface,

      ),
      sections: [
        SettingsSection(
          title: Text('Common', style: TextStyle(color: Colors.brown[800])),
          tiles: [
            if (isDebug) SettingsTile(
              title: Text("Language"),
              description: Text(localizationDelegate.currentLocale.languageCode),
              onPressed: (context) {
                showInputDialog("Choose a language. Allowed values: $SUPPORTED_LANGUAGES",
                    okHandler: (value) => setState(() {
                      localizationDelegate.changeLocale(Locale(value));
                    }),
                  validationMessage: "This language is not supported!",
                  validationHandler: (v) => SUPPORTED_LANGUAGES.contains(v),
                );

              },
            ),

          ],
        ),
        SettingsSection(
          title: Text('Game Settings', style: TextStyle(color: Colors.brown[800])),
          tiles: [
            SettingsTile.switchTile(
              title: const Text('Show coordinates'),
              description: const Text('Show coordinates at the x and y axis on the grid'),
              initialValue: PreferenceService().showCoordinates,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_COORDINATES, value);
                setState(() => PreferenceService().showCoordinates = value);
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Show points'),
              description: const Text("Show order points on chips"),
              initialValue: PreferenceService().showPoints,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_POINTS, value);
                setState(() => PreferenceService().showPoints = value);
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Show hints'),
              description: const Text("Show hints to help what to do"),
              initialValue: PreferenceService().showHints,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_HINTS, value);
                setState(() => PreferenceService().showHints = value);
              },
            ),
            SettingsTile.switchTile(
              title: const Text('Show errors'),
              description: const Text("Show errors when moving chips wrongly"),
              initialValue: PreferenceService().showChipErrors,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_CHIP_ERRORS, value);
                setState(() => PreferenceService().showChipErrors = value);
              },
            ),
          ],
        ),

        SettingsSection(
          title: Text('Multiplayer matches', style: TextStyle(color: Colors.brown[800])),
          tiles: [

            SettingsTile(
                title: user.name.isNotEmpty ? Text("Change your name '${user.name}'") : Text('Set your name'),
                description: const Text("Your name is shown in messages for opponents"),
                onPressed: (value) async {
                  showInputDialog(translate('dialogs.yourName'),
                    prefilledText: user.name,
                    maxLength: maxNameLength,
                    okHandler: (name) async {
                      user.name = name;
                      await StorageService().saveUser(user);
                      setState(() {});
                    },
                    validationMessage: translate("errors.illegalCharsForUserName"),
                    validationHandler: (v) => allowedCharsRegExp.hasMatch(v),
                  );
                }
            ),

            SettingsTile(
              enabled: user.hasSigningCapability(),
              title: Text('Sign messages: ${PreferenceService().signMessages.name}'),
              description: const Text("Cryptographically sign messages you send in multi player matches."),
              onPressed: (_) {
                showChoiceDialog("Sign messages with your public key, if you want to ensure, your messages are not tampered and to prove, they are originated from you. This might be important if you share your moves with the public.",
                  width: 320,
                  height: 490,
                  highlightButtonIndex: PreferenceService().signMessages.index,
                  firstString: "Never",
                  firstDescriptionString: "No signature is added and you are not bothered about this.",
                  firstHandler: () {
                    PreferenceService().signMessages = SignMessages.Never;
                    PreferenceService().setInt(PreferenceService.PREF_SIGN_ALL_MESSAGES, PreferenceService().signMessages.index);
                    setState(() {});
                  },
                  secondString: "On demand",
                  secondDescriptionString: "You can decide for each single match independently.",
                  secondHandler: () {
                    PreferenceService().signMessages = SignMessages.OnDemand;
                    PreferenceService().setInt(PreferenceService.PREF_SIGN_ALL_MESSAGES, PreferenceService().signMessages.index);
                    setState(() {});
                  },
                  thirdString: "Always",
                  thirdDescriptionString: "A signature is added to all messages automatically without asking you.",
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
          title: Text('Backup / Restore', style: TextStyle(color: Colors.brown[800])),
          tiles: [
            SettingsTile(
              leading: Icon(Icons.download, color: Colors.brown[800]),
              title: Text("Backup all into a file"),
              description: Text("Save your user identity, all ongoing and finished matches and all achievements"),
              onPressed: (_) {
                BackupRestoreService().backup(
                        (message) => toastInfo(context, message ?? "Done!"),
                        (message) => toastLost(context, message));
              },
            ),
            SettingsTile(
              leading: Icon(Icons.upload_file, color: Colors.brown[800]),
              title: Text("Restore from a file"),
              description: Text("Usually after re-installation of the app, you can import a previously created backup file"),
              onPressed: (_) {
                ask("Restoring from a file will overwrite all current data! Are you sure to do this:",
                    icon: Icons.warning,
                    () {
                      BackupRestoreService().restore(
                              (b) => toastInfo(context, b ? "Done!" : "Error!"),
                              (message) => toastLost(context, message));
                    });

              },
            ),

            SettingsTile(
              enabled: user.hasSigningCapability(),
              leading: Icon(Icons.key, color: Colors.brown[800]),
              title: Text("Share your public key"),
              description: Text("If you sign your message, it could be necessary to share your public key with others."),
              onPressed: (_) {
                showChoiceDialog("Choose a way how to share your public key:",
                    firstString: 'As JWK format',
                    firstHandler: () {
                      final publicKeyData = Base64Codec.urlSafe().decoder.convert(user.id);
                      final publicKey = SimplePublicKey(publicKeyData, type: KeyPairType.ed25519);
                      final jwk = Jwk.fromPublicKey(publicKey);
                      final json = jwk.toJson();
                      SharePlus.instance.share(
                          ShareParams(text: json.toString(), subject: 'Public Key JWK from ${toReadableId(user.id)}'));
                    },
                    secondString: 'As PEM format',
                    secondHandler: () {
                      final publicKey = Base64Codec.urlSafe().decoder.convert(user.id);
                      final pemBlock = PemCodec(PemLabel.publicKey).encode(publicKey);
                      SharePlus.instance.share(
                          ShareParams(text: pemBlock, subject: 'Public Key PEM from ${toReadableId(user.id)}'));
                    },
                    fourthString: "Close",
                    fourthHandler: () {}
                );

              },
            ),
          ],
        ),

        SettingsSection(
          tiles: [
            CustomSettingsTile(child:
              Padding(padding: EdgeInsets.all(32),
                child: Text("Your User-Id: ${toReadableId(user.id)}"))),

            const CustomSettingsTile(child: SizedBox(height: 36)),

          ],
        ),
      ],
    );
  }


  Future<User>_loadAllPrefs() async {
    return await StorageService().loadUser() ?? User();
  }

}
