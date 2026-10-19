import 'package:flutter/material.dart';

import '../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../Model/Setting.dart';
import 'Categories/AboutSettings.dart';
import 'Categories/AccountSettings.dart';
import 'Categories/DownloadSettings.dart';
import 'Categories/ExtensionSettings.dart';
import 'Categories/AppearanceSettings.dart';
import 'Categories/GeneralSettings.dart';
import 'Categories/NetworkSettings.dart';
import 'Categories/UpdateSettings.dart';
import 'Categories/WatchSettings.dart';

export 'Categories/AboutSettings.dart' show settingsAppVersion;

class SettingsCategory {
  final String title;
  final String description;
  final IconData icon;
  final List<Setting> Function(BuildContext) build;
  final List<Setting> Function(BuildContext)? search;

  const SettingsCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.build,
    this.search,
  });
}

List<SettingsCategory> get settingsCategories => [
  SettingsCategory(
    title: getString.settingsAppearance,
    description: getString.settingsAppearanceDesc,
    icon: Icons.palette_outlined,
    build: appearanceSettings,
    search: appearanceRows,
  ),
  SettingsCategory(
    title: getString.settingsGeneral,
    description: getString.settingsGeneralDesc,
    icon: Icons.tune_rounded,
    build: generalSettings,
  ),
  SettingsCategory(
    title: getString.settingsNetwork,
    description: getString.settingsNetworkDesc,
    icon: Icons.language_rounded,
    build: networkSettings,
  ),
  SettingsCategory(
    title: getString.settingsWatch,
    description: getString.settingsWatchDesc,
    icon: Icons.movie_filter_rounded,
    build: watchSettings,
    search: watchRows,
  ),
  SettingsCategory(
    title: getString.settingsDownloads,
    description: getString.settingsDownloadsDesc,
    icon: Icons.download_rounded,
    build: downloadSettings,
  ),
  SettingsCategory(
    title: getString.extension(2),
    description: getString.settingsExtensionsDesc,
    icon: Icons.extension_rounded,
    build: extensionSettings,
  ),
  SettingsCategory(
    title: getString.account,
    description: getString.settingsAccountDesc,
    icon: Icons.person_outline_rounded,
    build: accountSettings,
  ),
  SettingsCategory(
    title: getString.settingsUpdates,
    description: getString.settingsUpdatesDesc,
    icon: Icons.system_update_alt_rounded,
    build: updateSettings,
  ),
  SettingsCategory(
    title: getString.about,
    description: getString.settingsAboutDesc,
    icon: Icons.info_outline_rounded,
    build: aboutSettings,
  ),
];

List<Setting> allSettings(BuildContext context) => [
  for (final c in settingsCategories) ...[
    Setting.header(c.title.toUpperCase()),
    ...(c.search ?? c.build)(context),
  ],
];
