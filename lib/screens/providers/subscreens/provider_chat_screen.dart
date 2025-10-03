import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';
import '../../../services/chat_service.dart';
import '../../../models/message_model.dart';

// Individual Chat Screen
class ProviderChatScreen extends StatefulWidget {
  final String customerName;
  final String customerId;

  const ProviderChatScreen({
    Key? key,
    required this.customerName,
    required this.customerId,
  }) : super(key: key);

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering the chat
    _chatService.markMessagesAsRead(widget.customerId);
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
        receiverId: widget.customerId,
        text: _messageController.text.trim(),
        contactName: widget.customerName,
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
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: TextWidget(
                text: widget.customerName[0].toUpperCase(),
                fontSize: 16,
                fontFamily: 'Bold',
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: widget.customerName,
                    fontSize: 18,
                    fontFamily: 'Bold',
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _makePhoneCall();
            },
            icon: const FaIcon(
              FontAwesomeIcons.phone,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.customerId),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final message =
                        Message.fromMap(messageDoc.data(), messageDoc.id);
                    final isMe = message.senderId ==
                        FirebaseAuth.instance.currentUser!.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.primary.withOpacity(0.1),
                              child: TextWidget(
                                text: widget.customerName[0].toUpperCase(),
                                fontSize: 12,
                                fontFamily: 'Bold',
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    text: message.text,
                                    fontSize: 16,
                                    fontFamily: 'Regular',
                                    color:
                                        isMe ? Colors.white : AppColors.primary,
                                  ),
                                  const SizedBox(height: 4),
                                  TextWidget(
                                    text: _formatTime(message.timestamp),
                                    fontSize: 12,
                                    fontFamily: 'Regular',
                                    color: isMe
                                        ? Colors.white.withOpacity(0.7)
                                        : AppColors.onSecondary
                                            .withOpacity(0.5),
                                  ),
                                  // Show read status for sent messages
                                  if (isMe && message.isRead) ...[
                                    const SizedBox(height: 2),
                                    TextWidget(
                                      text: 'Read',
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white.withOpacity(0.7)
                                          : AppColors.onSecondary
                                              .withOpacity(0.5),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              child: FaIcon(
                                message.isRead
                                    ? FontAwesomeIcons.checkDouble
                                    : FontAwesomeIcons.check,
                                color: message.isRead
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Function to make a phone call using url_launcher
  void _makePhoneCall() async {
    // First, we need to get the customer's phone number from Firestore
    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customerId)
          .get();

      if (customerDoc.exists && customerDoc.data() != null) {
        final customerData = customerDoc.data()!;
        final phoneNumber = customerData['phone'] as String?;

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
                text: 'Phone number not available for this customer',
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
        // Customer document not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: TextWidget(
              text: 'Customer information not found',
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
      // Error occurred while fetching customer data
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          TouchableWidget(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.paperPlane,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
