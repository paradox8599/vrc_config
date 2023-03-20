import 'package:get/get.dart';

class Tr extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh': {
          'title': 'VRChat 配置',
          'cache': '缓存',
          'cache_loc': '缓存位置',
          'choose': '选择',
          'cache_size': '缓存大小',
          'clear': '清除',
          'cache_expiry': '缓存过期时间',
          'day': '天',
          'days': '天',
          'config_path': '配置文件路径',
          'config_not_found': '未找到配置文件',
          'enter': '输入',
          'edit': '修改',
        },
        'en': {
          'title': 'VRChat Configs',
          'cache': 'Cache',
          'cache_loc': 'Cache Location',
          'choose': 'Choose',
          'cache_size': 'Cache Size',
          'clear': 'Clear',
          'cache_expiry': 'Cache Expiry',
          'day': 'day',
          'days': 'days',
          'config_path': 'Config Path',
          'config_not_found': 'Config file not found',
          'enter': 'Enter',
          'edit': 'Edit',
        }
      };
}
