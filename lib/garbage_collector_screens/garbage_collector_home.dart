import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GarbageCollectorHomePage extends StatefulWidget {
  @override
  _GarbageCollectorHomePageState createState() =>
      _GarbageCollectorHomePageState();
}

class _GarbageCollectorHomePageState extends State<GarbageCollectorHomePage> {
  int _currentIndex = 0;
  String _collectorName = "Garbage Collector"; // Default name
  bool _isLoading = true; // Loading state

  // List of images for the carousel
  final List<String> imgList = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRH6lycMNl6e37Bx1TYAhinEPNYpTQWMUWu1Q&s',
    'https://as1.ftcdn.net/v2/jpg/01/78/67/96/1000_F_178679633_UVvAxl884FvnSV45uMt5sgxpN33FJGWd.jpg',
    'https://as2.ftcdn.net/v2/jpg/04/67/48/53/1000_F_467485323_Tv01IEe8xq4NgK9jdYzsDAVt0FBBpoqC.jpg',
    'https://askhrgreen.org/wp-content/uploads/2019/08/Suffolk-GAC.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRnbetNBpflQ-VzwJiTAm9geCtjz0sbV1bHYCEdy9RTHyk5jZLMdKV12WsZ5n-M2LIwEsM&usqp=CAU',
    'https://i.ytimg.com/vi/pUqplRBQWFo/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGDEgYyhyMA8=&rs=AOn4CLArYlTLg4LIXpLDNU4P9bsRdbjVHw',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCollectorName(); // Fetch collector name on initialization
  }

  void _fetchCollectorName() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (snapshot.exists) {
        var userData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _collectorName = userData['name'] ?? "Garbage Collector";
          _isLoading = false; // Set loading to false after fetching
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? Text('Loading...')
            : Center(child: Text('Welcome, $_collectorName')), // Centered title
        backgroundColor: Colors.amber[700], // Vibrant yellowish color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30.0)), // Rounded corners
        ),
        elevation: 4, // Optional shadow
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          _buildCarouselSlider(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 200.0,
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            autoPlayCurve: Curves.fastOutSlowIn,
            enableInfiniteScroll: true,
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: imgList.map((item) {
            return Container(
              margin: EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imgList.map((url) {
            int index = imgList.indexOf(url);
            return Container(
              width: 8.0,
              height: 8.0,
              margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index
                    ? Colors.yellow[700]
                    : Colors.grey[300],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
