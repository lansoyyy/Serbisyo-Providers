import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../subscreens/message_screen.dart';
import '../subscreens/viewprovider_profile_screen.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({Key? key}) : super(key: key);

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Recent

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              TextWidget(
                text: 'Filter Conversations',
                fontSize: 18,
                fontFamily: 'Bold',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              ...['All', 'Active', 'Recent'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return TouchableWidget(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          filter == 'All'
                              ? FontAwesomeIcons.list
                              : filter == 'Active'
                                  ? FontAwesomeIcons.circle
                                  : FontAwesomeIcons.clock,
                          size: 16,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        TextWidget(
                          text: filter,
                          fontSize: 16,
                          fontFamily: isSelected ? 'Bold' : 'Medium',
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.onSecondary,
                        ),
                        const Spacer(),
                        if (isSelected)
                          FaIcon(
                            FontAwesomeIcons.check,
                            size: 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showNewMessageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                          text: 'Start New Conversation',
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
                    // Search bar for providers
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.magnifyingGlass,
                              color: AppColors.onSecondary.withOpacity(0.6),
                              size: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search providers...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color:
                                        AppColors.onSecondary.withOpacity(0.6),
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                  ),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Medium',
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              TouchableWidget(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                child: FaIcon(
                                  FontAwesomeIcons.xmark,
                                  color: AppColors.onSecondary.withOpacity(0.6),
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextWidget(
                      text: 'Providers You\'ve Booked',
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    // List of providers the user has transacted with
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _getUserProvidersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: TextWidget(
                              text: 'Error loading providers',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: Colors.red,
                            ),
                          );
                        }

                        final providers =
                            _extractUniqueProviders(snapshot.data?.docs ?? []);
                        final filteredProviders = providers.where((provider) {
                          if (_searchQuery.isEmpty) return true;
                          final name = provider['name'] as String? ?? '';
                          final service = provider['service'] as String? ?? '';
                          return name
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase()) ||
                              service
                                  .toLowerCase()
                                  .contains(_searchQuery.toLowerCase());
                        }).toList();

                        if (filteredProviders.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.userFriends,
                                    size: 40,
                                    color: AppColors.primary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  TextWidget(
                                    text: _searchQuery.isEmpty
                                        ? 'No providers found'
                                        : 'No providers match your search',
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  TextWidget(
                                    text: _searchQuery.isEmpty
                                        ? 'Book a service to start messaging providers'
                                        : 'Try a different search term',
                                    fontSize: 12,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.5),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: filteredProviders.length,
                            itemBuilder: (context, index) {
                              final provider = filteredProviders[index];
                              return _buildProviderItem(provider);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Stream to fetch providers the user has booked services from
  Stream<QuerySnapshot<Map<String, dynamic>>> _getUserProvidersStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingTimestamp', descending: true)
        .snapshots();
  }

  // Extract unique providers from booking documents
  List<Map<String, dynamic>> _extractUniqueProviders(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final Map<String, Map<String, dynamic>> uniqueProviders = {};

    for (var booking in bookings) {
      final data = booking.data();
      final providerId = data['providerId'] as String? ?? '';
      final providerName = data['providerFullName'] as String? ?? 'Provider';
      final serviceName = data['serviceName'] as String? ?? 'Service';

      // Only add if we haven't seen this provider yet or if this is a more recent booking
      if (!uniqueProviders.containsKey(providerId) ||
          uniqueProviders[providerId]!['timestamp'] == null ||
          (data['bookingTimestamp'] != null &&
              (uniqueProviders[providerId]!['timestamp'] as Timestamp?)
                      ?.toDate()
                      .isBefore(
                          (data['bookingTimestamp'] as Timestamp).toDate()) ==
                  true)) {
        uniqueProviders[providerId] = {
          'id': providerId,
          'name': providerName,
          'service': serviceName,
          'timestamp': data['bookingTimestamp'],
        };
      }
    }

    return uniqueProviders.values.toList();
  }

  // Build a provider item for the list
  Widget _buildProviderItem(Map<String, dynamic> provider) {
    return TouchableWidget(
      onTap: () {
        Navigator.pop(context);
        // Navigate to message screen with selected provider
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              contactName: provider['name'] as String,
              providerId: provider['id'] as String,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.1),
            width: 1,
          ),
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
            TouchableWidget(
              onTap: () {
                Navigator.pop(context);
                // Navigate to provider profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewProviderProfileScreen(
                      providerId: provider['id'] as String,
                    ),
                  ),
                );
              },
              child: Container(
                width: 50,
                height: 50,
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
                child: Center(
                  child: TextWidget(
                    text: (provider['name'] as String)
                        .split(' ')
                        .map((e) => e[0])
                        .join(''),
                    fontSize: 16,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TouchableWidget(
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to provider profile
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewProviderProfileScreen(
                            providerId: provider['id'] as String,
                          ),
                        ),
                      );
                    },
                    child: TextWidget(
                      text: provider['name'] as String,
                      fontSize: 16,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextWidget(
                      text: provider['service'] as String,
                      fontSize: 12,
                      fontFamily: 'Medium',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            FaIcon(
              FontAwesomeIcons.commentDots,
              color: AppColors.primary.withOpacity(0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredChats() {
    final allChats = List.generate(
        8,
        (index) => {
              'name': [
                'Maria Santos',
                'John Miller',
                'Anna Garcia',
                'David Wilson',
                'Sofia Rodriguez',
                'Michael Brown',
                'Elena Lopez',
                'James Taylor'
              ][index],
              'service': [
                'House Cleaning',
                'AC Repair',
                'Plumbing',
                'Electrical Work',
                'Gardening',
                'Painting',
                'Carpentry',
                'Pest Control'
              ][index],
              'lastMessage': [
                'Thank you for the excellent service!',
                'I\'ll be there at 2 PM tomorrow',
                'The job is completed. Please check',
                'When would be convenient for you?',
                'I have all the materials ready',
                'Running 15 minutes late, sorry!',
                'Service completed successfully',
                'Please confirm the appointment'
              ][index],
              'time': [
                '2:30 PM',
                '1:45 PM',
                '12:20 PM',
                '11:15 AM',
                '10:30 AM',
                'Yesterday',
                'Yesterday',
                '2 days ago'
              ][index],
              'hasUnread': index % 3 == 0,
              'isActive': index < 4,
            });

    if (_selectedFilter == 'All') {
      return allChats;
    } else if (_selectedFilter == 'Active') {
      return allChats.where((chat) => chat['isActive'] == true).toList();
    } else {
      return allChats.where((chat) => chat['isActive'] != true).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _getFilteredChats();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
                          FontAwesomeIcons.commentDots,
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
                              text: 'Messages',
                              fontSize: 28,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            TextWidget(
                              text: 'Chat with your service providers',
                              fontSize: 14,
                              fontFamily: 'Regular',
                              color: AppColors.onSecondary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                      TouchableWidget(
                        onTap: () {
                          // Handle new message action - could show a modal to select provider
                          _showNewMessageOptions();
                        },
                        child: Container(
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
                          child: FaIcon(
                            FontAwesomeIcons.plus,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Filter and Search Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  color: AppColors.onSecondary.withOpacity(0.6),
                                  size: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onSubmitted: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search conversations...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: AppColors.onSecondary
                                            .withOpacity(0.6),
                                        fontSize: 14,
                                        fontFamily: 'Regular',
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Medium',
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  TouchableWidget(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.onSecondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.xmark,
                                        color: AppColors.onSecondary
                                            .withOpacity(0.7),
                                        size: 12,
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Filter Button
                      TouchableWidget(
                        onTap: _showFilterOptions,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: _selectedFilter != 'All'
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color:
                                _selectedFilter != 'All' ? null : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedFilter != 'All'
                                  ? AppColors.primary
                                  : AppColors.primary.withOpacity(0.3),
                              width: _selectedFilter != 'All' ? 0 : 1.5,
                            ),
                            boxShadow: _selectedFilter != 'All'
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(
                                _selectedFilter == 'All'
                                    ? FontAwesomeIcons.filter
                                    : _selectedFilter == 'Active'
                                        ? FontAwesomeIcons.circle
                                        : FontAwesomeIcons.clock,
                                size: 16,
                                color: _selectedFilter != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              TextWidget(
                                text: _selectedFilter,
                                fontSize: 14,
                                fontFamily: 'Bold',
                                color: _selectedFilter != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              FaIcon(
                                FontAwesomeIcons.chevronDown,
                                size: 12,
                                color: _selectedFilter != 'All'
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chat List - Updated to use real Firebase data
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _getUserConversationsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: TextWidget(
                        text: 'Error loading conversations',
                        fontSize: 16,
                        fontFamily: 'Regular',
                        color: Colors.red,
                      ),
                    );
                  }

                  final conversations =
                      _extractUniqueConversations(snapshot.data?.docs ?? []);
                  final filteredConversations =
                      conversations.where((conversation) {
                    if (_searchQuery.isEmpty) return true;
                    final name = conversation['name'] as String? ?? '';
                    final service = conversation['service'] as String? ?? '';
                    return name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        service
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredConversations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.commentSlash,
                              size: 48,
                              color: AppColors.primary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextWidget(
                            text: 'No Conversations',
                            fontSize: 18,
                            fontFamily: 'Bold',
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          TextWidget(
                            text: 'Start a conversation with a provider',
                            fontSize: 14,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...filteredConversations
                            .map((conversation) =>
                                _buildConversationItem(conversation))
                            .toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stream to fetch user's conversations
  Stream<QuerySnapshot<Map<String, dynamic>>> _getUserConversationsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('bookingTimestamp', descending: true)
        .snapshots();
  }

  // Extract unique conversations from booking documents
  List<Map<String, dynamic>> _extractUniqueConversations(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final Map<String, Map<String, dynamic>> uniqueConversations = {};

    for (var booking in bookings) {
      final data = booking.data();
      final providerId = data['providerId'] as String? ?? '';
      final providerName = data['providerFullName'] as String? ?? 'Provider';
      final serviceName = data['serviceName'] as String? ?? 'Service';
      final bookingTimestamp = data['bookingTimestamp'] as Timestamp?;

      // Only add if we haven't seen this provider yet or if this is a more recent booking
      if (!uniqueConversations.containsKey(providerId) ||
          uniqueConversations[providerId]!['bookingTimestamp'] == null ||
          (bookingTimestamp != null &&
              (uniqueConversations[providerId]!['bookingTimestamp']
                          as Timestamp?)
                      ?.toDate()
                      .isBefore(bookingTimestamp.toDate()) ==
                  true)) {
        uniqueConversations[providerId] = {
          'id': providerId,
          'name': providerName,
          'service': serviceName,
          'bookingTimestamp': bookingTimestamp,
        };
      }
    }

    return uniqueConversations.values.toList();
  }

  // Build a conversation item for the list
  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    final String providerId = conversation['id'] as String;
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Generate chat room ID (same logic as in chat service)
    List<String> sortedIds = [userId, providerId]..sort();
    final String chatRoomId = '${sortedIds[0]}_${sortedIds[1]}';

    return TouchableWidget(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              contactName: conversation['name'] as String,
              providerId: conversation['id'] as String,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Enhanced Avatar
              Container(
                width: 60,
                height: 60,
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
                child: Center(
                  child: TextWidget(
                    text: (conversation['name'] as String)
                        .split(' ')
                        .map((e) => e[0])
                        .join(''),
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Chat Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: conversation['name'] as String,
                                fontSize: 16,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextWidget(
                                  text: conversation['service'] as String,
                                  fontSize: 11,
                                  fontFamily: 'Medium',
                                  color: AppColors.primary,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Display time from the conversation data
                        if (conversation['timestamp'] != null) ...[
                          TextWidget(
                            text: _formatTimeAgo(
                                conversation['timestamp'] as Timestamp),
                            fontSize: 12,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.7),
                            maxLines: 1,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Last message preview from Firebase
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('chatrooms')
                          .doc(chatRoomId)
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.commentDots,
                                  color: AppColors.primary,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextWidget(
                                  text: 'Loading...',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.8),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          );
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.commentDots,
                                  color: AppColors.primary,
                                  size: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextWidget(
                                  text: 'No messages yet',
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.8),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          );
                        }

                        final lastMessageDoc = snapshot.data!.docs.first;
                        final lastMessageData = lastMessageDoc.data();
                        final lastMessageText =
                            lastMessageData['text'] as String? ?? '';
                        final lastMessageTimestamp =
                            lastMessageData['timestamp'] as Timestamp?;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: FaIcon(
                                FontAwesomeIcons.commentDots,
                                color: AppColors.primary,
                                size: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: lastMessageText,
                                    fontSize: 14,
                                    fontFamily: 'Regular',
                                    color:
                                        AppColors.onSecondary.withOpacity(0.8),
                                    maxLines: 2,
                                  ),
                                  if (lastMessageTimestamp != null) ...[
                                    const SizedBox(height: 2),
                                    TextWidget(
                                      text:
                                          _formatTimeAgo(lastMessageTimestamp),
                                      fontSize: 11,
                                      fontFamily: 'Regular',
                                      color: AppColors.onSecondary
                                          .withOpacity(0.6),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format timestamp to relative time
  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final time = timestamp.toDate();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}
