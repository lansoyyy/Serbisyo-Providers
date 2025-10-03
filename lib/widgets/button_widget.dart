import 'package:flutter/material.dart';
import 'package:hanap_raket/utils/colors.dart';
import 'package:hanap_raket/widgets/text_widget.dart';

class ButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double? fontSize;
  final double? height;
  final double? radius;
  final Color color;
  final Color? textColor;
  final bool loading;
  final bool disabled;

  const ButtonWidget(
      {super.key,
      this.radius = 100,
      required this.label,
      this.textColor = Colors.white,
      this.onPressed,
      this.width = 300,
      this.fontSize = 18,
      this.height = 60,
      this.color = primary,
      this.loading = false,
      this.disabled = false});
  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius!)),
        minWidth: width,
        height: height,
        color: color,
        onPressed:
            (loading || disabled || onPressed == null) ? null : onPressed,
        child: loading
            ? SizedBox(
                width: (fontSize ?? 18) + 4,
                height: (fontSize ?? 18) + 4,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(textColor ?? Colors.white),
                ),
              )
            : TextWidget(
                text: label,
                fontSize: fontSize!,
                color: textColor,
                fontFamily: 'Bold',
              ));
  }
}
