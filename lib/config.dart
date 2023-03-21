import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:vrc_config/config_manager.dart';

class Config extends GetxController {
  final File configFile;
  late Map<String, dynamic> _configData;

  final Rx<String> cacheDir = ''.obs;
  final Rx<int> cacheSize = 0.obs;
  final Rx<int> cacheExpiry = 0.obs;

  Config(this.configFile) {
    read();
    cacheDir.value =
        _configData['cache_directory'] ?? ConfigManager.defaultConfigPath;
    cacheSize.value = _configData['cache_size'] ?? 20;
    cacheExpiry.value = _configData['cache_expiry_delay'] ?? 30;
  }

  String get path => configFile.path;

  bool get exists => configFile.existsSync();

  void read() {
    if (!configFile.existsSync()) {
      _configData = {};
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
