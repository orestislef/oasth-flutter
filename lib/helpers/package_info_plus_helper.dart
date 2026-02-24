import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoPlusHelper {
  static String? packageName;

  static Future<void> ensureInitialized() async {
    final info = await PackageInfo.fromPlatform();
    packageName = info.packageName;
  }
}
