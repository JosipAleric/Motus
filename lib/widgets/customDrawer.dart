import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconify_design/iconify_design.dart';
import '../theme/app_theme.dart';

const double _kIconSize = 17.0;

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.borderRadius,
    this.isLogout = false,
  });

  final String icon;
  final String label;
  final String route;
  final BorderRadius borderRadius;
  final bool isLogout;

  void _navigateAndClose(BuildContext context) {
    GoRouter.of(context).pop();
    GoRouter.of(context).go(route);
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    GoRouter.of(context).pop();
    GoRouter.of(context).go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isLogout ? const Color(0xFFF22727) : AppColors.textPrimary;
    final Color backgroundColor = isLogout ? const Color(0x0bf22727) : AppColors.surfaceCard;
    final Color leadingIconBgColor = isLogout ? const Color(0x0bf22727) : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: leadingIconBgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconifyIcon(
            icon: icon,
            size: _kIconSize,
            color: isLogout ? itemColor : const Color(0xFF404040),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: itemColor,
                letterSpacing: 1.2,
              ),
            ),
            IconifyIcon(
              icon: "mdi:chevron-right",
              color: isLogout ? itemColor : AppColors.textSecondary,
            ),
          ],
        ),
        onTap: isLogout
            ? () => _signOut(context)
            : () => _navigateAndClose(context),
      ),
    );
  }
}

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(30);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const _DrawerHeaderContent(),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  _DrawerItem(
                    icon: "mdi:home",
                    label: "Početna",
                    route: "/",
                    borderRadius: borderRadius,
                  ),
                  _DrawerItem(
                    icon: "mdi:tools",
                    label: "Servisi",
                    route: "/services",
                    borderRadius: borderRadius,
                  ),
                  _DrawerItem(
                    icon: "mdi:gas-station",
                    label: "Gorivo",
                    route: "/fuel",
                    borderRadius: borderRadius,
                  ),
                  _DrawerItem(
                    icon: "mdi:account-circle",
                    label: "Profil",
                    route: "/profile",
                    borderRadius: borderRadius,
                  ),
                  const Divider(color: AppColors.divider),
                  _DrawerItem(
                    icon: "mdi:logout",
                    label: "Odjava",
                    route: "",
                    borderRadius: borderRadius,
                    isLogout: true,
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: _DrawerFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeaderContent extends StatelessWidget {
  const _DrawerHeaderContent();

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      padding: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.white),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 40,
                  height: 40,
                  colorFilter: ColorFilter.mode(AppColors.textPrimary, BlendMode.srcIn),
                ),
                const SizedBox(height: 10),
                const Text(
                  'MOTUS',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontFamily: "Michroma",
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => GoRouter.of(context).pop(), // Closes the drawer
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const <Widget>[
        Text(
          "Motus Copyright ©",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Sva prava pridržana',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}