import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    Rx<int> turns = 0.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text('title'.tr),
        actions: [
          Row(
            children: [
              const Text('English'),
              Switch(
                value: Get.locale!.languageCode == 'zh',
                onChanged: (value) {
                  Get.updateLocale(
                      value ? const Locale('zh') : const Locale('en'));
                },
              ),
              const Text('中文'),
            ],
          ),
          IconButton(
            onPressed: () {
              Future.doWhile(() async {
                const ms = 100;
                const loops = 3;
                turns.value += 100;
                await Future.delayed(const Duration(milliseconds: ms));
                final result = turns.value % (ms * loops) != 0;
                return result;
              });
              configMan.reloadConfig();
            },
            icon: Obx(
              () => AnimatedRotation(
                turns: turns.value / 100,
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.refresh),
              ),
            ),
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

              Obx(() => config.value.exists ? cacheCard() : Container()),

              // Other settings...
            ],
          ),
        ),
      ),
    );
  }

  Widget cacheCard() {
    final Rx<int> diskSpace = 0.obs;
    Get.put(diskSpace, tag: 'diskSpace');
    _getDiskSpace(diskSpace);
    return configCard(
      'cache'.tr,
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
                final sizeDiff = diskSpace.value - config.value.cacheSize.value;
                return Text('($diskSpace GB)',
                    style: TextStyle(
                      color: sizeDiff < 10
                          ? Colors.red
                          : sizeDiff < config.value.cacheSize.value * 0.5
                              ? Colors.yellow
                              : Colors.black,
                    ));
              })
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: Text('copy'.tr),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: config.value.cacheDir.value));
                  Get.rawSnackbar(
                    title: 'copied'.tr,
                    message: config.value.cacheDir.value,
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              ElevatedButton(
                onPressed: _chooseCachePath,
                child: Text('edit'.tr),
              ),
            ],
          ),
        ),

        // Size

        ListTile(
          leading: Text('cache_size'.tr),
          title: Obx(() => Text('${config.value.cacheSize.value} GB')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _clearCache,
                child: Text('clear'.tr),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              ElevatedButton(
                onPressed: _editCacheSize,
                child: Text('edit'.tr),
              ),
            ],
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
    String oldPath = config.value.cacheDir.value;
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    Directory dir = Directory(result);
    if (!dir.existsSync()) return;
    config.value.setCacheDirectory(dir.path);
    // prompt for moving files
    // TODO: move files
    // await Get.defaultDialog(
    //   title: 'move_cache'.tr,
    //   content: Text('move_cache_confirm'.tr),
    //   textConfirm: 'move'.tr,
    //   textCancel: 'cancel'.tr,
    //   onConfirm: () {
    //     Get.back();
    //   },
    // );
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

  void _clearCache() {
    Rx<bool> show = false.obs;
    Get.defaultDialog(
      title: 'clear_cache'.tr,
      content: Column(
        children: [
          Text('clear_cache_confirm'.tr),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Text(config.value.cacheDir.value),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              SizedBox(
                width: 16,
                height: 16,
                child: Obx(
                  () => show.value
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const SizedBox(),
                ),
              )
            ],
          ),
        ],
      ),
      textConfirm: 'clear'.tr,
      textCancel: 'cancel'.tr,
      onConfirm: () async {
        final dir = Directory(config.value.cacheDir.value);
        show.value = true;
        try {
          final cacheDir = Directory('${dir.path}\\Cache-WindowsPlayer');
          cacheDir.deleteSync(recursive: true);
          // ignore: empty_catches
        } catch (e) {}
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
      },
    );
  }

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
