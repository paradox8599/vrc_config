import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:universal_disk_space/universal_disk_space.dart';
import 'package:vrc_config/config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Config get config => Get.find<Config>();

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
              config.read();
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
              // Cache configs

              Obx(() => config.dirExists.value
                  ? cacheCard()
                  : Center(child: Text('no_game'.tr))),

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
          title: Obx(() {
            return Wrap(
              children: [
                Text(config.cacheDir.value),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                () {
                  final sizeDiff = diskSpace.value - config.cacheSize.value;
                  return Text('($diskSpace GB)',
                      style: TextStyle(
                        color: sizeDiff < 10
                            ? Colors.red
                            : sizeDiff < config.cacheSize.value * 0.5
                                ? Colors.yellow
                                : Colors.black,
                      ));
                }()
              ],
            );
          }),
          trailing: Wrap(
            children: [
              ElevatedButton(
                child: Text('copy'.tr),
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: config.cacheDir.value));
                  Get.rawSnackbar(
                    title: 'copied'.tr,
                    message: config.cacheDir.value,
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
          title: Obx(() => Text('${config.cacheSize.value} GB')),
          trailing: Wrap(
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
              '${config.cacheExpiry} ${config.cacheExpiry.value > 1 ? 'days'.tr : 'day'.tr}')),
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
              title: Wrap(
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

  Future<void> _chooseCachePath() async {
    String oldPath = config.cacheDir.value;
    String? result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    Directory dir = Directory(result);
    if (!dir.existsSync()) return;
    config.setCacheDirectory(dir.path);
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
        .where((d) => config.cacheDir.value.startsWith(d.devicePath));
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
          Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
              ),
              Text(config.cacheDir.value),
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
        final dir = Directory(config.cacheDir.value);
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
      initVal: config.cacheSize.value,
      unit: 'GB',
    );
    config.setCacheSize(size);
  }

  Future<void> _editCacheExpiry() async {
    final days = await _numberInputDialog(
      'cache_expiry'.tr,
      initVal: config.cacheExpiry.value,
      unit: 'days'.tr,
    );
    config.setCacheExpiry(days);
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
