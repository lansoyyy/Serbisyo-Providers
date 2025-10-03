import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hanap_raket/utils/const.dart';

class VersionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if force update is required
  /// Compares APP_VERSION from const.dart with current_version in Firestore
  /// Returns a map with update info or null if no update needed
  static Future<Map<String, dynamic>?> checkForceUpdate() async {
    try {
      // Fetch version info from Firestore
      final versionDoc = await _firestore
          .collection('app_config')
          .doc('version_control')
          .get();

      if (!versionDoc.exists) {
        return null;
      }

      final data = versionDoc.data()!;
      final currentVersion = data['current_version'] as String?;
      final changes = data['changes'] as List<dynamic>? ?? [];
      final updateUrl = data['update_url'] as String? ?? '';

      // Check if versions match
      if (currentVersion != null && currentVersion != APP_VERSION) {
        return {
          'force_update': true,
          'current_version': APP_VERSION,
          'latest_version': currentVersion,
          'changes': changes,
          'update_url': updateUrl,
        };
      }

      return null;
    } catch (e) {
      print('Error checking version: $e');
      return null;
    }
  }
}
