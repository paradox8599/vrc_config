import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:universal_disk_space/universal_disk_space.dart';
import 'package:vrc_config/config.dart';
import 'package:vrc_config/config_manager.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  ConfigManager get configMan => Get.find<ConfigManager>();
  Rx<Config> get config => configMan.config;

  @override
  Widget build(BuildContext context) {
    final Rx<int> diskSpace = 0.obs;
    Get.put(diskSpace, tag: 'diskSpace');
    _getDiskSpace(diskSpace);

    return Scaffold(
      appBar: AppBar(
        title: Text('title'.tr),
        actions: [
          IconButton(
            onPressed: () {
              configMan.reloadConfig();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // config path

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Text('config_path'.tr),
                      title: Obx(
                        () => config.value.exists
                            ? Text(config.value.path)
                            : Text('config_not_found'.tr),
                      ),
                      trailing: ElevatedButton(
                        onPressed: _chooseConfigPath,
                        child: Text('choose'.tr),
                      ),
                    ),
                  ],
                ),
              ),

              // Cache configs

              configCard(
                'cache'.tr,
                action: ElevatedButton(
                  onPressed: () {},
                  child: Text('clear'.tr),
                ),
                [
                  // cache directory

                  ListTile(
                    leading: Text('cache_dir'.tr),
                    title: Row(
                      children: [
                        Obx(() => Text(config.value.cacheDir.value)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        Obx(() {
                          final sizeDiff =
                              diskSpace.value - config.value.cacheSize.value;
                          return Text('($diskSpace GB)',
                              style: TextStyle(
                                color: sizeDiff < 10
                                    ? Colors.red
                                    : sizeDiff <
                                            config.value.cacheSize.value * 0.5
                                        ? Colors.yellow
                                        : Colors.black,
                              ));
                        })
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: _chooseCachePath,
                      child: Text('move'.tr),
                    ),
                  ),

                  // Size

                  ListTile(
                    leading: Text('cache_size'.tr),
                    title:
                        Obx(() => Text('${config.value.cacheSize.value} GB')),
                    trailing: ElevatedButton(
                      onPressed: _editCacheSize,
                      child: Text('edit'.tr),
                    ),
                  ),

                  // Expiry

                  ListTile(
                    leading: Text('cache_expiry'.tr),
                    title: Obx(() => Text(
                        '${config.value.cacheExpiry} ${config.value.cacheExpiry.value > 1 ? 'days'.tr : 'day'.tr}')),
                    trailing: ElevatedButton(
                      onPressed: _editCacheExpiry,
                      child: Text('edit'.tr),
                    ),
                  ),
                ],
              ),
              // Other settings...
            ],
          ),
        ),
      ),
    );
  }

  Widget configCard(String title, List<Widget> children, {Widget? action}) =>
      Card(
        child: Column(
          children: [
            ListTile(
              title: Row(
                children: [
                  Text(title),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  if (action != null) action,
                ],
              ),
            ),
            ...children,
          ],
        ),
      );

  Future<void> _chooseConfigPath() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    PlatformFile? file = result?.files.single;
    if (file == null) return;
    configMan.setConfigPath(file.path!);
  }

  Future<void> _chooseCachePath() async {
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    Directory dir = Directory(result);
    if (!dir.existsSync()) return;
    config.value.setCacheDirectory(dir.path);
    _getDiskSpace(Get.find(tag: 'diskSpace'));
  }

  Future<void> _getDiskSpace(Rx<int> driveSpace) async {
    final diskSpace = DiskSpace();
    await diskSpace.scan();
    final space = diskSpace.disks
        .where((d) => config.value.cacheDir.value.startsWith(d.devicePath));
    driveSpace.value =
        space.isEmpty ? 0 : space.first.availableSpace ~/ 1024 ~/ 1024 ~/ 1024;
  }

  void _clearCache() {}

  Future<void> _editCacheSize() async {
    final size = await _numberInputDialog(
      'cache_size'.tr,
      initVal: config.value.cacheSize.value,
      unit: 'GB',
    );
    config.value.setCacheSize(size);
  }

  Future<void> _editCacheExpiry() async {
    final days = await _numberInputDialog(
      'cache_expiry'.tr,
      initVal: config.value.cacheExpiry.value,
      unit: 'days'.tr,
    );
    config.value.setCacheExpiry(days);
  }

  Future<int> _numberInputDialog(String title,
      {int initVal = 0, String unit = ''}) async {
    final ct = TextEditingController(text: initVal.toString());
    int? result;

    await Get.defaultDialog(
      title: title,
      content: TextField(
        keyboardType: TextInputType.number,
        controller: ct,
        textAlign: TextAlign.center,
        decoration: InputDecoration(suffixText: unit),
      ),
      textConfirm: 'confirm'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () {
        result = int.parse(ct.text);
        Get.back();
      },
    );

    return result ?? initVal;
  }
}
