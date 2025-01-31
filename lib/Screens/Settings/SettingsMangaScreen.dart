import 'package:flutter/material.dart';

import '../../Adaptor/Settings/SettingsAdaptor.dart';
import '../../DataClass/Setting.dart';
import '../../Functions/Function.dart';
import '../../Preferences/PrefManager.dart';
import '../../Theme/LanguageSwitcher.dart';
import '../../Widgets/AlertDialogBuilder.dart';
import 'BaseSettingsScreen.dart';

class SettingsMangaScreen extends StatefulWidget {
  const SettingsMangaScreen({super.key});

  @override
  State<StatefulWidget> createState() => SettingsMangaScreenState();
}

class SettingsMangaScreenState extends BaseSettingsScreen {
  @override
  String title() => getString.manga;

  @override
  Widget icon() => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(
          size: 52,
          Icons.import_contacts,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );

  @override
  List<Widget> get settingsList {
    return [
      Text(
        getString.anilist,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      SettingsAdaptor(
        settings: [
          Setting(
            type: SettingType.normal,
            name: getString.manageLayout(getString.manga, getString.anilist),
            description: getString.manageLayoutDescription(getString.manga),
            icon: Icons.tune,
            onClick: () async {
              final homeLayoutMap =
                  PrefManager.getVal(PrefName.anilistMangaLayout);
              List<String> titles =
                  List<String>.from(homeLayoutMap.keys.toList());
              List<bool> checkedStates =
                  List<bool>.from(homeLayoutMap.values.toList());

              AlertDialogBuilder(context)
                ..setTitle(
                    getString.manageLayout(getString.manga, getString.anilist))
                ..reorderableMultiSelectableItems(
                  titles,
                  checkedStates,
                  (reorderedItems) => titles = reorderedItems,
                  (newCheckedStates) => checkedStates = newCheckedStates,
                )
                ..setPositiveButton(
                  getString.ok,
                  () {
                    PrefManager.setVal(PrefName.anilistMangaLayout,
                        Map.fromIterables(titles, checkedStates));
                    Refresh.activity[RefreshId.Anilist.mangaPage]?.value = true;
                  },
                )
                ..setNegativeButton(getString.cancel, null)
                ..show();
            },
          ),
        ],
      ),
      Text(
        getString.mal,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      SettingsAdaptor(
        settings: [
          Setting(
            type: SettingType.normal,
            name: getString.manageLayout(getString.manga, getString.mal),
            description: getString.manageLayoutDescription(getString.manga),
            icon: Icons.tune,
            onClick: () async {
              final homeLayoutMap = PrefManager.getVal(PrefName.malMangaLayout);
              List<String> titles =
                  List<String>.from(homeLayoutMap.keys.toList());
              List<bool> checkedStates =
                  List<bool>.from(homeLayoutMap.values.toList());

              AlertDialogBuilder(context)
                ..setTitle(
                  getString.manageLayout(getString.manga, getString.mal),
                )
                ..reorderableMultiSelectableItems(
                  titles,
                  checkedStates,
                  (reorderedItems) => titles = reorderedItems,
                  (newCheckedStates) => checkedStates = newCheckedStates,
                )
                ..setPositiveButton(
                  getString.ok,
                  () {
                    PrefManager.setVal(PrefName.malMangaLayout,
                        Map.fromIterables(titles, checkedStates));
                    Refresh.activity[RefreshId.Mal.mangaPage]?.value = true;
                  },
                )
                ..setNegativeButton(getString.cancel, null)
                ..show();
            },
          ),
        ],
      ),
    ];
  }
}
