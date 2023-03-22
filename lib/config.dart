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
    cacheDir.listen((value) {
      getDirSize();
    });
    read();
  }

  final RxBool _exists = false.obs;
  RxBool get exists {
    _exists.value = configFile.existsSync();
    return _exists;
  }

  final RxBool _dirExists = false.obs;
  RxBool get dirExists {
    _dirExists.value = configFile.parent.existsSync();
    return _dirExists;
  }

  void read() {
    if (!dirExists.value) return;
    if (!configFile.existsSync()) {
      _configData = {};
    } else {
      final configRaw = configFile.readAsStringSync();
      _configData = jsonDecode(configRaw);
    }
    setCacheDirectory(_configData['cache_directory'] ?? configPath);
    setCacheSize(_configData['cache_size'] ?? 20);
    setCacheExpiry(_configData['cache_expiry_delay'] ?? 30);
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

  final Rx<int> dirSize = 0.obs;
  int getDirSize() {
    int totalSize = 0;
    var dir = Directory('$cacheDir\\Cache-WindowsPlayer');
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      // ignore: empty_catches
    } catch (e) {}
    dirSize.value = totalSize ~/ 1024 ~/ 1024 ~/ 1024;
    return totalSize;
  }

  int get remainingSize {
    return cacheSize.value - dirSize.value;
  }
}
