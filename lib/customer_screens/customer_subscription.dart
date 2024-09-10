import 'package:flutter/material.dart';
import 'payment_gatewat.dart';

class SubscriptionPage extends StatelessWidget {
  final String userName;
  final String userId;

  SubscriptionPage({required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Information'),
        backgroundColor: Colors.yellow[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome $userName!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'User ID: $userId',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Thank you for registering with our service. Here are the benefits of subscribing:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            _buildBenefitList(),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
              ),
              onPressed: () {
                // Pass userId for payment processing
                StripeService.instance.makePayment(context, userId: userId);
              },
              child: Text('Proceed to payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(Icons.check, color: Colors.green),
          title: Text('Access to exclusive content'),
        ),
        ListTile(
          leading: Icon(Icons.check, color: Colors.green),
          title: Text('Priority customer support'),
        ),
        ListTile(
          leading: Icon(Icons.check, color: Colors.green),
          title: Text('Monthly newsletters and updates'),
        ),
      ],
    );
  }
}
