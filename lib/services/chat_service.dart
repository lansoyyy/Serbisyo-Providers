import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the chat room ID for two users (consistent regardless of order)
  String _getChatRoomId(String user1Id, String user2Id) {
    // Create a consistent chat room ID by sorting the user IDs
    List<String> sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Send a message
  Future<void> sendMessage({
    required String receiverId,
    required String text,
    required String contactName,
  }) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, receiverId);
    final Timestamp timestamp = Timestamp.now();

    // Create the message
    final Message message = Message(
      id: '',
      senderId: currentUserId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
      isRead: false,
    );

    // Save the message to Firestore
    await _firestore
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    // Update the chat room metadata
    await _firestore.collection('chatrooms').doc(chatRoomId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': text,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
    }, SetOptions(merge: true));

    // Update unread count for receiver
    final chatRoomRef = _firestore.collection('chatrooms').doc(chatRoomId);
    final receiverUnreadRef =
        chatRoomRef.collection('unread_counts').doc(receiverId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(receiverUnreadRef);
      if (snapshot.exists) {
        final currentCount = snapshot.data()?['count'] ?? 0;
        transaction.update(receiverUnreadRef, {'count': currentCount + 1});
      } else {
        transaction.set(receiverUnreadRef, {'count': 1});
      }
    });
  }

  // Get messages for a chat room
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String receiverId) {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, receiverId);

    return _firestore
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, receiverId);

    // Update unread count for current user
    final chatRoomRef = _firestore.collection('chatrooms').doc(chatRoomId);
    final userUnreadRef =
        chatRoomRef.collection('unread_counts').doc(currentUserId);

    await userUnreadRef.set({'count': 0});

    // Mark messages as read
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Get unread message count
  Stream<int> getUnreadCount(String userId) {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, userId);

    return _firestore
        .collection('chatrooms')
        .doc(chatRoomId)
        .collection('unread_counts')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['count'] ?? 0;
      }
      return 0;
    });
  }

  // Get last message for a chat room
  Stream<DocumentSnapshot<Map<String, dynamic>>> getLastMessage(String userId) {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, userId);

    return _firestore.collection('chatrooms').doc(chatRoomId).snapshots();
  }
}
