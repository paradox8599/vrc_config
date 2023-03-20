import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrc_config/config_manager.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final configMan = Get.find<ConfigManager>();

    final Rx<String> cachePath = '-'.obs;
    final Rx<double> cacheSize = 0.0.obs;
    final Rx<int> cacheExpiry = 0.obs;

    return Scaffold(
      appBar: AppBar(
        title: Text('title'.tr),
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
                        () => configMan.config.value.exists
                            ? Text(configMan.config.value.path)
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
                [
                  // Location

                  ListTile(
                    leading: Text('cache_loc'.tr),
                    title: Text(cachePath.value),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: Text('choose'.tr),
                    ),
                  ),

                  // Size

                  ListTile(
                    leading: Text('cache_size'.tr),
                    title: Row(children: [
                      Text('$cacheSize GB'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text('clear'.tr),
                      ),
                    ]),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: Text('edit'.tr),
                    ),
                  ),

                  // Expiry

                  ListTile(
                    leading: Text('cache_expiry'.tr),
                    title: Text(
                      '$cacheExpiry ${cacheExpiry.value > 1 ? 'days'.tr : 'day'.tr}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {},
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

  Widget configCard(String title, List<Widget> children) => Card(
        child: Column(
          children: [
            ListTile(
              title: Text(title),
            ),
            ...children,
          ],
        ),
      );

  Future<void> _chooseConfigPath() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    PlatformFile? file = result?.files.single;
    if (file == null) return;
    final configMan = Get.find<ConfigManager>();
    configMan.setConfigPath(file.path!);
  }

  void _chooseCachePath() {}

  void _clearCache() {}

  void _editCacheSize() {}

  void _editCacheExpiry() {}
}
