import 'package:flutter/material.dart';

import '../config/theme.dart';

class SearchBarWidget extends StatelessWidget {

  const SearchBarWidget({
    super.key,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search products...',
    this.enabled = true,
    this.autofocus = false,
  });
  final VoidCallback? onTap;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey200,
          ),
        ),
        child: TextField(
          controller: controller,
          enabled: enabled && onTap == null,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.grey500,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.grey500,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
