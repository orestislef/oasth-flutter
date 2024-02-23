import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:oasth/screens/best_route_page.dart';
import 'package:oasth/screens/lines_page.dart';
import 'package:oasth/screens/stops_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: _buildTitleBasedOnIndex(currentIndex),
        ),
        bottomNavigationBar: BottomNavyBar(
          selectedIndex: currentIndex,
          items: <BottomNavyBarItem>[
            BottomNavyBarItem(
              icon: const Icon(Icons.linear_scale_rounded),
              title: _buildTitleBasedOnIndex(0),
              activeColor: Colors.deepOrangeAccent,
              inactiveColor: Colors.deepOrange,
            ),
            BottomNavyBarItem(
              icon: const Icon(Icons.follow_the_signs),
              title: _buildTitleBasedOnIndex(1),
              activeColor: Colors.blueAccent,
              inactiveColor: Colors.blue,
            ),
            BottomNavyBarItem(
              icon: const Icon(Icons.route),
              title: _buildTitleBasedOnIndex(2),
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.green,
            ),
          ],
          onItemSelected: (int value) {
            setState(() {
              currentIndex = value;
            });
          },
        ),
        body: getWidgetBasedOnIndex(currentIndex),
      ),
    );
  }

  Widget getWidgetBasedOnIndex(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const LinesPage();
      case 1:
        return const StopsPage();
      case 2:
        return const BestRoutePage();
      default:
        return Container();
    }
  }

  _buildTitleBasedOnIndex(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return const Text('Γραμμές');
      case 1:
        return const Text('Στάσεις');
      case 2:
        return const Text('Βέλτιστη Διαδρομή');
      default:
        return Container();
    }
  }
}
