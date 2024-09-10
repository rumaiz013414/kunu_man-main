import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './edit_customer.dart';

class ViewCustomersPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteCustomer(BuildContext context, String customerId) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete this customer?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed) {
      try {
        await _firestore.collection('users').doc(customerId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Customer deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete customer: $e')),
        );
      }
    }
  }

  String _calculateSubscriptionStatus(Timestamp? subscriptionDate) {
    if (subscriptionDate == null) return 'N/A';

    DateTime startDate = subscriptionDate.toDate();
    DateTime currentDate = DateTime.now();
    Duration duration = currentDate.difference(startDate);

    if (duration.inDays > 180) {
      // 6 months
      return 'Expired';
    } else {
      return 'Active';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Customers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('role', isEqualTo: 'customer')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No customers available.'));
          }

          final customers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final customerId = customer.id;
              final customerData = customer.data() as Map<String, dynamic>;
              final customerName = customerData['first_name'] ?? 'Unknown';
              final customerEmail = customerData['email'] ?? 'Unknown';
              final subscriptionDate =
                  customerData['subscriptionDate'] as Timestamp?;
              final subscriptionStatus =
                  _calculateSubscriptionStatus(subscriptionDate);
              final expirationDate = subscriptionDate != null
                  ? subscriptionDate.toDate().toLocal().toString()
                  : 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(customerName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customerEmail),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getStatusColor(subscriptionStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Status: $subscriptionStatus'),
                        ],
                      ),
                      Text('Expires: $expirationDate'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCustomerPage(
                                  customerId: customerId,
                                  customerData: customerData),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteCustomer(context, customerId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
