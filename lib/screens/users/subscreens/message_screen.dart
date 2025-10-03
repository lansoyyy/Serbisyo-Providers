import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../services/chat_service.dart';
import '../../../models/message_model.dart';
import 'viewprovider_profile_screen.dart';

class MessageScreen extends StatefulWidget {
  final String contactName;
  final String providerId;

  const MessageScreen(
      {Key? key, required this.contactName, required this.providerId})
      : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering the chat
    _chatService.markMessagesAsRead(widget.providerId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await _chatService.sendMessage(
        receiverId: widget.providerId,
        text: _messageController.text.trim(),
        contactName: widget.contactName,
      );
      _messageController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: TouchableWidget(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewProviderProfileScreen(
                  providerId: widget.providerId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.13),
                child: Center(
                  child: TextWidget(
                    text: (widget.contactName)
                        .split(' ')
                        .map((e) => e[0])
                        .join(''),
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextWidget(
                  text: widget.contactName,
                  fontSize: 20,
                  fontFamily: 'Bold',
                  color: AppColors.primary,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            onPressed: () {
              _makePhoneCall();
            },
            icon: Icon(
              Icons.phone,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Subtle background pattern or color separation
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background,
                    AppColors.background.withOpacity(0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _chatService.getMessages(widget.providerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: TextWidget(
                          text: 'Error loading messages',
                          fontSize: 16,
                          fontFamily: 'Regular',
                          color: Colors.red,
                        ),
                      );
                    }

                    final messages = snapshot.data?.docs ?? [];

                    // Scroll to bottom when new messages arrive
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 18),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageDoc = messages[index];
                        final message =
                            Message.fromMap(messageDoc.data(), messageDoc.id);
                        final isMe = message.senderId ==
                            FirebaseAuth.instance.currentUser!.uid;

                        return Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.08),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                      bottomRight: Radius.circular(18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextWidget(
                                        text: message.text,
                                        fontSize: 15,
                                        color: AppColors.primary,
                                        maxLines: 10,
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text: _formatTime(message.timestamp),
                                        fontSize: 11,
                                        color: Colors.grey,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                            ] else ...[
                              const SizedBox(width: 40),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(18),
                                      topRight: Radius.circular(18),
                                      bottomLeft: Radius.circular(18),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppColors.primary.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      TextWidget(
                                        text: message.text,
                                        fontSize: 15,
                                        color: AppColors.onPrimary,
                                        maxLines: 10,
                                      ),
                                      const SizedBox(height: 4),
                                      TextWidget(
                                        text: _formatTime(message.timestamp),
                                        fontSize: 11,
                                        color: Colors.white70,
                                        maxLines: 1,
                                      ),
                                      // Show read status for sent messages
                                      if (message.isRead) ...[
                                        const SizedBox(height: 2),
                                        TextWidget(
                                          text: 'Read',
                                          fontSize: 10,
                                          color: Colors.white70,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // Floating message input bar
              Container(
                margin: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: AppColors.onSecondary.withOpacity(0.6),
                            fontSize: 15,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 15),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TouchableWidget(
                      onTap: _sendMessage,
                      child: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.send, color: AppColors.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to make a phone call using url_launcher
  void _makePhoneCall() async {
    // First, we need to get the provider's phone number from Firestore
    try {
      final providerDoc = await FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.providerId)
          .get();

      if (providerDoc.exists && providerDoc.data() != null) {
        final providerData = providerDoc.data()!;
        final phoneNumber = providerData['phone'] as String?;

        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          final Uri phoneUri = Uri.parse('tel:$phoneNumber');
          if (await launchUrl(phoneUri)) {
            // Call launched successfully
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: TextWidget(
                  text: 'Calling $phoneNumber',
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: Colors.white,
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            // Could not launch the call
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: TextWidget(
                  text: 'Could not make the call',
                  fontSize: 14,
                  fontFamily: 'Regular',
                  color: Colors.white,
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Phone number not available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: TextWidget(
                text: 'Phone number not available for this provider',
                fontSize: 14,
                fontFamily: 'Regular',
                color: Colors.white,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Provider document not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Provider information not found',
              fontSize: 14,
              fontFamily: 'Regular',
              color: Colors.white,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error occurred while fetching provider data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: TextWidget(
            text: 'Error: ${e.toString()}',
            fontSize: 14,
            fontFamily: 'Regular',
            color: Colors.white,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
