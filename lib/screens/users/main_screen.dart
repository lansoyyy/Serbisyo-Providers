import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hanap_raket/screens/users/tabs/home_tab.dart';
import '../../utils/colors.dart';
import 'tabs/services_tab.dart';
import 'tabs/booking_tab.dart';
import 'tabs/chat_tab.dart';
import 'tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  final int? initialTab;
  final String? serviceCategory;
  final String? serviceSearch;

  const MainScreen({
    Key? key,
    this.initialTab,
    this.serviceCategory,
    this.serviceSearch,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Convenience class for navigation with filters
class MainScreenWithFilters extends MainScreen {
  const MainScreenWithFilters({
    Key? key,
    required int initialTab,
    String? serviceCategory,
    String? serviceSearch,
  }) : super(
          key: key,
          initialTab: initialTab,
          serviceCategory: serviceCategory,
          serviceSearch: serviceSearch,
        );
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;

    _screens = [
      HomeTab(),
      ServicesTab(
        initialCategory: widget.serviceCategory,
        initialSearch: widget.serviceSearch,
      ),
      const BookingTab(),
      const ChatTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildNavItem(FontAwesomeIcons.house, 'Home', 0),
                _buildNavItem(FontAwesomeIcons.toolbox, 'Services', 1),
                _buildNavItem(
                  _currentIndex == 2
                      ? FontAwesomeIcons.solidCalendar
                      : FontAwesomeIcons.calendar,
                  'Booking',
                  2,
                ),
                _buildNavItem(
                  _currentIndex == 3
                      ? FontAwesomeIcons.solidCommentDots
                      : FontAwesomeIcons.commentDots,
                  'Chat',
                  3,
                ),
                _buildNavItem(
                  _currentIndex == 4
                      ? FontAwesomeIcons.solidUser
                      : FontAwesomeIcons.user,
                  'Profile',
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : AppColors.onSecondary.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSecondary.withOpacity(0.6),
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
