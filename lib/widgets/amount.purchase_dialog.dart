import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountPurchaseDialog extends StatelessWidget {
  int? percentage;
  bool? isPurchase;

  AmountPurchaseDialog({this.percentage = 0, this.isPurchase = false});

  @override
  Widget build(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isPurchase! ? 'Amount of Purchase (Redeem)' : 'Amount of Purchase',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C2526),
          fontFamily: 'Medium',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              labelStyle: TextStyle(color: Colors.grey[600]),
              prefixText: '₱ ',
              prefixStyle: const TextStyle(
                color: Color(0xFF1C2526),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF0033A0), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1C2526)),
          ),
          const SizedBox(height: 12),
          Text(
            percentage == 0
                ? 'Inputted amount will be deducted to customer points'
                : '$percentage% of the entered amount will be awarded as loyalty points to the customer.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'Regular',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontFamily: 'Medium',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (amountController.text.isNotEmpty) {
              Navigator.pop(context, amountController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0033A0),
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 2,
          ),
          child: const Text(
            'Submit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Medium',
            ),
          ),
        ),
      ],
    );
  }
}
