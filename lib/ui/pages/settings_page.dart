
import 'package:flutter/material.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:hyle_x/service/BackupRestoreService.dart';
import 'package:hyle_x/service/StorageService.dart';
import 'package:hyle_x/ui/ui_utils.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../app.dart';
import '../../model/messaging.dart';
import '../../model/user.dart';
import '../../service/PreferenceService.dart';
import '../dialogs.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {


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
              description: const Text("Show errors when movng chips wrongly"),
              initialValue: PreferenceService().showChipErrors,
              onToggle: (bool value) {
                PreferenceService().setBool(PreferenceService.PREF_SHOW_CHIP_ERRORS, value);
                setState(() => PreferenceService().showChipErrors = value);
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
