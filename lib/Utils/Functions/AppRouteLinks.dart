import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../../Api/Services/Extension/Services.dart';
import '../../Core/Services/MediaServiceController.dart';
import '../../Core/State/State.dart';
import '../../Core/ThemeManager/LanguageSwitcher.dart';
import '../../Screen/Detail/Watch/Data/Media/ResumeStore.dart';
import '../../Screen/Downloads/DownloadsScreen.dart';
import '../../Screen/Feed/FeedNavigation.dart';
import '../../Screen/Feed/ResumeLauncher.dart';
import 'DeepLinkHandlers.dart';
import 'NavigateToScreen.dart';
import 'SnackBar.dart';

const appRouteHost = 'app';

String appRouteLink(String route) => 'dartotsu://$appRouteHost/$route';

class AppRouteLinks extends DeepLinkHandler {
  static const routes = {'continue', 'search', 'downloads', 'calendar'};

  static String? _route(Uri uri) {
    if (!appSchemes.contains(uri.scheme.toLowerCase()) ||
        uri.host != appRouteHost) {
      return null;
    }
    final route = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    return routes.contains(route) ? route : null;
  }

  @override
  bool matches(Uri uri) => _route(uri) != null;

  @override
  Future<void> handle(BuildContext context, Uri uri) async {
    final services = find<MediaServiceController>();
    final service = services.currentService.value;
    switch (_route(uri)) {
      case 'continue':
        final entry = ResumeStore.visible(service).firstOrNull;
        if (entry == null) {
          return snackString(getString.shortcutNothingToContinue);
        }
        await openResume(context, service, entry);
      case 'search':
        openSearch(context, service);
      case 'downloads':
        unawaited(navigateToPage(context, const DownloadsScreen()));
      case 'calendar':
        final extension = services.services
            .where((s) => s.id == extensionServiceId)
            .firstOrNull;
        if (extension != null) openCalendar(context, extension);
    }
  }
}
