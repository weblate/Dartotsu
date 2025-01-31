import 'package:collection/collection.dart';
import 'package:dantotsu/Preferences/PrefManager.dart';
import 'package:flutter/material.dart';

import 'MediaService.dart';

class MediaServiceProvider with ChangeNotifier {
  late MediaService _currentService;

  MediaService get currentService => _currentService;

  MediaServiceProvider() {
    var preferredService = PrefManager.getVal(PrefName.source);
    _currentService =
        _findService(preferredService) ?? MediaService.allServices.first;
  }

  void switchService(String serviceName) {
    var newService = _findService(serviceName);
    if (newService != null) {
      _currentService = newService;
      PrefManager.setVal(PrefName.source, serviceName);
      notifyListeners();
    } else {
      throw Exception("Service with name $serviceName not found");
    }
  }

  MediaService? _findService(String serviceName) => MediaService.allServices
      .firstWhereOrNull((s) => s.runtimeType.toString() == serviceName);
}
