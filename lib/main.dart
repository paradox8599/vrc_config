import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrc_config/config_manager.dart';
import 'package:vrc_config/home_page.dart';
import 'package:vrc_config/tr.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  await init();
  runApp(const VRCConfigApp());
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ConfigManager());

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    title: 'VRC Config',
    size: Size(600, 450),
    minimumSize: Size(600, 450),
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class VRCConfigApp extends StatelessWidget {
  const VRCConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: Tr(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      fallbackLocale: const Locale('en'),
      title: 'VRC Config',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.amber,
      ),
      home: const HomePage(),
    );
  }
}
