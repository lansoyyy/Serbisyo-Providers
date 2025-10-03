import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../utils/colors.dart';
import '../../widgets/text_widget.dart';
import 'tabs/provider_home_screen.dart';
import 'tabs/provider_bookings_screen.dart';
import 'tabs/provider_messages_screen.dart';
import 'tabs/provider_profile_screen.dart' hide Row, SizedBox;

class ProviderMainScreen extends StatefulWidget {
  final int initialTab;

  const ProviderMainScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<ProviderMainScreen> createState() => _ProviderMainScreenState();
}

class _ProviderMainScreenState extends State<ProviderMainScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProviderHomeScreen(), // Dashboard (includes calendar, earnings, analytics)
    const ProviderBookingsScreen(), // Bookings & Customers combined
    const ProviderMessagesScreen(),

    const ProviderProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: FontAwesomeIcons.home,
      label: 'Dashboard',
      color: AppColors.primary,
    ),
    NavigationItem(
      icon: FontAwesomeIcons.clipboardList,
      label: 'Bookings',
      color: AppColors.primary.shade600,
    ),
    NavigationItem(
      icon: FontAwesomeIcons.comments,
      label: 'Messages',
      color: AppColors.primary.shade700,
    ),
    NavigationItem(
      icon: FontAwesomeIcons.user,
      label: 'Profile',
      color: AppColors.primary.shade800,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _pageController = PageController(initialPage: _selectedIndex);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navigationItems.length, (index) {
              final item = _navigationItems[index];
              final isSelected = _selectedIndex == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: GestureDetector(
                  onTap: () => _onTabSelected(index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item.color
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: FaIcon(
                            item.icon,
                            color: isSelected ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? item.color : Colors.grey,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const FaIcon(
                      FontAwesomeIcons.userTie,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextWidget(
                    text: 'Maria Santos',
                    fontSize: 20,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.5),
                      ),
                    ),
                    child: TextWidget(
                      text: 'Premium Provider',
                      fontSize: 14,
                      fontFamily: 'Bold',
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    FontAwesomeIcons.user,
                    'Profile',
                    'Business info & portfolio',
                    AppColors.primary.shade600,
                    4,
                  ),
                  _buildDrawerItem(
                    FontAwesomeIcons.gear,
                    'Settings',
                    'App preferences',
                    AppColors.primary.shade700,
                    5,
                  ),
                  const Divider(height: 32),
                  _buildDrawerItem(
                    FontAwesomeIcons.questionCircle,
                    'Help & Support',
                    'Get assistance',
                    AppColors.primary.shade400,
                    null,
                  ),
                  _buildDrawerItem(
                    FontAwesomeIcons.rightFromBracket,
                    'Logout',
                    'Sign out of account',
                    AppColors.accent,
                    null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    int? screenIndex,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        title: TextWidget(
          text: title,
          fontSize: 16,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        subtitle: TextWidget(
          text: subtitle,
          fontSize: 14,
          fontFamily: 'Regular',
          color: AppColors.onSecondary.withOpacity(0.7),
        ),
        onTap: () {
          Navigator.pop(context);
          if (screenIndex != null) {
            _onTabSelected(screenIndex);
          } else {
            // Handle special actions like logout
            if (title == 'Logout') {
              _handleLogout();
            }
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: TextWidget(
          text: 'Logout',
          fontSize: 20,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        content: TextWidget(
          text: 'Are you sure you want to logout?',
          fontSize: 16,
          fontFamily: 'Regular',
          color: AppColors.onSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: TextWidget(
              text: 'Cancel',
              fontSize: 16,
              fontFamily: 'Medium',
              color: AppColors.onSecondary,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login or splash
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: TextWidget(
              text: 'Logout',
              fontSize: 16,
              fontFamily: 'Bold',
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

// Placeholder screens for each tab
class ProviderServicesScreen extends StatelessWidget {
  const ProviderServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary.shade800,
        title: TextWidget(
          text: 'Services',
          fontSize: 22,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Services Screen - Coming Soon'),
      ),
    );
  }
}

class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary.shade700,
        title: TextWidget(
          text: 'Settings',
          fontSize: 22,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Settings Screen - Coming Soon'),
      ),
    );
  }
}
