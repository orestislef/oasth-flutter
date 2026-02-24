import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/api/api/api.dart';
import 'package:oasth/data/oasth_repository.dart';
import 'package:oasth/screens/home_page.dart';

import 'helpers/language_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await OasthRepository().init();

  // Start background data download (non-blocking)
  Api.downloadAllData().then((_) {
    debugPrint('[App] Background data download complete');
  }).catchError((e) {
    debugPrint('[App] Background data download failed: $e');
  });

  runApp(
    EasyLocalization(
      supportedLocales: LanguageHelper.getAvailableLocales(),
      path: LanguageHelper.getAssetsPath(),
      fallbackLocale: LanguageHelper.getAvailableLocales().first,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      title: 'OASTH',
      home: const HomePage(),
    );
  }
}
