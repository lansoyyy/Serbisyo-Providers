import 'package:flutter/material.dart';

class DividerWidget extends StatelessWidget {
  Color? color;
  DividerWidget({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: 0.5,
      color: color,
    );
  }
}
