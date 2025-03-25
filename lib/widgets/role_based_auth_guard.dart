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
            
            // Check for role in both locations - either root level or metadata
            String? role;
            if (userData.containsKey('role')) {
              role = userData['role'] as String?;
            } else if (userData.containsKey('metadata') && 
                       userData['metadata'] is Map<String, dynamic> &&
                       (userData['metadata'] as Map<String, dynamic>).containsKey('role')) {
              role = userData['metadata']['role'] as String?;
            }
            
            role = role ?? 'user'; // Default to user if no role found
            
            print('User role from Firestore: $role');
            print('User data: $userData');

            // Route based on user role
            switch (role) {
              case 'blogger':
                print('Navigating to blogger home page');
                return const BloggerHomePage();
              case 'restaurant':
                print('Navigating to restaurant home page');
                return const RestaurantHomePage();
              case 'customer':
              case 'user':
              default:
                print('Navigating to default home page');
                return const HomePage();
            }
          },
        );
      },
    );
  }
} 