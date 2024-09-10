import 'package:flutter/material.dart';
import '../garbage_collector_screens/garbage_collection_routes.dart';
import '../garbage_collector_screens/garbage_collector_profile/garbage_profile_details.dart';
import 'booking_page_collector.dart';
import 'garbage_collector_home.dart';

class GarbageCollectorRoutes extends StatefulWidget {
  @override
  _GarbageCollectorRoutesState createState() => _GarbageCollectorRoutesState();
}

class _GarbageCollectorRoutesState extends State<GarbageCollectorRoutes> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    GarbageCollectorHomePage(),
    GarbageCollectionRoutes(),
    BookingListScreenCollector(),
    GarbageCollectorProfileSection(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9C4), // Banana yellow background color
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delete),
              label: 'Collections',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromARGB(
              255, 0, 0, 0), // Subtle banana yellow for selected item
          unselectedItemColor:
              Color.fromARGB(255, 134, 126, 4), // Unselected item color
          backgroundColor:
              const Color(0xFFFDF6C4), // Light banana yellow for the background
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Allows labels to always show
        ),
      ),
    );
  }
}
