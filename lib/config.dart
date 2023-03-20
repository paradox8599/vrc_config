import 'dart:convert';
import 'dart:io';

class Config {
  final File configFile;
  late final Map<String, dynamic> _configData;

  Config(this.configFile) {
    read();
  }

  String get path => configFile.path;

  bool get exists => configFile.existsSync();

  void read() {
    if (!configFile.existsSync()) return;
    final configRaw = configFile.readAsStringSync();
    _configData = jsonDecode(configRaw);
  }

  void save() {
    configFile.writeAsStringSync(jsonEncode(_configData));
  }

  void setCacheDirectory(String path) {
    if (Directory(path).existsSync()) {
      _configData['cacheDirectory'] = path;
      save();
    }
  }

  void setCacheSize(int size) {
    if (size > 0) {
      _configData['cacheSize'] = size;
      save();
    }
  }

  void setCacheExpiry(int expiry) {
    if (expiry > 0) {
      _configData['cacheExpiry'] = expiry;
      save();
    }
  }
}
