/// Restaurant Database Structure
/// 
/// This file defines the complete Firebase database structure for restaurant-side application.
/// All restaurant data is completely separated from customer and blogger data.

class RestaurantDatabaseStructure {
  // ============================================================================
  // AUTHENTICATION COLLECTIONS
  // ============================================================================
  
  /// Restaurant users collection - completely separate from customer/blogger users
  static const String restaurantUsers = 'restaurant_users';
  
  /// Restaurant authentication tokens and sessions
  static const String restaurantAuth = 'restaurant_auth';
  
  // ============================================================================
  // RESTAURANT CORE DATA
  // ============================================================================
  
  /// Main restaurant profiles and business information
  static const String restaurants = 'restaurants';
  
  /// Restaurant business hours and availability
  static const String restaurantHours = 'restaurant_hours';
  
  /// Restaurant locations and addresses
  static const String restaurantLocations = 'restaurant_locations';
  
  /// Restaurant contact information
  static const String restaurantContacts = 'restaurant_contacts';
  
  // ============================================================================
  // RESTAURANT OPERATIONAL DATA
  // ============================================================================
  
  /// Restaurant menu items and categories
  static const String restaurantMenus = 'restaurant_menus';
  
  /// Restaurant menu photos and images
  static const String restaurantMenuPhotos = 'restaurant_menu_photos';
  
  /// Restaurant table configurations and availability
  static const String restaurantTables = 'restaurant_tables';
  
  /// Restaurant staff and employees
  static const String restaurantStaff = 'restaurant_staff';
  
  // ============================================================================
  // RESTAURANT ORDERS AND RESERVATIONS
  // ============================================================================
  
  /// Food orders placed by customers (restaurant view)
  static const String restaurantOrders = 'restaurant_orders';
  
  /// Table reservations made by customers (restaurant view)
  static const String restaurantReservations = 'restaurant_reservations';
  
  /// Order and reservation status updates
  static const String restaurantOrderStatus = 'restaurant_order_status';
  
  // ============================================================================
  // RESTAURANT CUSTOMER INTERACTIONS
  // ============================================================================
  
  /// Reviews received by restaurant
  static const String restaurantReviews = 'restaurant_reviews';
  
  /// Customer feedback and complaints
  static const String restaurantFeedback = 'restaurant_feedback';
  
  /// Customer inquiries and messages
  static const String restaurantInquiries = 'restaurant_inquiries';
  
  // ============================================================================
  // RESTAURANT NOTIFICATIONS AND COMMUNICATIONS
  // ============================================================================
  
  /// Restaurant notifications (orders, reservations, reviews)
  static const String restaurantNotifications = 'restaurant_notifications';
  
  /// Restaurant announcements and updates
  static const String restaurantAnnouncements = 'restaurant_announcements';
  
  /// Restaurant communication logs
  static const String restaurantCommunications = 'restaurant_communications';
  
  // ============================================================================
  // RESTAURANT ANALYTICS AND REPORTING
  // ============================================================================
  
  /// Restaurant sales analytics
  static const String restaurantAnalytics = 'restaurant_analytics';
  
  /// Restaurant performance metrics
  static const String restaurantMetrics = 'restaurant_metrics';
  
  /// Restaurant reports and insights
  static const String restaurantReports = 'restaurant_reports';
  
  // ============================================================================
  // RESTAURANT ACTIVITIES AND LOGS
  // ============================================================================
  
  /// Restaurant activity logs
  static const String restaurantActivities = 'restaurant_activities';
  
  /// Restaurant audit trails
  static const String restaurantAuditLogs = 'restaurant_audit_logs';
  
  /// Restaurant system logs
  static const String restaurantSystemLogs = 'restaurant_system_logs';
  
  // ============================================================================
  // RESTAURANT STORAGE PATHS
  // ============================================================================
  
  /// Restaurant profile images
  static const String restaurantImagesPath = 'restaurant_images';
  
  /// Restaurant menu photos
  static const String restaurantMenuImagesPath = 'restaurant_menu_images';
  
  /// Restaurant documents and files
  static const String restaurantDocumentsPath = 'restaurant_documents';
  
  /// Restaurant promotional materials
  static const String restaurantPromotionalPath = 'restaurant_promotional';
  
  // ============================================================================
  // RESTAURANT SUBCOLLECTIONS STRUCTURE
  // ============================================================================
  
  /// Get restaurant-specific subcollection path
  static String getRestaurantSubcollection(String restaurantId, String subcollection) {
    return '$restaurants/$restaurantId/$subcollection';
  }
  
  /// Get restaurant notifications path
  static String getRestaurantNotificationsPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'notifications');
  }
  
  /// Get restaurant orders path
  static String getRestaurantOrdersPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'orders');
  }
  
  /// Get restaurant reservations path
  static String getRestaurantReservationsPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'reservations');
  }
  
  /// Get restaurant menu path
  static String getRestaurantMenuPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'menu');
  }
  
  /// Get restaurant tables path
  static String getRestaurantTablesPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'tables');
  }
  
  /// Get restaurant analytics path
  static String getRestaurantAnalyticsPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'analytics');
  }
  
  /// Get restaurant activities path
  static String getRestaurantActivitiesPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'activities');
  }
  
  /// Get restaurant reviews path
  static String getRestaurantReviewsPath(String restaurantId) {
    return getRestaurantSubcollection(restaurantId, 'reviews');
  }
  
  // ============================================================================
  // RESTAURANT STORAGE PATHS
  // ============================================================================
  
  /// Get restaurant storage path
  static String getRestaurantStoragePath(String restaurantId, String type) {
    return '$type/$restaurantId';
  }
  
  /// Get restaurant image storage path
  static String getRestaurantImagePath(String restaurantId, String imageName) {
    return '$restaurantImagesPath/$restaurantId/$imageName';
  }
  
  /// Get restaurant menu image storage path
  static String getRestaurantMenuImagePath(String restaurantId, String imageName) {
    return '$restaurantMenuImagesPath/$restaurantId/$imageName';
  }
  
  // ============================================================================
  // RESTAURANT DATA VALIDATION
  // ============================================================================
  
  /// Validate restaurant ID format
  static bool isValidRestaurantId(String restaurantId) {
    return restaurantId.isNotEmpty && restaurantId.length >= 8;
  }
  
  /// Generate restaurant-specific document ID
  static String generateRestaurantDocumentId(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return '${prefix}_${timestamp}_$random';
  }
  
  /// Validate restaurant data before saving
  static Map<String, dynamic> validateRestaurantData(Map<String, dynamic> data) {
    final validatedData = Map<String, dynamic>.from(data);
    
    // Add restaurant-specific metadata
    validatedData['updatedAt'] = DateTime.now().toIso8601String();
    validatedData['dataType'] = 'restaurant';
    validatedData['version'] = '1.0';
    
    return validatedData;
  }
}
