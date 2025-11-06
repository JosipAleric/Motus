import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconify_design/iconify_design.dart';
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showAddCarButton;
  final String subtitle;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showAddCarButton = false,
    this.subtitle = '',
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openDrawer = ref.watch(drawerProvider);

    Widget leadingWidget;
    Widget actionWidget;

    if (GoRouter.of(context).canPop()) {
      // Use GestureDetector instead of IconButton to eliminate built-in padding
      leadingWidget = GestureDetector(
        onTap: () {
          GoRouter.of(context).pop();
        },
        // Wrap the icon in Padding.zero if you want a tiny buffer, or remove Padding entirely.
        child: Padding(
          padding: EdgeInsets.zero,
          child: IconifyIcon(icon: 'solar:arrow-left-broken', color: Color(0xFF000000), size: 20),
        ),
      );
    } else {
      leadingWidget = GestureDetector(
        onTap: openDrawer != null ? () => openDrawer() : null,
        child: Padding(
          padding: EdgeInsets.zero,
          child: IconifyIcon(icon: 'gg:menu-left', color: Color(0xFF4E4E4E), size: 20),
        ),
      );
    }

// --- Action Widget Modification ---
    if (showAddCarButton) {
      // Use GestureDetector instead of IconButton to eliminate built-in padding
      actionWidget = GestureDetector(
        onTap: () => GoRouter.of(context).go('/add_car'),
        child: Padding(
          padding: EdgeInsets.zero,
          child: IconifyIcon(icon: 'fa7-solid:plus', color: Color(0xFF4E4E4E), size: 18),
        ),
      );
    } else {
      actionWidget = GestureDetector(
        onTap: () => {GoRouter.of(context).pushNamed('settings')},
        child: Padding(
          padding: EdgeInsets.zero,
          child: IconifyIcon(icon: 'heroicons-outline:cog', color: Color(0xFF4E4E4E), size: 25),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: leadingWidget,
        leadingWidth: 27,
        scrolledUnderElevation: 0,
        actionsPadding: const EdgeInsets.all(0),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontFamily: "Michroma",
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [actionWidget],
      ),
    );
  }
}
