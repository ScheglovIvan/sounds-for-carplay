import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pill-shaped input used for search and generic text entry. Fill/hint colors
/// come from the theme's [InputDecorationTheme]; this widget just supplies the
/// leading search glyph, clear affordance and a consistent shape.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.leadingIcon = Icons.search_rounded,
    this.showClear = false,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? leadingIcon;
  final bool showClear;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: leadingIcon == null
            ? null
            : Icon(leadingIcon, color: AppColors.textSecondary, size: 20),
        suffixIcon: showClear
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    color: AppColors.textSecondary, size: 18),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}
