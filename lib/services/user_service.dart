import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import './firebase_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  static final CollectionReference _usersCollection = 
      _firestore.collection('users');

  // Add rate limiting variables
  static DateTime? _lastUpdateTime;
  static const _minimumUpdateInterval = Duration(seconds: 2);

  static Future<void> initializeUserCollection() async {
    try {
      final collectionExists = await FirebaseService.verifyCollection('users');
      if (!collectionExists) {
        await FirebaseService.initialize();
      }
    } catch (e) {
      print('Error initializing user collection: $e');
      rethrow;
    }
  }

  static Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      await initializeUserCollection();
      final doc = await _usersCollection.doc(userId).get();
      print('Retrieved user data for: $userId');
      return doc;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  static Future<bool> isUsernameAvailable(String username) async {
    try {
      await initializeUserCollection();
      final QuerySnapshot result = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print('Error checking username availability: $e');
      rethrow;
    }
  }

  static Future<void> createUser(UserModel user) async {
    try {
      await initializeUserCollection();
      await _usersCollection.doc(user.id).set(user.toMap());
      print('User created successfully: ${user.email}');
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  static Future<void> updateUser(UserModel user) async {
    try {
      // Check if enough time has passed since last update
      if (_lastUpdateTime != null) {
        final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!);
        if (timeSinceLastUpdate < _minimumUpdateInterval) {
          // Wait for the remaining time
          await Future.delayed(_minimumUpdateInterval - timeSinceLastUpdate);
        }
      }

      await initializeUserCollection();
      await _usersCollection.doc(user.id).update(user.toMap());
      
      // Update the last update time
      _lastUpdateTime = DateTime.now();
      
      print('User updated successfully: ${user.id}');
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      await initializeUserCollection();
      await _usersCollection.doc(userId).delete();
      print('User deleted successfully: $userId');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  static Future<bool> userExists(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    return doc.exists;
  }

  static Future<UserModel?> getUserModel(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  static Future<GoogleSignInAccount?> getGoogleUser() async {
    try {
      print('Starting Google sign-in flow...');
      
      // Check if there's a previously signed-in user and sign out
      try {
        if (_googleSignIn.currentUser != null) {
          await _googleSignIn.signOut();
          print('Signed out previous Google user');
        }
      } catch (e) {
        print('Error signing out previous user: $e');
        // Continue even if sign out fails
      }
      
      // Trigger the authentication flow
      print('Prompting user for Google sign-in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('Google sign-in was cancelled by user');
      } else {
        print('Google sign-in successful: ${googleUser.email}');
      }
      
      return googleUser;
    } catch (e) {
      print('Error getting Google user: $e');
      print('Error details: ${e.runtimeType}');
      return null;
    }
  }

  static Future<UserCredential> signInWithGoogle({required String role}) async {
    try {
      print('Starting Google sign-in process...');
      
      // First make sure we're signed out from Firebase
      try {
        await _auth.signOut();
      } catch (e) {
        print('Error signing out from Firebase: $e');
        // Continue even if sign out fails
      }
      
      // Get the Google user with our helper method
      final GoogleSignInAccount? googleUser = await getGoogleUser();
      
      if (googleUser == null) {
        print('Google sign-in was cancelled by user');
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      try {
        print('Getting Google auth details for ${googleUser.email}');
        
        // Get authentication details
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        print('Access Token: ${googleAuth.accessToken?.substring(0, 10)}...');
        print('ID Token: ${googleAuth.idToken?.substring(0, 10)}...');
        
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          print('Failed to get Google auth tokens');
          throw FirebaseAuthException(
            code: 'invalid-credential',
            message: 'Unable to obtain Google authentication tokens',
          );
        }

        print('Creating Firebase credential with Google tokens');
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Signing in to Firebase with Google credential');
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Failed to get user after successful authentication',
          );
        }

        print('Firebase sign-in successful: ${userCredential.user?.email}');
        
        // Create or update user document
        try {
          final user = userCredential.user;
          if (user == null) {
            throw Exception('User credential is null');
          }
          
          final userDoc = await _usersCollection.doc(user.uid).get();
          
          if (!userDoc.exists) {
            print('Creating new user document for Google user');
            final newUser = UserModel(
              id: user.uid,
              email: user.email ?? '',
              name: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
              username: user.email?.split('@')[0] ?? 'user',
              phoneNumber: user.phoneNumber,
              profileImageUrl: user.photoURL,
              createdAt: DateTime.now(),
              lastLoginAt: DateTime.now(),
              isEmailVerified: user.emailVerified,
              metadata: {
                'lastPasswordChange': DateTime.now().toIso8601String(),
                'createdBy': 'google',
                'accountType': 'google.com',
                'role': role,
                'createdAt': DateTime.now().toIso8601String(),
              },
            );
            
            await createUser(newUser);
          } else {
            print('Updating existing user document for Google user');
            await _usersCollection.doc(user.uid).update({
              'lastLoginAt': FieldValue.serverTimestamp(),
              'isEmailVerified': user.emailVerified,
              'profileImageUrl': user.photoURL,
              'name': user.displayName,
              'metadata.lastLoginAt': FieldValue.serverTimestamp(),
              'metadata.role': role,
            });
          }
        } catch (e) {
          // If we fail to update the user document, log but continue
          print('Error updating user document: $e');
          print('User was authenticated but document update failed');
        }

        return userCredential;
        
      } catch (e) {
        print('Error during Google authentication: $e');
        print('Error type: ${e.runtimeType}');
        rethrow;
      }
    } catch (e) {
      print('Error in Google sign-in process: $e');
      print('Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Sign in with email and password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // Check if user document exists
      final user = userCredential.user!;
      final userDoc = await _usersCollection.doc(user.uid).get();
      
      if (!userDoc.exists) {
        // Create new user document if it doesn't exist
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? email,
          name: user.displayName ?? email.split('@')[0],
          username: email.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
          metadata: {
            'createdBy': 'email',
            'accountType': 'email',
            'role': role,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        
        await createUser(newUser);
      } else {
        // Update last login time and role
        await _usersCollection.doc(user.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'metadata.lastLoginAt': FieldValue.serverTimestamp(),
          'metadata.role': role,
        });
      }

      return userCredential;
    } catch (e) {
      print('Error signing in user: $e');
      rethrow;
    }
  }

  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String username,
    String? phoneNumber,
    required String role,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user in Firestore
      final user = UserModel(
        id: userCredential.user?.uid ?? '',
        email: email,
        name: name,
        username: username,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: userCredential.user?.emailVerified ?? false,
        metadata: {
          'createdBy': 'email',
          'accountType': 'email',
          'role': role,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );

      await createUser(user);
      return userCredential;
    } catch (e) {
      print('Error signing up user: $e');
      rethrow;
    }
  }

  // Check if email is already used with a specific role
  static Future<bool> isEmailUsedWithRole(String email, String role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return false; // Email doesn't exist yet
      }
      
      // If user exists, check their role
      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final existingRole = userData['metadata']?['role'] as String?;
        final roles = userData['metadata']?['roles'] as List<dynamic>?;
        
        // If role matches exactly, allow login
        if (existingRole == role) {
          return false;
        }
        
        // If user has multiple roles, check if the requested role is in the list
        if (roles != null && roles.contains(role)) {
          return false;
        }
        
        // If no role is set yet, allow login
        if (existingRole == null) {
          return false;
        }
      }
      
      // Only return true if the email exists with a different role and no multiple roles
      return true;
    } catch (e) {
      print('Error checking email with role: $e');
      return false; // In case of error, allow the login
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut(); // Sign out from Google as well
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
} 