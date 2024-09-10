import 'package:flutter/material.dart';
import 'customer_profile/customer_profile_details.dart';
import 'customer_services_mainpage.dart';
import 'customer_home_page.dart';
import 'customer_support.dart';

class CustomerHomePage extends StatefulWidget {
  final int initialIndex;

  const CustomerHomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _CustomerHomePageState createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [
    HomePage(),
    CustomerRoutesPage(),
    CustomerSupportScreen(),
    CustomerProfileDetails(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
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
              icon: Icon(Icons.route),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent),
              label: 'Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person), // Customer support icon
              label: 'Profile', // Customer support label
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
