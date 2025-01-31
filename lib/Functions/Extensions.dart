import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../Services/MediaService.dart';
import '../Services/ServiceSwitcher.dart';
import '../main.dart';

extension IntExtension on int {
  double statusBar() {
    var context = navigatorKey.currentContext ?? Get.context;
    return this + MediaQuery.paddingOf(context!).top;
  }

  double bottomBar() {
    var context = navigatorKey.currentContext ?? Get.context;
    return this + MediaQuery.of(context!).padding.bottom;
  }

  double screenWidth() {
    var context = navigatorKey.currentContext ?? Get.context;
    return MediaQuery.of(context!).size.width;
  }

  double screenWidthWithContext(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double screenHeight() {
    var context = navigatorKey.currentContext ?? Get.context;
    return MediaQuery.of(context!).size.height;
  }
}

extension Stuff on BuildContext {
  MediaService currentService({bool listen = true}) {
    return Provider.of<MediaServiceProvider>(this, listen: listen)
        .currentService;
  }
}
