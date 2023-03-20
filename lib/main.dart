import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vrc_config/config_manager.dart';
import 'package:vrc_config/home_page.dart';
import 'package:vrc_config/tr.dart';

void main() async {
  await init();
  runApp(const VRCConfigApp());
}

Future<void> init() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(ConfigManager());
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
