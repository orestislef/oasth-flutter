import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:oasth/helpers/language_helper.dart';

class LanguageToggleWidget extends StatefulWidget {
  const LanguageToggleWidget({super.key});

  @override
  State<LanguageToggleWidget> createState() => _LanguageToggleWidgetState();
}

class _LanguageToggleWidgetState extends State<LanguageToggleWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'app_language'.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () async {
                await context
                    .setLocale(LanguageHelper.getAvailableLocales().last)
                    .then((value) => Navigator.of(context).pop());
              },
              child: Image.asset(
                'assets/icons/greek_flag.png',
                width: 50,
                height: 50,
                opacity: LanguageHelper.getLanguageUsedInApp(context) == 'el'
                    ? const AlwaysStoppedAnimation(1.0)
                    : const AlwaysStoppedAnimation(0.3),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () async {
                await context
                    .setLocale(LanguageHelper.getAvailableLocales().first)
                    .then((value) => Navigator.of(context).pop());
              },
              child: Image.asset(
                'assets/icons/english_flag.png',
                width: 50,
                height: 50,
                opacity: LanguageHelper.getLanguageUsedInApp(context) == 'en'
                    ? const AlwaysStoppedAnimation(1.0)
                    : const AlwaysStoppedAnimation(0.3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class LocaleNotificationDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  Locale? _overriddenLocale;

  void setLocale(Locale locale) {
    _overriddenLocale = locale;
  }

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const DefaultMaterialLocalizations();
  }

  @override
  bool shouldReload(
          covariant LocalizationsDelegate<MaterialLocalizations> old) =>
      true;

  Locale? get overriddenLocale => _overriddenLocale;
}
