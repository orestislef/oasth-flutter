import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../widgets/language_toggle.dart';

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String details;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.details,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _toggleExpansion,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.details,
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('more'.tr()),
      ),
      body: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: _buildList(),
        ),
      ),
    );
  }

  List<Widget> _buildList() {
    return [
      const LanguageToggleWidget(),
      CustomExpansionTile(
        title: 'about_app'.tr(),
        details: 'about_app_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'contact_us'.tr(),
        details: 'contact_us_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'privacy_policy'.tr(),
        details: 'privacy_policy_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'terms_and_conditions'.tr(),
        details: 'terms_and_conditions_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq1'.tr(),
        details: 'faq1_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq2'.tr(),
        details: 'faq2_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq3'.tr(),
        details: 'faq3_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq4'.tr(),
        details: 'faq4_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq5'.tr(),
        details: 'faq5_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq6'.tr(),
        details: 'faq6_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq7'.tr(),
        details: 'faq7_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq8'.tr(),
        details: 'faq8_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq9'.tr(),
        details: 'faq9_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq10'.tr(),
        details: 'faq10_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq11'.tr(),
        details: 'faq11_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq12'.tr(),
        details: 'faq12_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq13'.tr(),
        details: 'faq13_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq14'.tr(),
        details: 'faq14_details'.tr(),
      ),
      CustomExpansionTile(
        title: 'faq15'.tr(),
        details: 'faq15_details'.tr(),
      ),
    ];
  }
}
