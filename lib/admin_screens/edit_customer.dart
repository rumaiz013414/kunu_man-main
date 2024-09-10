import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCustomerPage extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  EditCustomerPage({required this.customerId, required this.customerData});

  @override
  _EditCustomerPageState createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerData['name']);
    _emailController =
        TextEditingController(text: widget.customerData['email']);
  }

  void _updateCustomer() {
    _firestore.collection('users').doc(widget.customerId).update({
      'name': _nameController.text,
      'email': _emailController.text,
    }).then((_) {
      Navigator.pop(context);
    });
  }

  void _deleteCustomer() {
    _firestore.collection('users').doc(widget.customerId).delete().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully deleted')),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Customer')),
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
                  onPressed: _updateCustomer,
                  child: Text('Save Changes'),
                ),
                ElevatedButton(
                  onPressed: _deleteCustomer,
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
