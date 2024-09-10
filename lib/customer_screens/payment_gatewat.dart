import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package
import 'package:testing/services/stripe_keys.dart'; // Stripe keys file
import 'package:testing/common/authentication_screens/login_screen.dart'; // Assuming this exists

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Make payment with userId passed to handle user-specific actions
  Future<void> makePayment(BuildContext context,
      {required String userId}) async {
    try {
      // Create payment intent on the backend
      String? paymentIntentClientSecret =
          await _createPaymentIntent(100, "usd");

      if (paymentIntentClientSecret == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create payment intent')),
        );
        return;
      }

      // Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'KUNU.LK',
        ),
      );

      // Process payment with user context and userId for transaction logging
      await _processPayment(context, userId);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during payment: ${e.toString()}')),
      );
    }
  }

  // Create payment intent on Stripe's API
  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        'amount': _calculateTotalAmount(amount),
        'currency': currency,
      };

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
            "Content-Type": "application/x-www-form-urlencoded"
          },
        ),
      );

      if (response.data != null) {
        return response.data["client_secret"];
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Process the payment and handle the result (navigate, log transaction, etc.)
  Future<void> _processPayment(BuildContext context, String userId) async {
    try {
      await Stripe.instance.presentPaymentSheet();

      // Show success message after payment
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful!')),
      );

      // Update the user's subscription status after successful payment
      await _updateSubscriptionStatus(userId);

      // Navigate to the desired page (e.g., Login page or another screen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                LoginPage()), // Example: Login page after payment
      );
    } catch (e) {
      print(e);

      // Handle payment failure
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Payment failed: ${e.error.localizedMessage}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    }
  }

  // Calculate the total amount in the smallest currency unit (e.g., cents)
  String _calculateTotalAmount(int amount) {
    final calculateTotalAmount =
        amount * 100; // Stripe uses the smallest currency unit
    return calculateTotalAmount.toString();
  }

  // Update the user's subscription status in Firestore after successful payment
  Future<void> _updateSubscriptionStatus(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscriptionStatus': 'active',
        'subscriptionDate': FieldValue.serverTimestamp(),
      });
      print('Subscription status updated successfully for user: $userId');
    } catch (e) {
      print('Failed to update subscription status: $e');
    }
  }
}
