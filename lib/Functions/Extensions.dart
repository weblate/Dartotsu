import 'package:flutter/cupertino.dart';

import '../main.dart';

extension IntExtension on int {
  double statusBar() {
    var context = navigatorKey.currentContext;
    return this + MediaQuery.paddingOf(context!).top;
  }
}