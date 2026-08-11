import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The shared navigation bar. Renders a centered title with an optional leading
/// control (back / menu) and a list of trailing actions (e.g. a GET PRO badge).
///
/// Implements [PreferredSizeWidget] so it can be dropped straight into
/// `Scaffold.appBar` or `AppScaffold.topBar`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.showBack = false,
    this.onBack,
    this.showMenu = false,
    this.onMenu,
    this.actions = const [],
    this.centerTitle = true,
    this.backgroundColor,
  });

  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showMenu;
  final VoidCallback? onMenu;
  final List<Widget> actions;
  final bool centerTitle;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    Widget? leadingWidget = leading;
    if (leadingWidget == null && showBack) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 30),
        color: AppColors.textPrimary,
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    } else if (leadingWidget == null && showMenu) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.menu_rounded),
        color: AppColors.textPrimary,
        onPressed: onMenu,
      );
    }

    final TextStyle titleStyle =
        (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return SafeArea(
      bottom: false,
      child: Container(
        height: preferredSize.height,
        color: backgroundColor ?? Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: leadingWidget == null
                  ? null
                  : Align(alignment: Alignment.centerLeft, child: leadingWidget),
            ),
            Expanded(
              child: titleWidget ??
                  (title == null
                      ? const SizedBox.shrink()
                      : Text(
                          title!,
                          textAlign:
                              centerTitle ? TextAlign.center : TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        )),
            ),
            if (actions.isEmpty)
              const SizedBox(width: 48)
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                ...actions,
                const SizedBox(width: 8),
              ]),
          ],
        ),
      ),
    );
  }
}
