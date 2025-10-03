import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppTextFormField extends StatefulWidget {
  const AppTextFormField({
    super.key,
    required this.textInputAction,
    required this.labelText,
    required this.keyboardType,
    required this.controller,
    this.onChanged,
    this.validator,
    this.obscureText,
    this.suffixIcon,
    this.prefixIcon,
    this.onEditingComplete,
    this.autofocus,
    this.focusNode,
    this.hintText,
    this.maxLines,
    this.enabled,
  });

  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final bool? obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String labelText;
  final String? hintText;
  final bool? autofocus;
  final FocusNode? focusNode;
  final void Function()? onEditingComplete;
  final int? maxLines;
  final bool? enabled;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused
                ? AppColors.primary
                : widget.controller.text.isNotEmpty
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
            width: _isFocused ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _isFocused ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          focusNode: _focusNode,
          onChanged: (value) {
            setState(() {}); // Rebuild to update border color
            widget.onChanged?.call(value);
          },
          autofocus: widget.autofocus ?? false,
          validator: widget.validator,
          obscureText: widget.obscureText ?? false,
          obscuringCharacter: '●',
          onEditingComplete: widget.onEditingComplete,
          maxLines: widget.maxLines ?? 1,
          enabled: widget.enabled ?? true,
          decoration: InputDecoration(
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            labelText: widget.labelText,
            hintText: widget.hintText,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isFocused ? AppColors.primary : Colors.grey.shade600,
              fontFamily: 'Medium',
            ),
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
              fontFamily: 'Regular',
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontFamily: 'Medium',
            ),
          ),
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            fontFamily: 'Medium',
          ),
        ),
      ),
    );
  }
}
