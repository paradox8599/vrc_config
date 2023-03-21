import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';

class Config extends GetxController {
  static final configPath =
      '${Platform.environment['LocalAppData']!}Low/VRChat/vrchat';
  final File configFile = File('$configPath/config.json');

  late Map<String, dynamic> _configData;

  final Rx<String> cacheDir = ''.obs;
  final Rx<int> cacheSize = 0.obs;
  final Rx<int> cacheExpiry = 0.obs;

  Config() {
    read();
    cacheDir.value = _configData['cache_directory'] ?? configPath;
    cacheSize.value = _configData['cache_size'] ?? 20;
    cacheExpiry.value = _configData['cache_expiry_delay'] ?? 30;
  }

  final RxBool _exists = false.obs;
  RxBool get exists {
    _exists.value = configFile.existsSync();
    return _exists;
  }

  void read() {
    if (!configFile.existsSync()) {
      _configData = {};
      save();
      return;
    }
    final configRaw = configFile.readAsStringSync();
    _configData = jsonDecode(configRaw);
  }

  void save() {
    configFile.writeAsStringSync(jsonEncode(_configData));
  }

  void setCacheDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      cacheDir.value = dir.path;
      _configData['cache_directory'] = dir.path;
      save();
    }
  }

  void setCacheSize(int size) {
    if (size > 0) {
      cacheSize.value = size;
      _configData['cache_size'] = size;
      save();
    }
  }

  void setCacheExpiry(int days) {
    if (days > 0) {
      cacheExpiry.value = days;
      _configData['cache_expiry_delay'] = days;
      save();
    }
  }
}
