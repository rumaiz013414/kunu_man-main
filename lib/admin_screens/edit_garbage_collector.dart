import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditGarbageCollectorPage extends StatefulWidget {
  final String collectorId;
  final Map<String, dynamic> collectorData;

  EditGarbageCollectorPage(
      {required this.collectorId, required this.collectorData});

  @override
  _EditGarbageCollectorPageState createState() =>
      _EditGarbageCollectorPageState();
}

class _EditGarbageCollectorPageState extends State<EditGarbageCollectorPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.collectorData['name']);
    _emailController =
        TextEditingController(text: widget.collectorData['email']);
  }

  void _updateCollector() {
    _firestore.collection('users').doc(widget.collectorId).update({
      'name': _nameController.text,
      'email': _emailController.text,
    }).then((_) {
      Navigator.pop(context);
    });
  }

  void _deleteCollector() {
    _firestore.collection('users').doc(widget.collectorId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully deleted')),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Garbage Collector')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _updateCollector,
                  child: Text('Save Changes'),
                ),
                ElevatedButton(
                  onPressed: _deleteCollector,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
