import 'dart:io';

import 'package:get/get.dart';
import 'package:vrc_config/config.dart';

class ConfigManager {
  late String _configPath;

  String get defaultConfigPath =>
      '${Platform.environment['LocalAppData']!}Low/VRChat/vrchat/config.json';

  File get configFile => File(_configPath);

  ConfigManager() {
    setConfigPath(defaultConfigPath);
  }

  void setConfigPath(String path) {
    _configPath = path;
    _config.value = Config(File(path));
  }

  final Rx<Config> _config = Config(File('')).obs;
  Rx<Config> get config => _config;
}
