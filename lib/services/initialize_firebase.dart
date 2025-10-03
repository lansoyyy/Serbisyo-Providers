import 'package:cloud_firestore/cloud_firestore.dart';

/// Initialize Firebase app_config collection with version_control document
/// Run this once to set up the force update feature
class FirebaseInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the app_config/version_control document
  static Future<void> initializeVersionControl() async {
    try {
      await _firestore.collection('app_config').doc('version_control').set({
        'current_version': '1.0.0',
        'update_url': 'https://play.google.com/store/apps/details?id=com.yourapp.hanap_raket',
        'changes': [
          'Initial release',
          'Welcome to Hanap Raket!',
        ],
      });
      
      print('✅ Successfully initialized app_config/version_control');
      print('📝 You can now manage app versions from Firebase Console');
    } catch (e) {
      print('❌ Error initializing version control: $e');
    }
  }

  /// Check if version_control document exists
  static Future<bool> versionControlExists() async {
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('version_control')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking version control: $e');
      return false;
    }
  }
}
