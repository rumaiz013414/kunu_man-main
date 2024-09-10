import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'customer_screens/collection_schedule_screen.dart';
import 'customer_screens/customer_profile/customer_profile_details.dart';
import 'customer_screens/customer_profile/customer_profile_photo.dart';
import 'customer_screens/update_location_screen.dart';
import 'garbage_collector_screens/garbage_collector_profile/garbage_profile_details.dart';
import 'common/authentication_screens/login_screen.dart';
import 'common/authentication_screens/registration_screen.dart';
import 'common/authentication_screens/password_reset_screen.dart';
import 'customer_screens/customer_home_routes.dart';
import 'garbage_collector_screens/garbage_collector_routes.dart';
import 'admin_screens/admin_home.dart';
import 'services/auth_wrapper.dart';
import 'garbage_collector_screens/garbage_collector_profile/edit_garbage_profile.dart';
import 'customer_screens/customer_profile/edit_customer_profile.dart';
import 'customer_screens/customer_subscription.dart';
import 'customer_screens/daytimeSelection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51PnDsU01DZVgze5h4iuzC4DKxUfG7XGPezbdp4PX3fkLmmJCrbIKwmgUdPeIeP84WQUebTNSA5V7gmFsvCrG1auM00ZQMc14ea';
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kunu.Lk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthWrapper(),
      initialRoute: '/',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegistrationPage(),
        '/customerHome': (context) => CustomerHomePage(),
        '/garbageCollectorHome': (context) => GarbageCollectorRoutes(),
        '/adminHome': (context) => AdminHome(),
        '/reset': (context) => PasswordResetPage(),
        '/customerProfile': (context) => CustomerProfileDetails(),
        '/customerProfilePhoto': (context) => CustomerProfilePhotoPage(),
        '/editGarbageProfile': (context) => EditGarbageProfilePage(),
        '/garbageCollectorProfile': (context) =>
            GarbageCollectorProfileSection(),
        '/editCustomerProfile': (context) => EditCustomerProfilePage(),
        '/daytimeSelection': (context) => DayTimeSelectionPage(
              userId: '',
            ),
        '/customersub': (context) => SubscriptionPage(
              userName: '',
              userId: '',
            ),
        '/updateLocation': (context) => UpdateLocationScreen(),
        '/collectionSchedule': (context) => CollectionScheduleScreen(),
      },
    );
  }
}
