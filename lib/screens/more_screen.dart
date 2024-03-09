import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('more'.tr()),
      ),
      body: const Center(
        child: Text('more'),
      ),
    );
  }
}
