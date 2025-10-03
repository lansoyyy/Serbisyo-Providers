import 'package:intl/intl.dart';

// App Version - Update this when releasing new version
// This is compared with 'current_version' field in Firebase (app_config/version_control)
// If they don't match, users will be forced to update
const String APP_VERSION = '1.0.0';

// Facebook App Configuration
const String FACEBOOK_APP_ID = '581133848359906';
const String FACEBOOK_APP_SECRET = 'd9f5ed7037579bf061199a46b57b4747';
const String FACEBOOK_CLIENT_TOKEN = '1fa733dc73112f6eb59ff0b5b34cc0d0';

String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number);
}

enum Scantype { nfc, qrcode, cardnumber }
