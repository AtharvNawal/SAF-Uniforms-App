import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';
import '../app_text_styles.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.fieldLabel(),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.onChanged,
    this.height = AppSpacing.fieldHeight,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final double height;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: AppTextStyles.body(
          color: isDark ? AppColors.ink : AppColors.inkDark,
          fontSize: 14,
        ).copyWith(fontWeight: FontWeight.w500),
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: AppTextStyles.body(color: AppColors.inkSubtle),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: isDark ? AppColors.lineStrong : AppColors.lineLightStrong,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: isDark ? AppColors.lineStrong : AppColors.lineLightStrong,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabel,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: AppSpacing.fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface2,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.lineStrong : AppColors.lineLightStrong,
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1D20),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          style: AppTextStyles.body(
            color: isDark ? AppColors.ink : AppColors.inkDark,
            fontSize: 14,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<T>(
                  value: e,
                  child: Text(itemLabel(e)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
