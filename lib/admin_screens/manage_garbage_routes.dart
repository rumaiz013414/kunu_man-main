import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'select_route_points.dart';

class ManageGarbageRoutesPage extends StatefulWidget {
  @override
  _ManageGarbageRoutesPageState createState() =>
      _ManageGarbageRoutesPageState();
}

class _ManageGarbageRoutesPageState extends State<ManageGarbageRoutesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  String? _selectedWasteType;
  List<LatLng> _routePoints = [];
  String? _selectedRouteId; // To track the currently selected route for editing

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final now = DateTime.now();
      final time =
          DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      controller.text = DateFormat('HH:mm').format(time);
    }
  }

  Future<void> _selectRoutePoints() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRoutePointsPage(),
      ),
    );

    if (result != null && result['route_points'] != null) {
      setState(() {
        _routePoints = result['route_points']; // Store selected route points
      });
    }
  }

  String _generateRouteId() {
    return Random().nextInt(1000000).toString(); // Simple random ID
  }

  void _createOrUpdateRoute() async {
    if (_formKey.currentState!.validate() && _routePoints.isNotEmpty) {
      String startTime = _startTimeController.text.trim();
      String endTime = _endTimeController.text.trim();
      String wasteType = _selectedWasteType!;
      String routeId = _selectedRouteId ??
          _generateRouteId(); // Generate new if editing a route

      try {
        await FirebaseFirestore.instance
            .collection('garbage_routes')
            .doc(routeId)
            .set({
          'routeId': routeId,
          'route_points': _routePoints
              .map((point) =>
                  {'latitude': point.latitude, 'longitude': point.longitude})
              .toList(),
          'start_time': startTime,
          'end_time': endTime,
          'waste_type': wasteType,
          'created_at': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_selectedRouteId == null
                  ? 'Route created successfully'
                  : 'Route updated successfully')),
        );

        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill all fields and select route points')),
      );
    }
  }

  void _clearForm() {
    _startTimeController.clear();
    _endTimeController.clear();
    setState(() {
      _selectedWasteType = null;
      _routePoints = [];
      _selectedRouteId = null;
    });
  }

  Future<void> _deleteRoute(String routeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('garbage_routes')
          .doc(routeId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route deleted successfully')),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting route: ${e.toString()}')),
      );
    }
  }

  void _editRoute(Map<String, dynamic> routeData) {
    setState(() {
      _selectedRouteId = routeData['routeId'];
      _routePoints = (routeData['route_points'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList();
      _startTimeController.text = routeData['start_time'];
      _endTimeController.text = routeData['end_time'];
      _selectedWasteType = routeData['waste_type'];
    });
  }

  Stream<QuerySnapshot> _getRoutesStream() {
    return FirebaseFirestore.instance.collection('garbage_routes').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Garbage Collection Routes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _selectRoutePoints,
                    child: Text('Select Route Points'),
                  ),
                  if (_routePoints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Route Points:'),
                          ..._routePoints.map((point) => Text(
                              '(${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})')),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _startTimeController,
                    readOnly: true,
                    decoration:
                        InputDecoration(labelText: 'Estimated Start Time'),
                    onTap: () => _selectTime(context, _startTimeController),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _endTimeController,
                    readOnly: true,
                    decoration:
                        InputDecoration(labelText: 'Estimated End Time'),
                    onTap: () => _selectTime(context, _endTimeController),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedWasteType,
                    decoration: InputDecoration(labelText: 'Waste Type'),
                    items: [
                      DropdownMenuItem(
                        value: 'Electronics',
                        child: Text('Electronics'),
                      ),
                      DropdownMenuItem(
                        value: 'Plastics',
                        child: Text('Plastics'),
                      ),
                      DropdownMenuItem(
                        value: 'Paper',
                        child: Text('Paper'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedWasteType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a waste type';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createOrUpdateRoute,
                    child: Text(_selectedRouteId == null
                        ? 'Create Route'
                        : 'Update Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Existing Routes:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _getRoutesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var routeData = snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                    return ListTile(
                      title: Text('Route ID: ${routeData['routeId']}'),
                      subtitle: Text('Waste Type: ${routeData['waste_type']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editRoute(routeData),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteRoute(routeData['routeId']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
