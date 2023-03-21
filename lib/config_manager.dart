import 'dart:io';

import 'package:get/get.dart';
import 'package:vrc_config/config.dart';

class ConfigManager {
  late String _configPath;

  static String get defaultConfigPath =>
      '${Platform.environment['LocalAppData']!}Low/VRChat/vrchat/config.json';

  File get configFile => File(_configPath);

  ConfigManager() {
    setConfigPath(defaultConfigPath);
  }

  void setConfigPath(String path) {
    _configPath = path;
    config.value = Config(File(path));
  }

  void reloadConfig() => config.value = Config(File(_configPath));

  final Rx<Config> config = Config(File('')).obs;
}
