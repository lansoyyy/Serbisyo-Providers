import 'package:flutter/material.dart';
import 'package:hanap_raket/utils/colors.dart';
import 'package:hanap_raket/widgets/text_widget.dart';
import 'package:hanap_raket/widgets/button_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final List<dynamic> changes;
  final String updateUrl;

  const ForceUpdateScreen({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.changes,
    required this.updateUrl,
  });

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _isUpdating = false;

  void _launchUpdateUrl() {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final uri = Uri.parse(widget.updateUrl);
    canLaunchUrl(uri).then((canLaunch) {
      if (canLaunch) {
        launchUrl(uri, mode: LaunchMode.externalApplication).then((_) {
          // If we return to the app, reset the updating state
          if (mounted) {
            setState(() {
              _isUpdating = false;
            });
          }
        });
      } else {
        // If we can't launch, reset the updating state
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final paddingValue = isSmallScreen ? 16.0 : 24.0;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(paddingValue),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Update Icon with enhanced visual and animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: isSmallScreen ? 120 : 140,
                      height: isSmallScreen ? 120 : 140,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedScale(
                            scale: _isUpdating ? 0.9 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.system_update_alt,
                              size: isSmallScreen ? 60 : 70,
                              color: AppColors.primary,
                            ),
                          ),
                          Positioned(
                            bottom: 25,
                            right: 25,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedRotation(
                                turns: _isUpdating ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    TextWidget(
                      text: 'Update Required',
                      fontSize: isSmallScreen ? 24 : 28,
                      fontFamily: 'Bold',
                      color: textBlack,
                      align: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Version Info with enhanced visual hierarchy and animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Current Version
                          Expanded(
                            child: Column(
                              children: [
                                TextWidget(
                                  text: 'Current Version',
                                  fontSize: 12,
                                  color: ashGray,
                                  fontFamily: 'Regular',
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextWidget(
                                    text: widget.currentVersion,
                                    fontSize: 16,
                                    fontFamily: 'Bold',
                                    color: textBlack,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow Icon
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                          // New Version
                          Expanded(
                            child: Column(
                              children: [
                                TextWidget(
                                  text: 'Latest Version',
                                  fontSize: 12,
                                  color: ashGray,
                                  fontFamily: 'Regular',
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: TextWidget(
                                    text: widget.latestVersion,
                                    fontSize: 16,
                                    fontFamily: 'Bold',
                                    color: AppColors.primary,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Description
                    TextWidget(
                      text:
                          'A new version of the app is available. Please update to continue using the app.',
                      fontSize: isSmallScreen ? 12 : 14,
                      color: ashGray,
                      fontFamily: 'Regular',
                      align: TextAlign.center,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Changes Section with enhanced styling and animation
                    if (widget.changes.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextWidget(
                            text: "What's New",
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        constraints: BoxConstraints(
                          maxHeight: isSmallScreen ? 200 : 250,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(20),
                          itemCount: widget.changes.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              color: AppColors.background,
                              thickness: 1,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextWidget(
                                    text: widget.changes[index].toString(),
                                    fontSize: 14,
                                    color: textBlack,
                                    fontFamily: 'Regular',
                                    maxLines: 5,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    const Spacer(),

                    // Update Button with loading state and animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      height: isSmallScreen ? 48 : 56,
                      child: ButtonWidget(
                        label: _isUpdating ? 'Updating...' : 'Update Now',
                        onPressed: _isUpdating ? null : _launchUpdateUrl,
                        width: double.infinity,
                        height: isSmallScreen ? 48 : 56,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: AppColors.primary,
                        radius: 12,
                        loading: _isUpdating,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info Text
                    TextWidget(
                      text: 'You must update to continue',
                      fontSize: isSmallScreen ? 10 : 12,
                      color: ashGray,
                      fontFamily: 'Regular',
                      align: TextAlign.center,
                      maxLines: 1,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
