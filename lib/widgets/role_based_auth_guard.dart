import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';
import '../pages/blogger/blogger_home_page.dart';
import '../pages/restaurant/restaurant_home_page.dart';

class RoleBasedAuthGuard extends StatelessWidget {
  const RoleBasedAuthGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginPage();
        }

        // User is authenticated, now check their role
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${userSnapshot.error}'),
                ),
              );
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Default to regular user if no user document exists
              return const HomePage();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final metadata = userData['metadata'] as Map<String, dynamic>?;
            final role = metadata?['role'] as String? ?? 'user';

            // Route based on user role
            switch (role) {
              case 'blogger':
                return const BloggerHomePage();
              case 'restaurant':
                return const RestaurantHomePage();
              case 'user':
              default:
                return const HomePage();
            }
          },
        );
      },
    );
  }
} 