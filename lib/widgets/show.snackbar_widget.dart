import 'package:hanap_raket/widgets/text_widget.dart';
import 'package:flutter/material.dart';

showSnackBar(BuildContext context, String title, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: TextWidget(
        text: title,
        fontSize: 14,
        fontFamily: 'Regular',
        color: Colors.white,
      ),
      backgroundColor: color,
    ),
  );
}
