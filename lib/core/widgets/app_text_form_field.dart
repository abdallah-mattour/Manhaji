// lib/core/widgets/app_text_form_field.dart
import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../theme/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextStyle? style;
  final InputDecoration? decoration; // ← أضفنا دعم decoration كامل
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;

  const AppTextFormField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textDirection,
    this.textAlign,
    this.style,
    this.decoration, // ← أضفناها
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    // دمج الـ decoration المخصص مع الافتراضي
    final defaultDecoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: 18,
      ),
    );

    final finalDecoration = decoration != null
        ? defaultDecoration.copyWith(
            labelText: decoration!.labelText ?? defaultDecoration.labelText,
            hintText: decoration!.hintText ?? defaultDecoration.hintText,
            prefixIcon: decoration!.prefixIcon ?? defaultDecoration.prefixIcon,
            suffixIcon: decoration!.suffixIcon ?? defaultDecoration.suffixIcon,
            filled: decoration!.filled ?? defaultDecoration.filled,
            fillColor: decoration!.fillColor ?? defaultDecoration.fillColor,
            border: decoration!.border ?? defaultDecoration.border,
            enabledBorder:
                decoration!.enabledBorder ?? defaultDecoration.enabledBorder,
            focusedBorder:
                decoration!.focusedBorder ?? defaultDecoration.focusedBorder,
            contentPadding:
                decoration!.contentPadding ?? defaultDecoration.contentPadding,
          )
        : defaultDecoration;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection ?? TextDirection.rtl,
      textAlign: textAlign ?? TextAlign.start,
      style: style ?? const TextStyle(fontFamily: 'Cairo', fontSize: 16),
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: finalDecoration,

      // إزالة Scan Text
      contextMenuBuilder: (context, editableTextState) {
        final List<ContextMenuButtonItem> buttonItems =
            editableTextState.contextMenuButtonItems;

        buttonItems.removeWhere(
          (item) =>
              item.label == 'Scan Text' ||
              item.label == 'مسح النص' ||
              item.label == 'Scan' ||
              item.label.toString().toLowerCase().contains('scan'),
        );

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: buttonItems,
        );
      },
    );
  }
}
