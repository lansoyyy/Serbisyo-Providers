import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../main_screen.dart';

class SearchServiceScreen extends StatefulWidget {
  const SearchServiceScreen({Key? key}) : super(key: key);

  @override
  State<SearchServiceScreen> createState() => _SearchServiceScreenState();
}

class _SearchServiceScreenState extends State<SearchServiceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _searchQuery = '';
  bool _isSearching = false;

  // Remove hardcoded data and replace with dynamic data
  List<Map<String, dynamic>> _serviceCategories = [];
  List<String> _popularSearches = [];
  List<String> _recentSearches = [];
  List<String> _allServices = [];
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _fadeController.forward();
      _slideController.forward();
    });

    _searchController.addListener(_onSearchChanged);
  }

  // Load initial data from Firebase
  void _loadInitialData() async {
    try {
      // Load service categories
      await _loadServiceCategories();

      // Load popular searches (could be based on most searched services)
      _loadPopularSearches();
    } catch (e) {
      print('Error loading initial data: $e');
      // Fallback to some default data
      setState(() {
        _popularSearches = [
          'House Cleaning',
          'AC Repair',
          'Plumbing',
          'Electrical Work',
          'Painting',
          'Gardening',
          'Computer Repair',
          'Car Wash',
        ];
      });
    }
  }

  // Load service categories from Firebase
  Future<void> _loadServiceCategories() async {
    try {
      // Get all approved providers
      final providersSnapshot = await FirebaseFirestore.instance
          .collection('providers')
          .where('applicationStatus', isEqualTo: 'approved')
          .get();

      final categoriesMap = <String, Map<String, dynamic>>{};

      // Collect all unique categories and services from providers
      for (var providerDoc in providersSnapshot.docs) {
        try {
          // Get services for this provider
          final servicesSnapshot = await FirebaseFirestore.instance
              .collection('providers')
              .doc(providerDoc.id)
              .collection('services')
              .get();

          for (var serviceDoc in servicesSnapshot.docs) {
            final serviceData = serviceDoc.data();
            final category = serviceData['category'] as String? ?? 'General';
            final serviceName = serviceData['name'] as String? ?? 'Service';

            // Initialize category if not exists
            if (!categoriesMap.containsKey(category)) {
              IconData icon;
              Color color;

              // Assign icons and colors based on category
              switch (category) {
                case 'Residential':
                  icon = FontAwesomeIcons.house;
                  color = Colors.blue;
                  break;
                case 'Commercial':
                  icon = FontAwesomeIcons.building;
                  color = Colors.green;
                  break;
                case 'Specialized':
                  icon = FontAwesomeIcons.star;
                  color = Colors.orange;
                  break;
                case 'Maintenance':
                  icon = FontAwesomeIcons.wrench;
                  color = Colors.red;
                  break;
                default:
                  icon = FontAwesomeIcons.briefcase;
                  color = AppColors.primary;
              }

              categoriesMap[category] = {
                'name': category,
                'icon': icon,
                'color': color,
                'services': <String>[],
              };
            }

            // Add service to category if not already added
            final servicesList =
                List<String>.from(categoriesMap[category]!['services']);
            if (!servicesList.contains(serviceName)) {
              servicesList.add(serviceName);
              categoriesMap[category]!['services'] = servicesList;
            }

            // Add to all services list
            if (!_allServices.contains(serviceName)) {
              _allServices.add(serviceName);
            }
          }
        } catch (e) {
          print('Error loading services for provider ${providerDoc.id}: $e');
        }
      }

      // Convert map to list
      final categoriesList = categoriesMap.values.toList();

      setState(() {
        _serviceCategories = categoriesList;
      });
    } catch (e) {
      print('Error loading service categories: $e');
    }
  }

  // Load popular searches (this could be based on actual search analytics)
  void _loadPopularSearches() {
    // For now, we'll use a combination of services from different categories
    final popular = <String>[];

    for (var category in _serviceCategories) {
      final services = List<String>.from(category['services']);
      if (services.isNotEmpty) {
        // Add first service from each category
        popular.add(services[0]);
        // Add second service if available
        if (services.length > 1) {
          popular.add(services[1]);
        }
      }

      // Limit to 8 popular searches
      if (popular.length >= 8) break;
    }

    // Fill with defaults if needed
    final defaults = [
      'House Cleaning',
      'AC Repair',
      'Plumbing',
      'Electrical Work',
      'Painting',
      'Gardening',
      'Computer Repair',
      'Car Wash',
    ];

    for (var defaultService in defaults) {
      if (popular.length >= 8) break;
      if (!popular.contains(defaultService)) {
        popular.add(defaultService);
      }
    }

    setState(() {
      _popularSearches = popular;
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _isSearching = _searchQuery.isNotEmpty;

      if (_searchQuery.isNotEmpty) {
        _searchResults = _allServices
            .where((service) =>
                service.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      } else {
        _searchResults = [];
      }
    });
  }

  void _onServiceTap(String serviceName) {
    // Add to recent searches if not already there
    if (!_recentSearches.contains(serviceName)) {
      _recentSearches.insert(0, serviceName);
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    }

    // Determine the category for the service
    String category = _getCategoryForService(serviceName);

    // Navigate back to main screen and switch to services tab with filters
    _navigateToServicesTab(category, serviceName);
  }

  String _getCategoryForService(String serviceName) {
    // Map services to their categories
    for (var categoryData in _serviceCategories) {
      List<String> services = List<String>.from(categoryData['services']);
      if (services.contains(serviceName)) {
        return categoryData['name'];
      }
    }

    // Default fallback based on service name patterns
    if (serviceName.toLowerCase().contains('clean')) return 'Cleaning';
    if (serviceName.toLowerCase().contains('repair') ||
        serviceName.toLowerCase().contains('electrical') ||
        serviceName.toLowerCase().contains('plumbing') ||
        serviceName.toLowerCase().contains('ac')) return 'Repair';
    if (serviceName.toLowerCase().contains('car')) return 'Automotive';
    if (serviceName.toLowerCase().contains('computer') ||
        serviceName.toLowerCase().contains('phone') ||
        serviceName.toLowerCase().contains('tv') ||
        serviceName.toLowerCase().contains('wi-fi')) return 'Technology';
    if (serviceName.toLowerCase().contains('massage') ||
        serviceName.toLowerCase().contains('hair') ||
        serviceName.toLowerCase().contains('beauty') ||
        serviceName.toLowerCase().contains('pet')) return 'Personal Care';
    if (serviceName.toLowerCase().contains('garden') ||
        serviceName.toLowerCase().contains('paint') ||
        serviceName.toLowerCase().contains('carpen') ||
        serviceName.toLowerCase().contains('home')) return 'Home Services';

    return 'Cleaning'; // Default category
  }

  void _navigateToServicesTab(String category, String serviceName) {
    // Navigate back to main screen with services tab and filters
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Navigate to main screen with specific tab and filters
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreenWithFilters(
          initialTab: 1, // Services tab index
          serviceCategory: category,
          serviceSearch: serviceName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search bar
            _buildSearchHeader(),

            // Content area
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _isSearching
                      ? _buildSearchResults()
                      : _buildBrowseContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              TouchableWidget(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'What service do you need?',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(16),
                        child: FaIcon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? TouchableWidget(
                              onTap: () {
                                _searchController.clear();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  size: 16,
                                  color: AppColors.onSecondary.withOpacity(0.6),
                                ),
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: AppColors.onSecondary.withOpacity(0.6),
                        fontSize: 16,
                        fontFamily: 'Regular',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Medium',
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isSearching) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 60),
                TextWidget(
                  text: '${_searchResults.length} results found',
                  fontSize: 14,
                  fontFamily: 'Medium',
                  color: AppColors.onSecondary.withOpacity(0.7),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrowseContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            _buildSectionHeader(
                'Recent Searches', FontAwesomeIcons.clockRotateLeft),
            const SizedBox(height: 12),
            _buildRecentSearches(),
            const SizedBox(height: 24),
          ],

          // Service Categories
          _buildSectionHeader('Browse Categories', FontAwesomeIcons.th),
          const SizedBox(height: 12),
          _buildServiceCategories(),
          const SizedBox(height: 24),

          // Popular Searches
          _buildSectionHeader('Popular Searches', FontAwesomeIcons.fire),
          const SizedBox(height: 12),
          _buildPopularSearches(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.onSecondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                FontAwesomeIcons.magnifyingGlass,
                size: 40,
                color: AppColors.onSecondary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'No services found',
              fontSize: 18,
              fontFamily: 'Bold',
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            TextWidget(
              text: 'Try searching for a different service',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
              align: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final service = _searchResults[index];
        return _buildSearchResultItem(service);
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        TextWidget(
          text: title,
          fontSize: 18,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _recentSearches.map((search) {
          return TouchableWidget(
            onTap: () => _onServiceTap(search),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.clock,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  TextWidget(
                    text: search,
                    fontSize: 14,
                    fontFamily: 'Medium',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceCategories() {
    if (_serviceCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            TextWidget(
              text: 'Loading categories...',
              fontSize: 14,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _serviceCategories.length,
      itemBuilder: (context, index) {
        final category = _serviceCategories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return TouchableWidget(
      onTap: () {
        // Show services in this category
        _showCategoryServices(category);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: (category['color'] as Color).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  category['icon'] as IconData,
                  size: 24,
                  color: category['color'] as Color,
                ),
              ),
              const SizedBox(height: 12),
              TextWidget(
                text: category['name'] as String,
                fontSize: 14,
                fontFamily: 'Bold',
                color: AppColors.primary,
                align: TextAlign.center,
              ),
              const SizedBox(height: 4),
              TextWidget(
                text: '${(category['services'] as List).length} services',
                fontSize: 12,
                fontFamily: 'Regular',
                color: AppColors.onSecondary.withOpacity(0.7),
                align: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSearches() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _popularSearches.map((search) {
          return _buildPopularSearchItem(search);
        }).toList(),
      ),
    );
  }

  Widget _buildPopularSearchItem(String search) {
    return TouchableWidget(
      onTap: () => _onServiceTap(search),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.fire,
                size: 14,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: search,
                fontSize: 14,
                fontFamily: 'Medium',
                color: AppColors.primary,
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(String service) {
    return TouchableWidget(
      onTap: () => _onServiceTap(service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FaIcon(
                FontAwesomeIcons.wrench,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: service,
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: 'Professional $service services',
                    fontSize: 12,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryServices(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (category['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FaIcon(
                        category['icon'] as IconData,
                        size: 20,
                        color: category['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: category['name'] as String,
                            fontSize: 20,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                          ),
                          TextWidget(
                            text:
                                '${(category['services'] as List).length} services available',
                            fontSize: 14,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Services list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: (category['services'] as List).length,
                  itemBuilder: (context, index) {
                    final service = (category['services'] as List)[index];
                    return _buildCategoryServiceItem(
                        service, category['color'] as Color);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryServiceItem(String service, Color color) {
    return TouchableWidget(
      onTap: () {
        Navigator.pop(context);
        _onServiceTap(service);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                FontAwesomeIcons.gear,
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextWidget(
                text: service,
                fontSize: 16,
                fontFamily: 'Medium',
                color: AppColors.primary,
              ),
            ),
            FaIcon(
              FontAwesomeIcons.chevronRight,
              size: 12,
              color: AppColors.onSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}
