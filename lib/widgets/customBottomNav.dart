import 'package:flutter/material.dart';
import 'package:iconify_design/iconify_design.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNav extends StatelessWidget {
  final Function(int)? onItemTapped;

  const CustomBottomNav({
    Key? key,
    this.onItemTapped,
  }) : super(key: key);

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouter.of(context).routeInformationProvider.value.location ?? '/';
    if (location.startsWith('/services')) return 1;
    if (location.startsWith('/refuels')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Home
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: const Offset(0, -0.5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(context, 'solar:home-bold-duotone', "Početna", 0, '/'),
                _buildNavItem(context, 'f7:wrench-fill', "Servisi", 1, '/services'),
                const SizedBox(width: 60),
                _buildNavItem(context, 'streamline-ultimate:trip-road', "Trip log", 3, '/refuels'),
                _buildNavItem(context, 'fluent:inprivate-account-24-filled', "Profil", 4, '/profile'),
              ],
            ),
          ),
          Positioned(
            top: -20,
            child: _buildCenterButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String icon, String label, int index, String route) {
    final selectedIndex = _getSelectedIndex(context);
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (index != 2) {
          GoRouter.of(context).go(route);
        } else if (onItemTapped != null) {
          onItemTapped!(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey.shade300 : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(14),
            child: IconifyIcon(
              icon: icon,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.black : const Color(0xFF606060),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        GoRouter.of(context).push('/add_service');
      },
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(15),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          const Text(
            "Novi",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF7A7A7A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

