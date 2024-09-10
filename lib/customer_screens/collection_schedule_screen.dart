import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CollectionScheduleScreen extends StatefulWidget {
  @override
  _CollectionScheduleScreenState createState() =>
      _CollectionScheduleScreenState();
}

class _CollectionScheduleScreenState extends State<CollectionScheduleScreen>
    with SingleTickerProviderStateMixin {
  Map<String, TimeOfDay?> selectedDays = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _canChangePreferences = true;
  String? _nextAvailableChange;

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
    _checkChangeLimit();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
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
              selectedDays[day] = _parseTime(time);
            });
          });
        }
      }
    } catch (e) {
      print("Error fetching user preferences: $e");
    }
  }

  Future<void> _checkChangeLimit() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          var data = snapshot.data() as Map<String, dynamic>;
          Timestamp? lastChange = data['last_change'];

          if (lastChange != null) {
            DateTime nextChangeDate =
                lastChange.toDate().add(Duration(days: 7));
            DateTime now = DateTime.now();

            if (now.isBefore(nextChangeDate)) {
              setState(() {
                _canChangePreferences = false;
                _nextAvailableChange =
                    DateFormat.yMMMd().add_jm().format(nextChangeDate);
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error checking change limit: $e");
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print("Error parsing time: $e");
      return null;
    }
  }

  Future<void> _selectTime(String day) async {
    if (selectedDays.values.where((time) => time != null).length >= 3 &&
        selectedDays[day] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only select 3 days. Cancel one to select another.'),
        ),
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedDays[day] ?? TimeOfDay.now(),
      helpText: 'Select a time between 8 AM - 10 AM or 3 PM - 5 PM',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null &&
        (pickedTime.hour >= 8 && pickedTime.hour < 10 ||
            pickedTime.hour >= 15 && pickedTime.hour < 17)) {
      setState(() {
        selectedDays[day] = pickedTime;
      });
    } else if (pickedTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a time within the allowed range.'),
        ),
      );
    }
  }

  bool get _isSaveButtonEnabled {
    return _canChangePreferences &&
        selectedDays.values.where((time) => time != null).length > 0;
  }

  Future<void> _savePreferences() async {
    if (!_isSaveButtonEnabled) return;

    Map<String, String> dayTimePreferences = {};

    selectedDays.forEach((day, time) {
      if (time != null) {
        dayTimePreferences[day] = time.format(context);
      }
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'day_time_preferences': dayTimePreferences,
          'last_change': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preferences saved successfully')),
        );
        setState(() {
          _canChangePreferences = false;
          _nextAvailableChange = DateFormat.yMMMd().add_jm().format(
              DateTime.now().add(Duration(days: 7)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CHANGE COLLECTION SCHEDULE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black26,
                offset: Offset(3, 3),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.yellow[700],
        elevation: 10,
        shadowColor: Colors.yellow[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Instructions:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: 8),
            FadeTransition(
              opacity: _animation,
              child: Text(
                '1. You can select up to 3 days and 3 time slots.\n'
                '2. Time slots are limited to 8 AM - 10 AM and 3 PM - 5 PM.\n'
                '3. You can change your preferences once a week.\n'
                '${_nextAvailableChange != null ? "4. Next available change: $_nextAvailableChange" : ""}',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            SizedBox(height: 16),
            FadeTransition(
              opacity: _animation,
              child: Text(
                'Select Time for Each Day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: selectedDays.keys.map((day) {
                  final time = selectedDays[day];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.access_time, color: Colors.yellow[700]),
                        title: Text(
                          day,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                        subtitle: time != null
                            ? Text(
                                time.format(context),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              )
                            : Text(
                                'No time selected',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                        onTap: _canChangePreferences ? () => _selectTime(day) : null,
                        contentPadding: EdgeInsets.all(16.0),
                        tileColor: Colors.grey[100],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isSaveButtonEnabled ? _savePreferences : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaveButtonEnabled ? Colors.yellow[700] : Colors.grey,
                  elevation: 5,
                  shadowColor: _isSaveButtonEnabled
                      ? Colors.yellow[700]!.withOpacity(0.5)
                      : Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _canChangePreferences
                      ? 'Save New Preferences'
                      : 'Changes Only After A Week',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
