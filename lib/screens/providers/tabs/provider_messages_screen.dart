import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanap_raket/screens/providers/subscreens/provider_chat_screen.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

class ProviderMessagesScreen extends StatefulWidget {
  const ProviderMessagesScreen({Key? key}) : super(key: key);

  @override
  State<ProviderMessagesScreen> createState() => _ProviderMessagesScreenState();
}

class _ProviderMessagesScreenState extends State<ProviderMessagesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const FaIcon(
                                    FontAwesomeIcons.comments,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: 'Messages',
                                        fontSize: 26,
                                        fontFamily: 'Bold',
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text: 'Chat with your customers',
                                        fontSize: 16,
                                        fontFamily: 'Regular',
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildSearchBar(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: _buildAllMessages(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openNewChatScreen();
        },
        backgroundColor: AppColors.primary,
        child: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            color: Colors.white,
            size: 20,
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
                border: InputBorder.none,
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
                child: FaIcon(
                  FontAwesomeIcons.xmark,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Stream to fetch provider's conversations
  Stream<QuerySnapshot<Map<String, dynamic>>>
      _getProviderConversationsStream() {
    final providerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('providerId', isEqualTo: providerId)
        .orderBy('bookingTimestamp', descending: true)
        .snapshots();
  }

  // Extract unique conversations from booking documents
  List<Map<String, dynamic>> _extractUniqueConversations(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings) {
    final Map<String, Map<String, dynamic>> uniqueConversations = {};

    for (var booking in bookings) {
      final data = booking.data();
      final userId = data['userId'] as String? ?? '';
      final userFirstName = data['userFirstName'] as String? ?? 'Customer';
      final userLastName = data['userLastName'] as String? ?? '';
      final userFullName = '$userFirstName $userLastName'.trim();
      final serviceName = data['serviceName'] as String? ?? 'Service';
      final bookingTimestamp = data['bookingTimestamp'] as Timestamp?;

      // Only add if we haven't seen this user yet or if this is a more recent booking
      if (!uniqueConversations.containsKey(userId) ||
          uniqueConversations[userId]!['bookingTimestamp'] == null ||
          (bookingTimestamp != null &&
              (uniqueConversations[userId]!['bookingTimestamp'] as Timestamp?)
                      ?.toDate()
                      .isBefore(bookingTimestamp.toDate()) ==
                  true)) {
        uniqueConversations[userId] = {
          'id': userId,
          'name': userFullName.isNotEmpty ? userFullName : userFirstName,
          'service': serviceName,
          'bookingTimestamp': bookingTimestamp,
        };
      }
    }

    return uniqueConversations.values.toList();
  }

  Widget _buildAllMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getProviderConversationsStream(),
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
        final filteredConversations = conversations.where((conversation) {
          if (_searchQuery.isEmpty) return true;
          final name = conversation['name'] as String? ?? '';
          final service = conversation['service'] as String? ?? '';
          return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              service.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredConversations.isEmpty) {
          return _buildEmptyState(
            FontAwesomeIcons.envelopeOpen,
            'No Conversations',
            'You have no conversations with customers yet.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation = filteredConversations[index];
              return _buildConversationCard(conversation);
            },
          ),
        );
      },
    );
  }

  Widget _buildUnreadMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _getProviderConversationsStream(),
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

        // For now, we'll show all conversations in the unread tab as well
        // In a more advanced implementation, we would check for actual unread messages
        final filteredConversations = conversations.where((conversation) {
          if (_searchQuery.isEmpty) return true;
          final name = conversation['name'] as String? ?? '';
          final service = conversation['service'] as String? ?? '';
          return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              service.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredConversations.isEmpty) {
          return _buildEmptyState(
            FontAwesomeIcons.envelopeOpen,
            'No Unread Messages',
            'All caught up! You have no unread messages.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredConversations.length,
            itemBuilder: (context, index) {
              final conversation = filteredConversations[index];
              return _buildConversationCard(conversation);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: FaIcon(
              icon,
              color: AppColors.primary.withOpacity(0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          TextWidget(
            text: title,
            fontSize: 22,
            fontFamily: 'Bold',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextWidget(
              text: subtitle,
              fontSize: 16,
              fontFamily: 'Regular',
              color: AppColors.onSecondary.withOpacity(0.7),
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Map<String, dynamic> conversation) {
    final String userId = conversation['id'] as String;
    final String providerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Generate chat room ID (same logic as in chat service)
    List<String> sortedIds = [userId, providerId]..sort();
    final String chatRoomId = '${sortedIds[0]}_${sortedIds[1]}';

    return TouchableWidget(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProviderChatScreen(
              customerName: conversation['name'] as String,
              customerId: conversation['id'] as String,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: TextWidget(
                    text: (conversation['name'] as String)[0].toUpperCase(),
                    fontSize: 22,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),

            // Conversation content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextWidget(
                          text: conversation['name'] as String,
                          fontSize: 18,
                          fontFamily: 'Bold',
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return TextWidget(
                          text: 'Loading...',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                          maxLines: 2,
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return TextWidget(
                          text: 'No messages yet',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: AppColors.onSecondary.withOpacity(0.7),
                          maxLines: 2,
                        );
                      }

                      final lastMessageDoc = snapshot.data!.docs.first;
                      final lastMessageData = lastMessageDoc.data();
                      final lastMessageText =
                          lastMessageData['text'] as String? ?? '';
                      final lastMessageTimestamp =
                          lastMessageData['timestamp'] as Timestamp?;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: lastMessageText,
                            fontSize: 16,
                            fontFamily: 'Regular',
                            color: AppColors.onSecondary.withOpacity(0.9),
                            maxLines: 2,
                          ),
                          if (lastMessageTimestamp != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.clock,
                                  color: AppColors.onSecondary.withOpacity(0.5),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                TextWidget(
                                  text: _formatTimeAgo(lastMessageTimestamp),
                                  fontSize: 14,
                                  fontFamily: 'Regular',
                                  color: AppColors.onSecondary.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                // Unread indicator would go here in a more advanced implementation
                TouchableWidget(
                  onTap: () {
                    _showMessageOptions(conversation);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.ellipsisVertical,
                      color: Colors.grey.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

  void _showMessageOptions(Map<String, dynamic> conversation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              FontAwesomeIcons.envelope,
              'View Conversation',
              AppColors.primary,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderChatScreen(
                      customerName: conversation['name'] as String,
                      customerId: conversation['id'] as String,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return TouchableWidget(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            TextWidget(
              text: title,
              fontSize: 18,
              fontFamily: 'Medium',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _openNewChatScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    TextWidget(
                      text: 'Previous Customers',
                      fontSize: 22,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    const Spacer(),
                    TouchableWidget(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.xmark,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.magnifyingGlass,
                        color: Colors.grey,
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
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search customers...',
                            hintStyle: TextStyle(
                              color: Colors.grey.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
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
                            child: const FaIcon(
                              FontAwesomeIcons.xmark,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _getProviderConversationsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: TextWidget(
                          text: 'Error loading customers',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: Colors.red,
                        ),
                      );
                    }

                    final conversations =
                        _extractUniqueConversations(snapshot.data?.docs ?? []);
                    final filteredConversations = conversations
                        .where((conversation) {
                          if (_searchQuery.isEmpty) return true;
                          final name = conversation['name'] as String? ?? '';
                          return name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase());
                        })
                        .toList()
                        .reversed
                        .toList();

                    if (filteredConversations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.users,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextWidget(
                              text: 'No Customers Found',
                              fontSize: 22,
                              fontFamily: 'Bold',
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: TextWidget(
                                text:
                                    'You haven\'t had any transactions with customers yet.',
                                fontSize: 16,
                                fontFamily: 'Regular',
                                color: AppColors.onSecondary.withOpacity(0.7),
                                align: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conversation = filteredConversations[index];
                        return _buildCustomerCard(conversation);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TouchableWidget(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderChatScreen(
                customerName: customer['name'] as String,
                customerId: customer['id'] as String,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
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
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: TextWidget(
                  text: (customer['name'] as String)[0].toUpperCase(),
                  fontSize: 18,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: customer['name'] as String,
                      fontSize: 18,
                      fontFamily: 'Bold',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    TextWidget(
                      text: customer['service'] as String? ?? 'Service',
                      fontSize: 14,
                      fontFamily: 'Regular',
                      color: AppColors.onSecondary.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              const FaIcon(
                FontAwesomeIcons.chevronRight,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
