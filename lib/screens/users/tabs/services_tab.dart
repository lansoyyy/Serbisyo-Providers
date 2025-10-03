import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../subscreens/provider_booking_screen.dart';
import '../subscreens/viewprovider_profile_screen.dart';

class ServicesTab extends StatefulWidget {
  final String? initialCategory;
  final String? initialSearch;

  const ServicesTab({
    Key? key,
    this.initialCategory,
    this.initialSearch,
  }) : super(key: key);

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  late TextEditingController _searchController;
  final List<String> _categories = [
    'All Categories',
    'Residential',
    'Commercial',
    'Specialized',
    'Maintenance',
  ];
  late String _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Initialize with provided parameters or use All Categories as default
    String initialCategory = widget.initialCategory ?? 'All Categories';

    // If a specific category was provided, check if it exists in our list
    if (initialCategory != 'All Categories' &&
        !_categories.contains(initialCategory)) {
      // Try to find a close match or use default
      if (initialCategory.toLowerCase().contains('residential') ||
          initialCategory.toLowerCase().contains('home') ||
          initialCategory.toLowerCase().contains('clean')) {
        initialCategory = 'Residential';
      } else if (initialCategory.toLowerCase().contains('commercial') ||
          initialCategory.toLowerCase().contains('office')) {
        initialCategory = 'Commercial';
      } else if (initialCategory.toLowerCase().contains('specialized') ||
          initialCategory.toLowerCase().contains('personal') ||
          initialCategory.toLowerCase().contains('tech')) {
        initialCategory = 'Specialized';
      } else if (initialCategory.toLowerCase().contains('maintenance') ||
          initialCategory.toLowerCase().contains('repair') ||
          initialCategory.toLowerCase().contains('plumbing') ||
          initialCategory.toLowerCase().contains('auto')) {
        initialCategory = 'Maintenance';
      } else {
        initialCategory = 'All Categories'; // Default fallback
      }
    }

    _selectedCategory = initialCategory;
    _searchController = TextEditingController(
      text: widget.initialSearch ?? '',
    );

    // Add listener to update search query when text changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: 'Select Category',
                      fontSize: 20,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    TouchableWidget(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _categories.map((cat) {
                    final selected = _selectedCategory == cat;
                    return TouchableWidget(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: selected ? null : AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.2),
                            width: selected ? 0 : 1,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              _getCategoryIcon(cat),
                              size: 16,
                              color:
                                  selected ? Colors.white : AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            TextWidget(
                              text: cat,
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color:
                                  selected ? Colors.white : AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'All Categories':
        return FontAwesomeIcons.layerGroup;
      case 'Residential':
        return FontAwesomeIcons.house;
      case 'Commercial':
        return FontAwesomeIcons.building;
      case 'Specialized':
        return FontAwesomeIcons.star;
      case 'Maintenance':
        return FontAwesomeIcons.wrench;
      default:
        return FontAwesomeIcons.circle;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'All Categories':
        return AppColors.primary;
      case 'Residential':
        return Colors.blue;
      case 'Commercial':
        return Colors.green;
      case 'Specialized':
        return Colors.orange;
      case 'Maintenance':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  Future<List<Map<String, dynamic>>> _filterProvidersByCategory(
      List<QueryDocumentSnapshot> providers, String category) async {
    final filteredProvidersWithServices = <Map<String, dynamic>>[];

    // Check each provider to see if they have services in the specified category
    for (final provider in providers) {
      try {
        // First get services matching the category (or all if "All Categories" is selected)
        QuerySnapshot servicesSnapshot;

        if (category == 'All Categories') {
          // If "All Categories" is selected, get all services
          servicesSnapshot = await FirebaseFirestore.instance
              .collection('providers')
              .doc(provider.id)
              .collection('services')
              .get();
        } else if (_searchQuery.isEmpty) {
          // If no search query, just filter by category
          servicesSnapshot = await FirebaseFirestore.instance
              .collection('providers')
              .doc(provider.id)
              .collection('services')
              .where('category', isEqualTo: category)
              .get();
        } else {
          // If we have a search query, we need to get all services in the category
          // and filter them client-side since Firestore doesn't support text search
          servicesSnapshot = await FirebaseFirestore.instance
              .collection('providers')
              .doc(provider.id)
              .collection('services')
              .where('category', isEqualTo: category)
              .get();
        }

        // Filter services by search query if needed
        final filteredServices = servicesSnapshot.docs.where((serviceDoc) {
          if (_searchQuery.isEmpty) return true;

          final serviceData = serviceDoc.data() as Map<String, dynamic>;
          final serviceName =
              (serviceData['name'] as String? ?? '').toLowerCase();
          final serviceDescription =
              (serviceData['description'] as String? ?? '').toLowerCase();

          return serviceName.contains(_searchQuery) ||
              serviceDescription.contains(_searchQuery);
        }).toList();

        // If they have matching services, add them and their services to the filtered list
        if (filteredServices.isNotEmpty) {
          // Add each matching service as a separate item
          for (final serviceDoc in filteredServices) {
            final serviceData = serviceDoc.data() as Map<String, dynamic>;

            filteredProvidersWithServices.add({
              'provider': provider,
              'service': serviceData,
            });
          }
        }
      } catch (e) {
        print('Error checking services for provider ${provider.id}: $e');
      }
    }

    return filteredProvidersWithServices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: 'Discover Services',
                              fontSize: 28,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text: 'Find verified professionals near you',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Enhanced Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 16,
                          offset: const Offset(0, -2),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const FaIcon(
                                FontAwesomeIcons.magnifyingGlass,
                                color: AppColors.primary,
                                size: 16),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search for services...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                      color: AppColors.onSecondary
                                          .withOpacity(0.6),
                                      fontSize: 15,
                                      fontFamily: 'Regular'),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            color: AppColors.onSecondary
                                                .withOpacity(0.5),
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontFamily: 'Medium',
                                ),
                                onSubmitted: (value) {
                                  setState(() {
                                    _searchQuery = value.trim().toLowerCase();
                                  });
                                },
                              ),
                            ),
                          ),
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const FaIcon(FontAwesomeIcons.sliders,
                                  size: 16, color: Colors.white),
                              onPressed: () {
                                _showFilterSheet(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Results Header with enhanced design
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FaIcon(
                          _getCategoryIcon(_selectedCategory),
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: _searchQuery.isEmpty
                                ? (_selectedCategory == 'All Categories'
                                    ? 'All Services'
                                    : 'Results for "$_selectedCategory"')
                                : (_selectedCategory == 'All Categories'
                                    ? 'Search: "${_searchQuery}"'
                                    : 'Search: "${_searchQuery}" in $_selectedCategory'),
                            fontSize: 16,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                          ),
                          // We'll update this count after fetching data
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('providers')
                                .where('applicationStatus',
                                    isEqualTo: 'approved')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return TextWidget(
                                  text: 'Loading...',
                                  fontSize: 12,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.7),
                                );
                              }

                              if (snapshot.hasError) {
                                return TextWidget(
                                  text: 'Error loading providers',
                                  fontSize: 12,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.7),
                                );
                              }

                              final providers = snapshot.data?.docs ?? [];

                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: _filterProvidersByCategory(
                                    providers, _selectedCategory),
                                builder: (context, futureSnapshot) {
                                  if (futureSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return TextWidget(
                                      text: 'Loading...',
                                      fontSize: 12,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.7),
                                    );
                                  }

                                  if (futureSnapshot.hasError) {
                                    return TextWidget(
                                      text: 'Error loading providers',
                                      fontSize: 12,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.7),
                                    );
                                  }

                                  final count =
                                      futureSnapshot.data?.length ?? 0;
                                  return TextWidget(
                                    text: _searchQuery.isEmpty
                                        ? '$count services found'
                                        : '$count matches found',
                                    fontSize: 12,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.7),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .where('applicationStatus', isEqualTo: 'approved')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextWidget(
                            text: '...',
                            fontSize: 14,
                            fontFamily: 'Bold',
                            color: AppColors.secondary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextWidget(
                            text: '0',
                            fontSize: 14,
                            fontFamily: 'Bold',
                            color: AppColors.secondary,
                          ),
                        );
                      }

                      final providers = snapshot.data?.docs ?? [];

                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _filterProvidersByCategory(
                            providers, _selectedCategory),
                        builder: (context, futureSnapshot) {
                          if (futureSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextWidget(
                                text: '...',
                                fontSize: 14,
                                fontFamily: 'Bold',
                                color: AppColors.secondary,
                              ),
                            );
                          }

                          if (futureSnapshot.hasError) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: TextWidget(
                                text: '0',
                                fontSize: 14,
                                fontFamily: 'Bold',
                                color: AppColors.secondary,
                              ),
                            );
                          }

                          final count = futureSnapshot.data?.length ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _searchQuery.isEmpty
                                  ? AppColors.secondary.withOpacity(0.1)
                                  : AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _searchQuery.isEmpty
                                    ? AppColors.secondary.withOpacity(0.3)
                                    : AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextWidget(
                              text: '$count',
                              fontSize: 14,
                              fontFamily: 'Bold',
                              color: _searchQuery.isEmpty
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Service List - Now fetching from Firestore with proper filtering
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('providers')
                    .where('applicationStatus', isEqualTo: 'approved')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    // Show error details for debugging
                    print('Error fetching providers: ${snapshot.error}');
                    return Center(
                      child: TextWidget(
                        text:
                            'Error loading service providers: ${snapshot.error}',
                        fontSize: 16,
                        fontFamily: 'Medium',
                        color: Colors.red,
                      ),
                    );
                  }

                  final providers = snapshot.data?.docs ?? [];

                  // Debug information
                  print('Found ${providers.length} approved providers');

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _filterProvidersByCategory(
                        providers, _selectedCategory),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (futureSnapshot.hasError) {
                        print(
                            'Error filtering providers: ${futureSnapshot.error}');
                        return Center(
                          child: TextWidget(
                            text:
                                'Error filtering providers: ${futureSnapshot.error}',
                            fontSize: 16,
                            fontFamily: 'Medium',
                            color: Colors.red,
                          ),
                        );
                      }

                      final providersWithServices = futureSnapshot.data ?? [];

                      print(
                          'Found ${providersWithServices.length} providers with services in category $_selectedCategory');

                      if (providersWithServices.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.boxOpen,
                                size: 64,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              TextWidget(
                                text: _searchQuery.isEmpty
                                    ? 'No service providers available'
                                    : 'No matching services found',
                                fontSize: 18,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              TextWidget(
                                text: _searchQuery.isEmpty
                                    ? 'Check back later for new providers'
                                    : 'Try different search terms or categories',
                                fontSize: 14,
                                fontFamily: 'Regular',
                                color: AppColors.onSecondary.withOpacity(0.7),
                              ),
                              if (_searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: TextWidget(
                                      text: 'Clear Search',
                                      fontSize: 14,
                                      fontFamily: 'Bold',
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        children: [
                          // Search indicator
                          if (_searchQuery.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextWidget(
                                      text: _selectedCategory ==
                                              'All Categories'
                                          ? 'Found ${providersWithServices.length} service${providersWithServices.length != 1 ? 's' : ''} matching "${_searchQuery}"'
                                          : 'Found ${providersWithServices.length} service${providersWithServices.length != 1 ? 's' : ''} matching "${_searchQuery}" in $_selectedCategory',
                                      fontSize: 13,
                                      fontFamily: 'Medium',
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  TouchableWidget(
                                    onTap: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(
                                        Icons.clear,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ...providersWithServices.map((item) {
                            final providerDoc =
                                item['provider'] as QueryDocumentSnapshot;
                            final serviceData =
                                item['service'] as Map<String, dynamic>;

                            final data =
                                providerDoc.data() as Map<String, dynamic>;
                            final providerId = providerDoc.id;

                            // Extract provider information
                            final firstName = (data['firstName'] ??
                                    data['fullName'] ??
                                    'Provider')
                                .toString();
                            final lastName =
                                (data['lastName'] ?? '').toString();
                            final businessName = (data['businessName'] ??
                                    'Professional Services')
                                .toString();
                            final providerName = lastName.isNotEmpty
                                ? '$firstName $lastName'
                                : firstName;
                            final email = (data['email'] ?? '').toString();
                            final phone = (data['phone'] ?? '').toString();
                            final location =
                                (data['location'] ?? 'Location not specified')
                                    .toString();

                            // Get rating and reviews
                            final rating =
                                (data['rating'] as num?)?.toDouble() ?? 0.0;
                            final totalBookings =
                                (data['reviews'] as num?)?.toInt() ?? 0;

                            // Extract service details
                            final serviceName =
                                serviceData['name'] as String? ?? 'Service';
                            final serviceDescription =
                                serviceData['description'] as String? ??
                                    'No description';
                            final price = serviceData['price'] as num? ?? 0;
                            final duration =
                                serviceData['duration'] as String? ??
                                    'Duration not specified';
                            final isActive =
                                serviceData['isActive'] as bool? ?? true;

                            return _buildServiceCard(
                              experience: providerDoc['experience'],
                              providerId: providerId,
                              serviceType: _selectedCategory,
                              providerName: providerName,
                              rating: rating,
                              price: price.toInt(),
                              imageColor: _getCategoryColor(_selectedCategory),
                              imageIcon: _getCategoryIcon(_selectedCategory),
                              distance: '2.5km', // Default distance
                              reviews: totalBookings,
                              businessName: businessName,
                              email: email,
                              phone: phone,
                              location: location,
                              serviceName: serviceName,
                              serviceDescription: serviceDescription,
                              duration: duration,
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String providerId,
    required String serviceType,
    required String providerName,
    required double rating,
    required int price,
    required Color imageColor,
    required IconData imageIcon,
    String experience = '',
    String distance = '2.5km',
    int reviews = 100,
    String businessName = 'Professional Services',
    String email = '',
    String phone = '',
    String location = 'Location not specified',
    String serviceName = 'Service',
    String serviceDescription = 'No description',
    String duration = 'Duration not specified',
  }) {
    return TouchableWidget(
      onTap: () {
        Get.to(() => ProviderBookingScreen(
              providerId: providerId,
              providerName: providerName,
              rating: rating,
              reviews: reviews,
              experience: experience,
              verified: true,
              description: serviceDescription,
              initialSelectedService: serviceName, // Pass the selected service
            ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with profile and service info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Profile Picture
                  Stack(
                    children: [
                      TouchableWidget(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProviderProfileScreen(
                                providerId:
                                    providerId, // Pass provider ID instead of individual parameters
                                initialSelectedService: serviceName,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                              width: 2,
                            ),
                          ),
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('providers')
                                .doc(providerId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data!.data() != null) {
                                final data = snapshot.data!.data()!;
                                final profilePicture =
                                    data['profilePicture'] as String?;

                                if (profilePicture != null &&
                                    profilePicture.isNotEmpty) {
                                  // Show image from Firebase Storage
                                  return ClipOval(
                                    child: Image.network(
                                      profilePicture,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        // Fallback to initials if image fails to load
                                        return Container(
                                          color: imageColor.withOpacity(0.2),
                                          child: Center(
                                            child: TextWidget(
                                              text: _getInitials(providerName),
                                              fontSize: 24,
                                              fontFamily: 'Bold',
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }
                              }

                              // Show initials as fallback
                              return Center(
                                child: TextWidget(
                                  text: _getInitials(providerName),
                                  fontSize: 24,
                                  fontFamily: 'Bold',
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Provider Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TouchableWidget(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewProviderProfileScreen(
                                  providerId:
                                      providerId, // Pass provider ID instead of individual parameters
                                  initialSelectedService: serviceName,
                                ),
                              ),
                            );
                          },
                          child: TextWidget(
                            text: providerName,
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              imageIcon,
                              size: 14,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            TextWidget(
                              text: businessName,
                              fontSize: 14,
                              fontFamily: 'Medium',
                              color: AppColors.onSecondary.withOpacity(0.8),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.locationDot,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            TextWidget(
                              text: distance,
                              fontSize: 12,
                              fontFamily: 'Medium',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            FaIcon(
                              FontAwesomeIcons.clock,
                              size: 12,
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            TextWidget(
                              text: 'Available now',
                              fontSize: 12,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Pricing badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextWidget(
                          text: '₱$price',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: Colors.white,
                        ),
                        TextWidget(
                          text: duration,
                          fontSize: 10,
                          fontFamily: 'Regular',
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Service details
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: imageColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: imageColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: serviceName,
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  TextWidget(
                    text: serviceDescription,
                    fontSize: 13,
                    fontFamily: 'Regular',
                    color: AppColors.onSecondary.withOpacity(0.7),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            // Stats section
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Rating
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.solidStar,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: rating > 0
                                  ? rating.toStringAsFixed(1)
                                  : 'N/A',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            TextWidget(
                              text: '$reviews reviews',
                              fontSize: 12,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                  // Completion rate
                  Expanded(
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.checkCircle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: '${(reviews * 0.95).round()}',
                              fontSize: 16,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            TextWidget(
                              text: 'jobs done',
                              fontSize: 12,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: TouchableWidget(
                  onTap: () {
                    Get.to(() => ProviderBookingScreen(
                          providerId: providerId,
                          providerName: providerName,
                          rating: rating,
                          reviews: reviews,
                          experience: experience,
                          verified: true,
                          description: serviceDescription,
                          initialSelectedService:
                              serviceName, // Pass the selected service
                        ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendarCheck,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        TextWidget(
                          text: 'Book Now',
                          fontSize: 16,
                          fontFamily: 'Bold',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> names = name.split(' ');
    String initials = '';
    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }
    return initials;
  }
}
