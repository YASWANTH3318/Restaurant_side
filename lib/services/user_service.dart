import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import './firebase_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
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
      // Trigger the authentication flow without signing in
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      return googleUser;
    } catch (e) {
      print('Error getting Google user: $e');
      return null;
    }
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user document exists
      final userDoc = await getUserData(userCredential.user!.uid);
      
      if (!userDoc.exists) {
        // Create new user document if it doesn't exist
        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          username: email.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
          metadata: {
            'createdBy': 'email',
            'accountType': 'email',
            'role': role,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        
        await createUser(newUser);
      } else {
        // Get existing user data
        final userData = userDoc.data() as Map<String, dynamic>;
        final metadata = Map<String, dynamic>.from(userData['metadata']);
        
        // Update last login time and ensure role is set
        if (!metadata.containsKey('role')) {
          metadata['role'] = role;
        }
        
        await updateUser(UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          username: email.split('@')[0],
          createdAt: userData['createdAt'].toDate(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: userCredential.user!.emailVerified,
          metadata: metadata,
        ));
      }

      return userCredential;
    } catch (e) {
      print('Error signing in user: $e');
      rethrow;
    }
  }

  static Future<UserCredential> signInWithGoogle({required String role}) async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      }

      try {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final userCredential = await _auth.signInWithCredential(credential);

        // Check if user document exists
        final userDoc = await getUserData(userCredential.user!.uid);
        
        if (!userDoc.exists) {
          // Create new user document if it doesn't exist
          final newUser = UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email!,
            name: userCredential.user!.displayName ?? userCredential.user!.email!.split('@')[0],
            username: userCredential.user!.email!.split('@')[0],
            phoneNumber: userCredential.user!.phoneNumber,
            profileImageUrl: userCredential.user!.photoURL,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isEmailVerified: userCredential.user!.emailVerified,
            metadata: {
              'lastPasswordChange': DateTime.now().toIso8601String(),
              'createdBy': 'google',
              'accountType': 'google',
              'role': role,
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
          
          await createUser(newUser);
        } else {
          // Get existing user data
          final userData = userDoc.data() as Map<String, dynamic>;
          final metadata = Map<String, dynamic>.from(userData['metadata']);
          
          // Update last login time and ensure role is set
          if (!metadata.containsKey('role')) {
            metadata['role'] = role;
          }
          
          await updateUser(UserModel(
            id: userCredential.user!.uid,
            email: userCredential.user!.email!,
            name: userCredential.user!.displayName ?? userCredential.user!.email!.split('@')[0],
            username: userCredential.user!.email!.split('@')[0],
            phoneNumber: userCredential.user!.phoneNumber,
            profileImageUrl: userCredential.user!.photoURL,
            createdAt: userData['createdAt'].toDate(),
            lastLoginAt: DateTime.now(),
            isEmailVerified: userCredential.user!.emailVerified,
            metadata: metadata,
          ));
        }

        return userCredential;
      } catch (e) {
        print('Firebase Auth Error: $e');
        rethrow;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
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
        id: userCredential.user!.uid,
        email: email,
        name: name,
        username: username,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: userCredential.user!.emailVerified,
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
      
      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final existingRole = userData['metadata']?['role'] as String?;
        
        if (existingRole != null && existingRole != role) {
          return true; // Email exists with a different role
        }
      }
      
      return false; // Email doesn't exist or exists with the same role
    } catch (e) {
      print('Error checking email with role: $e');
      return false;
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