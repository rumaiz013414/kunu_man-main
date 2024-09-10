import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testing/customer_screens/customer_profile/notifications_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> imgList = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRH6lycMNl6e37Bx1TYAhinEPNYpTQWMUWu1Q&s',
    'https://as1.ftcdn.net/v2/jpg/01/78/67/96/1000_F_178679633_UVvAxl884FvnSV45uMt5sgxpN33FJGWd.jpg',
    'https://as2.ftcdn.net/v2/jpg/04/67/48/53/1000_F_467485323_Tv01IEe8xq4NgK9jdYzsDAVt0FBBpoqC.jpg',
    'https://askhrgreen.org/wp-content/uploads/2019/08/Suffolk-GAC.jpg',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRnbetNBpflQ-VzwJiTAm9geCtjz0sbV1bHYCEdy9RTHyk5jZLMdKV12WsZ5n-M2LIwEsM&usqp=CAU',
    'https://i.ytimg.com/vi/pUqplRBQWFo/hq720.jpg?sqp=-oaymwE7CK4FEIIDSFryq4qpAy0IARUAAAAAGAElAADIQj0AgKJD8AEB-AH-CYAC0AWKAgwIABABGDEgYyhyMA8=&rs=AOn4CLArYlTLg4LIXpLDNU4P9bsRdbjVHw',
  ];

  Map<String, String?> userPreferences = {};
  List<Map<String, dynamic>> userBookings = [];
  List<Map<String, dynamic>> latestNews = [];
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchUserPreferences();
    _fetchUserBookings();
    _fetchLatestNews();
    _fetchNotifications();
  }

  Future<void> _fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          var data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            _userName = data['first_name'] ?? 'Friend';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching user name: $e";
      });
    }
  }

  Future<void> _fetchUserPreferences() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          var data = snapshot.data() as Map<String, dynamic>;
          var preferences =
              data['day_time_preferences'] as Map<String, dynamic>;

          setState(() {
            preferences.forEach((day, time) {
              userPreferences[day] = time;
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching user preferences: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserBookings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .get();

        setState(() {
          userBookings = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching user bookings: $e";
      });
    }
  }

  Future<void> _fetchLatestNews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('latest_news')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        latestNews = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching latest news: $e";
      });
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        notifications = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching notifications: $e";
      });
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('bookings')
            .doc(bookingId)
            .delete();

        setState(() {
          userBookings.removeWhere((booking) => booking['id'] == bookingId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking deleted successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting booking: $e')),
      );
    }
  }

  Future<void> _confirmDeleteBooking(String bookingId) async {
    TextEditingController _verificationController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must enter the verification text
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Cancellation!'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to cancel this booking? Please type "CANCEL" to confirm.'),
                SizedBox(height: 10),
                TextField(
                  controller: _verificationController,
                  decoration: InputDecoration(
                    labelText: 'Enter "CANCEL" to confirm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                if (_verificationController.text.toUpperCase() == 'CANCEL') {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  _deleteBooking(bookingId); // Call delete booking function
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Verification failed. Please enter "CANCEL" to confirm.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10.0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $_userName',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black26,
                    offset: Offset(3, 3),
                  ),
                ],
              ),
            ),
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow[700],
        shadowColor: Colors.yellow[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        actions: [
          SizedBox(
            width: 40,
            child: IconButton(
              icon: Icon(Icons.notifications, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Carousel Slider
            _buildCarouselSlider(),
            SizedBox(height: 20),
            // Introduction Section
            _buildIntroduction(),
            SizedBox(height: 20),
            // Collection Days and Times
            _buildCollectionDaysAndTimes(),
            SizedBox(height: 20),
            // User Bookings
            _buildUserBookings(),
            SizedBox(height: 20),
            // Latest News Section
            _buildLatestNews(),
            SizedBox(height: 20),
            // Follow Us Section
            _buildFollowUsSection(),
            SizedBox(height: 20),
            // Footer Section
            _buildFooterSection(),
          ],
        ),
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
          items: imgList
              .map((item) => Container(
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
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Container(
                              color: Colors.black54,
                              padding: EdgeInsets.all(5.0),
                              child: Text(
                                'Slide ${imgList.indexOf(item) + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
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

  Widget _buildIntroduction() {
    return Text(
      'Welcome To Kunu.lk!!! Your Trusted Partner In Efficient Garbage Management. '
      'We Are Dedicated To Ensuring Your Environment Remains Clean And Sustainable. '
      'With Our Range Of Services, You Can Easily Manage Your Waste Disposal Needs From The Comfort Of Your Home.',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[900],
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildCollectionDaysAndTimes() {
    return Container(
      padding: EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.teal,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Your Collection Days and Times',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey[400]!,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : userPreferences.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No collection preferences set. Please update your preferences.',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: userPreferences.entries.map((entry) {
                            return Card(
                              elevation: 5,
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.calendar_today,
                                    color: Colors.teal),
                                title: Text(entry.key),
                                subtitle:
                                    Text(entry.value ?? 'No time selected'),
                                trailing: Icon(Icons.chevron_right),
                              ),
                            );
                          }).toList(),
                        ),
        ],
      ),
    );
  }

  Widget _buildUserBookings() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.teal,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Your Private Bookings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey[400]!,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  : userBookings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No bookings found. Please make a booking.',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          children: userBookings.map((booking) {
                            return Card(
                              elevation: 5,
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                leading:
                                    Icon(Icons.bookmark, color: Colors.teal),
                                title: Text(booking['date'] ?? ''),
                                subtitle: Text(
                                    'Quantity: ${booking['waste_quantity']} kg'),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteBooking(
                                      booking['id'] as String),
                                ),
                                onTap: () {
                                  // Additional action on tap if needed
                                },
                              ),
                            );
                          }).toList(),
                        ),
        ],
      ),
    );
  }

  Widget _buildLatestNews() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.teal,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Latest News',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey[400]!,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          ...latestNews.map((news) {
            return ListTile(
              leading: Icon(Icons.announcement, color: Colors.yellow[700]),
              title: Text(news['title'] ?? 'Latest News'),
              subtitle: Text(news['description'] ?? 'Click to read more'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // Handle news detail navigation
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFollowUsSection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.teal,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Center(
            child: Text(
              'Follow Us',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.grey[400]!,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialMediaIcon(
                icon: Icons.language,
                url: 'https://www.kunu.lk',
                tooltip: 'Visit Website',
              ),
              _buildSocialMediaIcon(
                icon: Icons.facebook,
                url: 'https://www.facebook.com/kunu.lk',
                tooltip: 'Visit Facebook',
              ),
              _buildSocialMediaIcon(
                icon: Icons.share,
                url: 'https://www.instagram.com/kunu.lk',
                tooltip: 'Visit Instagram',
              ),
              _buildSocialMediaIcon(
                icon: Icons.email,
                url: 'mailto:rifkhanfaris4260@gmail.com',
                tooltip: 'Send an Email',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Terms & Conditions | Privacy Policy',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            '© 2024 Kunu.lk. All rights reserved.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaIcon(
      {required IconData icon, required String url, required String tooltip}) {
    return IconButton(
      icon: Icon(icon, color: Colors.teal),
      tooltip: tooltip,
      onPressed: () async {
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Could not launch $url';
        }
      },
    );
  }
}
