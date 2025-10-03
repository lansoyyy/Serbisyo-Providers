import 'package:flutter/material.dart';
import 'package:hanap_raket/services/initialize_firebase.dart';
import 'package:hanap_raket/utils/colors.dart';
import 'package:hanap_raket/widgets/text_widget.dart';
import 'package:hanap_raket/widgets/button_widget.dart';

/// Admin screen to initialize Firebase collections
/// Navigate to this screen once to set up app_config/version_control
class FirebaseInitScreen extends StatefulWidget {
  const FirebaseInitScreen({super.key});

  @override
  State<FirebaseInitScreen> createState() => _FirebaseInitScreenState();
}

class _FirebaseInitScreenState extends State<FirebaseInitScreen> {
  bool _isLoading = false;
  bool? _exists;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkExistence();
  }

  Future<void> _checkExistence() async {
    setState(() => _isLoading = true);
    final exists = await FirebaseInitializer.versionControlExists();
    setState(() {
      _exists = exists;
      _isLoading = false;
      _message = exists
          ? '✅ Version control is already set up'
          : '⚠️ Version control needs to be initialized';
    });
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _message = 'Initializing...';
    });

    await FirebaseInitializer.initializeVersionControl();

    setState(() {
      _isLoading = false;
      _message = '✅ Successfully initialized! You can go back now.';
      _exists = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextWidget(
          text: 'Firebase Setup',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
          maxLines: 1,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              TextWidget(
                text: 'Initialize Firebase',
                fontSize: 24,
                fontFamily: 'Bold',
                color: textBlack,
                align: TextAlign.center,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Description
              TextWidget(
                text:
                    'This will create the app_config collection with version_control document in Firestore.',
                fontSize: 14,
                color: ashGray,
                fontFamily: 'Regular',
                align: TextAlign.center,
                maxLines: 5,
              ),
              const SizedBox(height: 32),

              // Status Message
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _exists == true
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _exists == true
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _exists == true ? Icons.check_circle : Icons.info,
                        color: _exists == true ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextWidget(
                          text: _message,
                          fontSize: 14,
                          color: textBlack,
                          fontFamily: 'Regular',
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Initialize Button
              if (_exists != true)
                ButtonWidget(
                  label: 'Initialize Now',
                  onPressed: _initialize,
                  loading: _isLoading,
                  width: double.infinity,
                  height: 56,
                  fontSize: 16,
                  color: AppColors.primary,
                  radius: 12,
                ),

              // Refresh Button
              if (_exists == true)
                ButtonWidget(
                  label: 'Check Again',
                  onPressed: _checkExistence,
                  loading: _isLoading,
                  width: double.infinity,
                  height: 56,
                  fontSize: 16,
                  color: AppColors.secondary,
                  textColor: Colors.black,
                  radius: 12,
                ),

              const SizedBox(height: 16),

              // Info
              TextWidget(
                text:
                    'After initialization, you can manage versions from Firebase Console',
                fontSize: 12,
                color: ashGray,
                fontFamily: 'Regular',
                align: TextAlign.center,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
