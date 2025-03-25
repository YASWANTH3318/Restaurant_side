import 'package:flutter/foundation.dart';

/// A utility class to handle errors in the application
class ErrorHandler {
  
  /// Logs an error with its stack trace in a format that's easy to read
  static void logError(dynamic error, StackTrace? stackTrace) {
    debugPrint('╔═══════════════════════════ ERROR ═══════════════════════════╗');
    debugPrint('║ ${error.toString()}');
    debugPrint('╠═══════════════════════ STACK TRACE ═══════════════════════╣');
    
    if (stackTrace != null) {
      final stackLines = stackTrace.toString().split('\n');
      for (var line in stackLines) {
        if (line.trim().isNotEmpty) {
          debugPrint('║ $line');
        }
      }
    } else {
      debugPrint('║ No stack trace available');
    }
    
    debugPrint('╚═════════════════════════════════════════════════════════════╝');
  }
  
  /// Handles a Firebase error with a user-friendly message
  static String getFirebaseErrorMessage(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('network_error') || 
        errorMessage.contains('network error') || 
        errorMessage.contains('socket')) {
      return 'Network connection error. Please check your internet connection.';
    } else if (errorMessage.contains('permission-denied') || 
               errorMessage.contains('permission denied')) {
      return 'You don\'t have permission to perform this action.';
    } else if (errorMessage.contains('not-found') || 
               errorMessage.contains('not found')) {
      return 'The requested resource was not found.';
    } else if (errorMessage.contains('invalid-email')) {
      return 'The email address is not valid.';
    } else if (errorMessage.contains('wrong-password')) {
      return 'The password is incorrect.';
    } else if (errorMessage.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (errorMessage.contains('email-already-in-use')) {
      return 'This email is already associated with an account.';
    } else if (errorMessage.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    } else if (errorMessage.contains('requires-recent-login')) {
      return 'This operation requires re-authentication. Please log in again.';
    }
    
    // Default message for other errors
    return 'An error occurred. Please try again later.';
  }
} 