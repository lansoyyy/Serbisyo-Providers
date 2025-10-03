import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../utils/colors.dart';
import '../../../widgets/text_widget.dart';
import '../../../widgets/touchable_widget.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<FAQItem> faqItems = [
    FAQItem(
      question: 'How do I book a service?',
      answer:
          'To book a service, browse our Services tab, select your preferred provider, choose a time slot, and confirm your booking. You\'ll receive a confirmation notification.',
      icon: FontAwesomeIcons.calendarPlus,
      category: 'Booking',
    ),
    FAQItem(
      question: 'How can I cancel or reschedule my booking?',
      answer:
          'Go to your Bookings tab, find your appointment, and tap on it. You\'ll see options to cancel or reschedule. Please note that cancellation policies may apply.',
      icon: FontAwesomeIcons.calendarXmark,
      category: 'Booking',
    ),
    FAQItem(
      question: 'What payment methods are accepted?',
      answer:
          'We accept GCash, PayMaya, credit/debit cards, and bank transfers. You can manage your payment methods in Profile > Payment Methods.',
      icon: FontAwesomeIcons.creditCard,
      category: 'Payment',
    ),
    FAQItem(
      question: 'How do I contact my service provider?',
      answer:
          'You can message your service provider directly through the Chat tab. Once you have a confirmed booking, you\'ll be able to communicate with them.',
      icon: FontAwesomeIcons.comments,
      category: 'Communication',
    ),
    FAQItem(
      question: 'What if I\'m not satisfied with the service?',
      answer:
          'We have a satisfaction guarantee. You can rate and review the service after completion. If you\'re not satisfied, contact our support team for assistance.',
      icon: FontAwesomeIcons.star,
      category: 'Service Quality',
    ),
    FAQItem(
      question: 'How do I become a service provider?',
      answer:
          'To become a service provider, contact our support team. We\'ll guide you through the application process, requirements, and verification steps.',
      icon: FontAwesomeIcons.userPlus,
      category: 'Provider',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer:
          'Yes, we take privacy seriously. Your personal information is encrypted and stored securely. You can review our privacy settings in Profile > Privacy & Security.',
      icon: FontAwesomeIcons.shield,
      category: 'Privacy',
    ),
    FAQItem(
      question: 'How do I update my profile information?',
      answer:
          'Go to Profile tab and tap on "Edit Profile" in the Account Settings section. You can update your name, email, phone number, and address.',
      icon: FontAwesomeIcons.userPen,
      category: 'Account',
    ),
  ];

  String selectedCategory = 'All';
  List<String> categories = [
    'All',
    'Booking',
    'Payment',
    'Communication',
    'Service Quality',
    'Provider',
    'Privacy',
    'Account'
  ];

  @override
  Widget build(BuildContext context) {
    List<FAQItem> filteredFAQs = selectedCategory == 'All'
        ? faqItems
        : faqItems.where((faq) => faq.category == selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: TouchableWidget(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        title: TextWidget(
          text: 'Help Center',
          fontSize: 20,
          fontFamily: 'Bold',
          color: Colors.white,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.questionCircle,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextWidget(
                    text: 'Frequently Asked Questions',
                    fontSize: 24,
                    fontFamily: 'Bold',
                    color: Colors.white,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextWidget(
                    text: 'Find answers to common questions about our services',
                    fontSize: 14,
                    fontFamily: 'Regular',
                    color: Colors.white.withOpacity(0.9),
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return TouchableWidget(
                  onTap: () {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: TextWidget(
                        text: category,
                        fontSize: 14,
                        fontFamily: 'Medium',
                        color:
                            isSelected ? Colors.white : AppColors.onSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: filteredFAQs.length,
              itemBuilder: (context, index) {
                final faq = filteredFAQs[index];
                return _buildFAQCard(faq);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(
            faq.icon,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        title: TextWidget(
          text: faq.question,
          fontSize: 16,
          fontFamily: 'Bold',
          color: AppColors.primary,
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextWidget(
            text: faq.category,
            fontSize: 11,
            fontFamily: 'Medium',
            color: AppColors.primary,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              child: TextWidget(
                text: faq.answer,
                fontSize: 14,
                fontFamily: 'Regular',
                color: AppColors.onSecondary,
                maxLines: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final IconData icon;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.icon,
    required this.category,
  });
}
